import 'lexer.dart';
import 'utils.dart';


class ParserError extends Error {
    String msg;

    ParserError([String msg = '']);

    String toString() => this.msg;
}


Node parse(SimpleStream<Token> ss) {
    Node n = new Node(type: 'nop', value: '');
    while (ss.hasNext()) {
        if (ss.peek().type == TokenType.control
                && ss.peek().symbol == 'import') {
            n.addChild(parse_import(ss));
        } else if (ss.peek().type == TokenType.submodule) {
            n.addChild(parse_submodule(ss));
        }
    }
    return n;
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
    Node n = new Node(type: 'condition', value: '')
        ..addChild(parse_expression(ss))
        ..addChild(parse_expression(ss))
        ..addChild(parse_statement(ss));
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


Node parse_if_statement(SimpleStream<Token> ss, [String symbol='if']) {
    if (ss.peek().type != TokenType.control
            || ss.peek().symbol != symbol)
        throw new ParserError('Expected $symbol');

    if (symbol == 'else')
        return new Node(type: 'control', value: ss.next().symbol)
            ..addChild(parse_block(ss));

    Node n = new Node(type: 'control', value: ss.next().symbol)
        ..addChild(parse_parenthetical(ss))
        ..addChild(parse_block(ss));
    if (ss.hasNext()
            && ss.peek().type == TokenType.control
            && ['elif', 'else'].contains(ss.peek().symbol))
        n.addChild(parse_if_statement(ss, ss.peek().symbol));
    return n;
}


Node parse_parameters_definition(SimpleStream<Token> ss) {
    if (ss.peek().type != TokenType.openparen)
        throw new ParserError('Expected "("');
    ss.next();
    Node params = new Node(type: 'parameters', value: '');
    while (ss.hasNext() && ss.peek().type == TokenType.type) {
        Node param = parse_type(ss)
            ..addChild(parse_name(ss));
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
    SimpleStream<Token> inner =
        get_nested_by(ss, TokenType.openparen, TokenType.closeparen);
    Node params = new Node(type: 'arguments', value: '');
    while (inner.hasNext()) {
        SimpleStream<Token> arg = new SimpleStream<Token>([]);
        while (inner.hasNext() && inner.peek().type != TokenType.comma)
            arg.push(inner.next());
        if (inner.hasNext() && inner.peek().type == TokenType.comma)
            inner.next();
        params.addChild(parse_statement(arg));
    }
    return params;
}

/// Get the inner portion of the stream [ss] nested between [open] and [close].
SimpleStream<Token> get_nested_by(SimpleStream<Token> ss,
                                  TokenType open, TokenType close) {
    if (ss.peek().type != open)
        throw new ParserError('Expected $open');
    ss.next();
    int count = 1;
    SimpleStream<Token> ret = new SimpleStream<Token>([]);
    while (ss.hasNext() && count > 0) {
        if (ss.peek().type == open) {
            count++;
            ret.push(ss.next());
        } else if (ss.peek().type == close) {
            count--;
            if (count > 0)
                ret.push(ss.next());
        } else {
            ret.push(ss.next());
        }
    }
    if (ss.peek().type != close)
        throw new ParserError('Expected $close');
    ss.next();
    return ret;
}


/// Parse a group of literals/names/etc. separated by functions/operators.
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
    } else if (ss.peek().type == TokenType.type) {
        return parse_definition(ss);
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
//    List<TokenType> acceptable_types = [TokenType.num, TokenType.openparen];
//    Node oper = parse_operator(ss)
//        ..addChild(n);
//    if (! ss.hasNext() || (! LITERAL.contains(ss.peek().type)
//                           && ss.peek().type != TokenType.name
//                           && (ss.peek().type != TokenType.openparen
//                               && ss.peek().type != TokenType.assign))) {
//        throw new ParserError('Expected a literal, name, function, or parenthetical');
//    }
//    oper.addChild(parse_statement(ss));
//    return oper;
    List<TokenType> acceptable_types = [TokenType.num, TokenType.openparen];
    Node args = new Node(type: 'arguments', value: '');
    args.addChild(n);
    Node oper = parse_operator(ss);
    if (! ss.hasNext() || (! LITERAL.contains(ss.peek().type)
                           && ss.peek().type != TokenType.name
                           && (ss.peek().type != TokenType.openparen
                               && ss.peek().type != TokenType.assign))) {
        throw new ParserError('Expected a literal, name, function, or parenthetical');
    }
    args.addChild(parse_statement(ss));
    return new Node(type: 'sub-call', value: 'call')
        ..addChild(oper)
        ..addChild(args);
}


/// Parse a statement enclosed in `()`.
Node parse_parenthetical(SimpleStream<Token> ss) {
    return parse_statement(
        get_nested_by(ss, TokenType.openparen, TokenType.closeparen)
        );
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
        return type;
    } else if (ss.hasNext() && (ss.peek().type != TokenType.assign)) {
        throw new ParserError('Expected ";" or "<-"');
    } else {
        return new Node(type: 'assign', value: ss.next().symbol)
            ..addChild(type)
            ..addChild(parse_literal(ss)); // TODO change to expression
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
    String type_repr = ss.peek().type.toString().split('.').last;
    return new Node(type: type_repr, value: ss.next().symbol);
}


main() {
    print(TokenType.bool.toString().split('.').last);
}
