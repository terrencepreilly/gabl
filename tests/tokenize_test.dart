import 'package:test/test.dart';

import '../lib/parser.dart';

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
        expect(new List<String>.from(tokens.map((x) => x.toString())),
                ['sub', 'sayHi', '(', 'String', 'a', ')', '{',
                 'Msg', '(', 'hello', ',', 'a', ')', ';', '}']);
    });
}
