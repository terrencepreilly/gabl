# BNF for Gabl

<import> -> from <name> import <name>;

<except> -> except (<name>) <block>

<for-loop> -> for (<type-pair> ; <stmt> ; <stmt>) <block>

<while-loop> -> while ( <stmt> ) <block>

<if-stmt> -> if ( <stmt> ) <block>

<submodule> -> sub <name> <param> <sub-block>

<sub-block> -> { <sequence> [return <expr>] }

<block> -> { <sequence> }

<sequence> -> <expr> [<sequence>]
  | ϵ

<return> -> return <name>
  | return <literal>

<declare> -> <type-pair>;

<assign> -> <name> = <expr>

<expr> -> <stmt> ;

<stmt> -> <name>|<literal> {<oper> <stmt>}
  | <submodule> {<oper> <stmt>}
  | ( <stmt> )


<param> -> ( [<type-pair>] )
  | ( <type-pair> {,<type-pair>} )

<type-pair> -> <type> <name>

## Token definitions

<literal> -> <string>
  | <numeric>
  | <bool>
  | <date>
  | <null>

<oper> -> +
  | -
  | +
  | *
  | /
  | |
  | &

<name> -> <alpha><alpha-num>
  | <alpha>

<alpha> -> [a-zA-Z_]
<alpha-num> -> [a-zA-Z_0-9]

<string> -> ".?"

<numeric> -> \d*\.+\d*

<bool> -> true
  | false

<date> -> \d{2}/\d{2}/\d{2}

<null> -> null
