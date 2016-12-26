import 'lexer.dart';
import 'utils.dart';

const List<TokenType> LITERAL = const [
    TokenType.num,
    TokenType.str,
    TokenType.bool,
    TokenType.date,
    ];


/// An AST Node.
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
        ret += children.getRange(0, half).join(' ');
        if (half > 0) {
            if (value != '')
                ret += ' ' + value + ' ';
            else if (type == 'block'
                    || type == 'parameters')
                ret += ' ';
        } else {
            ret += value;
        }
        ret += children.getRange(half, children.length).join(' ');
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


Node parse_import(SimpleStream<Token> ss) {
    if (! ss.hasNext()
            || ss.peek().type != TokenType.control
            || ss.peek().symbol != 'import')
        throw new ParserError('Expected "import"');
    ss.next();
    Node n = new Node(type: 'import', value: 'import')
        ..addChild(parse_name(ss));
    if (! ss.hasNext() || ss.peek().type != TokenType.semicolon)
        throw new ParserError('Expected ";"');
    ss.next();
    return n;
}

Node parse_handle(SimpleStream<Token> ss) {
    if (! ss.hasNext()
            || ss.peek().type != TokenType.control
            || ss.peek().symbol != 'handle')
        throw new ParserError('Expected "handle"');
    ss.next();
    return new Node(type: 'handle', value: 'handle')
        ..addChild(parse_parenthetical(ss))
        ..addChild(parse_block(ss));
}


Node parse_submodule(SimpleStream<Token> ss) {
    if (! ss.hasNext()
            || (ss.peek().type != TokenType.submodule
                && ss.peek().symbol != 'sub'))
        throw new ParserError('Expected sub');
    ss.next();
    return new Node(type: 'submodule', value: parse_name(ss).value)
        ..addChild(parse_parameters_definition(ss))
        ..addChild(parse_block(ss));
}


Node parse_while(SimpleStream<Token> ss) {
    if (! ss.hasNext()
            || (ss.peek().type != TokenType.control
                && ss.peek().symbol != 'while'))
        throw new ParserError('Expected "while"');
    ss.next();
    return new Node(type: 'control', value: 'while')
        ..addChild(parse_parenthetical(ss))
        ..addChild(parse_block(ss));
}


Node parse_for(SimpleStream<Token> ss) {
    if (! ss.hasNext()
            || (ss.peek().type != TokenType.control
                && ss.peek().symbol != 'for'))
        throw new ParserError('Expected "for"');
    ss.next();
    return new Node(type: 'control', value: 'for')
        ..addChild(parse_for_condition(ss))
        ..addChild(parse_block(ss));
}


Node parse_for_condition(SimpleStream<Token> ss) {
    if (! ss.hasNext() || ss.peek().type != TokenType.openparen)
        throw new ParserError('Expected "("');
    ss.next();
    Node n = new Node(type: 'condition', value: '');
    n.addChild(parse_expression(ss));
    n.addChild(parse_expression(ss));
    n.addChild(parse_statement(ss));
    if (! ss.hasNext() || ss.peek().type != TokenType.closeparen)
        throw new ParserError('Expected ")"');
    ss.next();
    return n;
}


Node parse_expression(SimpleStream<Token> ss) {
    if (ss.hasNext() && ss.peek().type == TokenType.semicolon) {
        ss.next();
        return new Node(type: 'nop', value: '');
    }
    Node n = parse_statement(ss);
    if (! ss.hasNext() || ss.peek().type != TokenType.semicolon)
        throw new ParserError('Expected ";"');
    ss.next();
    return n;
}


Node parse_if_statement(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.control
            || ss.peek().symbol != 'if')
        throw new ParserError('Expected "if"');

    Node n = new Node(type: 'control', value: 'if');
    ss.next();
    n.addChild(parse_parenthetical(ss));
    n.addChild(parse_block(ss));
    if (ss.hasNext() && ss.peek().type == TokenType.control) {
        if (ss.peek().symbol == 'elif')
            n.addChild(parse_elif_statement(ss));
        else if (ss.peek().symbol == 'else')
            n.addChild(parse_else_statement(ss));
    }
    return n;
}


Node parse_elif_statement(SimpleStream<Token> ss) {
    // TODO Combine these three if-controls somehow.
    if (ss.peek().type != TokenType.control
            || ss.peek().symbol != 'elif')
        throw new ParserError('Expected "elif"');

    Node n = new Node(type: 'control', value: 'elif');
    ss.next();
    n.addChild(parse_parenthetical(ss));
    n.addChild(parse_block(ss));
    if (ss.hasNext() && ss.peek().type == TokenType.control) {
        if (ss.peek().symbol == 'elif')
            n.addChild(parse_elif_statement(ss));
        else if (ss.peek().symbol == 'else')
            n.addChild(parse_else_statement(ss));
    }
    return n;
}


Node parse_else_statement(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.control
            || ss.peek().symbol != 'else')
        throw new ParserError('Expected "else"');

    Node n = new Node(type: 'control', value: 'else');
    ss.next();
    n.addChild(parse_block(ss));
    return n;
}


Node parse_parameters_definition(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.openparen)
        throw new ParserError('Expected "("');
    ss.next();
    Node params = new Node(type: 'parameters', value: '');
    while (ss.hasNext() && ss.peek().type == TokenType.type) {
        Node param = parse_type(ss);
        param.addChild(parse_name(ss));
        params.addChild(param);
        if (ss.peek().type == TokenType.comma)
            ss.next();
    }
    if (! ss.hasNext() || ss.peek().type != TokenType.closeparen)
        throw new ParserError('Expected ")"');
    ss.next();
    return params;
}

