Translation files are the means of importing GAB functionality into gabl.
They are written in yaml with the general format:

```yaml
- module: name
- functions:
  - gabl name:
    name: Gab Name
    params:
      - type
      - type
    return: type
    doc: An explanation of the function.
- variables:
  - type:
    - name
    - name
```

For example a module for message boxes could look like:

```yaml
- module: io.msg
- functions:
  - Msg:
    name: F.Intrinsic.UI.Msgbox
    params:
       - str
    return:
- variables:
```

Then, in the gabl script, you would write something like:

```gabl
import io.msg;

sub main() {
  Msg("Hello world!");
}
```

And gabl will translate it, using the above definition, to:

```GAB
Program.Sub.Main.Start
F.Intrinsic.UI.Msgbox("Hello world!");
Program.Sub.Main.End
```
