# Expectations Mode

[![Circle CI](https://circleci.com/gh/clojure-expectations/expectations-mode.svg?style=svg)](https://circleci.com/gh/clojure-expectations/expectations-mode)

A minor Emacs mode for running
[Expectations](https://github.com/jaycfields/expectations), based upon
[Clojure test
mode](https://github.com/technomancy/clojure-mode/blob/master/clojure-test-mode.el).

## Important

Versions 0.0.2 and lower use swank, version 0.0.3 and greater use
nrepl. Going forward, only nrepl will be supported.

## Installation

*Please note Expectations v1.3.7 or greater is required to use expectations-mode.*

You can either install the package manually or use the package manager package.el.

To install using the package manager, add the marmalade repo to your package-archives:

```lisp
(require 'package)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/") t)
```

And package-install expectations-mode in the usual way.

To install manually, download expectations-mode.el, put it somewhere on your Emacs load
path, and require it inside of init.el

```lisp
(require 'expectations-mode)
```

This will add a `clojure-mode-hook` to enable `expectations-mode`
whenever a Clojure test file is opened that has a namespace with
'expectations.' or '-expectations' inside of it.

For example namespaces like...

```lisp
(ns myproject.expectations.core
  (:use expectations))

(ns myproject.core-expectations
  (:use expectations))
```

...will cause `expectations-mode` to automatically activate. Where as
namespaces like:

```lisp
(ns myproject.test.core
  (:use clojure.test))
```

...will be ignored.

## Colours

Expectations colourises its output by default. To turn this off and
get rid of the annoying characters in your output, add this to your
init.el in an appropriate place:

```lisp
(setenv "EXPECTATIONS_COLORIZE" "false")
```

## Usage

Current key mappings are:

```
C-c ,    run tests in ns
C-c C-,  run tests in ns
C-c k    clear test results
C-c '    show message for test under cursor
```

The keybindings are a subset of the bindings used in
`clojure-test-mode` and work the same way.

The shortcuts to run individual tests are not required, as you
generally use the `-focus` version of the expectations macros to run
an expectation in isolation.

## License

Distributed under the GNU General Public License; see C-h t to view.
