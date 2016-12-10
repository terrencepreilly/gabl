import 'lexer.dart';
import 'utils.dart';


class Node {
    String type;
    String value;
    List<Node> children;

    Node({this.type, this.value})
        : children = new List<Node>();

    addChild(Node n) {
        this.children.add(n);
    }

    childAt(int i) {
        return this.children[i];
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
    } else if (ss.peek().type != TokenType.operator
            && ss.peek().symbol != '=') {
        throw new ParserError('Expected ";" or "="');
    } else {
        Node eq = new Node(type: 'operator', value: ss.next().symbol);
        eq.addChild(type);
        eq.addChild(parse_str(ss)); // TODO change expression
    }
    return type;
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
    if (ss.peek().type != TokenType.literal
            && ! STRING_LITERAL.hasMatch(ss.peek().symbol))
        throw new ParserError('Expected a str');
    return new Node(type: 'str', value: ss.next().symbol);
}

main() {
}
