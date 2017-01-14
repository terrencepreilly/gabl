import 'package:test/test.dart';
import '../../lib/utils.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/translate.dart';

void main() {
    group('translate definition', () {
        test('without initialization', () {
            Node n = parse_definition(streamify('int a;'));
            expect(translate_definition(n), equals('V.Local.A.Declare(Long)'));
        });

        test('with initialization', () {
            Node n = parse_expression(streamify('int a <- 5;'));
            expect(translate_definition(n), equals('V.Local.A.Declare(Long, 5)'));
        });
    });
}
