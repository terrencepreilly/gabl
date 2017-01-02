# Gabl

A (hopefully very) simple programming language compiling down
to a hideous language nobody should ever have to write,
read, parse, or stumble across.  **Gabl**'s main purpose is to
support easier extensions than **GAB**, type safety, and scope.

## Language Features (planned)
A BNF description of **Gabl** can be found in `docs/bnf.md`.

**Gabl** will have four primitive types: `num`, `str`, `bool`, `date`,
`null`.  There will be a primitive record type and arrays.

**Gabl** will support higher-order functions, and some basic
error handling.

Adding modules from GAB, once the main control structures
and such have been determined, should be easy.  They will
be described in a translation file, using YAML (see
`docs/translation_files.md`.)

## Example

Just as a quick example of what I imagine **Gabl** to look
like:

Printing:

```gabl
sub hello(str name) {
  Msg("Hello, " + name);
}
```

Fibonacci sequence:

```gabl
sub fib(num limit) {
  num[] ret <- [1, 1];
  num a <- 1;
  num b <- 1;
  num c <- a + b;

  while (c < limit) {
    ret << c;
    a <- b;
    b <- c;
    c <- a + b;
  }

  return ret;
}
```

Error checking:

```gabl
sub throwsError() {
  throw 'Bad programming problem';
}

sub handleError(str error) {
  Msg(error);
}

sub main() {
  handle(handleError) {
    throwsError();
  }
}
```
