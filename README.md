# Gabl

A (hopefully very) simple programming language compiling down
to a hideous language nobody should ever have to write,
read, parse, or stumble across.  _Gabl_'s main purpose is to
support easier extensions than _GAB_, type safety, and scope.

## Language Features (planned)
A BNF description of _Gabl_ can be found in `docs/bnf.md`.

_Gabl_ will have four primitive types: `num`, `str`, `bool`, `date`,
`null`.  There will be a primitive record type and arrays.

_Gabl_ will support higher-order functions, and some
extremely generic error handling.

## Why Dart?
I chose to write this in _Dart_ mostly for fun.  Also, if
I ever would like to transpile this project to _Javascript_,
I could support a web interface.
