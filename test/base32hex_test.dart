import 'dart:typed_data';

import 'package:bysquare_dart/bysquare_dart.dart';
import 'package:test/test.dart';

void main() {
  group('base32hexEncode', () {
    final cases = [
      (name: 'empty',       input: <int>[],                         expected: ''),
      (name: '1 byte',      input: [102],                           expected: 'CO======'),
      (name: '2 bytes',     input: [102, 111],                      expected: 'CPNG===='),
      (name: '3 bytes',     input: [102, 111, 111],                 expected: 'CPNMU==='),
      (name: '4 bytes',     input: [102, 111, 111, 98],             expected: 'CPNMUOG='),
      (name: '5 bytes',     input: [102, 111, 111, 98, 97],         expected: 'CPNMUOJ1'),
      (name: '6 bytes',     input: [102, 111, 111, 98, 97, 114],    expected: 'CPNMUOJ1E8======'),
    ];

    for (final c in cases) {
      test(c.name, () {
        expect(base32hexEncode(c.input), equals(c.expected));
      });
    }

    test('no padding - 3 bytes', () {
      expect(
        base32hexEncode([102, 111, 111], addPadding: false),
        equals('CPNMU'),
      );
    });
  });

  group('base32hexDecode', () {
    final cases = [
      (name: 'empty',   input: '',             expected: <int>[]),
      (name: '1 byte',  input: 'CO======',     expected: [102]),
      (name: '2 bytes', input: 'CPNG====',     expected: [102, 111]),
      (name: '3 bytes', input: 'CPNMU===',     expected: [102, 111, 111]),
      (name: '4 bytes', input: 'CPNMUOG=',     expected: [102, 111, 111, 98]),
      (name: '5 bytes', input: 'CPNMUOJ1',     expected: [102, 111, 111, 98, 97]),
      (name: '6 bytes', input: 'CPNMUOJ1E8======', expected: [102, 111, 111, 98, 97, 114]),
    ];

    for (final c in cases) {
      test(c.name, () {
        expect(
          base32hexDecode(c.input),
          equals(Uint8List.fromList(c.expected)),
        );
      });
    }

    test('loose mode - lowercase', () {
      expect(
        base32hexDecode('cpnmu===', loose: true),
        equals(Uint8List.fromList([102, 111, 111])),
      );
    });

    test('loose mode - no padding', () {
      expect(
        base32hexDecode('CPNMU', loose: true),
        equals(Uint8List.fromList([102, 111, 111])),
      );
    });

    test('invalid character throws', () {
      expect(() => base32hexDecode('CPNM!'), throwsArgumentError);
    });

    test('round-trip', () {
      final original = Uint8List.fromList(
          List.generate(64, (i) => i * 3 % 256));
      final encoded = base32hexEncode(original, addPadding: false);
      expect(base32hexDecode(encoded, loose: true), equals(original));
    });
  });
}
