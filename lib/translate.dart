import 'package:yaml/yaml.dart';
import 'dart:async';
import 'dart:io';

import 'utils.dart';


Map<String, String> typeMap = {
    'int': 'Long',
    'float': 'Float',
    'str': 'String',
    'bool': 'Boolean',
    'date': 'Date',
};

List<String> LITERALS = new List<String>.from(typeMap.keys);


String properCase(String s) {
    if (s.length == 0)
        return s;
    else if (s.length == 1)
        return s.toUpperCase();
    else
        return s[0].toUpperCase() + s.substring(1, s.length);
}


class TranslationError extends Error {
    String msg;

    TranslationError(this.msg);

    String toString() => this.msg;
}


class RedefinitionError extends Error {
    String msg;

    RedefinitionError(this.msg);

    String toString() => this.msg;
}


class MemoryError extends Error {
    String msg;

    MemoryError(this.msg);

    String toString() => this.msg;
}


/// Describes the variables that have been defined in the given scope.
class Memory {
    Set<String> names;
    Map<String, Set<String>> types;
    String last;
    int _last_index;
    String _prefix;

    Memory() {
        names = new Set<String>();
        types = new Map<String, Set<String>>();
        _last_index = 0;
        _prefix = 'v';
    }

    /// Add a [name] to this scope.
    void add(String name, String type) {
        if (names.contains(name) && types[name].contains(type))
            throw new RedefinitionError('Variable $name already exists.');
        names.add(name);
        if (! types.containsKey(name))
            types[name] = new Set<String>();
        types[name].add(type);
        last = name;
    }

    /// If [name] is in this scope, make it the last one referenced.
    void touch(String name) {
        if (! names.contains(name))
            throw new MemoryError('Name "$name" is undefined.');
        else
            last = name;
    }

    /// Add a unique name to [names], and return it.
    String next(String type) {
        while (names.contains('$_prefix$_last_index')) {
            _last_index++;
        }
        add('$_prefix$_last_index', type);
        return '$_prefix$_last_index';
    }

    /// Lookup what types are associated with this [name].
    List<String> lookup_types(String name) {
        if (! types.containsKey(name))
            return new List<String>();
        return new List<String>.from(types[name]);
    }
}


String unimplemented(Node n) {
//    throw new TranslationError('Unimplemented!');
    return '';
}

const Map<String, Function> router = const {
    'block': translate_block,
    'parameters': translate_parameters,
    'submodule': translate_submodule,
    'import': unimplemented,
    'int': translate_literal,
    'float': translate_literal,
    'bool': translate_literal,
    'str': translate_literal,
    'none': translate_literal,
    'date': translate_literal,
    'type': translate_definition,
    'assign': translate_definition,
    'sub-call': translate_sub_call,
    'name': translate_name,
};


String translate(Node ast) {
    String ret = '';
    for (Node child in ast.children) {
        if (child.type == 'submodule')
            ret += translate_submodule(child);
        else if (child.type == 'import')
            ;
    }
    return ret;
}

bool list_equality<T>(List<T> l1, List<T> l2) {
    if (l1.length != l2.length)
        return false;
    return new List<bool>
        .generate(l1.length, (i) => l1[i] == l2[i], growable: false)
        .every((x) => x);
}


// TODO Refactor! This is gross!
/// Select the definition of the submodule call to use for [n].
Map select_submodule_definition(Map definitions, Node n, [Memory mem]) {
    if (n.type != 'sub-call')
        throw new TranslationError('Expected a submodule');

    if (! ['name', 'operator'].contains(n.childAt(0).type))
        throw new TranslationError('Expected name');
    String gabl_name = n.childAt(0).value;
    if (! definitions['functions'].containsKey(gabl_name))
        throw new TranslationError('Submodule $gabl_name undefined');
    if (n.childAt(1)?.type != 'arguments')
        throw new TranslationError('Expected arguments to submodule');

    List<Map> defs = definitions['functions'][gabl_name];
    List<Node> args = n.childAt(1).childrenAfter(0);
    List<String> arg_types = get_argument_types(args, mem);
    List<List<String>> param_types = new List<List<String>>
        .generate(defs.length, (i) => defs[i]['params']);
    for (int i = 0; i < param_types.length; i++) {
        if (list_equality(param_types[i], arg_types))
            return defs[i];
    } // No definition with the given parameters exists.
    throw new TranslationError(
        'Submodule $gabl_name with parameters $arg_types not found'
        );
}

List<String> get_argument_types(List<Node> args, Memory mem) {
    // This currently only returns one type per argument.  In the future,
    // we may want to return more.
    return new List<String>.from(args.map((arg) {
        if (LITERALS.contains(arg.type))
            return arg.type;
        else if (arg.type == 'name')
            return mem.lookup_types(arg.value).first;
        else
            throw new TranslationError('Unexpected node type ${arg.type}');
    }));
}

String translate_submodule(Node sub, [Map definitions = const {}]) {
    if (sub.type != 'submodule')
        throw new TranslationError('Expected a submodule node');
    Node params = sub.childAt(0);
    Node block = sub.childAt(1);
    String properName = properCase(sub.value);
    return [
        translate_parameters(params, definitions),
        'Program.Submodule.$properName.Start',
        translate_block(block, definitions),
        'Program.Submodule.$properName.End',
        ].join('\n');
}

