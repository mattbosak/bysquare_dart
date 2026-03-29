import 'package:bysquare_dart/bysquare_dart.dart';
import 'package:test/test.dart';

InvoiceDataModel _sampleInvoice() => InvoiceDataModel(
      documentType: InvoiceDocumentType.invoice,
      invoiceId: 'FAK-2024-001',
      issueDate: '20241201',
      localCurrencyCode: 'EUR',
      supplierParty: const SupplierParty(
        partyName: 'Dodávateľ s.r.o.',
        companyVatId: 'SK1234567890',
        postalAddress: PostalAddress(
          streetName: 'Hlavná',
          buildingNumber: '1',
          cityName: 'Bratislava',
          postalZone: '81101',
          country: 'SK',
        ),
        contact: Contact(
          name: 'Ján Novák',
          email: 'jan@example.sk',
        ),
      ),
      customerParty: const CustomerParty(partyName: 'Zákazník a.s.'),
      numberOfInvoiceLines: 2,
      taxCategorySummaries: [
        const TaxCategorySummary(
          classifiedTaxCategory: 0.20,
          taxExclusiveAmount: 100.0,
          taxAmount: 20.0,
        ),
      ],
      monetarySummary: const MonetarySummary(paidDepositsAmount: 0),
      paymentMeans: PaymentMean.moneyTransfer,
    );

