;;; expectations-mode.el --- Minor mode for expectations tests

;; Author: Gareth Jones <gareth.e.jones@gmail.com>
;; Version: 0.0.4
;; Keywords: languages, lisp, test
;; Package-Requires: ((nrepl "0.1.5") (clojure-mode "1.11"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file provides support for running Clojure tests (using the
;; expectations framework) via nrepl and seeing feedback in the test
;; buffer about which tests failed or errored.

;; This library is based on the clojure-test-mode by Phil Hagelberg.

;;; History:

;; 0.0.1: 2012-04-10
;;  * initial release

;; 0.0.2: 2012-04-21
;;  * dont remove clojure-mode-hook for clojure-test-mode
;;  * you must now have your expectations files in an 'expectations'
;;    ns for the mode to automatically turn on.

;; 0.0.3: 2012-10-23
;;  * ported to run on nrepl
;;  * changed regexp for looking for expectations mode to match
;; foo-expectations also

;; 0.0.4: 2012-10-25
;;  * fix issue with having to compile tests before running

;;; Code:

(require 'clojure-mode)
(require 'nrepl-client)
(require 'cider-interaction)

(defface expectations-failure-face
  '((((class color) (background light))
     :background "orange red")
    (((class color) (background dark))
     :background "firebrick"))
  "Face for failures in expectations tests."
  :group 'expectations-mode)

(defface expectations-error-face
  '((((class color) (background light))
     :background "orange1")
    (((class color) (background dark))
     :background "orange4"))
  "Face for errors in expectations tests."
  :group 'expectations-mode)

(defface expectations-success-face
  '((((class color) (background light))
     :foreground "black"
     :background "green")
    (((class color) (background dark))
     :foreground "black"
     :background "green"))
  "Face for success in expectations tests."
  :group 'expectations-mode)

;; vars to keep count of all/failed/errored tests

(defvar expectations-count         0)
(defvar expectations-failure-count 0)
(defvar expectations-error-count   0)

(defconst expectations-valid-results
  '(:success :fail :error)
  "Results we are interested in reporting on")

(defun expectations-response-handler (callback stdout-handler)
  (lexical-let ((buffer (current-buffer))
                (callback callback)
                (stdout-handler stdout-handler))
    (nrepl-make-response-handler buffer
                                 (lambda (buffer value)
                                   (funcall callback buffer value))
                                 (lambda (buffer value)
                                   (when stdout-handler
                                     (funcall stdout-handler value))
                                   (cider-repl-emit-interactive-output value))
                                 (lambda (buffer err)
                                   (message (format "%s" err)))
                                 '())))

(defun expectations-eval (string &optional handler stdout-handler synch)
  (if synch
      (funcall handler (current-buffer)
               (plist-get (nrepl-send-string-sync string (cider-current-ns)) :value)
               synch)
    (nrepl-send-string string
                       (expectations-response-handler (or handler #'identity) stdout-handler)
                       (cider-current-ns))))

(defun expectations-test-clear (&optional callback synch)
  "Clear all counters and unmap generated vars for expectations"
  (interactive)
  (remove-overlays)
  (setq expectations-count         0
        expectations-failure-count 0
        expectations-error-count   0)
  (expectations-eval
   "(do
      (require 'expectations)
      (expectations/disable-run-on-shutdown)
      (doseq [[a b] (ns-interns *ns*)
              :when ((meta b) :expectation)]
        (ns-unmap *ns* a)))"
   callback nil synch))

(defun expectations-highlight-problem (line event msg)
  (save-excursion
    (goto-line line)
    (let ((beg (point)))
      (end-of-line)
      (let ((overlay (make-overlay beg (point))))
        (overlay-put overlay 'face (if (equal event :fail)
                                       'expectations-failure-face
                                     'expectations-error-face))
        (overlay-put overlay 'message msg)))))

(defun expectations-inc-counter-for (event)
  (when (member event expectations-valid-results)
    (incf expectations-count))
  (cond
   ((equal :fail event)  (incf expectations-failure-count))
   ((equal :error event) (incf expectations-error-count))))

(defun expectations-extract-result (result)
  (expectations-inc-counter-for (car result))
  (when (or (eq :fail (car result))
            (eq :error (car result)))
    (destructuring-bind (event msg line) (coerce result 'list)
      (expectations-highlight-problem line event msg))))

(defun expectations-echo-results ()
  (expectations-update-compilation-buffer-mode-line)
  (message
   (propertize
    (format "Ran %s tests. %s failures, %s errors."
            expectations-count expectations-failure-count
            expectations-error-count)
    'face
    (cond ((not (= expectations-error-count 0)) 'expectations-error-face)
          ((not (= expectations-failure-count 0)) 'expectations-failure-face)
          (t 'expectations-success-face)))))

(defun expectations-extract-results (buffer value &optional synch)
  (with-current-buffer buffer
    (let ((results (read value)))
      (mapc #'expectations-extract-result results)
      (expectations-echo-results))))

(defun expectations-run-and-extract-results (runner-fn buffer value &optional synch)
  (expectations-kill-compilation-buffer)
  (with-current-buffer buffer
    (cider-load-current-buffer)
    (expectations-eval
     (format "(do
        %s
        (for [[n s] (ns-interns *ns*)
              :let [m (meta s)]
              :when (:expectation m)]
          (apply list (:status m))))" (funcall runner-fn))
     #'expectations-extract-results
     #'expectations-display-compilation-buffer
     synch)))

(defun expectations-run-tests (&optional synch)
  "Run all the tests in the current namespace."
  (interactive)
  (save-some-buffers nil (lambda () (equal major-mode 'clojure-mode)))
  (message "Testing...")
  (save-window-excursion
    (expectations-test-clear (apply-partially #'expectations-run-and-extract-results
                                              (lambda () "(expectations/run-tests [*ns*])")) synch)))

(defun expectations-show-result ()
  (interactive)
  (let ((overlay (find-if (lambda (o) (overlay-get o 'message))
                          (overlays-at (point)))))
    (if overlay
        (message (replace-regexp-in-string "%" "%%"
                                           (overlay-get overlay 'message))))))

(defvar expectations-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c ,")   'expectations-run-tests)
    (define-key map (kbd "C-c C-,") 'expectations-run-tests)
    (define-key map (kbd "C-c M-,") 'expectations-run-test)
    (define-key map (kbd "C-c k")   'expectations-test-clear)
    (define-key map (kbd "C-c '")   'expectations-show-result)
    map))

;;;###autoload
(define-minor-mode expectations-mode
  "A minor mode for running expectations tests"
  nil " Expectations" expectations-mode-map)

;;;###autoload
(progn
  (defun expectations-maybe-enable ()
    "Enable expectations-mode and disable clojure-test-mode if
the current buffer contains a namespace with a \"test.\" bit on
it."
    (let ((ns (clojure-find-package)))  ; defined in clojure-mode.el
      (when (or (search "expectations." ns)
                (search "-expectations" ns))
        (save-window-excursion
          (expectations-mode t)
          (clojure-test-mode 0)))))
  (add-hook 'clojure-mode-hook 'expectations-maybe-enable))

;; Compilation mode spike

(defun expectations-extract-filename ()
  (let* ((ns (match-string 2))
         (filename
          (read
           (plist-get (nrepl-send-string-sync (format "(-> \"%s\" symbol ns-publics first val meta :file)" ns)
                                              (cider-current-ns))
                      :value))))
    (list filename)))

(defun expectations-kill-compilation-buffer ()
  (when (get-buffer "*expectations*")
    (delete-windows-on (get-buffer "*expectations*"))
    (kill-buffer "*expectations*")))

(defun expectations-update-compilation-buffer-mode-line ()
  (with-current-buffer (get-buffer "*expectations*")
    (compilation-handle-exit  (cond ((not (= expectations-error-count 0)) "error")
                                    ((not (= expectations-failure-count 0)) "failure")
                                    (t "success"))
                              (+ expectations-failure-count expectations-error-count) "")))

(defun expectations-display-compilation-buffer (out)
  (with-current-buffer (get-buffer-create "*expectations*")
    (expectations-results-mode)
    (cider-emit-into-color-buffer (current-buffer) out)
    (display-buffer (current-buffer))
    (setq next-error-last-buffer (current-buffer))
    (compilation-set-window-height (get-buffer-window "*expectations*"))))

(add-to-list 'compilation-error-regexp-alist 'expectations)
(add-to-list 'compilation-error-regexp-alist-alist
             '(expectations "\\(?:failure\\|error\\) in (.+:\\([[:digit:]]+\\)) : \\(.+\\)"
                            expectations-extract-filename
                            1))

(define-compilation-mode expectations-results-mode "Expectations" ""
  (setq compilation-window-height 10))

;; Running single tests

(defun expectations-test-at-point ()
  (interactive)
  (let ((clj (format "(first (filter (fn [v] (>= (-> v meta :line) %d))
                                     (sort-by (comp :line meta) (vals (ns-publics (find-ns '%s))))))"
                     (line-number-at-pos)
                     (cider-current-ns))))
    (plist-get (nrepl-send-string-sync clj (cider-current-ns)) :value)))

(defun expectations-run-test (&optional synch)
  "Run test at point"
  (interactive)
  (save-some-buffers nil (lambda () (equal major-mode 'clojure-mode)))
  (message "Testing...")
  (save-window-excursion
    (expectations-test-clear (apply-partially #'expectations-run-and-extract-results
                                              (lambda ()
                                                (format
                                                 "(when-let [t %s] (expectations/run-tests-in-vars [t]))"
                                                 (expectations-test-at-point)))) synch)))

(provide 'expectations-mode)

;;; expectations-mode.el ends here
