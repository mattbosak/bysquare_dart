import 'dart:typed_data';

const _chars = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
const _bits = 5;
const _mask = 0x1F; // 0b11111

/// Encodes [input] bytes to a Base32Hex string.
///
/// When [addPadding] is `true` (default) the output is padded to a multiple
/// of 8 characters with `=`. Pass `false` to suppress padding - this is what
/// the bysquare wire format expects.
String base32hexEncode(List<int> input, {bool addPadding = true}) {
  final output = StringBuffer();
  int buffer = 0;
  int bitsLeft = 0;

  for (final byte in input) {
    buffer = (buffer << 8) | (byte & 0xFF);
    bitsLeft += 8;

    while (bitsLeft >= _bits) {
      bitsLeft -= _bits;
      output.writeCharCode(_chars.codeUnitAt((buffer >> bitsLeft) & _mask));
    }
  }

  if (bitsLeft > 0) {
    final maskedValue = (buffer << (_bits - bitsLeft)) & _mask;
    output.writeCharCode(_chars.codeUnitAt(maskedValue));
  }

  var result = output.toString();

  if (addPadding) {
    final paddedLength = ((result.length + 7) ~/ 8) * 8;
    result = result.padRight(paddedLength, '=');
  }

  return result;
}

/// Decodes a Base32Hex [input] string back to bytes.
///
/// When [loose] is `true` the input is uppercased and missing padding is
/// added automatically. This is useful when reading QR codes that may omit
/// padding.
Uint8List base32hexDecode(String input, {bool loose = false}) {
  if (loose) {
    input = input.toUpperCase();
    final paddingNeeded = (8 - (input.length % 8)) % 8;
    input += '=' * paddingNeeded;
  }

  input = input.replaceAll(RegExp(r'=+$'), '');

  final output = <int>[];
  int buffer = 0;
  int bitsLeft = 0;

  for (int i = 0; i < input.length; i++) {
    final index = _chars.indexOf(input[i]);
    if (index == -1) {
      throw ArgumentError('Invalid Base32Hex character: "${input[i]}"');
    }

    buffer = (buffer << _bits) | index;
    bitsLeft += _bits;

    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      output.add((buffer >> bitsLeft) & 0xFF);
    }
  }

  return Uint8List.fromList(output);
}
