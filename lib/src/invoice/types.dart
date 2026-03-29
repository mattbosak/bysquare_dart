/// Invoice document sub-types within bysquareType=1.
abstract final class InvoiceDocumentType {
  static const int invoice         = 0x00;
  static const int proformaInvoice = 0x01;
  static const int creditNote      = 0x02;
  static const int debitNote       = 0x03;
  static const int advanceInvoice  = 0x04;
}

/// Payment means as bit-flag constants. Combine with bitwise OR.
abstract final class PaymentMean {
  static const int moneyTransfer  = 0x01;
  static const int cash           = 0x02;
  static const int cashOnDelivery = 0x04;
  static const int creditCard     = 0x08;
  static const int advance        = 0x10;
  static const int mutualOffset   = 0x20;
  static const int other          = 0x40;
}

class Contact {
  final String? name;
  final String? telephone;
  final String? email;

  const Contact({this.name, this.telephone, this.email});
}

class PostalAddress {
  final String? streetName;
  final String? buildingNumber;
  final String? cityName;
  final String? postalZone;
  final String? state;
  final String? country;

  const PostalAddress({
    this.streetName,
    this.buildingNumber,
    this.cityName,
    this.postalZone,
    this.state,
    this.country,
  });
}

class SupplierParty {
  final String partyName;
  final String? companyTaxId;
  final String? companyVatId;
  final String? companyRegisterId;
  final PostalAddress postalAddress;
  final Contact? contact;

  const SupplierParty({
    required this.partyName,
    this.companyTaxId,
    this.companyVatId,
    this.companyRegisterId,
    required this.postalAddress,
    this.contact,
  });
}

class CustomerParty {
  final String partyName;
  final String? companyTaxId;
  final String? companyVatId;
  final String? companyRegisterId;
  final String? partyIdentification;

  const CustomerParty({
    required this.partyName,
    this.companyTaxId,
    this.companyVatId,
    this.companyRegisterId,
    this.partyIdentification,
  });
}

class SingleInvoiceLine {
  final String? orderLineId;
  final String? deliveryNoteLineId;
  final String? itemName;
  final String? itemEanCode;

  /// `YYYYMMDD`
  final String? periodFromDate;

  /// `YYYYMMDD`
  final String? periodToDate;
  final double? invoicedQuantity;

  const SingleInvoiceLine({
    this.orderLineId,
    this.deliveryNoteLineId,
    this.itemName,
    this.itemEanCode,
    this.periodFromDate,
    this.periodToDate,
    this.invoicedQuantity,
  });
}

class TaxCategorySummary {
  /// Decimal in range [0, 1] representing the tax rate (e.g. 0.20 for 20 %).
  final double classifiedTaxCategory;
  final double taxExclusiveAmount;
  final double taxAmount;
  final double? alreadyClaimedTaxExclusiveAmount;
  final double? alreadyClaimedTaxAmount;

  const TaxCategorySummary({
    required this.classifiedTaxCategory,
    required this.taxExclusiveAmount,
    required this.taxAmount,
    this.alreadyClaimedTaxExclusiveAmount,
    this.alreadyClaimedTaxAmount,
  });
}

class MonetarySummary {
  final double? payableRoundingAmount;
  final double? paidDepositsAmount;

  const MonetarySummary({this.payableRoundingAmount, this.paidDepositsAmount});
}

/// Root data model for an Invoice by square QR code.
class InvoiceDataModel {
  final int documentType;

  /// Required invoice identifier.
  final String invoiceId;

  /// Required issue date in `YYYYMMDD` format.
  final String issueDate;

  final String? taxPointDate;
  final String? orderId;
  final String? deliveryNoteId;

  /// ISO 4217 currency code.
  final String localCurrencyCode;

  /// ISO 4217 foreign currency code. Required when [currRate] is set.
  final String? foreignCurrencyCode;
  final double? currRate;
  final double? referenceCurrRate;

  final SupplierParty supplierParty;
  final CustomerParty customerParty;

  /// Mutually exclusive with [singleInvoiceLine].
  final int? numberOfInvoiceLines;
  final String? invoiceDescription;

  /// Mutually exclusive with [numberOfInvoiceLines].
  final SingleInvoiceLine? singleInvoiceLine;

  final List<TaxCategorySummary> taxCategorySummaries;
  final MonetarySummary monetarySummary;

  /// Bitmask of [PaymentMean] values.
  final int? paymentMeans;

  const InvoiceDataModel({
    required this.documentType,
    required this.invoiceId,
    required this.issueDate,
    this.taxPointDate,
    this.orderId,
    this.deliveryNoteId,
    required this.localCurrencyCode,
    this.foreignCurrencyCode,
    this.currRate,
    this.referenceCurrRate,
    required this.supplierParty,
    required this.customerParty,
    this.numberOfInvoiceLines,
    this.invoiceDescription,
    this.singleInvoiceLine,
    required this.taxCategorySummaries,
    required this.monetarySummary,
    this.paymentMeans,
  });
}
