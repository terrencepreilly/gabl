import 'package:test/test.dart';

import '../lib/lexer.dart';
import '../lib/parser.dart';
import '../lib/utils.dart';

main() {
    group('expression', () {
        test('can parse name', () {
            String s = 'someName;';
            Iterable itr = tokenize(s);
            SimpleStream<Token> ss = new SimpleStream<Token>(
                new List<Token>.from(itr));

            Node n = parse(ss);
            expect(n, isNot(equals(null)));
        });

    });
}
