import 'package:bysquare_dart/bysquare_dart.dart';
import 'package:test/test.dart';

// Known-good QR string produced by the reference TypeScript implementation.
const String _knownQr =
    '0804Q000AEM958SPQK31JJFA00H0OBFGMH6PKV0OQSNQPQK5KCH0BB12EJI6C2NFLCHS43I7E8NVVNCAMCF3GSRUMS4EK680FG7L2H6H9UDVLMR955998RVVVBUV000';

void main() {
  // Classifier
  group('classifier', () {
    test('encodeOptions sums values', () {
      expect(
        encodeOptions([Month.january, Month.july, Month.october]),
        equals(577),
      );
    });

    test('decodeOptions splits into flags', () {
      expect(decodeOptions(577), equals([512, 64, 1]));
    });

    test('round-trip', () {
      final original = [Month.january, Month.june, Month.november];
      final encoded  = encodeOptions(original);
      final decoded  = decodeOptions(encoded);
      expect(decoded..sort(), equals(original..sort()));
    });

    test('zero returns empty', () {
      expect(decodeOptions(0), isEmpty);
    });
  });

  // PAY serializer (no LZMA/Base32 overhead - faster)
  group('paySerialize / payDeserialize', () {
    test('round-trips a simple payment order', () {
      final model = PayDataModel(
        invoiceId: 'inv-001',
        payments: [
          PaymentOrder(
            amount: 100.0,
            currencyCode: 'EUR',
            variableSymbol: '123',
            bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
            beneficiary: Beneficiary(name: 'Test s.r.o.'),
          ),
        ],
      );

      final tabbed = paySerialize(model);
      final decoded = payDeserialize(tabbed);

      expect(decoded.invoiceId, equals('inv-001'));
      expect(decoded.payments, hasLength(1));
      final p = decoded.payments.first as PaymentOrder;
      expect(p.amount, equals(100.0));
      expect(p.currencyCode, equals('EUR'));
      expect(p.variableSymbol, equals('123'));
      expect(p.bankAccounts.first.iban, equals('SK9611000000002918599669'));
      expect(p.beneficiary.name, equals('Test s.r.o.'));
    });

    test('round-trips a standing order', () {
      final model = PayDataModel(
        payments: [
          StandingOrder(
            amount: 50.0,
            currencyCode: 'EUR',
            bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
            beneficiary: Beneficiary(name: 'Prenajímateľ'),
            periodicity: Periodicity.monthly,
            day: 1,
            month: Month.january | Month.july,
            lastDate: '20251231',
          ),
        ],
      );

      final decoded = payDeserialize(paySerialize(model));
      final so = decoded.payments.first as StandingOrder;

      expect(so.periodicity, equals(Periodicity.monthly));
      expect(so.day, equals(1));
      expect(so.month, equals(Month.january | Month.july));
      expect(so.lastDate, equals('20251231'));
    });

    test('round-trips a direct debit', () {
      final model = PayDataModel(
        payments: [
          DirectDebit(
            currencyCode: 'EUR',
            bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
            beneficiary: Beneficiary(name: 'Veriteľ a.s.'),
            directDebitScheme: DirectDebitScheme.sepa,
            directDebitType: DirectDebitType.recurrent,
            mandateId: 'MANDATE-001',
          ),
        ],
      );

      final decoded = payDeserialize(paySerialize(model));
      final dd = decoded.payments.first as DirectDebit;

      expect(dd.directDebitScheme, equals(DirectDebitScheme.sepa));
      expect(dd.mandateId, equals('MANDATE-001'));
    });

    test('null amount survives round-trip', () {
      final model = PayDataModel(
        payments: [
          PaymentOrder(
            currencyCode: 'EUR',
            bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
            beneficiary: Beneficiary(name: 'Donations'),
          ),
        ],
      );

      final decoded = payDeserialize(paySerialize(model));
      // amount is null when not specified (e.g. voluntary donations)
      expect(decoded.payments.first.amount, isNull);
    });
  });

  // Full encode / decode (LZMA + Base32Hex)
  group('payEncode / payDecode', () {
    test('encodes to a non-empty Base32Hex string', () {
      final model = PayDataModel(
        invoiceId: 'random-id',
        payments: [
          PaymentOrder(
            amount: 100.0,
            currencyCode: 'EUR',
            variableSymbol: '123',
            bankAccounts: [
              BankAccount(iban: 'SK9611000000002918599669'),
            ],
            beneficiary: Beneficiary(name: 'Príjemca'),
          ),
        ],
      );

      final qr = payEncode(model);

      expect(qr, isNotEmpty);
      expect(RegExp(r'^[0-9A-V]+$').hasMatch(qr), isTrue);
    });

    test('round-trip produces equal model', () {
      final original = PayDataModel(
        invoiceId: 'rt-test',
        payments: [
          PaymentOrder(
            amount: 49.99,
            currencyCode: 'EUR',
            variableSymbol: '9876543210',
            paymentNote: 'Faktúra č. 2024/001',
            bankAccounts: [
              BankAccount(
                iban: 'SK9611000000002918599669',
                bic: 'TATRSKBX',
              ),
            ],
            beneficiary: Beneficiary(
              name: 'Dodávateľ s.r.o.',
              city: 'Bratislava',
            ),
          ),
        ],
      );

      final decoded = payDecode(payEncode(original));

      expect(decoded.invoiceId, equals(original.invoiceId));
      final op = original.payments.first as PaymentOrder;
      final dp = decoded.payments.first as PaymentOrder;

      expect(dp.amount, equals(op.amount));
      expect(dp.currencyCode, equals(op.currencyCode));
      expect(dp.variableSymbol, equals(op.variableSymbol));
      // Diacritics are stripped by default
      expect(dp.paymentNote, equals('Faktura c. 2024/001'));
      expect(dp.bankAccounts.first.iban, equals(op.bankAccounts.first.iban));
      expect(dp.bankAccounts.first.bic, equals(op.bankAccounts.first.bic));
      expect(dp.beneficiary.name, equals('Dodavatel s.r.o.'));
    });

    test('decodes known QR string from reference implementation', () {
      final model = payDecode(_knownQr);

      expect(model.invoiceId, equals('random-id'));
      expect(model.payments, hasLength(1));
      expect(model.payments.first.amount, equals(100.0));
      expect(model.payments.first.variableSymbol, equals('123'));
    });

    test('deburr=false preserves diacritics', () {
      final model = PayDataModel(
        payments: [
          PaymentOrder(
            amount: 1.0,
            currencyCode: 'EUR',
            paymentNote: 'Žltý kôň',
            bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
            beneficiary: Beneficiary(name: 'Príjemca'),
          ),
        ],
      );

      final qr = payEncode(
        model,
        const PayEncodeOptions(deburr: false),
      );
      final decoded = payDecode(qr);
      expect(decoded.payments.first.paymentNote, equals('Žltý kôň'));
    });

    test('version header is encoded correctly', () {
      final model = PayDataModel(
        payments: [
          PaymentOrder(
            amount: 1.0,
            currencyCode: 'EUR',
            bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
            beneficiary: Beneficiary(name: 'Test'),
          ),
        ],
      );

      // v1.0.0 → header prefix '00'
      expect(
        payEncode(model, const PayEncodeOptions(version: Version.v100)),
        startsWith('00'),
      );
      // v1.1.0 → header prefix '04'
      expect(
        payEncode(model, const PayEncodeOptions(version: Version.v110, validate: false)),
        startsWith('04'),
      );
      // v1.2.0 → header prefix '08'
      expect(
        payEncode(model, const PayEncodeOptions(version: Version.v120)),
        startsWith('08'),
      );
    });
  });

  // Validation
  group('validatePayDataModel', () {
    test('throws for invalid IBAN', () {
      expect(
        () => validatePayDataModel(
          PayDataModel(
            payments: [
              PaymentOrder(
                currencyCode: 'EUR',
                bankAccounts: [BankAccount(iban: 'INVALID')],
                beneficiary: Beneficiary(name: 'Test'),
              ),
            ],
          ),
        ),
        throwsA(isA<BysquareValidationError>()),
      );
    });

    test('throws for missing beneficiary name on v1.2.0', () {
      expect(
        () => validatePayDataModel(
          PayDataModel(
            payments: [
              PaymentOrder(
                currencyCode: 'EUR',
                bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
                beneficiary: const Beneficiary(name: ''),
              ),
            ],
          ),
        ),
        throwsA(isA<BysquareValidationError>()),
      );
    });

    test('passes for valid model', () {
      expect(
        () => validatePayDataModel(
          PayDataModel(
            payments: [
              PaymentOrder(
                amount: 10.0,
                currencyCode: 'EUR',
                bankAccounts: [BankAccount(iban: 'SK9611000000002918599669')],
                beneficiary: Beneficiary(name: 'Platiteľ'),
              ),
            ],
          ),
        ),
        returnsNormally,
      );
    });
  });
}