Node parse_parameters_call(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.openparen)
        throw new ParserError('Expected "("');
    ss.next();
    Node params = new Node(type: 'arguments', value: '');
    while (ss.hasNext() && ss.peek().type != TokenType.closeparen) {
        SimpleStream<Token> arg = new SimpleStream<Token>([]);
        while (ss.hasNext()
                && ss.peek().type != TokenType.comma
                && ss.peek().type != TokenType.closeparen)
            arg.push(ss.next());
        if (ss.hasNext() && ss.peek().type == TokenType.comma)
            ss.next();
        params.addChild(parse_statement(arg));
    }
    if (! ss.hasNext() || ss.peek().type != TokenType.closeparen)
        throw new ParserError('Expected ")"');
    ss.next();
    return params;
}


Node parse_statement(SimpleStream<Token> ss) {
    if (! ss.hasNext()) {
        return new Node(type: 'nop', value: '');
    } else if (LITERAL.contains(ss.peek().type)) {
        Node n = parse_literal(ss);
        if (ss.hasNext()
                && (ss.peek().type == TokenType.operator
                    || ss.peek().type == TokenType.assign)) {
            return parse_expression_operator(ss, n);
        }
        return n;
    } else if (ss.peek().type == TokenType.name) {
        Node n = parse_name(ss);
        if (ss.hasNext()
                && (ss.peek().type == TokenType.operator
                    || ss.peek().type == TokenType.assign)) {
            return parse_expression_operator(ss, n);
        } else if (ss.hasNext() && ss.peek().type == TokenType.openparen) {
            return new Node(type: 'sub-call', value: 'call')
                ..addChild(n)
                ..addChild(parse_parameters_call(ss));
        }
        return n;
    } else if (ss.peek().type == TokenType.openparen) {
        Node n = parse_parenthetical(ss);
        if (ss.hasNext() && ss.peek().type == TokenType.operator)
            return parse_expression_operator(ss, n);
        return n;
    } else if (ss.peek().type == TokenType.closeparen) {
        return new Node(type: 'nop', value: '');
    } else if (ss.peek().type == TokenType.control) {
        return parse_expression_control(ss);
    } else {
        throw new ParserError('Expected literal, name, function, or parenthetical.');
    }
}


Node parse_expression_control(SimpleStream<Token> ss) {
    if (! ss.hasNext() || ss.peek().type != TokenType.control)
        throw new ParserError('Expected a control statement such as "if", "while", etc.');
    if (ss.peek().symbol == 'return')
        return parse_expression_return(ss);
}

Node parse_expression_return(SimpleStream<Token> ss) {
    if (! ss.hasNext()
            || ss.peek().type != TokenType.control
            || ss.peek().symbol != 'return')
        throw new ParserError('Expected "return"');
    ss.next();
    return new Node(type: 'control', value: 'return')
        ..addChild(parse_statement(ss));
}


Node parse_expression_operator(SimpleStream<Token> ss, Node n) {
    List<TokenType> acceptable_types = [TokenType.num, TokenType.openparen];
    Node oper = parse_operator(ss)
        ..addChild(n);
    if (! ss.hasNext() || (! LITERAL.contains(ss.peek().type)
                           && ss.peek().type != TokenType.name
                           && (ss.peek().type != TokenType.openparen
                               && ss.peek().type != TokenType.assign))) {
        throw new ParserError('Expected a literal, name, function, or parenthetical');
    }
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


/// Parse a section enclosed in `{}`.
Node parse_block(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.openblock)
        throw new ParserError('Expected {');
    ss.next();
    Node n = new Node(type: 'block', value: '');
    while (ss.hasNext() && ss.peek().type != TokenType.closeblock) {
        if (ss.peek().type == TokenType.openblock) {
            n.addChild(parse_block(ss));
        } else if (ss.peek().type == TokenType.control
                   && ss.peek().symbol == 'handle') {
            n.addChild(parse_handle(ss));
        } else {
            n.addChild(parse_expression(ss));
        }
    }
    if (! ss.hasNext() || ss.peek().type != TokenType.closeblock)
        throw new ParserError('Expected }');
    ss.next();
    return n;
}


Node parse_operator(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.operator && ss.peek().type != TokenType.assign)
        throw new ParserError('Expected an operator');
    if (ss.peek().type == TokenType.operator)
        return new Node(type: 'operator', value: ss.next().symbol);
    else if (ss.peek().type == TokenType.assign)
        return new Node(type: 'assign', value: ss.next().symbol);
}


Node parse_definition(SimpleStream<Token> ss) {
    Node type = parse_type(ss);
    type.addChild(parse_name(ss));
    if (ss.peek().type == TokenType.semicolon) {
        ss.next();
        return type;
    } else if (ss.hasNext() && (ss.peek().type != TokenType.assign)) {
        throw new ParserError('Expected ";" or "<-"');
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
    if (! LITERAL.contains(ss.peek().type))
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
            sub fn() {
                handle(onException) {
                    Msg(x);
                }
            }
        ''';
    SimpleStream<Token> ss = new SimpleStream<Token>(
        new List<Token>.from(tokenize(script)));
    Node n = parse_submodule(ss);
    print(n);
}
