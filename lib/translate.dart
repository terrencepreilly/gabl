import 'package:yaml/yaml.dart';
import 'dart:async';
import 'dart:io';

import 'utils.dart';


Map<String, String> typeMap = {
    'num': 'Long',
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
    String gabl_name = sub.childAt(0)?.value;
    if (! definitions['functions'].containsKey(gabl_name))
        throw new TranslationError('Undefined submodule $gabl_name');
    Map definition = definitions['functions'][gabl_name];
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
