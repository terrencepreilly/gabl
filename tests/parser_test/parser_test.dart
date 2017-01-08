import 'package:test/test.dart';
import '../utils.dart';

import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/utils.dart';


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


    group('statement', () {
        test('null', () { fromStringExpect('', '()', parse_statement); });
        test('num', () { fromStringExpect('3', '(3)', parse_statement); });
        test('nums', () {
            fromStringExpect('3 + 4', '((+) call ((3)(4)))', parse_statement);
        });
        test('three numbers', () {
            fromStringExpect(
                '3 + 4 + 5',
                '((+) call ((3)((+) call ((4)(5)))))',
                parse_statement
                );
        });

        test('strings', () {
            fromStringExpect('"a" + "b"', '((+) call (("a")("b")))', parse_statement);
        });
        test('bool', () {
            fromStringExpect(
                'true * false',
                '((*) call ((true)(false)))',
                parse_statement
                );
        });
        test('name', () {
            fromStringExpect(
                'name1 + name2',
                '((+) call ((name1)(name2)))',
                parse_statement
                );
        });
        test('comparison', () {
            fromStringExpect('a > 0', '((>) call ((a)(0)))', parse_statement);
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
                '((+) call ((3)((+) call ((4)(5)))))',
                parse_parenthetical
                );
        });
        test('nested', () {
            fromStringExpect('(((9)))', '(9)', parse_parenthetical);
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
            fromStringExpect(
                '{ 3; 3 + 5; }',
                '((3) ((+) call ((3)(5))))',
                parse_block,
                );
            fromStringExpect(
                '{ 3 + (5 * 2); }',
                '(((+) call ((3)((*) call ((5)(2))))))',
                parse_block,
                );
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
            fromStringExpect('()', '()', parse_parameters_definition);
        });
        test('single parameter', () {
            fromStringExpect(
                '(num a)',
                '((num(a)))',
                parse_parameters_definition,
                );
        });
        test('multiple parameters', () {
            fromStringExpect(
                '(num a, str s)',
                '((num(a)) (str(s)))',
                parse_parameters_definition,
                );
            fromStringExpect(
                '(num n1, num n2, num n3, num n4)',
                '((num(n1)) (num(n2)) (num(n3)) (num(n4)))',
                parse_parameters_definition,
                );
        });
    });

    group('while loop', () {
        test('null', () {
            fromStringExpect(
                'while (true) {}',
                '((true) while ())',
                parse_while,
                );
        });
        test('simple', () {
            fromStringExpect(
                'while (a < 0) { a <- a + 1; }',
                '('
                    + '((<) call ((a)(0))) '
                    + 'while '
                    + '(((<-) call ((a)((+) call ((a)(1))))))'
                + ')',
                parse_while,
                );
        });
    });

    group('for loop', () {
        test('null', () {
            fromStringExpect(
                'for (; ;) {}',
                '((()() ()) for ())',
                parse_for,
                );
        });
        test('simple', () {
            String script = '''
                for (a <- 0; a > 0 ;a <- a + 1) {
                    b <- b + a;
                }
            ''';
            fromStringExpect(
                script,
                '('
                    + '('
                        + '((<-) call ((a)(0)))'
                        + '((>) call ((a)(0))) '
                        + '((<-) call ((a)((+) call ((a)(1)))))'
                    + ') '
                    + 'for '
                    + '(((<-) call ((b)((+) call ((b)(a))))))'
                + ')',
                parse_for,
                );
        });
    });

    group('handle statement', () {
        test('simple', () {
            String script = '''
                handle (handleException) { }
                ''';
            fromStringExpect(
                script,
                '((handleException) handle ())',
                parse_handle,
                );
        });
        test('complex', () {
            String script = '''
                handle (onException) {
                    x <- x + 1;
                }
                ''';
            fromStringExpect(
                script,
                '((onException) handle (((<-) call ((x)((+) call ((x)(1)))))))',
                parse_handle,
                );
        });
        test('nested in block', () {
            String script = '''
                sub fn() {
                    handle(onException) {
                        Msg(x);
                    }
                }
                ''';
            fromStringExpect(
                script,
                '(() fn (((onException) handle (((Msg) call ((x)))))))',
                parse_submodule,
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
                '(((>) call ((a)(0))) if (((<-) call ((a)((+) call ((a)(1)))))))',
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
                '(((>) call (((+) call ((a)(1)))(0))) if ('
                        + '((<-) call ((a)((+) call ((a)(1))))) '
                        + '((<-) call ((a)((/) call ((a)(2)))))'
                        + '))',
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
                '(((>) call ((a)(0))) if () (((<) call ((a)(0))) elif ()))',
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

    group('import', () {
        test('by simple name', () {
            String script = 'import http;';
            fromStringExpect(
                script,
                '(import(http))',
                parse_import,
                );
        });
        // TODO import where expressions can be accepted
    });

    group('submodule', () {
        test('null', () {
            String script = '''
                sub A() {}
                ''';
            fromStringExpect(
                script,
                '(() A ())',
                parse_submodule,
                );
        });
        test('with return', () {
            String script = '''
                sub double(num a) {
                    return a * 2;
                }
                ''';
            fromStringExpect(
                script,
                '(((num(a))) double ((return((*) call ((a)(2))))))',
                parse_submodule,
                );
        });
        test('calls', () {
            fromStringExpect(
                'double(x);',
                '((double) call ((x)))',
                );
            fromStringExpect(
                'combine(x, x2, 5*3);',
                '((combine) call ((x)(x2) ((*) call ((5)(3)))))',
                );
            fromStringExpect(
                'double(x <- 35);',
                '((double) call (((<-) call ((x)(35)))))',
                );
            fromStringExpect(
                '1 + double(x);',
                '((+) call ((1)((double) call ((x)))))',
                );
        });
        test('nested calls', () {
            fromStringExpect(
                'double(double(2));',
                '((double) call (((double) call ((2)))))',
            );
        });
    });

    group('script', () {
        test('Simple script', () {
            String script = '''
                import http;

                sub onHttpError() {
                    Msg("There was an error!");
                    return "";
                }

                sub retrievePage(str pagename) {
                    str value <- "";
                    handle(onHttpError) {
                        value <- get(pagename);
                    }
                    return value;
                }

                sub main() {
                    Msg(retrievePage("google.com"));
                }
                ''';
            Node n = null;
            n = parse(streamify(script));
            expect(n, isNot(equals(null)));
        });
    });

    group('get_nested_by', () {
        test('parses simple parenthetical', () {
            String script = '("hello")';
            SimpleStream<Token> ss = streamify(script);
            SimpleStream<Token> after =
                get_nested_by(ss, TokenType.openparen, TokenType.closeparen);
            expect(after.peek().type, equals(TokenType.str));
            expect(after.peek().symbol, equals('"hello"'));
        });
        test('parses nested parethentical', () {
            String script = '(("hello"), ("world"))';
            SimpleStream<Token> ss = streamify(script);
            SimpleStream<Token> after =
                get_nested_by(ss, TokenType.openparen, TokenType.closeparen);
            expect(after.peek().type, equals(TokenType.openparen));
            after.next(); // (
            expect(after.peek().type, equals(TokenType.str));
            expect(after.peek().symbol, equals('"hello"'));
            after.next(); // "hello"
            after.next(); // )
            after.next(); // ,
            after.next(); // (
            expect(after.peek().symbol, equals('"world"'));
        });
        test('parses nested three deep', () {
            String script = '{{{a}}}';
            SimpleStream<Token> ss = streamify(script);
            SimpleStream<Token> first =
                get_nested_by(ss, TokenType.openblock, TokenType.closeblock);
            SimpleStream<Token> second =
                get_nested_by(first, TokenType.openblock, TokenType.closeblock);
            SimpleStream<Token> third =
                get_nested_by(second, TokenType.openblock, TokenType.closeblock);
            expect(third.peek().symbol, equals('a'));
            expect(second.hasNext(), equals(false));
            expect(first.hasNext(), equals(false));
            expect(ss.hasNext(), equals(false));
        });
    });
}
