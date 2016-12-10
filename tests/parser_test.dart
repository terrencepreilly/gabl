import 'package:test/test.dart';

import '../lib/lexer.dart';
import '../lib/parser.dart';
import '../lib/utils.dart';

main() {
    test('can parse name', () {
        String s = 'someName';
        Iterable itr = tokenize(s);
        SimpleStream<Token> ss = new SimpleStream<Token>(
            new List<Token>.from(itr));

        Node name = parse_name(ss);
        expect(name, isNot(equals(null)));
        expect(name.type, equals('name'));
        expect(name.value, equals(s));
    });

    test('can parse type', () {
        String s = 'str';
        SimpleStream<Token> ss = new SimpleStream<Token>(
            new List<Token>.from(tokenize(s)));
        Node type = parse_type(ss);
        expect(type, isNot(equals(null)));
        expect(type.type, equals('type'));
        expect(type.value, equals(s));
    });

    group('definition', () {
        test('can parse null definition', () {
            // a delaration with optional instantiation
            String s = 'str a;';
            SimpleStream<Token> ss = new SimpleStream<Token>(
                new List<Token>.from(tokenize(s)));
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
            SimpleStream<Token> ss = new SimpleStream<Token>(
                new List<Token>.from(tokenize(s)));

            Node eq = parse_definition(ss);
            expect(eq.toString(), equals('((str (a)) <- ("hello"))'));
        });
    });
}
