# Gabl

A (hopefully very) simple programming language compiling down
to a hideous language nobody should ever have to write,
read, parse, or stumble across.  *Gabl*'s main purpose is to
support easier extensions than *GAB*, type safety, and scope.

## Language Features (planned)
A BNF description of *Gabl* can be found in `docs/bnf.md`.

*Gabl* will have four primitive types: `num`, `str`, `bool`, `date`,
`null`.  There will be a primitive record type and arrays.

*Gabl* will support higher-order functions, and some basic
error handling.

## Why Dart?
I chose to write this in *Dart* mostly for fun.  Also, if
I ever would like to transpile this project to *Javascript*,
I could support a web interface.

## Example

Just as a quick example of what I imagine *Gabl* to look
like:

Printing:

```gabl
sub hello(str name) {
  Msg("Hello, " + name);
}
```

Fibonacci sequence:

```gabl
sub fib(int limit) {
  int[] ret <- [1, 1];
  int a <- 1;
  int b <- 1;
  int c <- a + b;

  while (c < limit) {
    ret << c;
    a <- b;
    b <- c;
    c <- a + b;
  }

  return ret;
}
```
