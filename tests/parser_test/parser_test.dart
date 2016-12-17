import 'package:test/test.dart';

import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/utils.dart';


SimpleStream<Token> streamify(String s) {
    return new SimpleStream<Token>.from(tokenize(s));
}


/// Expect that [s], when parsed, will give the string [expected].
void fromStringExpect(String s, String expected,
        [Function parser = parse_expression]) {
    SimpleStream<Token> ss = streamify(s);
    Node exp = parser(ss);
    expect(exp.toString(), equals(expected));
}


/// Expect an exception to be raised from parsing [s] with [parser].
bool raisesException(String s, [Function parser = parse_expression]) {
    bool raised = false;
    try {
        parser(streamify(s));
    } catch(e) {
        raised = true;
    }
    expect(raised, equals(true), reason: '"$s" should have raised exception');
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
            expect(eq.toString(), equals('((str(a)) <- ("hello"))'));
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

        test('strings', () {
            fromStringExpect('"a" + "b"', '(("a") + ("b"))', parse_statement);
        });
        test('bool', () {
            fromStringExpect('true * false', '((true) * (false))', parse_statement);
        });
        test('name', () {
            fromStringExpect('name1 + name2', '((name1) + (name2))', parse_statement);
        });
        test('comparison', () {
            fromStringExpect('a > 0', '((a) > (0))', parse_statement);
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

    group('broken parenthetical', () {
        test('incorrectly called', () {
            raisesException('2 + (3 + 6)', parse_parenthetical);
            raisesException('(3 + 4', parse_parenthetical);
        });
    });

    group('block', () {
        test('null', () {
            fromStringExpect('{}', '()', parse_block);
        });
        test('simple', () {
            // TODO Normalize the string output of nodes so it makes sense.
            fromStringExpect('{ 3; 3 + 5; }', '((3) ((3) + (5)))', parse_block);
            fromStringExpect('{ 3 + (5 * 2); }', '(((3) + ((5) * (2))))', parse_block);
        });
        test('nested', () {
            fromStringExpect('{{}}', '(())', parse_block);
        });

        group('broken', () {
            test('missing {', () { raisesException('}', parse_block); });
            test('missing }', () { raisesException('{', parse_block); });
        });
    });

    group('parameters', () {
        test('null', () {
            fromStringExpect('()', '()', parse_parameters);
        });
        test('single parameter', () {
            fromStringExpect('(num a)', '((num(a)))', parse_parameters);
        });
        test('multiple parameters', () {
            fromStringExpect('(num a, str s)', '((num(a)) (str(s)))', parse_parameters);
            fromStringExpect(
                '(num n1, num n2, num n3, num n4)',
                '((num(n1)) (num(n2)) (num(n3)) (num(n4)))',
                parse_parameters,
                );
        });
    });

    group('if statement', () {
        test('null', () {
            fromStringExpect(
                'if (true) {}',
                '((true) if ())',
                parse_if_statement,
                );
        });
        test('simple', () {
            String script = '''
                if (a > 0) {
                    a <- a + 1;
                }
                ''';
            fromStringExpect(
                script,
                '(((a) > (0)) if (((a) <- ((a) + (1)))))',
                parse_if_statement,
                );
        });
        test('multiple', () {
            String script = '''
                if ((a + 1) > 0) {
                    a <- a + 1;
                    a <- a / 2;
                }
                ''';
            fromStringExpect(
                script,
                '((((a) + (1)) > (0)) if ' +
                    '(((a) <- ((a) + (1))) ((a) <- ((a) / (2)))))',
                parse_if_statement,
                );
        });
        test('with else if', () {
            String script = '''
                if (a > 0) {}
                elif (a < 0) {}
                ''';
            fromStringExpect(
                script,
                '(((a) > (0)) if () (((a) < (0)) elif ()))',
                parse_if_statement,
                );
        });
        test('with else', () {
            String script = '''
                if (false) {}
                else {}
                ''';
            fromStringExpect(
                script,
                '((false) if () (else()))',
                parse_if_statement,
                );
        });
        test('with else-if chains', () {
            String script = '''
                if (a) {}
                elif (b) {}
                elif (c) {}
                else {}
                ''';
            fromStringExpect(
                script,
                '((a) if () ((b) elif () ((c) elif () (else()))))',
                parse_if_statement,
                );
        });
    });
}
