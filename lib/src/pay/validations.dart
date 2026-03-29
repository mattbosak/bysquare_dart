import '../errors.dart';
import '../types.dart';
import 'types.dart';

bool _isValidYyyymmdd(String date) {
  if (!RegExp(r'^\d{8}$').hasMatch(date)) return false;

  final year = int.parse(date.substring(0, 4));
  final month = int.parse(date.substring(4, 6));
  final day = int.parse(date.substring(6, 8));

  if (month < 1 || month > 12) return false;
  if (day < 1) return false;

  final daysInMonth = DateTime(year, month + 1, 0).day;
  return day <= daysInMonth;
}

bool _isValidIban(String iban) {
  final cleaned = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (cleaned.length < 15 || cleaned.length > 34) return false;
  if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(cleaned)) return false;

  final rearranged = cleaned.substring(4) + cleaned.substring(0, 4);

  final numeric = StringBuffer();
  for (final ch in rearranged.split('')) {
    final code = ch.codeUnitAt(0);
    if (code >= 65 && code <= 90) {
      numeric.write(code - 55);
    } else {
      numeric.write(ch);
    }
  }

  var remainder = 0;
  for (final digit in numeric.toString().split('')) {
    remainder = (remainder * 10 + int.parse(digit)) % 97;
  }
  return remainder == 1;
}

bool _isValidBic(String bic) =>
    RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(bic);

bool _isValidCurrencyCode(String code) => RegExp(r'^[A-Z]{3}$').hasMatch(code);

/// Validates a [BankAccount] - IBAN and optional BIC.
void validateBankAccount(BankAccount account, String path) {
  if (!_isValidIban(account.iban)) {
    throw BysquareValidationError(
      'Invalid IBAN. Make sure ISO 13616 format is used.',
      '$path.iban',
    );
  }
  if (account.bic != null && !_isValidBic(account.bic!)) {
    throw BysquareValidationError(
      'Invalid BIC. Make sure ISO 9362 format is used.',
      '$path.bic',
    );
  }
}

/// Validates a [Payment] - currency code, dates, bank accounts, and
/// beneficiary name (required since v1.2.0).
void validatePayment(Payment payment, String path,
    {int version = Version.v120}) {
  for (var i = 0; i < payment.bankAccounts.length; i++) {
    validateBankAccount(payment.bankAccounts[i], '$path.bankAccounts[$i]');
  }

  if (!_isValidCurrencyCode(payment.currencyCode)) {
    throw BysquareValidationError(
      'Invalid currency code. Make sure ISO 4217 format is used.',
      '$path.currencyCode',
    );
  }

  if (payment.paymentDueDate != null &&
      !_isValidYyyymmdd(payment.paymentDueDate!)) {
    throw BysquareValidationError(
      'Invalid date. Make sure YYYYMMDD format is used.',
      '$path.paymentDueDate',
    );
  }

  if (payment is StandingOrder &&
      payment.lastDate != null &&
      !_isValidYyyymmdd(payment.lastDate!)) {
    throw BysquareValidationError(
      'Invalid date. Make sure YYYYMMDD format is used.',
      '$path.lastDate',
    );
  }

  if (payment is DirectDebit &&
      payment.validTillDate != null &&
      !_isValidYyyymmdd(payment.validTillDate!)) {
    throw BysquareValidationError(
      'Invalid date. Make sure YYYYMMDD format is used.',
      '$path.validTillDate',
    );
  }

  if (version >= Version.v120 && payment.beneficiary.name.isEmpty) {
    throw BysquareValidationError(
      'Beneficiary name is required.',
      '$path.beneficiary.name',
    );
  }
}

/// Validates the full [PayDataModel].
void validatePayDataModel(PayDataModel model, {int version = Version.v120}) {
  for (var i = 0; i < model.payments.length; i++) {
    validatePayment(model.payments[i], 'payments[$i]', version: version);
  }
}
