# Todo list

_\( managed using [todo-md](https://github.com/Hypercubed/todo-md) \)_

- [ ] general
  - [x] replace `num` with `int`, and add `float`
  - [ ] add `num` back, but for parameters/returns which
        can be either `int` or `float`.
  - [ ] add return type to submodules
- [ ] parser
  - [ ] submodule
    - [x] calling subs in submodules
    - [ ] calling subs with named parameters
- [ ] translate
  - [ ] handle global/local variables
  - [ ] handle scope
  - [ ] expressions
  - [ ] submodule call
  - [ ] handle statement
  - [ ] submodule definition
  - [ ] variable declaration
  - [ ] control structures
    - [ ] for loops
    - [ ] while loops
    - [ ] if-then-else statements

- [ ] <- is parsed as a sub-call.  Fix this so that it is just parsed as assign
     or handle elsewhere.
