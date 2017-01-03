import 'package:test/test.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/utils.dart';
import '../utils.dart';

main() {
    group('definition', () {
        test('can parse null definition', () {
            // a delaration with optional instantiation
            SimpleStream<Token> ss = streamify('str a;');

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
            SimpleStream<Token> ss = streamify(s);

            Node eq = parse_definition(ss);
            expect(eq.toString(), equals('((str(a)) <- ("hello"))'));
        });
    });
}
