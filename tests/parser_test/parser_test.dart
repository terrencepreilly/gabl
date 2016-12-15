import 'package:test/test.dart';

import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/utils.dart';

SimpleStream<Token> streamify(String s) {
    return new SimpleStream<Token>.from(tokenize(s));
}

main() {
    test('can parse name', () {
        SimpleStream<Token> ss = streamify('someName');

        Node name = parse_name(ss);
        expect(name, isNot(equals(null)));
        expect(name.type, equals('name'));
        expect(name.value, equals('someName'));
    });

    test('can parse type', () {
        SimpleStream<Token> ss = streamify('str');
        Node type = parse_type(ss);
        expect(type, isNot(equals(null)));
        expect(type.type, equals('type'));
        expect(type.value, equals('str'));
    });


    group('definition', () {
        test('can parse null definition', () {
            // a delaration with optional instantiation
            SimpleStream<Token> ss = streamify('str a;');

            Node def = parse_definition(ss);
            expect(def, isNot(equals(null)));
            expect(def.type, equals('type'));
            expect(def.value, equals('str'));

            Node child = def.childAt(0);
            expect(child, isNot(equals(null)));
            expect(child.type, equals('name'));
            expect(child.value, equals('a'));
        });

        test('can parse simple definition', () {
            String s = 'str a <- "hello";';
            SimpleStream<Token> ss = streamify(s);

            Node eq = parse_definition(ss);
            expect(eq.toString(), equals('((str (a)) <- ("hello"))'));
        });
    });

    group('new expression', () { // TODO change name
        test('can parse empty expression', () {
            String s = ';';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.type, equals('nop'));
        });

        test('can parse single value expression', () {
            String s = '5;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('(5)'));
        });

        test('can parse single operator with two values', () {
            String s = '5 + 2;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('((5) + (2))'));
        });

        test('can parse multiple operators with values', () {
            String s = '1 + 2 + 3;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('((1) + ((2) + (3)))'));
        });

        test('can parse empty parentheses', () {
            String s = '();';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.type, equals('nop'));
        });

        test('can parse parentheses with single number', () {
            String s = '(3);';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('(3)'));
        });

        test('can parse parentheses with multiple numbers', () {
            String s = '(3 + 5);';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('((3) + (5))'));
        });

        test('can parse numbers in and out of parentheses', () {
            String s = '(3 + 2) + 1;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('(((3) + (2)) + (1))'));
        });

        test('parentheses can change order', () {
            String s1 = '3 + 5 + 1;'; // normally process right to left
            String s2 = '(3 + 5) + 1;';
            SimpleStream<Token> ss1 = streamify(s1);
            SimpleStream<Token> ss2 = streamify(s2);

            Node exp1 = parse_expression(ss1);
            Node exp2 = parse_expression(ss2);
            expect(exp1.toString(), isNot(equals(exp2.toString())));
        });

        test('can handle nested paretheses', () {
            String s = '(((3)));';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('(3)'));
        });

        test('complicated parenthetical', () {
            String s = '((3) / (4 + 3)) * 5;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals(
                '(((3) / ((4) + (3))) * (5));'
                ));
        });
    });
}
