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

    group('expression', () {
        test('can parse simple expression', () {
            String s = 'a + 45 - 3;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals('((a) + ((45) - (3)))'));
        });

        test('can parse a long expression', () {
            String s = '1 + true + "oue" + 3 + a + b + true;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals(
                '((1) + ((true) + (("oue") + ((3) + ((a) + ((b) + (true)))))))'
                ));
        });

        test('can parse parentheses', () {
            String s = '(1 * 3) + 5;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals(
                '(((1) * (3)) + (5))'
                ));

            s = '(3 * 1) + (4 * 5);';
            ss = streamify(s);

            exp = parse_expression(ss);
            expect(exp.toString(), equals(
                '(((3) * (1)) + ((4) * (5)))',
                ));
        });

        test('can parse nested parentheses', () {
            String s = '3 + (5 / (1 + 7)) * 2;';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.toString(), equals(
                '((3) + (((5) / ((1) + (7))) * (2)))'
                ));
        });
    });
}
