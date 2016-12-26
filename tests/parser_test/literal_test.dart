import 'package:test/test.dart';
import '../../lib/parser.dart';
import '../../lib/lexer.dart';
import '../../lib/utils.dart';

SimpleStream<Token> streamify(String s) {
    return new SimpleStream<Token>.from(tokenize(s));
}

main() {
    group('literal as', () {
        test('num', () {
            String s = '123';
            SimpleStream<Token> ss = streamify(s);
            Node n = parse_literal(ss);
            expect(n.type, equals('num'));
            expect(n.value, equals('123'));
        });
        test('str', () {
            String s = '"ZZZ"';
            SimpleStream<Token> ss = streamify(s);
            Node n = parse_literal(ss);
            expect(n.type, equals('str'));
            expect(n.value, equals(s));
        });
        test('bool', () {
            String s = 'true';
            SimpleStream<Token> ss = streamify(s);
            Node n = parse_literal(ss);
            expect(n.type, equals('bool'));
            expect(n.value, equals(s));

            s = 'false';
            ss = streamify(s);
            n = parse_literal(ss);
            expect(n.type, equals('bool'));
            expect(n.value, equals(s));
        });
    });
    group('num', () {
        test('can parse integer', () {
            String s = '234';
            SimpleStream<Token> ss = streamify(s);
            Node n = parse_literal(ss);
            expect(n.type, equals('num'));
            expect(n.value, equals(s));
        });
        test('can parse float', () {
            String s = '467.032';
            SimpleStream<Token> ss = streamify(s);
            Node n = parse_literal(ss);
            expect(n.type, equals('num'));
            expect(n.value, equals(s));
        });
    });
    group('bool', () {
        test('can parse true', () {
            SimpleStream<Token> ss = streamify('true');
            Node n = parse_literal(ss);
            expect(n.type, equals('bool'));
            expect(n.value, equals('true'));
        });
        test('can parse false', () {
            SimpleStream<Token> ss = streamify('false');
            Node n = parse_literal(ss);
            expect(n.type, equals('bool'));
            expect(n.value, equals('false'));
        });
    });
    group('string', () {
        test('can parse single string', () {
            SimpleStream<Token> ss = streamify('"hello"');
            Node n = parse_literal(ss);
            expect(n.type, equals('str'));
            expect(n.value, equals('"hello"'));
        });
    });

    // TODO date
}
