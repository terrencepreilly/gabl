import 'package:test/test.dart';

import '../utils.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/utils.dart';

main() {
    group('expression', () {
        test('can parse empty expression', () {
            String s = ';';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.type, equals('nop'));
        });

        test('can parse single value expression', () {
            fromStringExpect('5;', '(5)');
        });

        test('can parse single operator with two values', () {
            fromStringExpect('5 + 2;', '((5) + (2))');
        });

        test('can parse multiple operators with values', () {
            fromStringExpect('1 + 2 + 3;', '((1) + ((2) + (3)))');
        });

        test('can parse empty parentheses', () {
            String s = '();';
            SimpleStream<Token> ss = streamify(s);

            Node exp = parse_expression(ss);
            expect(exp.type, equals('nop'));
        });

        test('can parse parentheses with single number', () {
            fromStringExpect('(3);', '(3)');
        });

        test('can parse parentheses with multiple numbers', () {
            fromStringExpect('(3 + 5);', '((3) + (5))');
        });

        test('can parse numbers in and out of parentheses', () {
            fromStringExpect('(3 + 2) + 1;', '(((3) + (2)) + (1))');
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
            fromStringExpect('(((3)));', '(3)');
        });

        test('complicated parenthetical', () {
            fromStringExpect(
                '((3) / (4 + 3)) * 5;',
                '(((3) / ((4) + (3))) * (5))'
                );
        });

        test('other types', () {
            fromStringExpect(
                '(true + "a") - (5 * name1);',
                '(((true) + ("a")) - ((5) * (name1)))',
                );
        });

        test('assignment expression', () {
            fromStringExpect(
                'a <- a + 1;',
                '((a) <- ((a) + (1)))',
                );
        });
        test('return', () {
            fromStringExpect(
                'return 0;',
                '(return(0))',
                );
        });
    });

    group('broken expressions', () {
        test('missing argument', () {
            raisesException('3 + ;');
            raisesException('+;');
            raisesException('+6;');
        });
        test('missing semicolon', () {
            raisesException('');
            raisesException('3');
            raisesException('3 + 6');
        });
        test('multiple operators', () {
            raisesException('++3;');
            raisesException('3++6;');
            raisesException('8**;');
        });
        test('mismatched parentheses', () {
            raisesException('(3 + 6;');
            raisesException('(5));');
        });

        test('incorrectly called', () {
            Function f = (SimpleStream<Token> ss) {
                parse_expression_operator(ss, new Node(type: 'num', value: '8'));
            };
            raisesException('3 + 6;', f);
            raisesException('(3 + 5);', f);
            raisesException('', f);
            raisesException(';', f);

            Function v = (SimpleStream<Token> ss) {
                parse_expression_operator(ss, new Node(type: 'num', value: '8'));
            };
            raisesException('3;', v);
        });
    });
}
