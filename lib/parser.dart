import 'lexer.dart';
import 'utils.dart';

enum NodeType {
    script,
    expression,
    declaration,
    // structures
    submodule,
    control,
    // variables
    name,
    string,
    numeric,
    boolean,
    date,
}

/* --------------------PARSER------------------------ */

class Node {
    NodeType type;
    String value;
    Node body;

    Node({this.type: null, this.value:  null, this.body: null});
}


Node parse(SimpleStream<Token> ss) {
    return null;
}

Node parse_name(SimpleStream<Token> ss) {
    if (ss.hasNext() && ss.peek().type == TokenType.name) {
        Token t = ss.next();
        if (ss.hasNext() && ss.peek().type != TokenType.semicolon)
            return null;
    }
}


main() {
    String script = '''
        sub fn(str a, int b) {
            Msg("hello"); 'Say hi
        }
    ''';
    print(tokenize(script));
}
