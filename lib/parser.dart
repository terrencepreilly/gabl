import 'lexer.dart';
import 'utils.dart';


class Node {
    String type;
    String value;
    List<Node> children;

    Node({this.type, this.value})
        : children = new List<Node>();

    addChild(Node n) {
        children.add(n);
    }

    childAt(int i) {
        return children[i];
    }

    String toString() {
        int half = children.length ~/ 2;
        String ret = '(';
        for (int i = 0; i < half; i++) {
            ret += childAt(i).toString() + ' ';
        }
        ret += value;
        for (int i = half; i < children.length; i++) {
            ret += ' ' + childAt(i).toString();
        }
        ret += ')';
        return ret;
    }
}


class ParserError extends Error {
    String msg;

    ParserError([String msg = '']);

    String toString() => this.msg;
}


Node parse(SimpleStream<Token> ss) {
    return null;
}


Node parse_definition(SimpleStream<Token> ss) {
    Node type = parse_type(ss);
    type.addChild(parse_name(ss));
    if (ss.peek().type == TokenType.semicolon) {
        ss.next();
        return type;
    } else if (ss.hasNext() && (ss.peek().type != TokenType.assign)) {
        print('${ss.peek().type} ${ss.peek().symbol}');
        //throw new ParserError('Expected ";" or "<-"');
    } else {
        Node eq = new Node(type: 'assign', value: ss.next().symbol);
        eq.addChild(type);
        eq.addChild(parse_str(ss)); // TODO change to expression
        return eq;
    }
}


Node parse_name(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.name)
        throw new ParserError('Expected a name');
    return new Node(type: 'name', value: ss.next().symbol);
}


Node parse_type(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.type)
        throw new ParserError('Expected a type');
    return new Node(type: 'type', value: ss.next().symbol);
}


Node parse_str(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.str)
        throw new ParserError('Expected a str');
    return new Node(type: 'str', value: ss.next().symbol);
}


main() {
    String script = '''
        str a <- "hello";
    ''';
    SimpleStream<Token> ss = new SimpleStream<Token>(
        new List<Token>.from(tokenize(script)));
    print(parse_definition(ss));
}
