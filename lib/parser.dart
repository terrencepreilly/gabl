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
    if (ss.peek().type == TokenType.semicolon) {
        ss.next();
        return new Node(type: 'nop', value: '');
    } else if (ss.peek().type == TokenType.num) {
        return parse_exp_literal(ss);
    } else if (ss.peek().type == TokenType.openparen) {
        Node n = parse_exp_parenthetical(ss);
        if (ss.peek().type == TokenType.operator) {
            return parse_exp_operator(ss, n);
        } else if (ss.peek().type == TokenType.semicolon
                || ss.peek().type == TokenType.closeparen) {
            return n;
        } else {
            throw new ParserError('Expected ";" or operator after ")"');
        }
    }
}

Node parse_exp_literal(SimpleStream<Token> ss) {
//    if (! const [TokenType.num].contains(ss.peek().type)) {
//        throw new ParserError('Expected literal or number');
//    }

    Node n = parse_literal(ss);
//    if (! ss.hasNext())
//        throw new ParserError('Unexpected end of expression');
    if (ss.peek().type == TokenType.operator)
        return parse_exp_operator(ss, n);
//    else if (ss.peek().type == TokenType.closeparen)
//        ;
    else if (ss.peek().type == TokenType.semicolon) {
        return n;
    }
    else if (ss.peek().type == TokenType.closeparen) {
        while (ss.hasNext() && ss.peek().type == TokenType.closeparen)
            ss.next();
        return n;
    }
//    else
//        throw new ParserError('Expected operator or ")"');
}

Node parse_exp_operator(SimpleStream<Token> ss, Node left) {
//    if (ss.peek().type != TokenType.operator)
//        throw new ParserError('Expected operator');
    Node o = parse_operator(ss);
    o.addChild(left);
    if (ss.peek().type == TokenType.num) {
        o.addChild(parse_exp_literal(ss));
        return o;
    }
}

Node parse_exp_parenthetical(ss) {
//    if ((! ss.hasNext()) || ss.peek().type != TokenType.openparen)
//        throw new ParserError('Expected "("');
    ss.next();
    Node n = new Node(type: 'nop', value: '');
//    if (! ss.hasNext())
//        throw new ParserError('Unexpected end of expression at "("');
    if (ss.peek().type == TokenType.num) // returns after close parenthesis
        n = parse_exp_literal(ss);

    if (! ss.hasNext() || ss.peek().type == TokenType.semicolon)
        return n;
    return n;
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
