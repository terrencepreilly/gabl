import 'package:test/test.dart';
import '../lib/utils.dart';
import '../lib/lexer.dart';
import '../lib/parser.dart';
import '../lib/translate.dart';


void nodeYields(Node n, String expected) {
    String translated = '';
    if (n.type == 'block')
        translated = translate_block(n);
    else if (n.type == 'parameters')
        translated = translate_parameters(n);
    else if (n.type == 'submodule')
        translated = translate_submodule(n);
    else if (n.type == 'type')
        translated = translate_definition(n);
    expect(translated, equals(expected));
}


void scriptYields(String script, String expected) {
    Node parsed = parse(streamify(script));
    expect(translate(parsed), equals(expected));
}


main() {
    group('translate submodules', () {
        test('without parameters or body', () {
            String script = '''
                sub main() {}
                ''';
            String expected = [
                '',
                'Program.Submodule.Main.Start',
                '',
                'Program.Submodule.Main.End'
            ].join('\n');
            scriptYields(script, expected);
        });
    });

    group('translate blocks', () {
        test('empty', () {
            Node n = new Node(type: 'block', value: '');
            nodeYields(n, '');
        });
    });

    group('translate parameters', () {
        test('empty', () {
            Node n = new Node(type: 'parameters', value: '');
            nodeYields(n, '');
        });
    });

    group('translate definition', () {
        test('without initialization', () {
            Node n = parse_definition(streamify('num a;'));
            nodeYields(n, 'V.Local.A.Declare(Long)');
        });
    });

    group('translate import', () {
        test('Returns a map of function definitions and literals', () async {
            List<Node> imports = new List<Node>()
                ..add(parse_import(streamify('import stdlib;')));
            Map definitions = await import_definitions(imports);
            expect(definitions.containsKey('functions'), equals(true));
            expect(definitions.containsKey('variables'), equals(true));
        });
    });

    group('translate expression', () {
        test('with import from stdlib', () async {
            List<Node> imports = new List<Node>()
                ..add(parse_import(streamify('import stdlib;')));
            Map definitions = await import_definitions(imports);
            Node expr = parse_expression(streamify('a <- 1 + 2;'));
            String expected = 'F.Intrinsic.Math.Add(1, 2, A)';
            expect(translate_expression(expr, definitions), equals(expected));
        });
    });
}
