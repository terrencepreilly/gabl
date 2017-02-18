import 'package:test/test.dart';
import '../../lib/utils.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/translate.dart';

void main() {
    group('translate definition', () {
        test('without initialization', () {
            Node n = parse_definition(streamify('int a;'));
            expect(translate_definition(n, {}, new Memory()),
                   equals('V.Local.A.Declare(Long)'));
        });

        test('with initialization', () {
            Node n = parse_expression(streamify('int a <- 5;'));
            expect(translate_definition(n, {}, new Memory()),
                   equals('V.Local.A.Declare(Long, 5)'));
        });
    });

    group('get_argument_types', () {
        Memory m = new Memory();
        Node named_1 = new Node(type: 'name', value: 'A');
        Node named_2 = new Node(type: 'name', value: 'B');
        m.add('A', 'int');
        m.add('B', 'bool');
        Node literal_1 = new Node(type: 'int', value: '7');
        Node literal_2 = new Node(type: 'bool', value: 'true');

        test('shows types of non-names', () {
            List<String> types = get_argument_types([literal_1, literal_2], m);
            expect(types, equals(const ['int', 'bool']));
        });
        test('shows types of names', () {
            List<String> types = get_argument_types(
                [literal_1, named_1, literal_2, named_2], m
                );
            expect(types, equals(const ['int', 'int', 'bool', 'bool']));
        });
    });
}
