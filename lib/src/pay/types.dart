/// Months as bit-flag constants. Combine with bitwise OR (or plain addition)
/// for standing orders that span multiple months.
abstract final class Month {
  static const int january = 0x001;
  static const int february = 0x002;
  static const int march = 0x004;
  static const int april = 0x008;
  static const int may = 0x010;
  static const int june = 0x020;
  static const int july = 0x040;
  static const int august = 0x080;
  static const int september = 0x100;
  static const int october = 0x200;
  static const int november = 0x400;
  static const int december = 0x800;
}

/// Periodicity of a standing order.
abstract final class Periodicity {
  static const String daily = 'd';
  static const String weekly = 'w';
  static const String biweekly = 'b';
  static const String monthly = 'm';
  static const String bimonthly = 'B';
  static const String quarterly = 'q';
  static const String semiannually = 's';
  static const String annually = 'a';
}

/// Payment type classifier.
abstract final class PaymentOptions {
  /// Single payment order.
  static const int paymentOrder = 0x01;

  /// Recurring payment; fill [StandingOrder] fields.
  static const int standingOrder = 0x02;

  /// Direct debit; fill [DirectDebit] fields.
  static const int directDebit = 0x04;
}

/// Direct debit scheme.
abstract final class DirectDebitScheme {
  static const int other = 0x00;
  static const int sepa = 0x01;
}

/// Direct debit type.
abstract final class DirectDebitType {
  static const int oneOff = 0x00;
  static const int recurrent = 0x01;
}

/// IBAN + optional BIC of a payment recipient.
class BankAccount {
  /// International Bank Account Number (ISO 13616).
  final String iban;

  /// Bank Identification Code / SWIFT code (ISO 9362). Optional.
  final String? bic;

  const BankAccount({required this.iban, this.bic});

  @override
  String toString() => 'BankAccount(iban: $iban, bic: $bic)';
}

/// Beneficiary (payment recipient) identification.
class Beneficiary {
  /// Full name of the beneficiary. Required since v1.2.0.
  final String name;
  final String? street;
  final String? city;

  const Beneficiary({required this.name, this.street, this.city});

  @override
  String toString() => 'Beneficiary(name: $name)';
}

/// Base class for all payment types.
sealed class Payment {
  final int type;
  final double? amount;
  final String currencyCode;
  final String? paymentDueDate;
  final String? variableSymbol;
  final String? constantSymbol;
  final String? specificSymbol;
  final String? originatorsReferenceInformation;
  final String? paymentNote;
  final List<BankAccount> bankAccounts;
  final Beneficiary beneficiary;

  const Payment({
    required this.type,
    this.amount,
    required this.currencyCode,
    this.paymentDueDate,
    this.variableSymbol,
    this.constantSymbol,
    this.specificSymbol,
    this.originatorsReferenceInformation,
    this.paymentNote,
    required this.bankAccounts,
    required this.beneficiary,
  });
}

/// A single, one-time payment order.
final class PaymentOrder extends Payment {
  const PaymentOrder({
    super.amount,
    required super.currencyCode,
    super.paymentDueDate,
    super.variableSymbol,
    super.constantSymbol,
    super.specificSymbol,
    super.originatorsReferenceInformation,
    super.paymentNote,
    required super.bankAccounts,
    required super.beneficiary,
  }) : super(type: PaymentOptions.paymentOrder);
}

/// A recurring (standing order) payment.
final class StandingOrder extends Payment {
  /// Day of the month (1-31) or day of the week (1-7) for weekly orders.
  final int? day;

  /// Bitmask of [Month] values indicating active months.
  final int? month;

  /// One of the [Periodicity] constants.
  final String periodicity;

  /// Last payment date in `YYYYMMDD` format. Order is cancelled after this.
  final String? lastDate;

  const StandingOrder({
    super.amount,
    required super.currencyCode,
    super.paymentDueDate,
    super.variableSymbol,
    super.constantSymbol,
    super.specificSymbol,
    super.originatorsReferenceInformation,
    super.paymentNote,
    required super.bankAccounts,
    required super.beneficiary,
    this.day,
    this.month,
    required this.periodicity,
    this.lastDate,
  }) : super(type: PaymentOptions.standingOrder);
}

/// A direct debit payment.
final class DirectDebit extends Payment {
  final int? directDebitScheme;
  final int? directDebitType;
  final String? ddVariableSymbol;
  final String? ddSpecificSymbol;
  final String? ddOriginatorsReferenceInformation;
  final String? mandateId;
  final String? creditorId;
  final String? contractId;
  final double? maxAmount;
  final String? validTillDate;

  const DirectDebit({
    super.amount,
    required super.currencyCode,
    super.paymentDueDate,
    super.variableSymbol,
    super.constantSymbol,
    super.specificSymbol,
    super.originatorsReferenceInformation,
    super.paymentNote,
    required super.bankAccounts,
    required super.beneficiary,
    this.directDebitScheme,
    this.directDebitType,
    this.ddVariableSymbol,
    this.ddSpecificSymbol,
    this.ddOriginatorsReferenceInformation,
    this.mandateId,
    this.creditorId,
    this.contractId,
    this.maxAmount,
    this.validTillDate,
  }) : super(type: PaymentOptions.directDebit);
}

/// Root data model for a PAY by square QR code.
class PayDataModel {
  /// Invoice or internal identifier. Max 10 characters.
  final String? invoiceId;

  /// One or more payments. The preferred payment must be first.
  final List<Payment> payments;

  const PayDataModel({this.invoiceId, required this.payments});
}
