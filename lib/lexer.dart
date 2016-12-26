import 'utils.dart';

RegExp STRING_LITERAL = new RegExp(r'".*?"');
RegExp NUMERIC_LITERAL = new RegExp(r'\b\d+\.?\d*');
RegExp BOOL_LITERAL = new RegExp(r'true|false');

RegExp CHARACTER = new RegExp(r'[a-zA-Z]');
RegExp NUMERIC = new RegExp(r'\d');
RegExp OPERATORS = new RegExp(r'[\+\-\*\/><]');
RegExp DELIMITERS = new RegExp(r'[\(\)\{\}\;\,]');

List<String> TYPES = const ['num', 'str', 'bool', 'date'];
List<String> CTRLS = const ['if', 'while', 'for', 'else', 'elif',
                            'return', 'handle', 'import'];
List<String> OPERS = const ['+', '-', '*', '/', '=', '>', '<'];

enum TokenType {
    submodule,
    name,
    type,
    str,
    bool,
    num,
    date,
    control,
    operator,
    openblock,
    closeblock,
    openparen,
    closeparen,
    semicolon,
    assign,
    comma,
}

const List<TokenType> LITERAL = const [
    TokenType.num,
    TokenType.str,
    TokenType.bool,
    TokenType.date,
    ];




class Token {
    String symbol;

    Token(this.symbol);

    TokenType get type {
        if (this.symbol == 'sub')
            return TokenType.submodule;
        else if (',' == this.symbol)
            return TokenType.comma;
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
        else if ('<-' == this.symbol)
            return TokenType.assign;
        else if (TYPES.any((x) => x == this.symbol))
            return TokenType.type;
        else if (CTRLS.any((x) => x == this.symbol))
            return TokenType.control;
        else if (OPERS.any((x) => x == this.symbol))
            return TokenType.operator;
        else if (NUMERIC_LITERAL.hasMatch(this.symbol))
            return TokenType.num;
        else if (STRING_LITERAL.hasMatch(this.symbol))
            return TokenType.str;
        else if (BOOL_LITERAL.hasMatch(this.symbol))
            return TokenType.bool;
        return TokenType.name;
    }

    String toString() {
        return this.symbol;
    }
}


/* TODO: break into individual functions */
Iterable tokenize(String script) sync* {
    String buff = '';
    Iterable iter = new Iterable.generate(script.length, (int i) => script[i]);
    SimpleStream<String> ss = new SimpleStream(new List<String>.from(iter));

    while (ss.hasNext()) {
        if (CHARACTER.hasMatch(ss.peek())) {
            while (ss.hasNext()
                    && (CHARACTER.hasMatch(ss.peek())
                        || NUMERIC.hasMatch(ss.peek())))
                buff += ss.next();
            yield new Token(buff);
            buff = '';
        } else if (NUMERIC.hasMatch(ss.peek())) {
            while (ss.hasNext() && NUMERIC.hasMatch(ss.peek()))
                buff += ss.next();
            if (ss.hasNext() && ss.peek() == '.') {
                buff += ss.next();
                while (ss.hasNext() && NUMERIC.hasMatch(ss.peek()))
                    buff += ss.next();
            }
            yield new Token(buff);
            buff = '';
        } else if (ss.peek() == '<') {
            buff += ss.next();
            if (ss.hasNext() && ss.peek() != '-') {
                yield new Token(buff);
                buff = '';
            } else if (ss.hasNext()) {
                yield new Token(buff + ss.next());
                buff = '';
            }
        } else if (OPERATORS.hasMatch(ss.peek())
                || DELIMITERS.hasMatch(ss.peek())) {
            yield new Token(ss.next());

        } else if (ss.peek() == "'") {
            ss.nextWhich((x) => x == '\n');
            if (ss.hasNext())
                ss.next();
        } else if (ss.peek() == '"') {
            buff += ss.next();
            while (ss.hasNext() && ss.peek() != '"')
                buff += ss.next();
            if (ss.hasNext())
                buff += ss.next();
            yield new Token(buff);
            buff = '';
        } else {
            ss.next();
        }
    }
}
