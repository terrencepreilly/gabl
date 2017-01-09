import 'dart:math';
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


main() {
    var random = new Random();

    group('translate submodules', () {
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
            Node n = parse_definition(streamify('int a;'));
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

    group('translate literal', () {
        test('number doesn\'t change', () {
            int number = random.nextInt(100);
            Node n = parse_literal(streamify(number.toString()));
            expect(translate_literal(n), equals(number.toString()));
        });
        test('bool is in proper case', () {
            Node n = parse_literal(streamify('true'));
            String expected = 'True';
            expect(translate_literal(n), equals(expected));
        });
        test('str doesn\'t change', () {
            String s = '"Hello, world!"';
            Node n = parse_literal(streamify(s));
            expect(translate_literal(n), equals(s));
        });
    });

    group('translate submodule call', () {
        test('fruitless', () {
            Map defs = {
                'functions': {
                    'Msg': [{
                        'name': 'F.Intrinsic.UI.MsgBox',
                        'params': ['str'],
                        'return': null,
                        }]
                    },
                'variables': {}
                };
            String s = 'Msg("hello!")';
            Node n = parse_statement(streamify(s));
            String expected = 'F.Intrinsic.UI.MsgBox("hello!")';
            expect(translate_sub_call(n, defs), equals(expected));
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
            String expected = 'F.Intrinsic.Math.Mult(1,3,A)';
            expect(translate_assignment(n, defs), equals(expected));
        });

        test('infixes', () {
            String s = 'a <- 1 * 3';
            Node n = parse_statement(streamify(s));
            String expected = 'F.Intrinsic.Math.Mult(1,3,A)';
            expect(translate_assignment(n, MULT), equals(expected));
        });
    });

    group('translate assignment', () {
        test('simple', () {
            Map defs = {
                'functions': {},
                'variables': {
                    'a': {'scope': 'V.Local'},
                },
            };
            String s = 'a <- 1';
            Node n = parse_statement(streamify(s));
            String expected = 'V.Local.A.Set(1)';
            expect(translate_assignment(n, defs), equals(expected));
        });
        test('by name', () {
            Map defs = {
                'functions': {},
                'variables': {
                    'a': {'scope': 'V.Local'},
                    'b': {'scope': 'V.Local'},
                },
            };
            String s = 'a <- b';
            Node n = parse_statement(streamify(s));
            String expected = 'V.Local.A.Set(B)';
            expect(translate_assignment(n, defs), equals(expected));
        });
    });

    group('find definition', () {
        test('can infer over types', () {
            Map defs = {
                'functions': {
                    '*': [
                        {
                            'name': 'F.Intrinsic.Math.Mult',
                            'params': ['int', 'int'],
                            'return': 'int',
                        },
                        {
                            'name': 'F.Intrinsic.Math.Mult',
                            'params': ['float', 'float'],
                            'return': 'float',
                        },
                    ]
                },
                'variables': {},
            };
            Node n_int =  parse_statement(streamify('3 * 4'));
            Node n_float = parse_statement(streamify('3.0 * 4.0'));
            Map def_int = select_submodule_definition(defs, n_int);
            Map def_float = select_submodule_definition(defs, n_float);
            expect(def_int['return'], equals('int'));
            expect(def_float['return'], equals('float'));
        });
    });
}
