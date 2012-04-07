;;; expectations-mode.el --- Minor mode for expectations tests

;; Author: Gareth Jones <gareth.e.jones@gmail.com>
;; Version: 0.0.1
;; Keywords: languages, lisp, test
;; Package-Requires: ((slime "20091016") (clojure-mode "1.7"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file provides support for running Clojure tests (using the
;; expectations framework) via SLIME and seeing feedback in the test
;; buffer about which tests failed or errored.

;; This library is based on the clojure-test-mode by Phil Hagelberg,
;; so many thanks to him :D

;;; Code:

(require 'clojure-mode)
(require 'slime)

(defun expectations-eval (string &optional handler)
  (slime-eval-async `(swank:eval-and-grab-output ,string)
                    (or handler #'identity)))

(defun expectations-eval-sync (string)
  (slime-eval `(swank:eval-and-grab-output ,string)))

(defun expectations-test-clear (&optional callback)
  "unmap generated vars for expectations"
  (interactive)
  (expectations-eval
   "(disable-run-on-shutdown)
    (doseq [[a b] (ns-interns *ns*)
            :when ((meta b) :expectation)]
      (ns-unmap *ns* a))"
   callback))

(defun expectations-get-results (result)
  (message result))

(defun expectations-run-tests ()
  "Run all the tests in the current namespace."
  (interactive)
  (save-some-buffers nil (lambda () (equal major-mode 'clojure-mode)))
  (message "Testing...")
  (expectations-test-clear)
  (save-window-excursion
    (clojure-test-clear
     (lambda (&rest args)
       (slime-eval-async `(swank:load-file
                           ,(slime-to-lisp-filename
                             (expand-file-name (buffer-file-name))))
                         (lambda (&rest args)
                           (slime-eval-async '(swank:interactive-eval
                                               "(run-tests [*ns*])")
                                             #'expectations-get-results)))))))

(defvar expectations-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c ,") 'expectations-run-tests)
    (define-key map (kbd "C-c C-,") 'expectations-run-tests)
    (define-key map (kbd "C-c k") 'expectations-test-clear)
    map))

(define-minor-mode expectations-mode
  "A minor mode for running expectations tests"
  nil " Test" expectations-mode-map
  ;; (when (slime-connected-p)
  ;;   (expectations-init))
  )

;;; expectations-mode.el ends here
