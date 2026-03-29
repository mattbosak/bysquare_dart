import 'types.dart';

String? _sanitize(String? value) => value?.replaceAll('\t', ' ');

String? _formatNumber(double? value) {
  if (value == null) return null;
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}

double? _parseNumber(String? value) =>
    (value != null && value.isNotEmpty) ? double.parse(value) : null;

String? _parseString(String? value) =>
    (value != null && value.isNotEmpty) ? value : null;

/// Serializes an [InvoiceDataModel] to the tab-separated wire format.
String invoiceSerialize(InvoiceDataModel data) {
  final s = <String?>[];

  // Core fields
  s.add(_sanitize(data.invoiceId));
  s.add(_sanitize(data.issueDate));
  s.add(_sanitize(data.taxPointDate));
  s.add(_sanitize(data.orderId));
  s.add(_sanitize(data.deliveryNoteId));
  s.add(_sanitize(data.localCurrencyCode));
  s.add(_sanitize(data.foreignCurrencyCode));
  s.add(_formatNumber(data.currRate));
  s.add(_formatNumber(data.referenceCurrRate));

  // Supplier party
  final sp = data.supplierParty;
  s.add(_sanitize(sp.partyName));
  s.add(_sanitize(sp.companyTaxId));
  s.add(_sanitize(sp.companyVatId));
  s.add(_sanitize(sp.companyRegisterId));

  final pa = sp.postalAddress;
  s.add(_sanitize(pa.streetName));
  s.add(_sanitize(pa.buildingNumber));
  s.add(_sanitize(pa.cityName));
  s.add(_sanitize(pa.postalZone));
  s.add(_sanitize(pa.state));
  s.add(_sanitize(pa.country));

  s.add(_sanitize(sp.contact?.name));
  s.add(_sanitize(sp.contact?.telephone));
  s.add(_sanitize(sp.contact?.email));

  // Customer party
  final cp = data.customerParty;
  s.add(_sanitize(cp.partyName));
  s.add(_sanitize(cp.companyTaxId));
  s.add(_sanitize(cp.companyVatId));
  s.add(_sanitize(cp.companyRegisterId));
  s.add(_sanitize(cp.partyIdentification));

  s.add(data.numberOfInvoiceLines?.toString());
  s.add(_sanitize(data.invoiceDescription));

  // Single invoice line
  final line = data.singleInvoiceLine;
  s.add(_sanitize(line?.orderLineId));
  s.add(_sanitize(line?.deliveryNoteLineId));
  s.add(_sanitize(line?.itemName));
  s.add(_sanitize(line?.itemEanCode));
  s.add(_sanitize(line?.periodFromDate));
  s.add(_sanitize(line?.periodToDate));
  s.add(_formatNumber(line?.invoicedQuantity));

  // Tax category summaries
  s.add(data.taxCategorySummaries.length.toString());
  for (final tcs in data.taxCategorySummaries) {
    s.add(tcs.classifiedTaxCategory.toString());
    s.add(tcs.taxExclusiveAmount.toString());
    s.add(tcs.taxAmount.toString());
    s.add(_formatNumber(tcs.alreadyClaimedTaxExclusiveAmount));
    s.add(_formatNumber(tcs.alreadyClaimedTaxAmount));
  }

  // Monetary summary
  s.add(_formatNumber(data.monetarySummary.payableRoundingAmount));
  s.add(_formatNumber(data.monetarySummary.paidDepositsAmount));

  // Payment means bitmask
  s.add(data.paymentMeans?.toString());

  return s.map((e) => e ?? '').join('\t');
}

