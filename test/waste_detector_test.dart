import 'package:flutter_test/flutter_test.dart';
import 'package:cash_guardian/data/services/waste_detector.dart';
import 'package:cash_guardian/data/models/transaction.dart';

void main() {
  late WasteDetector detector;
  late Map<String, double> budgets;

  setUp(() {
    detector = WasteDetector();
    budgets = {
      'food': 150.0,
      'transport': 100.0,
      'shopping': 100.0,
      'bills': 200.0,
      'subscription': 50.0,
      'entertainment': 50.0,
      'other': 50.0,
    };
  });

  Transaction createTransaction({
    double amount = 100,
    String merchant = 'Test Merchant',
    TransactionCategory category = TransactionCategory.food,
    int hour = 12,
    bool isWaste = false,
    String? wasteReason,
  }) {
    final now = DateTime.now();
    return Transaction()
      ..id = 1
      ..amount = amount
      ..merchant = merchant
      ..category = category
      ..timestamp = DateTime(now.year, now.month, now.day, hour)
      ..source = TransactionSource.manual
      ..isWaste = isWaste
      ..wasteReason = wasteReason
      ..date = DateTime(now.year, now.month, now.day);
  }

  group('WasteDetector', () {
    group('detect', () {
      test('returns existing waste result if transaction is already marked as waste', () {
        final tx = createTransaction(isWaste: true, wasteReason: 'Previous waste');
        final result = detector.detect(tx, [], [], budgets);

        expect(result, isNotNull);
        expect(result!.isWaste, isTrue);
        expect(result.reason, 'Previous waste');
      });

      test('returns null for normal transaction with no waste indicators', () {
        final tx = createTransaction(amount: 50, hour: 12);
        final todayTx = [tx];
        final result = detector.detect(tx, todayTx, todayTx, budgets);

        expect(result, isNull);
      });
    });

    group('_checkLateNightImpulse', () {
      test('flags late night purchase over 2x average as waste', () {
        final lateNightTx = createTransaction(amount: 500, hour: 23);
        final normalTx1 = createTransaction(amount: 100, hour: 10);
        final normalTx2 = createTransaction(amount: 100, hour: 14);
        final todayTx = [normalTx1, normalTx2, lateNightTx];

        final result = detector.detect(lateNightTx, todayTx, todayTx, budgets);

        expect(result, isNotNull);
        expect(result!.isWaste, isTrue);
        expect(result.rule, WasteRule.lateNightImpulse);
        expect(result.reason, contains('Late-night impulse'));
      });

      test('does not flag late night purchase under 2x average', () {
        final lateNightTx = createTransaction(amount: 150, hour: 23);
        final normalTx = createTransaction(amount: 100, hour: 10);
        final todayTx = [normalTx, lateNightTx];

        final result = detector.detect(lateNightTx, todayTx, todayTx, budgets);

        expect(result, isNull);
      });

      test('does not flag early morning hours (after 4 AM)', () {
        final morningTx = createTransaction(amount: 500, hour: 5);
        final normalTx = createTransaction(amount: 100, hour: 10);
        final todayTx = [normalTx, morningTx];

        final result = detector.detect(morningTx, todayTx, todayTx, budgets);

        expect(result, isNull);
      });
    });

    group('_checkRepeatedMerchant', () {
      test('flags same merchant 3+ times in a day as waste', () {
        final tx1 = createTransaction(merchant: 'Coffee Shop', amount: 50, hour: 8);
        final tx2 = createTransaction(merchant: 'Coffee Shop', amount: 50, hour: 10);
        final tx3 = createTransaction(merchant: 'Coffee Shop', amount: 50, hour: 14);
        final todayTx = [tx1, tx2, tx3];

        final result = detector.detect(tx3, todayTx, todayTx, budgets);

        expect(result, isNotNull);
        expect(result!.isWaste, isTrue);
        expect(result.rule, WasteRule.repeatedMerchant);
        expect(result.reason, contains('Coffee Shop'));
      });

      test('does not flag merchant with less than 3 visits', () {
        final tx1 = createTransaction(merchant: 'Coffee Shop', amount: 50, hour: 8);
        final tx2 = createTransaction(merchant: 'Coffee Shop', amount: 50, hour: 10);
        final todayTx = [tx1, tx2];

        final result = detector.detect(tx2, todayTx, todayTx, budgets);

        expect(result, isNull);
      });
    });

    group('_checkOverCategoryBudget', () {
      test('flags transaction that exceeds category budget', () {
        final tx = createTransaction(category: TransactionCategory.food, amount: 200);
        final existingTx = createTransaction(category: TransactionCategory.food, amount: 100);
        final todayTx = [existingTx, tx];

        final result = detector.detect(tx, todayTx, todayTx, budgets);

        expect(result, isNotNull);
        expect(result!.isWaste, isTrue);
        expect(result.rule, WasteRule.overCategoryBudget);
        expect(result.reason, contains('food'));
      });

      test('does not flag transaction within category budget', () {
        final tx = createTransaction(category: TransactionCategory.food, amount: 100);
        final todayTx = [tx];

        final result = detector.detect(tx, todayTx, todayTx, budgets);

        expect(result, isNull);
      });

      test('handles missing category budget', () {
        final tx = createTransaction(category: TransactionCategory.food, amount: 200);
        final emptyBudgets = <String, double>{};

        final result = detector.detect(tx, [], [], emptyBudgets);

        expect(result, isNull);
      });
    });

    group('_checkMicroSpending', () {
      test('flags 5+ small transactions as waste', () {
        final micro1 = createTransaction(amount: 50);
        final micro2 = createTransaction(amount: 80);
        final micro3 = createTransaction(amount: 30);
        final micro4 = createTransaction(amount: 90);
        final micro5 = createTransaction(amount: 40);
        final todayTx = [micro1, micro2, micro3, micro4, micro5];

        final result = detector.detect(micro5, todayTx, todayTx, budgets);

        expect(result, isNotNull);
        expect(result!.isWaste, isTrue);
        expect(result.rule, WasteRule.microSpending);
        expect(result.reason, contains('Micro-spending'));
      });

      test('does not flag less than 5 micro transactions', () {
        final micro1 = createTransaction(amount: 50);
        final micro2 = createTransaction(amount: 80);
        final micro3 = createTransaction(amount: 30);
        final todayTx = [micro1, micro2, micro3];

        final result = detector.detect(micro3, todayTx, todayTx, budgets);

        expect(result, isNull);
      });

      test('only counts transactions under 100 ETB', () {
        final micro1 = createTransaction(amount: 50);
        final micro2 = createTransaction(amount: 80);
        final micro3 = createTransaction(amount: 150);
        final micro4 = createTransaction(amount: 200);
        final micro5 = createTransaction(amount: 40);
        final todayTx = [micro1, micro2, micro3, micro4, micro5];

        final result = detector.detect(micro5, todayTx, todayTx, budgets);

        expect(result, isNull);
      });
    });
  });
}
