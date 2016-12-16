import 'package:test/test.dart';

import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/utils.dart';


SimpleStream<Token> streamify(String s) {
    return new SimpleStream<Token>.from(tokenize(s));
}


void fromStringExpect(String s, String expected,
        [Function parser = parse_expression]) {
    SimpleStream<Token> ss = streamify(s);
    Node exp = parser(ss);
    expect(exp.toString(), equals(expected));
}


bool raisesException(String s, [Function parser = parse_expression]) {
    try {
        parser(streamify(s));
    } catch(e) {
        return true;
    }
    return false;
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
    });

    group('statement', () {
        test('null', () { fromStringExpect('', '()', parse_statement); });
        test('num', () { fromStringExpect('3', '(3)', parse_statement); });
        test('nums', () {
            fromStringExpect('3 + 4', '((3) + (4))', parse_statement);
        });
        test('three numbers', () {
            fromStringExpect('3 + 4 + 5', '((3) + ((4) + (5)))', parse_statement);
        });
    });

    group('parenthetical', () {
        test('null', () {
            fromStringExpect('()', '()', parse_parenthetical);
        });
        test('num', () {
            fromStringExpect('(3)', '(3)', parse_parenthetical);
        });
        test('nums', () {
            fromStringExpect(
                '(3 + 4 + 5)',
                '((3) + ((4) + (5)))',
                parse_parenthetical
                );
        });
        test('nested', () {
            fromStringExpect('(((9)))', '(9)', parse_parenthetical);
        });
    });

    group('broken expressions', () {
        test('missing argument', () {
            expect(raisesException('3 + ;'), equals(true));
        });
    });
}