/// Deserializes the tab-separated [tabString] back into an [InvoiceDataModel].
InvoiceDataModel invoiceDeserialize(String tabString, int documentType) {
  final data = tabString.split('\t');
  int i = 0;

  String? next() => i < data.length ? data[i++] : null;

  // Core fields
  final invoiceId = next() ?? '';
  final issueDate = next() ?? '';
  final taxPointDate = _parseString(next());
  final orderId = _parseString(next());
  final deliveryNoteId = _parseString(next());
  final localCurrency = next() ?? '';
  final foreignCurrency = _parseString(next());
  final currRate = _parseNumber(next());
  final refCurrRate = _parseNumber(next());

  // Supplier party
  final spName = next() ?? '';
  final spTaxId = _parseString(next());
  final spVatId = _parseString(next());
  final spRegisterId = _parseString(next());

  final postalAddress = PostalAddress(
    streetName: _parseString(next()),
    buildingNumber: _parseString(next()),
    cityName: _parseString(next()),
    postalZone: _parseString(next()),
    state: _parseString(next()),
    country: _parseString(next()),
  );

  final contactName = _parseString(next());
  final contactPhone = _parseString(next());
  final contactEmail = _parseString(next());
  final contact = (contactName != null ||
          contactPhone != null ||
          contactEmail != null)
      ? Contact(name: contactName, telephone: contactPhone, email: contactEmail)
      : null;

  final supplierParty = SupplierParty(
    partyName: spName,
    companyTaxId: spTaxId,
    companyVatId: spVatId,
    companyRegisterId: spRegisterId,
    postalAddress: postalAddress,
    contact: contact,
  );

  // Customer party
  final customerParty = CustomerParty(
    partyName: next() ?? '',
    companyTaxId: _parseString(next()),
    companyVatId: _parseString(next()),
    companyRegisterId: _parseString(next()),
    partyIdentification: _parseString(next()),
  );

  final numberOfLines = _parseNumber(next())?.toInt();
  final invoiceDesc = _parseString(next());

  // Single invoice line
  final lineOrderId = _parseString(next());
  final lineDeliveryId = _parseString(next());
  final lineItemName = _parseString(next());
  final lineItemEan = _parseString(next());
  final linePeriodFrom = _parseString(next());
  final linePeriodTo = _parseString(next());
  final lineQuantity = _parseNumber(next());

  final hasSingleLine = lineOrderId != null ||
      lineDeliveryId != null ||
      lineItemName != null ||
      lineItemEan != null ||
      linePeriodFrom != null ||
      linePeriodTo != null ||
      lineQuantity != null;

  final singleLine = hasSingleLine
      ? SingleInvoiceLine(
          orderLineId: lineOrderId,
          deliveryNoteLineId: lineDeliveryId,
          itemName: lineItemName,
          itemEanCode: lineItemEan,
          periodFromDate: linePeriodFrom,
          periodToDate: linePeriodTo,
          invoicedQuantity: lineQuantity,
        )
      : null;

  // Tax category summaries
  final taxCount = int.parse(next() ?? '0');
  final taxSummaries = <TaxCategorySummary>[];
  for (int t = 0; t < taxCount; t++) {
    taxSummaries.add(TaxCategorySummary(
      classifiedTaxCategory: double.parse(next() ?? '0'),
      taxExclusiveAmount: double.parse(next() ?? '0'),
      taxAmount: double.parse(next() ?? '0'),
      alreadyClaimedTaxExclusiveAmount: _parseNumber(next()),
      alreadyClaimedTaxAmount: _parseNumber(next()),
    ));
  }

  // Monetary summary
  final monetarySummary = MonetarySummary(
    payableRoundingAmount: _parseNumber(next()),
    paidDepositsAmount: _parseNumber(next()),
  );

  final paymentMeans = _parseNumber(next())?.toInt();

  return InvoiceDataModel(
    documentType: documentType,
    invoiceId: invoiceId,
    issueDate: issueDate,
    taxPointDate: taxPointDate,
    orderId: orderId,
    deliveryNoteId: deliveryNoteId,
    localCurrencyCode: localCurrency,
    foreignCurrencyCode: foreignCurrency,
    currRate: currRate,
    referenceCurrRate: refCurrRate,
    supplierParty: supplierParty,
    customerParty: customerParty,
    numberOfInvoiceLines: numberOfLines,
    invoiceDescription: invoiceDesc,
    singleInvoiceLine: singleLine,
    taxCategorySummaries: taxSummaries,
    monetarySummary: monetarySummary,
    paymentMeans: paymentMeans,
  );
}
