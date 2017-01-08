# BNF for Gabl

<import> -> from <name> import <name>;

<except> -> except (<name>) <block>

<for-loop> -> for (<type-pair> ; <stmt> ; <stmt>) <block>

<while-loop> -> while ( <stmt> ) <block>

<if-stmt> -> if ( <stmt> ) <block>

<submodule> -> <type> sub <name> <param> <sub-block>

<sub-block> -> { <sequence> [return <expr>] }

<block> -> { <sequence> }

<sequence> -> <expr> [<sequence>]
  | ϵ

<return> -> return <name>
  | return <literal>

<declare> -> <type-pair>;

<define> -> <name> <- <expr>

<expr> -> <stmt> ;

<stmt> -> <name>|<literal> {<oper> <stmt>}
  | <submodule> {<oper> <stmt>}
  | ( <stmt> )
  | <stmt>

<stmt> -> NULL
  | <name>|<literal> [<oper> <stmt>]
  | <submodule> [<oper> <stmt>]
  | (<stmt>)


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
  | =

<assign> -> <-

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

