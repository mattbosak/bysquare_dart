# bysquare_dart

Dart port of [xseman/bysquare](https://github.com/xseman/bysquare) - encode and decode **PAY by square** and **Invoice by square** QR strings, the Slovak banking standard adopted by the Slovak Banking Association (SBA) in 2013.

## Features

- PAY by square encode & decode (spec v1.0.0 - v1.2.0)
- Invoice by square encode & decode
- Payment types: `PaymentOrder`, `StandingOrder`, `DirectDebit`
- Invoice types: `Invoice`, `ProformaInvoice`, `CreditNote`, `DebitNote`, `AdvanceInvoice`
- Diacritics removal for banking app compatibility
- Pure Dart - works in Flutter, Dart CLI, and server-side Dart

## Installation

```yaml
dependencies:
  bysquare_dart: ^1.0.0
```

## Usage

### Encode

```dart
import 'package:bysquare_dart/bysquare.dart';

final qr = payEncode(
  PayDataModel(
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
```

### Decode

```dart
import 'package:bysquare_dart/bysquare.dart';

final model = payDecode(qr);
print(model.payments.first.amount); // 19.99
```

## Credits

Based on [xseman/bysquare](https://github.com/xseman/bysquare) by Filip Seman (Apache-2.0).

## License

Apache-2.0
