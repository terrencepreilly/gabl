# A description of certain parts of the AST.

## If statements

### Example 1
Simple if statements such as
```gabl
if (a > 0) {
  a <- a + 1;
}
```
are parsed as
```
    (control, "if)
      /          \
(operator, >)     (block, )
    /      \          \
(name, a) (num, 0)    (assign, <-)
                       /        \
                  (name, a)  (operator, +)
                               /     \
                        (name, a)  (num, 1)
```
for which, the conditional statement is the first child, and the
block is the second child.

### Example 2
If we have multiple conditions in succession (an else-if) such as
```gabl
if (false) {}
elif (true) {}
```
then it is rendered as the third child (the `else` part):
```
          (control, if)
         /     |      \
        /      |       \
       /       |        \
(bool, false) (block, ) (control, elif)
                          /       \
                    (bool, true)  (block, )
```

### Example 3
The chain is continued:
```gabl
if (a) {}
elif (b) {}
elif (c) {}
else {}
```
becomes
```
              (control, if)
              /     |      \
             /      |       \
     (name, a)  (block,)    (control, elif)
                           /     |       \
                          /      |        \
                  (name, b)   (block,)  (control, elif)
                                        /   |      \
                                       /    |       \
                                (name, c) (block,) (control, else)
                                                     |
                                                     |
                                                (block,)
```

### Example 4
A single else statement looks similar to the above,
but with `else` instead of `elif`:
```gabl
if (false) {}
else {}
```
which becomes
```
          (control, if)
         /     |      \
        /      |       \
       /       |        \
(bool, false) (block, ) (control, else)
                             |
                          (block, )
```
Which, of course, has only one child.
