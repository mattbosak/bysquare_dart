import 'types.dart';

/// Replaces tab characters with a space so they don't break the wire format.
String? _sanitize(String? value) => value?.replaceAll('\t', ' ');

/// Formats a [double] without unnecessary decimal point (100.0 → "100").
String? _formatNumber(double? value) {
  if (value == null) return null;
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}

double? _parseNumber(String? value) =>
    (value != null && value.isNotEmpty) ? double.parse(value) : null;

String? _parseString(String? value) =>
    (value != null && value.isNotEmpty) ? value : null;

/// Transforms a [PayDataModel] into the tab-separated intermediate format.
String paySerialize(PayDataModel data) {
  final s = <String?>[];

  s.add(_sanitize(data.invoiceId?.toString()));
  s.add(data.payments.length.toString());

  for (final p in data.payments) {
    s.add(p.type.toString());
    s.add(_formatNumber(p.amount));
    s.add(_sanitize(p.currencyCode));
    s.add(_sanitize(p.paymentDueDate));
    s.add(_sanitize(p.variableSymbol));
    s.add(_sanitize(p.constantSymbol));
    s.add(_sanitize(p.specificSymbol));
    s.add(_sanitize(p.originatorsReferenceInformation));
    s.add(_sanitize(p.paymentNote));

    // Bank accounts
    s.add(p.bankAccounts.length.toString());
    for (final ba in p.bankAccounts) {
      s.add(_sanitize(ba.iban));
      s.add(_sanitize(ba.bic));
    }

    // Standing order extension
    if (p is StandingOrder) {
      s.add('1');
      s.add(p.day?.toString());
      s.add(p.month?.toString());
      s.add(_sanitize(p.periodicity));
      s.add(_sanitize(p.lastDate));
    } else {
      s.add('0');
    }

    // Direct debit extension
    if (p is DirectDebit) {
      s.add('1');
      s.add(p.directDebitScheme?.toString());
      s.add(p.directDebitType?.toString());
      s.add(_sanitize(p.ddVariableSymbol));
      s.add(_sanitize(p.ddSpecificSymbol));
      s.add(_sanitize(p.ddOriginatorsReferenceInformation));
      s.add(_sanitize(p.mandateId));
      s.add(_sanitize(p.creditorId));
      s.add(_sanitize(p.contractId));
      s.add(_formatNumber(p.maxAmount));
      s.add(_sanitize(p.validTillDate));
    } else {
      s.add('0');
    }
  }

  // Beneficiary block - one entry per payment, appended after all payments
  for (final p in data.payments) {
    s.add(_sanitize(p.beneficiary.name));
    s.add(_sanitize(p.beneficiary.street));
    s.add(_sanitize(p.beneficiary.city));
  }

  return s.map((e) => e ?? '').join('\t');
}

