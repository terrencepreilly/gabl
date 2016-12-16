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


Node parse_expression(SimpleStream<Token> ss) {
    if (ss.hasNext() && ss.peek().type == TokenType.semicolon) {
        ss.next();
        return new Node(type: 'nop', value: '');
    }
    Node n = parse_statement(ss);
    return n;
}


Node parse_statement(SimpleStream<Token> ss) {
    if (! ss.hasNext()) {
        return new Node(type: 'nop', value: '');
    } else if (ss.peek().type == TokenType.num) {
        Node n = parse_num(ss);
        if (ss.hasNext() && ss.peek().type == TokenType.operator) {
            return parse_expression_operator(ss, n);
        }
        return n;
    } else if (ss.peek().type == TokenType.openparen) {
        Node n = parse_parenthetical(ss);
        if (ss.hasNext() && ss.peek().type == TokenType.operator)
            return parse_expression_operator(ss, n);
        return n;
    }
}

Node parse_expression_operator(SimpleStream<Token> ss, Node n) {
//    if (ss.peek().type != TokenType.operator)
//        throw new 
    Node oper = parse_operator(ss)
        ..addChild(n);
    if (! ss.hasNext() || ! const [TokenType.num].contains(ss.peek().type))
        throw new ParserError('Expected a literal, name, or function');
    oper.addChild(parse_statement(ss));
    return oper;
}

Node parse_parenthetical(SimpleStream<Token> ss) {
    SimpleStream<Token> inner = new SimpleStream<Token>(new List<Token>());
    int counter = 1;
    ss.next();
    while (counter > 0 && ss.hasNext()) {
        if (ss.peek().type == TokenType.closeparen)
            counter--;
        else if (ss.peek().type == TokenType.openparen)
            counter++;
        inner.push(ss.next());
    }
    inner.pop();
    return parse_statement(inner);
}


Node parse_operator(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.operator)
        throw new ParserError('Expected an operator');
    return new Node(type: 'operator', value: ss.next().symbol);
}


Node parse_definition(SimpleStream<Token> ss) {
    Node type = parse_type(ss);
    type.addChild(parse_name(ss));
    if (ss.peek().type == TokenType.semicolon) {
        ss.next();
        return type;
    } else if (ss.hasNext() && (ss.peek().type != TokenType.assign)) {
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

Node parse_literal(SimpleStream<Token> ss) {
    if (! const [TokenType.bool, TokenType.str,
                 TokenType.num, TokenType.date].contains(ss.peek().type))
        throw new ParserError('Expected a literal type');
    switch (ss.peek().type) {
        case TokenType.bool:
            return parse_bool(ss);
            break;
        case TokenType.num:
            return parse_num(ss);
            break;
        case TokenType.str:
            return parse_str(ss);
            break;
        case TokenType.date:
            break;
        default:
            throw new ParserError('unrecognized literal type');
    }
}


Node parse_str(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.str)
        throw new ParserError('Expected a str');
    return new Node(type: 'str', value: ss.next().symbol);
}


Node parse_num(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.num)
        throw new ParserError('Expected a num');
    return new Node(type: 'num', value: ss.next().symbol);
}

Node parse_bool(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.bool)
        throw new ParserError('Expected a bool');
    return new Node(type: 'bool', value: ss.next().symbol);
}


main() {
    String script = '''
        3 + (5 / (1 + 7)) * 2;
    ''';
    SimpleStream<Token> ss = new SimpleStream<Token>(
        new List<Token>.from(tokenize(script)));
    print(parse_expression(ss));
}
