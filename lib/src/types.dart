/// Bysquare format version encoded in the QR header (4-bit field).
abstract final class Version {
  /// 1.0.0 - Created from original specification (2013-02-22).
  static const int v100 = 0x00;

  /// 1.1.0 - Added beneficiary name and address fields (2015-06-24).
  static const int v110 = 0x01;

  /// 1.2.0 - Beneficiary name is now required (2025-04-01).
  static const int v120 = 0x02;
}
