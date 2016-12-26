import 'package:test/test.dart';

import '../lib/lexer.dart';
import '../lib/parser.dart';
import '../lib/utils.dart';

/// Expect that [s], when parsed, will give the string [expected].
void fromStringExpect(String s, String expected,
        [Function parser = parse_expression]) {
    SimpleStream<Token> ss = streamify(s);
    Node exp = parser(ss);
    expect(exp.toString(), equals(expected));
}


/// Expect an exception to be raised from parsing [s] with [parser].
bool raisesException(String s, [Function parser = parse_expression]) {
    bool raised = false;
    try {
        parser(streamify(s));
    } catch(e) {
        raised = true;
    }
    expect(raised, equals(true), reason: '"$s" should have raised exception');
}


