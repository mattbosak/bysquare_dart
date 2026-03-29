/// Thrown when a data model field fails validation.
class BysquareValidationError implements Exception {
  final String message;

  /// JSON-path to the invalid field (e.g. `payments[0].bankAccounts[0].iban`).
  final String path;

  const BysquareValidationError(this.message, this.path);

  @override
  String toString() => 'BysquareValidationError at "$path": $message';
}

/// Thrown when encoding fails due to invalid header values or oversized payload.
class BysquareEncodeError implements Exception {
  final String message;
  final Map<String, dynamic>? extensions;

  const BysquareEncodeError(this.message, [this.extensions]);

  @override
  String toString() => 'BysquareEncodeError: $message'
      '${extensions != null ? ' $extensions' : ''}';
}

/// Thrown when decoding fails due to bad input, checksum mismatch, or
/// unsupported format version.
class BysquareDecodeError implements Exception {
  final String message;
  final Map<String, dynamic>? extensions;

  const BysquareDecodeError(this.message, [this.extensions]);

  @override
  String toString() => 'BysquareDecodeError: $message'
      '${extensions != null ? ' $extensions' : ''}';
}
