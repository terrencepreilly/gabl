import 'package:test/test.dart';
import '../../lib/utils.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/translate.dart';


void scriptYields(String script, String expected) {
    Node parsed = parse(streamify(script));
    expect(translate(parsed), equals(expected));
}


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
    });
}
