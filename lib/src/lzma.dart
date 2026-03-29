import 'dart:typed_data';

import 'package:lzma/lzma.dart';

// Fixed LZMA1 properties used by bysquare:
//   lc=3, lp=0, pb=2  →  (pb*5 + lp)*9 + lc = (2*5+0)*9+3 = 93 = 0x5D
const int _lzmaPropertyByte = 0x5D;

// Dictionary size 2^17 = 131072, stored little-endian in 4 bytes.
const List<int> _lzmaDictSize = [0x00, 0x00, 0x02, 0x00];

/// Compresses [input] with LZMA1.
///
/// Returns the **full** 13-byte-header + body stream. The caller is
/// responsible for stripping the header before embedding in a QR payload.
///
/// Uses `package:lzma` which is a pure-Dart LZMA SDK port.
Uint8List lzmaCompress(Uint8List input) {
  final compressed = Uint8List.fromList(lzma.encode(input));

  // Sanity-check: bysquare decodes with fixed properties 0x5D. Verify that
  // the encoder used the same property byte so round-trips work.
  if (compressed.isNotEmpty && compressed[0] != _lzmaPropertyByte) {
    throw StateError(
      'lzma.encode produced unexpected property byte '
      '0x${compressed[0].toRadixString(16).padLeft(2, '0')} '
      '(expected 0x5D). '
      'Please file an issue - the lzma package may have changed its defaults.',
    );
  }

  return compressed;
}

/// Decompresses an LZMA **body** (without the 13-byte header) back to the
/// original bytes.
///
/// [uncompressedLength] is the value stored in the bysquare payload-length
/// field (2 bytes, little-endian). It is used to reconstruct the full LZMA
/// stream header before passing data to `lzma.decode`.
Uint8List lzmaDecompress(Uint8List lzmaBody, int uncompressedLength) {
  // Build the 8-byte uncompressed-size field (little-endian 64-bit).
  final sizeBytes = Uint8List(8);
  sizeBytes[0] = uncompressedLength & 0xFF;
  sizeBytes[1] = (uncompressedLength >> 8) & 0xFF;
  sizeBytes[2] = (uncompressedLength >> 16) & 0xFF;
  sizeBytes[3] = (uncompressedLength >> 24) & 0xFF;
  // Bytes 4-7 remain 0 for sizes < 2^32.

  // Reconstruct the full LZMA stream: [props(1)] [dictSize(4)] [size(8)] [body]
  final fullStream = <int>[
    _lzmaPropertyByte,
    ..._lzmaDictSize,
    ...sizeBytes,
    ...lzmaBody,
  ];

  return Uint8List.fromList(lzma.decode(fullStream));
}
