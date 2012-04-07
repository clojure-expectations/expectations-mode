# Expectations Mode

A minor Emacs mode for running Expectations tests.

## Installation

Download expectations-mode.el, put it somewhere on your Emacs load
path, and require it inside of init.el.

```lisp
(require 'expectations-mode)
```

## Usage

There is no hook to enable expectations-mode at the moment, so you
need to do that manually with `M-x expectations-mode`.

There are very basic features currently, only the ability to run the
tests with `C-c ,` or `C-c C-,`. The expectations summary will be
shown in the minibuffer and the full output will be in the slime repl.

## License

Initially based upon (Clojure Test Mode)[https://github.com/technomancy/clojure-mode/blob/master/clojure-test-mode.el].

Distributed under the GNU General Public License; see C-h t to view.