/// Parses the tab-separated [tabString] into a [PayDataModel].
PayDataModel payDeserialize(String tabString) {
  final data = tabString.split('\t');
  int i = 0;

  String? next() => i < data.length ? data[i++] : null;

  final invoiceId = _parseString(next());
  final paymentsCount = int.parse(next() ?? '0');

  final payments = <Payment>[];

  for (int p = 0; p < paymentsCount; p++) {
    final type = int.parse(next() ?? '0');
    final amount = _parseNumber(next());
    final currencyCode = next() ?? 'EUR';
    final paymentDueDate = _parseString(next());
    final variableSymbol = _parseString(next());
    final constantSymbol = _parseString(next());
    final specificSymbol = _parseString(next());
    final originatorsRefInfo = _parseString(next());
    final paymentNote = _parseString(next());

    // Bank accounts
    final bankAccountsCount = int.parse(next() ?? '0');
    final bankAccounts = <BankAccount>[];
    for (int j = 0; j < bankAccountsCount; j++) {
      final iban = next() ?? '';
      final bic = _parseString(next());
      bankAccounts.add(BankAccount(iban: iban, bic: bic));
    }

    const placeholder = Beneficiary(name: '');

    // Standing order extension - always consumed to keep field alignment
    final standingOrderFlag = next();
    int? soDay;
    int? soMonth;
    String? soPeriodicity;
    String? soLastDate;
    if (standingOrderFlag == '1') {
      soDay = _parseNumber(next())?.toInt();
      soMonth = _parseNumber(next())?.toInt();
      soPeriodicity = _parseString(next());
      soLastDate = _parseString(next());
    }

    // Direct debit extension - always consumed to keep field alignment
    final directDebitFlag = next();
    int? ddScheme;
    int? ddType;
    String? ddVarSymbol;
    String? ddSpecSymbol;
    String? ddOriginatorsRef;
    String? ddMandateId;
    String? ddCreditorId;
    String? ddContractId;
    double? ddMaxAmount;
    String? ddValidTill;
    if (directDebitFlag == '1') {
      ddScheme = _parseNumber(next())?.toInt();
      ddType = _parseNumber(next())?.toInt();
      ddVarSymbol = _parseString(next());
      ddSpecSymbol = _parseString(next());
      ddOriginatorsRef = _parseString(next());
      ddMandateId = _parseString(next());
      ddCreditorId = _parseString(next());
      ddContractId = _parseString(next());
      ddMaxAmount = _parseNumber(next());
      ddValidTill = _parseString(next());
    }

    final Payment payment;
    if (type == PaymentOptions.standingOrder) {
      payment = StandingOrder(
        amount: amount,
        currencyCode: currencyCode,
        paymentDueDate: paymentDueDate,
        variableSymbol: variableSymbol,
        constantSymbol: constantSymbol,
        specificSymbol: specificSymbol,
        originatorsReferenceInformation: originatorsRefInfo,
        paymentNote: paymentNote,
        bankAccounts: bankAccounts,
        beneficiary: placeholder,
        day: soDay,
        month: soMonth,
        periodicity: soPeriodicity ?? '',
        lastDate: soLastDate,
      );
    } else if (type == PaymentOptions.directDebit) {
      payment = DirectDebit(
        amount: amount,
        currencyCode: currencyCode,
        paymentDueDate: paymentDueDate,
        variableSymbol: variableSymbol,
        constantSymbol: constantSymbol,
        specificSymbol: specificSymbol,
        originatorsReferenceInformation: originatorsRefInfo,
        paymentNote: paymentNote,
        bankAccounts: bankAccounts,
        beneficiary: placeholder,
        directDebitScheme: ddScheme,
        directDebitType: ddType,
        ddVariableSymbol: ddVarSymbol,
        ddSpecificSymbol: ddSpecSymbol,
        ddOriginatorsReferenceInformation: ddOriginatorsRef,
        mandateId: ddMandateId,
        creditorId: ddCreditorId,
        contractId: ddContractId,
        maxAmount: ddMaxAmount,
        validTillDate: ddValidTill,
      );
    } else {
      payment = PaymentOrder(
        amount: amount,
        currencyCode: currencyCode,
        paymentDueDate: paymentDueDate,
        variableSymbol: variableSymbol,
        constantSymbol: constantSymbol,
        specificSymbol: specificSymbol,
        originatorsReferenceInformation: originatorsRefInfo,
        paymentNote: paymentNote,
        bankAccounts: bankAccounts,
        beneficiary: placeholder,
      );
    }

    payments.add(payment);
  }

  // Beneficiary block - one entry per payment after all payment blocks
  for (int p = 0; p < paymentsCount; p++) {
    final name = next() ?? '';
    final street = _parseString(next());
    final city = _parseString(next());
    final beneficiary = Beneficiary(name: name, street: street, city: city);
    payments[p] = _withBeneficiary(payments[p], beneficiary);
  }

  return PayDataModel(invoiceId: invoiceId, payments: payments);
}

/// Returns a copy of [payment] with [beneficiary] replaced.
Payment _withBeneficiary(Payment payment, Beneficiary beneficiary) {
  return switch (payment) {
    PaymentOrder p => PaymentOrder(
        amount: p.amount,
        currencyCode: p.currencyCode,
        paymentDueDate: p.paymentDueDate,
        variableSymbol: p.variableSymbol,
        constantSymbol: p.constantSymbol,
        specificSymbol: p.specificSymbol,
        originatorsReferenceInformation: p.originatorsReferenceInformation,
        paymentNote: p.paymentNote,
        bankAccounts: p.bankAccounts,
        beneficiary: beneficiary,
      ),
    StandingOrder p => StandingOrder(
        amount: p.amount,
        currencyCode: p.currencyCode,
        paymentDueDate: p.paymentDueDate,
        variableSymbol: p.variableSymbol,
        constantSymbol: p.constantSymbol,
        specificSymbol: p.specificSymbol,
        originatorsReferenceInformation: p.originatorsReferenceInformation,
        paymentNote: p.paymentNote,
        bankAccounts: p.bankAccounts,
        beneficiary: beneficiary,
        day: p.day,
        month: p.month,
        periodicity: p.periodicity,
        lastDate: p.lastDate,
      ),
    DirectDebit p => DirectDebit(
        amount: p.amount,
        currencyCode: p.currencyCode,
        paymentDueDate: p.paymentDueDate,
        variableSymbol: p.variableSymbol,
        constantSymbol: p.constantSymbol,
        specificSymbol: p.specificSymbol,
        originatorsReferenceInformation: p.originatorsReferenceInformation,
        paymentNote: p.paymentNote,
        bankAccounts: p.bankAccounts,
        beneficiary: beneficiary,
        directDebitScheme: p.directDebitScheme,
        directDebitType: p.directDebitType,
        ddVariableSymbol: p.ddVariableSymbol,
        ddSpecificSymbol: p.ddSpecificSymbol,
        ddOriginatorsReferenceInformation: p.ddOriginatorsReferenceInformation,
        mandateId: p.mandateId,
        creditorId: p.creditorId,
        contractId: p.contractId,
        maxAmount: p.maxAmount,
        validTillDate: p.validTillDate,
      ),
  };
}
