(require 'clojure-mode)
(require 'slime)

(defun expectations-eval (string &optional handler)
  (slime-eval-async `(swank:eval-and-grab-output ,string)
                    (or handler #'identity)))

(defun expectations-eval-sync (string)
  (slime-eval `(swank:eval-and-grab-output ,string)))


