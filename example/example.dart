import 'package:bysquare_dart/bysquare_dart.dart';

void main() {
  // Encode
  final qr = payEncode(
    PayDataModel(
      invoiceId: 'FAK-2024-001',
      payments: [
        PaymentOrder(
          amount: 19.99,
          currencyCode: 'EUR',
          variableSymbol: '1234567890',
          bankAccounts: [
            BankAccount(
              iban: 'SK9611000000002918599669',
              bic: 'TATRSKBX',
            ),
          ],
          beneficiary: Beneficiary(name: 'Acme s.r.o.'),
        ),
      ],
    ),
  );

  print('Encoded: $qr');

  // Decode
  final model = payDecode(qr);
  print('Amount: ${model.payments.first.amount}');
  print('IBAN: ${model.payments.first.bankAccounts.first.iban}');
}
