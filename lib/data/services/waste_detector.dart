import '../models/transaction.dart';

enum WasteRule {
  subscriptionUnused,
  lateNightImpulse,
  repeatedMerchant,
  overCategoryBudget,
  microSpending,
  weekendOverhop,
}

class WasteResult {
  final bool isWaste;
  final String reason;
  final double wastedAmount;
  final double confidence;
  final WasteRule rule;

  WasteResult({
    required this.isWaste,
    required this.reason,
    required this.wastedAmount,
    required this.confidence,
    required this.rule,
  });
}

class WasteDetector {
  WasteResult? detect(
    Transaction tx,
    List<Transaction> todayTx,
    List<Transaction> weekTx,
    Map<String, double> budgets,
  ) {
    if (tx.isWaste) {
      return WasteResult(
        isWaste: true,
        reason: tx.wasteReason ?? 'Unknown waste',
        wastedAmount: tx.amount,
        confidence: 1.0,
        rule: WasteRule.subscriptionUnused,
      );
    }

    WasteResult? result;

    result = _checkLateNightImpulse(tx, todayTx);
    if (result != null) return result;

    result = _checkRepeatedMerchant(tx, todayTx);
    if (result != null) return result;

    result = _checkOverCategoryBudget(tx, todayTx, budgets);
    if (result != null) return result;

    result = _checkMicroSpending(tx, todayTx);
    if (result != null) return result;

    result = _checkWeekendOverhop(tx, weekTx);
    if (result != null) return result;

    return null;
  }

  WasteResult? _checkLateNightImpulse(Transaction tx, List<Transaction> todayTx) {
    final hour = tx.timestamp.hour;
    if (hour >= 23 || hour < 4) {
      final todaySpend = todayTx
          .where((t) => !t.isWaste)
          .fold(0.0, (sum, t) => sum + t.amount);
      final avgTransaction = todaySpend / (todayTx.where((t) => !t.isWaste).length.clamp(1, 100));

      if (tx.amount > avgTransaction * 2) {
        return WasteResult(
          isWaste: true,
          reason: 'Late-night impulse buy (${hour}:00)',
          wastedAmount: tx.amount,
          confidence: 0.85,
          rule: WasteRule.lateNightImpulse,
        );
      }
    }
    return null;
  }

  WasteResult? _checkRepeatedMerchant(Transaction tx, List<Transaction> todayTx) {
    final sameMerchantToday = todayTx
        .where((t) => t.merchant.toLowerCase() == tx.merchant.toLowerCase())
        .length;

    if (sameMerchantToday >= 3) {
      final totalAtMerchant = todayTx
          .where((t) => t.merchant.toLowerCase() == tx.merchant.toLowerCase())
          .fold(0.0, (sum, t) => sum + t.amount);

      return WasteResult(
        isWaste: true,
        reason: 'Repeated purchases from ${tx.merchant} ($sameMerchantToday times today)',
        wastedAmount: tx.amount,
        confidence: 0.75,
        rule: WasteRule.repeatedMerchant,
      );
    }
    return null;
  }

  WasteResult? _checkOverCategoryBudget(
    Transaction tx,
    List<Transaction> todayTx,
    Map<String, double> budgets,
  ) {
    final categoryName = tx.category.name;
    final budget = budgets[categoryName];

    if (budget != null && budget > 0) {
      final categorySpend = todayTx
          .where((t) => t.category == tx.category && !t.isWaste)
          .fold(0.0, (sum, t) => sum + t.amount);

      if (categorySpend > budget) {
        final excess = categorySpend - budget;
        return WasteResult(
          isWaste: true,
          reason: 'Over ${categoryName} budget by ETB ${excess.toStringAsFixed(0)}',
          wastedAmount: excess > 0 ? excess : tx.amount,
          confidence: 0.9,
          rule: WasteRule.overCategoryBudget,
        );
      }
    }
    return null;
  }

  WasteResult? _checkMicroSpending(Transaction tx, List<Transaction> todayTx) {
    if (tx.amount < 100) {
      final microTxCount = todayTx.where((t) => t.amount < 100 && !t.isWaste).length;

      if (microTxCount >= 5) {
        final microTotal = todayTx
            .where((t) => t.amount < 100 && !t.isWaste)
            .fold(0.0, (sum, t) => sum + t.amount);

        return WasteResult(
          isWaste: true,
          reason: 'Micro-spending: $microTxCount small purchases totaling ETB ${microTotal.toStringAsFixed(0)}',
          wastedAmount: microTotal,
          confidence: 0.7,
          rule: WasteRule.microSpending,
        );
      }
    }
    return null;
  }

  WasteResult? _checkWeekendOverhop(Transaction tx, List<Transaction> weekTx) {
    final dayOfWeek = tx.timestamp.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      final weekdayTx = weekTx.where((t) => t.timestamp.weekday < 6).toList();
      final weekendTx = weekTx.where((t) => t.timestamp.weekday >= 6).toList();

      if (weekdayTx.isNotEmpty && weekendTx.isNotEmpty) {
        final weekdayAvg = weekdayTx.fold(0.0, (sum, t) => sum + t.amount) / weekdayTx.length;
        final weekendTotal = weekendTx.fold(0.0, (sum, t) => sum + t.amount);

        if (weekendTotal > weekdayAvg * 2) {
          return WasteResult(
            isWaste: true,
            reason: 'Weekend overshop: spent ${(weekendTotal / weekdayAvg).toStringAsFixed(1)}x your weekday average',
            wastedAmount: tx.amount,
            confidence: 0.65,
            rule: WasteRule.weekendOverhop,
          );
        }
      }
    }
    return null;
  }

  void applyWasteResult(Transaction tx, WasteResult result) {
    tx.isWaste = result.isWaste;
    tx.wasteReason = result.reason;
  }
}
