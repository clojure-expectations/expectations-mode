# Expectations Mode

A minor Emacs mode for running
[Expectations](https://github.com/jaycfields/expectations), based upon
[Clojure test
mode](https://github.com/technomancy/clojure-mode/blob/master/clojure-test-mode.el).

## Installation

*Please note Expectations v1.3.7 or greater is required to use expectations-mode.*

Download expectations-mode.el, put it somewhere on your Emacs load
path, and require it inside of init.el.

```lisp
(require 'expectations-mode)
```

This will add a `clojure-mode-hook` to enable `expectations-mode`
whenever a Clojure test file is opened that has referenced
Expectations through a `:use` in the namespace.

## Usage

Current key mappings are:

```
C-c ,    run tests in ns
C-c C-,  run tests in ns
C-c C-k  clear test results
C-c '    show message for test under cursor
```

The keybindings are a subset of the bindings used in
`clojure-test-mode` and work the same way.
 
## License

Distributed under the GNU General Public License; see C-h t to view.