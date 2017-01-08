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

    TranslationError([String msg = '']);

    String toString() => this.msg;
}


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
Map select_submodule_definition(Map definitions, Node n) {
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
    List<String> arg_types = new List<String>.from(args.map((x) => x.type));
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

String translate_submodule(Node sub) {
    if (sub.type != 'submodule')
        throw new TranslationError('Expected a submodule node');
    Node params = sub.children.first;
    Node block = sub.children.last;
    String properName = properCase(sub.value);
    return [
        translate_parameters(params),
        'Program.Submodule.$properName.Start',
        translate_block(block),
        'Program.Submodule.$properName.End',
        ].join('\n');
}


String translate_block(Node block) {
    if (block.type != 'block')
        throw new TranslationError('Expected a block node');
    // handle children
    return '';
}


String translate_parameters(Node params) {
    if (params.type != 'parameters')
        throw new TranslationError('Expected a parameters node');
    // handle children
    return '';
}


String translate_definition(Node def) {
    if (def.children.length == 0)
        throw new TranslationError('Expected to have a name');
    String type = translate_type(def);
    String name = translate_name(def.children.first);
    // handle expression!
    return 'V.Local.$name.Declare($type)';
}


String translate_type(Node type) {
    if (type.type != 'type')
        throw new TranslationError('Expected a type node');
    if (! typeMap.containsKey(type.value))
        throw new TranslationError('Unknown type');
    return typeMap[type.value];
}


String translate_name(Node name) {
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

String translate_sub_call(Node sub, Map definitions) {
    if (sub.type != 'sub-call')
        throw new TranslationError('Expected a submodule call');
    Map definition = select_submodule_definition(definitions, sub);
    String ret = definition['name'] + '(';
    ret += sub.childAt(1).childrenAfter(0).map(
        (x) => translate_literal(x)).join(',');
    ret += ')';
    return ret;
}

String translate_literal(Node literal) {
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
