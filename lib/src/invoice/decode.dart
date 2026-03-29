import 'dart:convert';
import 'dart:typed_data';

import '../base32hex.dart';
import '../crc32.dart';
import '../errors.dart';
import '../header.dart';
import '../lzma.dart';
import '../types.dart';
import 'serializer.dart';
import 'types.dart';

/// Decodes a Base32Hex [qr] string into an [InvoiceDataModel].
///
/// Expects bysquareType=1 in the header. The documentType nibble determines
/// the invoice sub-type.
///
/// Throws [BysquareDecodeError] on malformed input, checksum mismatch, or
/// unsupported version.
InvoiceDataModel invoiceDecode(String qr) {
  final bytes = base32hexDecode(qr);

  if (bytes.length < 4) {
    throw const BysquareDecodeError('Input too short');
  }

  final header = decodeHeader(bytes.sublist(0, 2));

  if (header.bysquareType != 0x01) {
    throw BysquareDecodeError(
      'Expected bysquareType 1 (Invoice), got ${header.bysquareType}',
      {'bysquareType': header.bysquareType},
    );
  }

  if (header.version > Version.v120) {
    throw BysquareDecodeError(
      'Unsupported version',
      {'version': header.version},
    );
  }

  final payloadLength = bytes[2] | (bytes[3] << 8);
  final lzmaBody = bytes.sublist(4);

  late Uint8List decompressed;
  try {
    decompressed = lzmaDecompress(lzmaBody, payloadLength);
  } catch (e) {
    throw BysquareDecodeError(
      'LZMA decompression failed',
      {'error': e.toString()},
    );
  }

  if (decompressed.length < 4) {
    throw const BysquareDecodeError('Decompressed payload too short');
  }

  final storedChecksum = ByteData.view(
    decompressed.buffer,
    decompressed.offsetInBytes,
    4,
  ).getUint32(0, Endian.little);

  final body = decompressed.sublist(4);
  final decoded = utf8.decode(body);

  final computedChecksum = crc32(decoded);
  if (storedChecksum != computedChecksum) {
    throw BysquareDecodeError(
      'CRC32 checksum mismatch',
      {'stored': storedChecksum, 'computed': computedChecksum},
    );
  }

  return invoiceDeserialize(decoded, header.documentType);
}
