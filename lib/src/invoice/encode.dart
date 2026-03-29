import 'dart:typed_data';

import '../base32hex.dart';
import '../header.dart';
import '../lzma.dart';
import '../types.dart';
import 'serializer.dart';
import 'types.dart';
import 'validations.dart';

/// Options for [invoiceEncode].
class InvoiceEncodeOptions {
  /// Validate the data model before encoding. Defaults to `true`.
  final bool validate;

  /// Bysquare specification version to embed in the header.
  ///
  /// Note: the official app performs strict equality matching on version=0,
  /// so [Version.v100] is the only fully compatible value for invoices.
  /// Defaults to [Version.v100].
  final int version;

  const InvoiceEncodeOptions({
    this.validate = true,
    this.version = Version.v100,
  });
}

/// Encodes an [InvoiceDataModel] into a Base32Hex QR string.
///
/// Uses bysquareType=1; the [InvoiceDataModel.documentType] nibble selects the
/// specific sub-type (Invoice, ProformaInvoice, CreditNote, etc.).
String invoiceEncode(
  InvoiceDataModel model, [
  InvoiceEncodeOptions options = const InvoiceEncodeOptions(),
]) {
  if (options.validate) {
    validateInvoiceDataModel(model);
  }

  final tabbed    = invoiceSerialize(model);
  final checked   = addChecksum(tabbed);
  final compressed = lzmaCompress(checked);

  // Strip the 13-byte LZMA header - bysquare stores only the body
  final lzmaBody = compressed.sublist(13);

  final output = Uint8List.fromList([
    ...buildBysquareHeader(
      bySquareType: 0x01, // TYPE_INVOICE
      version: options.version,
      documentType: model.documentType,
    ),
    ...buildPayloadLength(checked.length),
    ...lzmaBody,
  ]);

  return base32hexEncode(output, addPadding: false);
}
