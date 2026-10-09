import 'package:flutter_test/flutter_test.dart';
import 'package:cash_guardian/data/services/sms_parser.dart';

void main() {
  group('BankSmsParser', () {
    group('parse', () {
      test('parses transfer message correctly', () {
        const sms = 'You have transferred ETB 250.00 to Coffee Shop';
        final result = BankSmsParser.parse(sms, 'CBE');

        expect(result, isNotNull);
        expect(result!.amount, 250.0);
        expect(result.merchant, 'Coffee Shop');
        expect(result.source.name, 'sms');
        expect(result.rawText, contains('CBE'));
      });

      test('parses debit message correctly', () {
        const sms = 'Your account has been debited with ETB 1,500.00';
        final result = BankSmsParser.parse(sms, 'Awash');

        expect(result, isNotNull);
        expect(result!.amount, 1500.0);
      });

      test('parses paid message correctly', () {
        const sms = 'You have paid ETB 75.50 to Pizza Place for lunch';
        final result = BankSmsParser.parse(sms, 'Dashen');

        expect(result, isNotNull);
        expect(result!.amount, 75.5);
        expect(result.merchant, 'Pizza Place');
      });

      test('parses Telebirr message correctly', () {
        const sms = 'Telebirr: You have sent ETB 100 to John Doe';
        final result = BankSmsParser.parse(sms, 'Telebirr');

        expect(result, isNotNull);
        expect(result!.amount, 100.0);
        expect(result.merchant, 'John Doe');
      });

      test('parses M-Pesa received message correctly', () {
        const sms = 'You have received ETB 500 from Alice';
        final result = BankSmsParser.parse(sms, 'M-Pesa');

        expect(result, isNotNull);
        expect(result!.amount, 500.0);
        expect(result.merchant, 'Alice');
      });

      test('parses CBE debit message correctly', () {
        const sms = 'ETB 2,000.00 debited from your account';
        final result = BankSmsParser.parse(sms, 'CBE');

        expect(result, isNotNull);
        expect(result!.amount, 2000.0);
      });

      test('returns null for invalid amount', () {
        const sms = 'Some invalid message without amount';
        final result = BankSmsParser.parse(sms, 'Bank');

        expect(result, isNull);
      });

      test('returns null for zero amount', () {
        const sms = 'You have transferred ETB 0.00 to Test';
        final result = BankSmsParser.parse(sms, 'Bank');

        expect(result, isNull);
      });

      test('handles amounts with commas', () {
        const sms = 'You have transferred ETB 1,234.56 to Merchant';
        final result = BankSmsParser.parse(sms, 'Bank');

        expect(result, isNotNull);
        expect(result!.amount, 1234.56);
      });
    });

    group('isBankSms', () {
      test('returns true for known banks', () {
        expect(BankSmsParser.isBankSms('CBE', ['CBE', 'Awash', 'Dashen']), isTrue);
        expect(BankSmsParser.isBankSms('AWASH Bank', ['CBE', 'Awash']), isTrue);
        expect(BankSmsParser.isBankSms('Telebirr', ['Telebirr']), isTrue);
        expect(BankSmsParser.isBankSms('M-Pesa SMS', ['M-Pesa']), isTrue);
      });

      test('returns false for unknown senders', () {
        expect(BankSmsParser.isBankSms('Random Number', ['CBE', 'Awash']), isFalse);
        expect(BankSmsParser.isBankSms('Friend', ['CBE']), isFalse);
      });

      test('is case insensitive', () {
        expect(BankSmsParser.isBankSms('cbe', ['CBE']), isTrue);
        expect(BankSmsParser.isBankSms('CBE', ['cbe']), isTrue);
      });
    });
  });
}
