import 'dart:typed_data';

import '../base32hex.dart';
import '../deburr.dart';
import '../header.dart';
import '../lzma.dart';
import '../types.dart';
import 'serializer.dart';
import 'types.dart';
import 'validations.dart';

/// Options for [payEncode].
class PayEncodeOptions {
  /// Strip diacritics from text fields before encoding.
  ///
  /// Many Slovak banking apps only accept ASCII text. Defaults to `true`.
  final bool deburr;

  /// Validate the data model before encoding. Defaults to `true`.
  final bool validate;

  /// Bysquare specification version to embed in the QR header.
  ///
  /// Defaults to [Version.v120]. Pass [Version.v100] or [Version.v110] for
  /// compatibility with older apps that do not require a beneficiary name.
  final int version;

  const PayEncodeOptions({
    this.deburr = true,
    this.validate = true,
    this.version = Version.v120,
  });
}

/// Removes diacritics from all text fields that may contain them.
PayDataModel _removeDiacritics(PayDataModel model) {
  final updatedPayments = model.payments.map((p) {
    final note = p.paymentNote != null ? deburr(p.paymentNote!) : null;
    final ben = Beneficiary(
      name: deburr(p.beneficiary.name),
      street:
          p.beneficiary.street != null ? deburr(p.beneficiary.street!) : null,
      city: p.beneficiary.city != null ? deburr(p.beneficiary.city!) : null,
    );

    return _copyPaymentWith(p, paymentNote: note, beneficiary: ben);
  }).toList();

  return PayDataModel(invoiceId: model.invoiceId, payments: updatedPayments);
}

/// Returns a copy of [p] with overridden [paymentNote] and [beneficiary].
Payment _copyPaymentWith(
  Payment p, {
  String? paymentNote,
  required Beneficiary beneficiary,
}) {
  return switch (p) {
    PaymentOrder _ => PaymentOrder(
        amount: p.amount,
        currencyCode: p.currencyCode,
        paymentDueDate: p.paymentDueDate,
        variableSymbol: p.variableSymbol,
        constantSymbol: p.constantSymbol,
        specificSymbol: p.specificSymbol,
        originatorsReferenceInformation: p.originatorsReferenceInformation,
        paymentNote: paymentNote,
        bankAccounts: p.bankAccounts,
        beneficiary: beneficiary,
      ),
    StandingOrder so => StandingOrder(
        amount: p.amount,
        currencyCode: p.currencyCode,
        paymentDueDate: p.paymentDueDate,
        variableSymbol: p.variableSymbol,
        constantSymbol: p.constantSymbol,
        specificSymbol: p.specificSymbol,
        originatorsReferenceInformation: p.originatorsReferenceInformation,
        paymentNote: paymentNote,
        bankAccounts: p.bankAccounts,
        beneficiary: beneficiary,
        day: so.day,
        month: so.month,
        periodicity: so.periodicity,
        lastDate: so.lastDate,
      ),
    DirectDebit dd => DirectDebit(
        amount: p.amount,
        currencyCode: p.currencyCode,
        paymentDueDate: p.paymentDueDate,
        variableSymbol: p.variableSymbol,
        constantSymbol: p.constantSymbol,
        specificSymbol: p.specificSymbol,
        originatorsReferenceInformation: p.originatorsReferenceInformation,
        paymentNote: paymentNote,
        bankAccounts: p.bankAccounts,
        beneficiary: beneficiary,
        directDebitScheme: dd.directDebitScheme,
        directDebitType: dd.directDebitType,
        ddVariableSymbol: dd.ddVariableSymbol,
        ddSpecificSymbol: dd.ddSpecificSymbol,
        ddOriginatorsReferenceInformation: dd.ddOriginatorsReferenceInformation,
        mandateId: dd.mandateId,
        creditorId: dd.creditorId,
        contractId: dd.contractId,
        maxAmount: dd.maxAmount,
        validTillDate: dd.validTillDate,
      ),
  };
}

/// Encodes a [PayDataModel] into a Base32Hex QR string ready for embedding
/// in a QR code image.
///
/// ```dart
/// final qr = payEncode(
///   PayDataModel(
///     payments: [
///       PaymentOrder(
///         amount: 19.99,
///         currencyCode: 'EUR',
///         bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
///         beneficiary: Beneficiary(name: 'Acme s.r.o.'),
///       ),
///     ],
///   ),
/// );
/// ```
String payEncode(PayDataModel model,
    [PayEncodeOptions options = const PayEncodeOptions()]) {
  if (options.deburr) {
    model = _removeDiacritics(model);
  }

  if (options.validate) {
    validatePayDataModel(model, version: options.version);
  }

  final tabbed = paySerialize(model);
  final checked = addChecksum(tabbed);
  final compressed = lzmaCompress(checked);

  // Strip the 13-byte LZMA header - bysquare stores only the body
  final lzmaBody = compressed.sublist(13);

  final output = Uint8List.fromList([
    ...buildBysquareHeader(
      bySquareType: 0x00,
      version: options.version,
      documentType: 0x00,
    ),
    ...buildPayloadLength(checked.length),
    ...lzmaBody,
  ]);

  return base32hexEncode(output, addPadding: false);
}
