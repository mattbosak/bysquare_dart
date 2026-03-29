import '../errors.dart';
import 'types.dart';

bool _isValidYyyymmdd(String date) {
  if (!RegExp(r'^\d{8}$').hasMatch(date)) return false;
  final year  = int.parse(date.substring(0, 4));
  final month = int.parse(date.substring(4, 6));
  final day   = int.parse(date.substring(6, 8));
  if (month < 1 || month > 12) return false;
  if (day < 1) return false;
  return day <= DateTime(year, month + 1, 0).day;
}

bool _isValidCurrencyCode(String code) =>
    RegExp(r'^[A-Z]{3}$').hasMatch(code);

bool _isValidCountryCode(String code) =>
    RegExp(r'^[A-Z]{2,3}$').hasMatch(code);

void _requireNonEmpty(dynamic value, String path) {
  if (value == null || (value is String && value.isEmpty)) {
    throw BysquareValidationError('Field is required.', path);
  }
}

void _requireDate(String? value, String path) {
  if (value != null && !_isValidYyyymmdd(value)) {
    throw BysquareValidationError(
      'Invalid date. Make sure YYYYMMDD format is used.',
      path,
    );
  }
}

/// Validates an [InvoiceDataModel] before encoding.
void validateInvoiceDataModel(InvoiceDataModel model) {
  _requireNonEmpty(model.invoiceId, 'invoiceId');
  _requireNonEmpty(model.issueDate, 'issueDate');
  _requireDate(model.issueDate, 'issueDate');
  _requireDate(model.taxPointDate, 'taxPointDate');

  _requireNonEmpty(model.localCurrencyCode, 'localCurrencyCode');
  if (!_isValidCurrencyCode(model.localCurrencyCode)) {
    throw const BysquareValidationError(
      'Invalid currency code. Must be 3 uppercase letters (ISO 4217).',
      'localCurrencyCode',
    );
  }

  // Foreign currency group: all three or none
  final hasForeign  = model.foreignCurrencyCode != null;
  final hasCurrRate = model.currRate != null;
  final hasRefRate  = model.referenceCurrRate != null;
  if (hasForeign != hasCurrRate || hasForeign != hasRefRate) {
    throw const BysquareValidationError(
      'When any of foreignCurrencyCode, currRate, or referenceCurrRate is '
      'set, all three are required.',
      'foreignCurrencyCode',
    );
  }
  if (hasForeign && !_isValidCurrencyCode(model.foreignCurrencyCode!)) {
    throw const BysquareValidationError(
      'Invalid currency code. Must be 3 uppercase letters (ISO 4217).',
      'foreignCurrencyCode',
    );
  }

  // Supplier party
  _requireNonEmpty(model.supplierParty.partyName, 'supplierParty.partyName');
  _requireNonEmpty(
    model.supplierParty.postalAddress.streetName,
    'supplierParty.postalAddress.streetName',
  );
  _requireNonEmpty(
    model.supplierParty.postalAddress.cityName,
    'supplierParty.postalAddress.cityName',
  );
  _requireNonEmpty(
    model.supplierParty.postalAddress.postalZone,
    'supplierParty.postalAddress.postalZone',
  );
  _requireNonEmpty(
    model.supplierParty.postalAddress.country,
    'supplierParty.postalAddress.country',
  );
  if (model.supplierParty.postalAddress.country != null &&
      !_isValidCountryCode(model.supplierParty.postalAddress.country!)) {
    throw const BysquareValidationError(
      'Invalid country code. Must be 2-3 uppercase letters.',
      'supplierParty.postalAddress.country',
    );
  }

  // Customer party
  _requireNonEmpty(model.customerParty.partyName, 'customerParty.partyName');

  // Invoice line: exactly one of numberOfInvoiceLines or singleInvoiceLine
  final hasLineCount  = model.numberOfInvoiceLines != null;
  final hasSingleLine = model.singleInvoiceLine != null;
  if (hasLineCount == hasSingleLine) {
    throw const BysquareValidationError(
      'Exactly one of numberOfInvoiceLines or singleInvoiceLine must be set.',
      'numberOfInvoiceLines',
    );
  }
  if (hasLineCount && model.numberOfInvoiceLines! <= 0) {
    throw const BysquareValidationError(
      'numberOfInvoiceLines must be a positive integer.',
      'numberOfInvoiceLines',
    );
  }

  // Single invoice line validation
  if (model.singleInvoiceLine != null) {
    final line = model.singleInvoiceLine!;
    final hasName = line.itemName != null;
    final hasEan  = line.itemEanCode != null;
    if (hasName == hasEan) {
      throw const BysquareValidationError(
        'Exactly one of itemName or itemEanCode must be set.',
        'singleInvoiceLine.itemName',
      );
    }

    final hasFrom = line.periodFromDate != null;
    final hasTo   = line.periodToDate != null;
    if (hasFrom != hasTo) {
      throw const BysquareValidationError(
        'Both periodFromDate and periodToDate must be set together.',
        'singleInvoiceLine.periodFromDate',
      );
    }
    if (hasFrom) {
      _requireDate(line.periodFromDate, 'singleInvoiceLine.periodFromDate');
      _requireDate(line.periodToDate,   'singleInvoiceLine.periodToDate');
      if (line.periodFromDate!.compareTo(line.periodToDate!) > 0) {
        throw const BysquareValidationError(
          'periodFromDate must not be after periodToDate.',
          'singleInvoiceLine.periodFromDate',
        );
      }
    }
  }

  // Tax category summaries
  if (model.taxCategorySummaries.isEmpty) {
    throw const BysquareValidationError(
      'At least one tax category summary is required.',
      'taxCategorySummaries',
    );
  }
  for (var i = 0; i < model.taxCategorySummaries.length; i++) {
    final tcs = model.taxCategorySummaries[i];
    if (tcs.classifiedTaxCategory < 0 || tcs.classifiedTaxCategory > 1) {
      throw BysquareValidationError(
        'classifiedTaxCategory must be a number in range [0, 1].',
        'taxCategorySummaries[$i].classifiedTaxCategory',
      );
    }
  }
}
