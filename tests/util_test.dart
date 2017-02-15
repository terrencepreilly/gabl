import 'package:test/test.dart';
import '../lib/translate.dart';

main() {
    group('Memory', () {
        test('can get types defined for a name', () {
            Memory m = new Memory();
            m.add('a', 'int');
            m.add('a', 'str');
            List<String> types = m.lookup_types('a');
            expect(types.length, equals(2));
            expect(types.contains('int'), equals(true));
            expect(types.contains('bool'), equals(false));
        });
        test('returns [] when name undefined', () {
            Memory m = new Memory();
            expect(m.lookup_types('a').length, equals(0));
            m.add('a', 'int');
            expect(m.lookup_types('b').length, equals(0));
        });
        test('Can add names to memory.', () {
            Memory mem = new Memory();
            mem.add('var1', 'str');
            mem.add('var2', 'str');
        });
        test('Can see last item added to memory', () {
            Memory mem = new Memory();
            mem.add('var1', 'int');
            mem.add('var2', 'int');
            expect(mem.last, equals('var2'));
        });
        test('Can designate the last item, if it already exists', () {
            Memory mem = new Memory();
            mem.add('var1', 'int');
            mem.add('var2', 'int');
            mem.touch('var1');
            expect(mem.last, equals('var1'));
        });
        test('Adding the same value twice raises an error', () {
            Memory mem = new Memory();
            mem.add('var1', 'str');
            try {
                mem.add('var1', 'str');
            } catch (e) {
                expect(e.msg, equals('Variable var1 already exists.'));
            }
        });
        test('Can generate a new, unique name', () {
            Memory mem = new Memory();
            mem.add('v0', 'str');
            mem.next('str');
            expect(mem.last, isNot(equals('v0')), reason: mem.names.join(' '));
            expect(mem.last, equals('v1'));
            mem.next('str');
            expect(mem.last, equals('v2'));
        });
    });
}
