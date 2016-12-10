import 'package:test/test.dart';

import '../lib/lexer.dart';

String SCRIPT = '''
sub sayHi(String a) {
    Msg("hello", a);
}
''';


main() {
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
        expect(tokens[0].type, equals(TokenType.literal));
    });
}
