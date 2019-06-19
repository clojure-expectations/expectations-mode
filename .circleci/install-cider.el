(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'cider)
  (setq network-security-level 'low)
  (package-refresh-contents)
  (package-install 'cider))
