# Gabl

A (hopefully very) simple programming language compiling down
to a hideous language nobody should ever have to write,
read, parse, or stumble across.  **Gabl**'s main purpose is to
support easier extensions than **GAB**, type safety, and scope.

## Language Features (planned)
A BNF description of **Gabl** can be found in `docs/bnf.md`.

**Gabl** will have six primitive types: `int`, `float`, `str`,
`bool`, `date`, `null`.  There will be a primitive record
type and arrays.

**Gabl** may eventually support higher-order functions, and
some basic error handling.  However, the main focus is
on better clarity of syntax, and on implementing scope.

Adding modules from GAB, once the main control structures
and such have been determined, should be easy.  They will
be described in a translation file, using YAML (see
`docs/translation_files.md`.)  This will also allow for
dyadic/monadic operator overriding. (Since operators are
defined in an include file, just as all other functions.)

## Example

Just as a quick example of what I imagine **Gabl** to look
like:

Printing:

```gabl
null sub hello(str name) {
  Msg("Hello, " + name);
}
```

Fibonacci sequence:

```gabl
int sub fib(int limit) {
  int[] ret <- [1, 1];
  int a <- 1;
  int b <- 1;
  int c <- a + b;

  while (c < limit) {
    ret ++ c;
    a <- b;
    b <- c;
    c <- a + b;
  }

  return ret;
}
```

Error checking:

```gabl
import stdlib;

null sub throwsError() {
  throw 'Bad programming problem';
}

null sub handleError(str error) {
  Msg(error);
}

null sub main() {
  handle(handleError) {
    throwsError();
  }
}
```