String route(Node n) {
    if (! router.containsKey(n.type))
        throw new TranslationError('Unexpected node type');
    return router[n.type](n);
}


String translate_block(Node block, [Map definitions = const {}]) {
    if (block.type != 'block')
        throw new TranslationError('Expected a block node');
    List<String> children = new List<String>();
    for (Node child in block.children) {
        print('Handling ${child.type}'); // TODO Remove.
        if (! router.containsKey(child.type))
            throw new TranslationError('Unexpected node type');
        Function fn = router[child.type];
        children.add(fn(child, definitions));
    }
    // handle children
    if (children.length == 0)
        return '';
    return children.join('\n');
}


String translate_parameters(Node params, [Map definitions = const {}]) {
    if (params.type != 'parameters')
        throw new TranslationError('Expected a parameters node');
    // handle children
    return '';
}


String translate_definition(Node def, [Map definitions = const {}]) {
    if (! ['type', 'assign'].contains(def.type))
        throw new TranslationError('Expected type or assignment node');
    if (def.children.length == 0)
        throw new TranslationError('Expected to have a name');
    if (def.type == 'type') {
        String type = translate_type(def);
        String name = translate_name(def.children.first);
        // handle expression!
        return 'V.Local.$name.Declare($type)';
    } else if (def.type == 'assign') {
        String type = translate_type(def.children.first);
        String name = translate_name(def.childAt(0).childAt(0));
        String value = translate_literal(def.childAt(1));
        return 'V.Local.$name.Declare($type, $value)';
    }
}


String translate_type(Node type, [Map definitions = const {}]) {
    if (type.type != 'type')
        throw new TranslationError('Expected a type node');
    if (! typeMap.containsKey(type.value))
        throw new TranslationError('Unknown type');
    return typeMap[type.value];
}


String translate_name(Node name, [Map definitions = const {}]) {
    if (name.type != 'name')
        throw new TranslationError('Expected a name node');
    return properCase(name.value);
}


String translate_expression(Node expr, Map definitions) {

}

String translate_assignment(Node ass, Map definitions) {
    if (ass.type != 'sub-call' || ass.childAt(0)?.type != 'assign')
        throw new TranslationError('Expected an assignment');
    Node args = ass.childAt(1);
    String target = translate_name(args.childAt(0));
    if (LITERALS.contains(args.childAt(1).type)) {
        // Handle literal assignment.
        Map def = definitions['variables'][args.childAt(0).value];
        String scope = def['scope'];
        String arg = args.childAt(1).value;
        return '$scope.$target.Set($arg)';
    } else if (args.childAt(1).type == 'name') {
        // Handle name assignment.
        Map def = definitions['variables'][args.childAt(0).value];
        String scope = def['scope'];
        String arg = translate_name(args.childAt(1));
        return '$scope.$target.Set($arg)';
    } else {
        // Handle function assignment.
        String sub = translate_sub_call(args.childAt(1), definitions);
        return sub.substring(0, sub.length-1) + ',' + target + ')';
    }
    // Handle expression assignment.
}

String translate_sub_call_2(Node sub, Map definitions, Memory mem) {
    if (sub.type != 'sub-call')
        throw new TranslationError('Expected a submodule call');
    // Translate the children into variable names, then process parent
    String ret = '';
    for (int i = 0; i < sub.childAt(1).children.length; i++) {
        Node curr = sub.childAt(1).children[i];
        if (curr.type == 'sub-call') {
            ret += translate_sub_call_2(curr, definitions, mem);
            String curr_new_name = mem.last;
            sub.childAt(1).children[i] = new Node(type: 'name', value: curr_new_name);
        }
    }
    Map def = select_submodule_definition(definitions, sub, mem);
    String varname = mem.next(def['return']);
    String definition = route(
        new Node(type: "type", value: def["return"])
            ..addChild(new Node(type: "name", value: varname))
        );
    String args = new List<String>.from(
        sub.childAt(1).children.map((x) => route(x))
        ).join(', ');
    return '$ret\n$definition\n${def["name"]}($args, ${properCase(varname)})';
}

// TODO: Remove
String translate_sub_call(Node sub, Map definitions) {
    if (sub.type != 'sub-call')
        throw new TranslationError('Expected a submodule call');
    if (sub.childAt(0).type == 'assign') {
        return 'V.local..Set(';
    } else {
        Map definition = select_submodule_definition(definitions, sub);
        String ret = definition['name'] + '(';
        ret += sub.childAt(1).childrenAfter(0).map(
            (x) => translate_literal(x)).join(',');
        ret += ')';
        return ret;
    }
}

String translate_literal(Node literal, [Map definitions = const {}]) {
    if (! LITERALS.contains(literal.type))
        throw new TranslationError('Expected a literal node');
    if (literal.type == 'bool')
        return properCase(literal.value);
    return literal.value;
}


Map update(Map orig, Map next) {
    for (var key in orig.keys) {
        if (next.containsKey(key) && next[key] != null)
            orig[key].addAll(next[key]);
    }
    return orig;
}


Future<Map> import_definitions(List<Node> imports) async {
    Map complete = new Map()
        ..addAll({'functions': new Map()})
        ..addAll({'variables': new Map()});
    for (Node n in imports) {
        String filename = n.children.first.value;
        String contents = await new File('translation/$filename.yaml').readAsString();
        Map definitions = loadYaml(contents);
        complete = update(complete, definitions);
    }
    return complete;
}
