import 'dart:convert';
import 'dart:typed_data';

import 'crc32.dart';
import 'errors.dart';

/// Maximum allowed uncompressed payload size (2^17 = 131 072 bytes).
const int maxCompressedSize = 131072;

/// Decoded representation of the 2-byte bysquare header.
class BysquareHeader {
  final int bysquareType;
  final int version;
  final int documentType;
  final int reserved;

  const BysquareHeader({
    required this.bysquareType,
    required this.version,
    required this.documentType,
    required this.reserved,
  });
}

/// Builds the 2-byte bysquare header from four 4-bit nibbles.
///
/// ```
/// Byte 0                  Byte 1
/// +----------+----------+----------+----------+
/// |   4 bit  |   4 bit  |   4 bit  |   4 bit  |
/// +----------+----------+----------+----------+
/// | BySqType | Version  | DocType  | Reserved |
/// +----------+----------+----------+----------+
/// ```
List<int> buildBysquareHeader({
  int bySquareType = 0x00,
  int version = 0x00,
  int documentType = 0x00,
  int reserved = 0x00,
}) {
  if (bySquareType < 0 || bySquareType > 15) {
    throw BysquareEncodeError(
      'Invalid BySquareType value in header, valid range <0,15>',
      {'invalidValue': bySquareType},
    );
  }
  if (version < 0 || version > 15) {
    throw BysquareEncodeError(
      'Invalid Version value in header',
      {'invalidValue': version},
    );
  }
  if (documentType < 0 || documentType > 15) {
    throw BysquareEncodeError(
      'Invalid DocumentType value in header, valid range <0,15>',
      {'invalidValue': documentType},
    );
  }
  if (reserved < 0 || reserved > 15) {
    throw BysquareEncodeError(
      'Invalid Reserved value in header, valid range <0,15>',
      {'invalidValue': reserved},
    );
  }

  return [
    (bySquareType << 4) | version,
    (documentType << 4) | reserved,
  ];
}

/// Extracts the four 4-bit nibbles from a 2-byte bysquare [header].
BysquareHeader decodeHeader(Uint8List header) {
  final bytes = (header[0] << 8) | header[1];
  return BysquareHeader(
    bysquareType: bytes >> 12,
    version: (bytes >> 8) & 0x0F,
    documentType: (bytes >> 4) & 0x0F,
    reserved: bytes & 0x0F,
  );
}

/// Encodes [length] as a little-endian 16-bit unsigned integer (2 bytes).
///
/// ```
/// +---------------+---------------+
/// |    Byte 0     |    Byte 1     |
/// +---------------+---------------+
/// |      LSB      |      MSB      |
/// +---------------+---------------+
/// ```
Uint8List buildPayloadLength(int length) {
  if (length >= maxCompressedSize) {
    throw BysquareEncodeError(
      'Allowed header data size exceeded',
      {'actualSize': length, 'allowedSize': maxCompressedSize},
    );
  }

  final bd = ByteData(2);
  bd.setUint16(0, length, Endian.little);
  return bd.buffer.asUint8List();
}

/// Prepends a 4-byte CRC32 checksum (little-endian) to [tabbedPayload].
///
/// ```
/// +------------------+---------------------------+
/// |      4 bytes     |        Variable           |
/// +------------------+---------------------------+
/// | CRC32 Checksum   | Tab-separated payload     |
/// | (little-endian)  | (UTF-8 encoded)           |
/// +------------------+---------------------------+
/// ```
Uint8List addChecksum(String tabbedPayload) {
  final bd = ByteData(4);
  bd.setUint32(0, crc32(tabbedPayload), Endian.little);

  final checksumBytes = bd.buffer.asUint8List();
  final payloadBytes = utf8.encode(tabbedPayload);

  final result = Uint8List(4 + payloadBytes.length);
  result.setRange(0, 4, checksumBytes);
  result.setRange(4, result.length, payloadBytes);
  return result;
}
