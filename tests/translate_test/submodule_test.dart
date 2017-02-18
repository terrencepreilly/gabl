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
Map MULT = {
    'functions': {
        '*': [{
            'name': 'F.Intrinsic.Math.Mult',
            'params': ['int', 'int'],
            'return': 'int',
        }],
    },
    'variables': {
        'a': {
            'scope': 'V.local',
        }
    }
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
                '',
                'V.Local.V0.Declare(Long)',
                'F.Intrinsic.Math.Add(A, 3, V0)',
                'V.Local.A.Set(V0)',
                'Program.Submodule.Main.End',
                ].join('\n');
            Node n = parse(streamify(script));
            String actual = translate_submodule(n.childAt(0), ADD, new Memory());
            expect(actual, equals(expected));
        });
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
            String actual = translate_sub_call(n, ADD, new Memory());
            expect(actual, equals(expected));
        });
        test('chains assigned arguments', () {
            String script = '7 + 5 + 3';
            Node n = parse_statement(streamify(script));
            String expected = [
                '',
                'V.Local.V0.Declare(Long)',
                'F.Intrinsic.Math.Add(5, 3, V0)',
                'V.Local.V1.Declare(Long)',
                'F.Intrinsic.Math.Add(7, V0, V1)',
                ].join('\n');
            String actual = translate_sub_call(n, ADD, new Memory());
            expect(actual, equals(expected));
        });
    });

    group('translate submodule call', () {
        test('fruitless', () {
            Map defs = {
                'functions': {
                    'Msg': [{
                        'name': 'F.Intrinsic.UI.MsgBox',
                        'params': ['str'],
                        'return': 'none',
                        }]
                    },
                'variables': {}
                };
            String s = 'Msg("hello!")';
            Node n = parse_statement(streamify(s));
            String expected = 'F.Intrinsic.UI.MsgBox("hello!")';
            expect(translate_sub_call(n, defs, new Memory()), equals(expected));
        });

        test('fruitfull', () {
            Map defs = {
                'functions': {
                    'mult': [{
                        'name': 'F.Intrinsic.Math.Mult',
                        'params': ['int', 'int'],
                        'return': 'int',
                        }]
                },
                'variables': {
                    'a': {
                        'scope': 'V.local',
                    }
                },
                };
            String s = 'a <- mult(1, 3)';
            Node n = parse_statement(streamify(s));
            String expected = [
                '',
                'V.Local.V0.Declare(Long)',
                'F.Intrinsic.Math.Mult(1, 3, V0)',
                'V.Local.A.Set(V0)',
                ].join('\n');
            expect(translate_assignment(n, defs, new Memory()), equals(expected));
        });

        test('infixes', () {
            String s = 'a <- 1 * 3';
            Node n = parse_statement(streamify(s));
            String expected = [
                '',
                'V.Local.V0.Declare(Long)',
                'F.Intrinsic.Math.Mult(1, 3, V0)',
                'V.Local.A.Set(V0)'
                ].join('\n');
            expect(translate_assignment(n, MULT, new Memory()), equals(expected));
        });
    });

}