void main() {
  group('invoiceSerialize / invoiceDeserialize', () {
    test('round-trips core fields', () {
      final model = _sampleInvoice();
      final tabbed = invoiceSerialize(model);
      final decoded = invoiceDeserialize(tabbed, InvoiceDocumentType.invoice);

      expect(decoded.invoiceId, equals(model.invoiceId));
      expect(decoded.issueDate, equals(model.issueDate));
      expect(decoded.localCurrencyCode, equals(model.localCurrencyCode));
      expect(decoded.supplierParty.partyName, equals('Dodávateľ s.r.o.'));
      expect(decoded.customerParty.partyName, equals('Zákazník a.s.'));
      expect(decoded.numberOfInvoiceLines, equals(2));
    });

    test('round-trips tax summaries', () {
      final model = _sampleInvoice();
      final decoded = invoiceDeserialize(
        invoiceSerialize(model),
        InvoiceDocumentType.invoice,
      );

      expect(decoded.taxCategorySummaries, hasLength(1));
      expect(
        decoded.taxCategorySummaries.first.classifiedTaxCategory,
        equals(0.20),
      );
      expect(
        decoded.taxCategorySummaries.first.taxExclusiveAmount,
        equals(100.0),
      );
    });

    test('round-trips single invoice line with itemName', () {
      final model = InvoiceDataModel(
        documentType: InvoiceDocumentType.invoice,
        invoiceId: 'FAK-001',
        issueDate: '20241201',
        localCurrencyCode: 'EUR',
        supplierParty: const SupplierParty(
          partyName: 'Supplier',
          postalAddress: PostalAddress(
            streetName: 'Street',
            cityName: 'City',
            postalZone: '12345',
            country: 'SK',
          ),
        ),
        customerParty: const CustomerParty(partyName: 'Customer'),
        singleInvoiceLine: const SingleInvoiceLine(
          itemName: 'Laptop',
          invoicedQuantity: 2,
          periodFromDate: '20241101',
          periodToDate: '20241130',
        ),
        taxCategorySummaries: [
          const TaxCategorySummary(
            classifiedTaxCategory: 0.20,
            taxExclusiveAmount: 2000,
            taxAmount: 400,
          ),
        ],
        monetarySummary: const MonetarySummary(),
      );

      final decoded = invoiceDeserialize(
        invoiceSerialize(model),
        InvoiceDocumentType.invoice,
      );

      expect(decoded.singleInvoiceLine, isNotNull);
      expect(decoded.singleInvoiceLine!.itemName, equals('Laptop'));
      expect(decoded.singleInvoiceLine!.invoicedQuantity, equals(2.0));
      expect(decoded.singleInvoiceLine!.periodFromDate, equals('20241101'));
    });
  });

  group('invoiceEncode / invoiceDecode', () {
    test('encodes to a valid Base32Hex string', () {
      final qr = invoiceEncode(_sampleInvoice());
      expect(qr, isNotEmpty);
      expect(RegExp(r'^[0-9A-V]+$').hasMatch(qr), isTrue);
    });

    test('full round-trip', () {
      final model = _sampleInvoice();
      final qr = invoiceEncode(model);
      final decoded = invoiceDecode(qr);

      expect(decoded.documentType, equals(InvoiceDocumentType.invoice));
      expect(decoded.invoiceId, equals(model.invoiceId));
      expect(decoded.issueDate, equals(model.issueDate));
      expect(
        decoded.supplierParty.partyName,
        equals(model.supplierParty.partyName),
      );
      expect(
        decoded.taxCategorySummaries.first.taxAmount,
        equals(20.0),
      );
    });

    test('document type is preserved in header', () {
      for (final docType in [
        InvoiceDocumentType.invoice,
        InvoiceDocumentType.proformaInvoice,
        InvoiceDocumentType.creditNote,
      ]) {
        final model = InvoiceDataModel(
          documentType: docType,
          invoiceId: 'X',
          issueDate: '20241201',
          localCurrencyCode: 'EUR',
          supplierParty: const SupplierParty(
            partyName: 'S',
            postalAddress: PostalAddress(
              streetName: 'St',
              cityName: 'C',
              postalZone: '12345',
              country: 'SK',
            ),
          ),
          customerParty: const CustomerParty(partyName: 'C'),
          numberOfInvoiceLines: 1,
          taxCategorySummaries: [
            const TaxCategorySummary(
              classifiedTaxCategory: 0,
              taxExclusiveAmount: 0,
              taxAmount: 0,
            ),
          ],
          monetarySummary: const MonetarySummary(),
        );

        final decoded = invoiceDecode(invoiceEncode(model));
        expect(decoded.documentType, equals(docType));
      }
    });
  });

  group('validateInvoiceDataModel', () {
    test('throws for missing invoiceId', () {
      expect(
        () => validateInvoiceDataModel(
          InvoiceDataModel(
            documentType: InvoiceDocumentType.invoice,
            invoiceId: '',
            issueDate: '20241201',
            localCurrencyCode: 'EUR',
            supplierParty: const SupplierParty(
              partyName: 'S',
              postalAddress: PostalAddress(
                streetName: 'St',
                cityName: 'C',
                postalZone: '12345',
                country: 'SK',
              ),
            ),
            customerParty: const CustomerParty(partyName: 'C'),
            numberOfInvoiceLines: 1,
            taxCategorySummaries: [
              const TaxCategorySummary(
                classifiedTaxCategory: 0,
                taxExclusiveAmount: 0,
                taxAmount: 0,
              ),
            ],
            monetarySummary: const MonetarySummary(),
          ),
        ),
        throwsA(isA<BysquareValidationError>()),
      );
    });

    test('throws when both numberOfInvoiceLines and singleInvoiceLine are set', () {
      expect(
        () => validateInvoiceDataModel(
          InvoiceDataModel(
            documentType: InvoiceDocumentType.invoice,
            invoiceId: 'X',
            issueDate: '20241201',
            localCurrencyCode: 'EUR',
            supplierParty: const SupplierParty(
              partyName: 'S',
              postalAddress: PostalAddress(
                streetName: 'St',
                cityName: 'C',
                postalZone: '12345',
                country: 'SK',
              ),
            ),
            customerParty: const CustomerParty(partyName: 'C'),
            numberOfInvoiceLines: 1,
            singleInvoiceLine: const SingleInvoiceLine(itemName: 'X'),
            taxCategorySummaries: [
              const TaxCategorySummary(
                classifiedTaxCategory: 0,
                taxExclusiveAmount: 0,
                taxAmount: 0,
              ),
            ],
            monetarySummary: const MonetarySummary(),
          ),
        ),
        throwsA(isA<BysquareValidationError>()),
      );
    });
  });
}
