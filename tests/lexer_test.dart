import '../lib/lexer.dart';
import 'package:test/test.dart';

void main() {
    group('symbol', () {

        test('submodule keyword can be detected', () {
            Token e = new Token('sub');
            expect(e.type, equals(TokenType.submodule));
        });

        test('name can be detected', () {
            Token e = new Token('aParameterName');
            expect(e.type, equals(TokenType.name));
        });

        test('type (int, string, etc.) can be detected', () {
            expect(new Token('num').type, equals(TokenType.type));
            expect(new Token('str').type, equals(TokenType.type));
            expect(new Token('bool').type, equals(TokenType.type));
            expect(new Token('date').type, equals(TokenType.type));
        });

        test('literal string can be detected', () {
            Token str = new Token('"a string"');
            expect(str.type, equals(TokenType.str));
        });

        test('literal number can be detected', () {
            Token number = new Token('2342');
            expect(number.type, equals(TokenType.num));
        });

        test('literal bool can be detected', () {
            Token bool1 = new Token('true');
            expect(bool1.type, equals(TokenType.bool));
            Token bool2 = new Token('false');
            expect(bool2.type, equals(TokenType.bool));
        });

        test('control can be detected', () {
            expect(new Token('if').type, equals(TokenType.control));
            expect(new Token('while').type, equals(TokenType.control));
            expect(new Token('for').type, equals(TokenType.control));
            expect(new Token('else').type, equals(TokenType.control));
        });

        test('operators can be detected', () {
            expect(new Token('+').type, equals(TokenType.operator));
            expect(new Token('=').type, equals(TokenType.operator));
        });

        test('assignment can be detected', () {
            expect(new Token('<-').type, equals(TokenType.assign));
        });

        test('block delimiters can be detected', () {
            expect(new Token('{').type, equals(TokenType.openblock));
            expect(new Token('}').type, equals(TokenType.closeblock));
        });

        test('parentheses can be detected', () {
            expect(new Token('(').type, equals(TokenType.openparen));
            expect(new Token(')').type, equals(TokenType.closeparen));
        });
    });

    group('tokenize', () {
        String SCRIPT = '''
        sub sayHi(String a) {
            Msg("hello", a);
        }
        ''';

        test('tokenize can be instantiated from a string', () {
            Iterable d = tokenize(SCRIPT);
        });
        test('tokenize parses all tokens', () {
            Iterable d = tokenize(SCRIPT);
            List<Token> tokens = new List<Token>.from(d);
            List<String> expected = [
                'sub', 'sayHi', '(', 'String', 'a', ')', '{',
                 'Msg', '(', '"hello"', ',', 'a', ')', ';', '}'
            ];
            for (int i = 0; i < expected.length && i < tokens.length; i++) {
                expect(tokens[i].toString(), equals(expected[i]));
            }
        });
        test('tokenize a single token', () {
            Iterable<Token> d = tokenize('"hello"');
            List<Token> tokens = new List<Token>.from(d);
            expect(tokens.length, equals(1));
            expect(tokens[0].toString(), equals('"hello"'));
            expect(tokens[0].type, equals(TokenType.str));
        });
    });
}
