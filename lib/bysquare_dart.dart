/// PAY by square & Invoice by square - Dart implementation.
///
/// Encodes and decodes Slovak banking QR codes following the SBA standard
/// (v1.2.0 for PAY, v1.0.0 for Invoice).
///
/// ## Quick start - PAY by square
///
/// ```dart
/// import 'package:bysquare_dart/bysquare_dart.dart';
///
/// // Encode
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
///
/// // Decode
/// final model = payDecode(qr);
/// ```
///
/// ## Quick start - Invoice by square
///
/// ```dart
/// import 'package:bysquare_dart/bysquare_dart.dart';
///
/// final qr = invoiceEncode(
///   InvoiceDataModel(
///     documentType: InvoiceDocumentType.invoice,
///     invoiceId: 'FAK-2024-001',
///     issueDate: '20241201',
///     localCurrencyCode: 'EUR',
///     supplierParty: SupplierParty(
///       partyName: 'Acme s.r.o.',
///       postalAddress: PostalAddress(
///         streetName: 'Hlavná',
///         cityName: 'Bratislava',
///         postalZone: '81101',
///         country: 'SK',
///       ),
///     ),
///     customerParty: CustomerParty(partyName: 'Zákazník a.s.'),
///     numberOfInvoiceLines: 3,
///     taxCategorySummaries: [
///       TaxCategorySummary(
///         classifiedTaxCategory: 0.20,
///         taxExclusiveAmount: 100,
///         taxAmount: 20,
///       ),
///     ],
///     monetarySummary: MonetarySummary(),
///   ),
/// );
/// ```
library bysquare;

export 'src/base32hex.dart';
export 'src/classifier.dart';
export 'src/crc32.dart';
export 'src/deburr.dart';
export 'src/errors.dart';
export 'src/types.dart';

// PAY by square
export 'src/pay/decode.dart';
export 'src/pay/encode.dart';
export 'src/pay/serializer.dart' show paySerialize, payDeserialize;
export 'src/pay/types.dart';
export 'src/pay/validations.dart';

// Invoice by square
export 'src/invoice/decode.dart';
export 'src/invoice/encode.dart';
export 'src/invoice/serializer.dart' show invoiceSerialize, invoiceDeserialize;
export 'src/invoice/types.dart';
export 'src/invoice/validations.dart';
