import 'dart:convert';

// Standard CRC32 lookup table (IEEE polynomial 0xEDB88320).
final List<int> _crc32Table = _buildTable();

List<int> _buildTable() {
  final table = List<int>.filled(256, 0);
  for (int i = 0; i < 256; i++) {
    int c = i;
    for (int j = 0; j < 8; j++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }
  return table;
}

/// Computes the CRC32 checksum of [data] encoded as UTF-8.
///
/// Returns an unsigned 32-bit integer.
int crc32(String data) {
  final bytes = utf8.encode(data);
  int crc = 0xFFFFFFFF;

  for (final byte in bytes) {
    crc = (crc >>> 8) ^ _crc32Table[(crc ^ byte) & 0xFF];
  }

  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
