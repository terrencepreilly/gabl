import 'utils.dart';

RegExp STRING_LITERAL = new RegExp(r'".*?"');
RegExp NUMERIC_LITERAL = new RegExp(r'[\d\.]+');
RegExp BOOL_LITERAL = new RegExp(r'true|false');

RegExp CHARACTER = new RegExp(r'[a-zA-Z]');
RegExp NUMERIC = new RegExp(r'\d');
RegExp OPERATORS = new RegExp(r'[\+\-\*\/]');
RegExp DELIMITERS = new RegExp(r'[\(\)\{\}\;\,]');

List<String> TYPES = const ['num', 'str', 'bool', 'date'];
List<String> CTRLS = const ['if', 'while', 'for', 'else'];
List<String> OPERS = const ['+', '-', '*', '/'];

enum TokenType {
    function,
    name,
    type,
    literal,
    control,
    operator,
    openblock,
    closeblock,
    openparen,
    closeparen,
    semicolon,
}


class Token {
    String symbol;

    Token(this.symbol);

    TokenType get type {
        if (this.symbol == 'sub')
            return TokenType.function;
        else if ('{' == this.symbol)
            return TokenType.openblock;
        else if ('}' == this.symbol)
            return TokenType.closeblock;
        else if ('(' == this.symbol)
            return TokenType.openparen;
        else if (')' == this.symbol)
            return TokenType.closeparen;
        else if (';' == this.symbol)
            return TokenType.semicolon;
        else if (TYPES.any((x) => x == this.symbol))
            return TokenType.type;
        else if (CTRLS.any((x) => x == this.symbol))
            return TokenType.control;
        else if (OPERS.any((x) => x == this.symbol))
            return TokenType.operator;
        else if (NUMERIC_LITERAL.hasMatch(this.symbol)
            || STRING_LITERAL.hasMatch(this.symbol))
            return TokenType.literal;
        return TokenType.name;
    }

    String toString() {
        return this.symbol;
    }
}


Iterable tokenize(String script) sync* {
    String buff = '';
    Iterable iter = new Iterable.generate(script.length, (int i) => script[i]);
    SimpleStream<String> ss = new SimpleStream(new List<String>.from(iter));

    while (ss.hasNext()) {
        // handle string literals!
        if (CHARACTER.hasMatch(ss.peek())) {
            while (ss.hasNext()
                    && (CHARACTER.hasMatch(ss.peek())
                        || NUMERIC.hasMatch(ss.peek()))) {
                buff += ss.next();
            }
            yield new Token(buff);
            buff = '';
        } else if (NUMERIC.hasMatch(ss.peek())) {
            while (ss.hasNext() && NUMERIC.hasMatch(ss.peek())) {
                buff += ss.next();
            }
            yield new Token(buff);
            buff = '';

        } else if (OPERATORS.hasMatch(ss.peek())
                || DELIMITERS.hasMatch(ss.peek())) {
            yield new Token(ss.next());

        } else if (ss.peek() == "'") {
            ss.nextWhich((x) => x == '\n');
            if (ss.hasNext())
                ss.next();
        } else if (ss.peek() == '"') {
            buff += ss.next();
            while (ss.hasNext() && ss.peek() != '"') {
                buff += ss.next();
            }
            if (ss.hasNext())
                buff += ss.next();
            yield new Token(buff);
            buff = '';
        } else {
            ss.next();
        }
    }
}
