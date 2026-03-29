import 'package:bysquare_dart/bysquare_dart.dart';
import 'package:test/test.dart';

void main() {
  group('crc32', () {
    final cases = [
      (input: '',          expected: 0),
      (input: 'a',         expected: 3904355907),
      (input: 'hello world', expected: 222957957),
      (input: '123456789', expected: 3421780262),
    ];

    for (final c in cases) {
      test('"${c.input}"', () {
        expect(crc32(c.input), equals(c.expected));
      });
    }
  });

  group('deburr', () {
    final cases = [
      (name: 'Slovak',   input: 'Pôvodná faktúra',           expected: 'Povodna faktura'),
      (name: 'Czech',    input: 'Príliš žluťoučký kůň',      expected: 'Prilis zlutoucky kun'),
      (name: 'German ß', input: 'ß',                         expected: 'ss'),
      (name: 'passthrough', input: 'Hello World 123',        expected: 'Hello World 123'),
      (name: 'empty',    input: '',                           expected: ''),
      (name: 'mixed',    input: 'Číslo 123 - Ján @ test.sk', expected: 'Cislo 123 - Jan @ test.sk'),
    ];

    for (final c in cases) {
      test(c.name, () {
        expect(deburr(c.input), equals(c.expected));
      });
    }
  });
}
