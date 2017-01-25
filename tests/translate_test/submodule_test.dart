import 'package:test/test.dart';
import '../../lib/utils.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/translate.dart';


void scriptYields(String script, String expected) {
    Node parsed = parse(streamify(script));
    expect(translate(parsed), equals(expected));
}

Map ADD = {
    'functions': {
        '+': [{
            'name': 'F.Intrinsic.Math.Add',
            'params': ['int', 'int'],
            'return': 'int',
        }],
    },
    'variables': {}
};


void main() {
    group('translate submodule', () {
        test('without parameters or body', () {
            String script = '''
                none sub main() {}
                ''';
            String expected = [
                '',
                'Program.Submodule.Main.Start',
                '',
                'Program.Submodule.Main.End'
            ].join('\n');
            scriptYields(script, expected);
        });

        test('with variable declarations', () {
            // The variable declarations should be in the submodule.
            String script = '''
                none sub main() {
                    int a;
                }
                ''';
            String expected = [
                '',
                'Program.Submodule.Main.Start',
                'V.Local.A.Declare(Long)',
                'Program.Submodule.Main.End',
                ].join('\n');
            scriptYields(script, expected);
        });

        test('with multiple expressions', () {
            String script = '''
                none sub main() {
                    int a <- 5;
                    a <- a + 3;
                }
                ''';
            String expected = [
                '',
                'Program.Submodule.Main.Start',
                'V.Local.A.Declare(Long, 5)',
                'F.Intrinsic.Math.Add(A, 3, A)',
                'Program.Submodule.Main.End',
                ].join('\n');
            Node n = parse(streamify(script));
            String actual = translate_submodule(n.childAt(0), ADD);
            expect(actual, equals(expected));
        }, skip: 'Prepare some other things.');
    });

    group('Long Expressions', () {
        test('without assignment still assign', () {
            String script = '5 + 3';
            Node n = parse_statement(streamify(script));
            String expected = [
                '',
                'V.Local.V0.Declare(Long)',
                'F.Intrinsic.Math.Add(5, 3, V0)',
                ].join('\n');
            String actual = translate_sub_call_2(n, ADD, new Memory());
            expect(actual, equals(expected));
        });
    });
}
