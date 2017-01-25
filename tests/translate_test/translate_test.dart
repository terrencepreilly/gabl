import 'dart:math';
import 'package:test/test.dart';
import '../../lib/utils.dart';
import '../../lib/lexer.dart';
import '../../lib/parser.dart';
import '../../lib/translate.dart';

const List<String> LITERAL_NODE_TYPES =
    const ['int', 'float', 'str', 'bool', 'date', 'none'];


// TODO: Get all of the methods to use this that can.
void nodeYields(Node n, String expected) {
    String translated = '';
    if (n.type == 'block')
        translated = translate_block(n);
    else if (n.type == 'parameters')
        translated = translate_parameters(n);
    else if (n.type == 'submodule')
        translated = translate_submodule(n);
    else if (LITERAL_NODE_TYPES.contains(n.type))
        translated = translate_literal(n);
    expect(translated, equals(expected));
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
    Random random = new Random();


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
            nodeYields(n, number.toString());
        });
        test('bool is in proper case', () {
            Node n = parse_literal(streamify('true'));
            String expected = 'True';
            nodeYields(n, 'True');
        });
        test('str doesn\'t change', () {
            String s = '"Hello, world!"';
            Node n = parse_literal(streamify(s));
            nodeYields(n, s);
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

    group('Memory', () {
        test('Can add names to memory.', () {
            Memory mem = new Memory();
            mem.add('var1');
            mem.add('var2');
        });
        test('Can see last item added to memory', () {
            Memory mem = new Memory();
            mem.add('var1');
            mem.add('var2');
            expect(mem.last, equals('var2'));
        });
        test('Can designate the last item, if it already exists', () {
            Memory mem = new Memory();
            mem.add('var1');
            mem.add('var2');
            mem.touch('var1');
            expect(mem.last, equals('var1'));
        });
        test('Adding the same value twice raises an error', () {
            Memory mem = new Memory();
            mem.add('var1');
            try {
                mem.add('var1');
            } catch (e) {
                expect(e.msg, equals('Variable var1 already exists.'));
            }
        });
        test('Can generate a new, unique name', () {
            Memory mem = new Memory();
            mem.add('v1');
            mem.next();
            expect(mem.last, isNot(equals('v1')));
        });
    });
}
