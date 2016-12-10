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
        test('literal can be detected', () {
            Token e1 = new Token('"a string"');
            expect(e1.type, equals(TokenType.literal));
            Token e2 = new Token('2342');
            expect(e2.type, equals(TokenType.literal));
            Token e3 = new Token('true');
            expect(e3.type, equals(TokenType.literal));
            Token e4 = new Token('false');
            expect(e4.type, equals(TokenType.literal));
        });
        test('control can be detected', () {
            expect(new Token('if').type, equals(TokenType.control));
            expect(new Token('while').type, equals(TokenType.control));
            expect(new Token('for').type, equals(TokenType.control));
            expect(new Token('else').type, equals(TokenType.control));
        });
        test('operators can be detected', () {
            expect(new Token('+').type, equals(TokenType.operator));
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
}
