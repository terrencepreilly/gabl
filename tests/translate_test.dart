import 'package:test/test.dart';
import '../lib/utils.dart';
import '../lib/lexer.dart';
import '../lib/parser.dart';

main() {
    group('declarations', () {
        test('without settings', () {
            SimpleStream<Token> ss = streamify('num a;');
            try {
                Node parsed = parse_expression(ss);
            } catch (e) {
                print(e.msg);
            }
        });
    });
}
