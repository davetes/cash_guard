import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction.dart';

final insightsProvider = FutureProvider<InsightsData>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));
  final monthAgo = today.subtract(const Duration(days: 30));

  final weekTx = await repo.getTransactionsForDateRange(weekAgo, today);
  final monthTx = await repo.getTransactionsForDateRange(monthAgo, today);

  final weekSpend = weekTx.fold(0.0, (sum, tx) => sum + tx.amount);
  final weekWasted = weekTx.where((tx) => tx.isWaste).fold(0.0, (sum, tx) => sum + tx.amount);

  final dailySpend = <DateTime, double>{};
  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final dayTx = weekTx.where((tx) =>
      tx.timestamp.year == date.year &&
      tx.timestamp.month == date.month &&
      tx.timestamp.day == date.day
    ).toList();
    dailySpend[date] = dayTx.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  final wasteReasons = <String, double>{};
  for (final tx in monthTx.where((tx) => tx.isWaste)) {
    final reason = tx.wasteReason ?? 'Unknown';
    wasteReasons[reason] = (wasteReasons[reason] ?? 0) + tx.amount;
  }

  final topWasteReasons = wasteReasons.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  Transaction? biggestRegret;
  double maxWaste = 0;
  for (final tx in monthTx.where((tx) => tx.isWaste)) {
    if (tx.amount > maxWaste) {
      maxWaste = tx.amount;
      biggestRegret = tx;
    }
  }

  final weekdayTx = weekTx.where((tx) => tx.timestamp.weekday < 6).toList();
  final weekendTx = weekTx.where((tx) => tx.timestamp.weekday >= 6).toList();
  final weekdayAvg = weekdayTx.isNotEmpty
      ? weekdayTx.fold(0.0, (sum, tx) => sum + tx.amount) / weekdayTx.length
      : 0.0;
  final weekendAvg = weekendTx.isNotEmpty
      ? weekendTx.fold(0.0, (sum, tx) => sum + tx.amount) / weekendTx.length
      : 0.0;

  final suggestions = _generateSuggestions(monthTx, weekTx);

  final previousWeekStart = weekAgo.subtract(const Duration(days: 7));
  final previousWeekEnd = weekAgo;
  final previousWeekTx = await repo.getTransactionsForDateRange(previousWeekStart, previousWeekEnd);
  final previousWeekSpend = previousWeekTx.fold(0.0, (sum, tx) => sum + tx.amount);
  final weekOverWeekChange = previousWeekSpend > 0
      ? ((weekSpend - previousWeekSpend) / previousWeekSpend * 100)
      : 0.0;

  return InsightsData(
    weekTotal: weekSpend,
    weekWasted: weekWasted,
    wastePercentage: weekSpend > 0 ? (weekWasted / weekSpend * 100) : 0,
    dailySpend: dailySpend,
    topWasteReasons: topWasteReasons.take(5).toList(),
    biggestRegret: biggestRegret,
    weekdayAvg: weekdayAvg,
    weekendAvg: weekendAvg,
    suggestions: suggestions,
    weekOverWeekChange: weekOverWeekChange,
  );
});

class InsightsData {
  final double weekTotal;
  final double weekWasted;
  final double wastePercentage;
  final Map<DateTime, double> dailySpend;
  final List<MapEntry<String, double>> topWasteReasons;
  final Transaction? biggestRegret;
  final double weekdayAvg;
  final double weekendAvg;
  final List<String> suggestions;
  final double weekOverWeekChange;

  InsightsData({
    required this.weekTotal,
    required this.weekWasted,
    required this.wastePercentage,
    required this.dailySpend,
    required this.topWasteReasons,
    required this.biggestRegret,
    required this.weekdayAvg,
    required this.weekendAvg,
    required this.suggestions,
    required this.weekOverWeekChange,
  });
}

List<String> _generateSuggestions(List<Transaction> monthTx, List<Transaction> weekTx) {
  final suggestions = <String>[];

  final foodTx = weekTx.where((tx) => tx.category == TransactionCategory.food).toList();
  if (foodTx.length > 10) {
    final foodTotal = foodTx.fold(0.0, (sum, tx) => sum + tx.amount);
    suggestions.add(
      'You spent ${Formatters.formatCurrency(foodTotal)} on food this week ($foodTx.length transactions). '
      'Consider meal prepping to save ~${Formatters.formatCurrency(foodTotal * 0.3)} per month.',
    );
  }

  final microTx = weekTx.where((tx) => tx.amount < 50).toList();
  if (microTx.length > 7) {
    final microTotal = microTx.fold(0.0, (sum, tx) => sum + tx.amount);
    suggestions.add(
      'You made $microTx.length small purchases under 50 ETB totaling ${Formatters.formatCurrency(microTotal)}. '
      'These add up quickly!',
    );
  }

  final subscriptionTx = monthTx.where((tx) =>
    tx.category == TransactionCategory.subscription && !tx.isWaste
  ).toList();
  if (subscriptionTx.isNotEmpty) {
    final subTotal = subscriptionTx.fold(0.0, (sum, tx) => sum + tx.amount);
    final unusedSub = monthTx.where((tx) =>
      tx.category == TransactionCategory.subscription && tx.isWaste
    ).toList();
    if (unusedSub.isNotEmpty) {
      suggestions.add(
        'You have ${subscriptionTx.length} subscriptions totaling ${Formatters.formatCurrency(subTotal)}/month. '
        '${unusedSub.length} appear unused.',
      );
    }
  }

  if (weekTx.any((tx) => tx.isWaste && tx.wasteReason?.contains('Late-night') == true)) {
    suggestions.add(
      'Late-night impulse buys are costing you. Try setting a reminder to avoid spending after 10 PM.',
    );
  }

  return suggestions;
}

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, InsightsData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WeekSummaryCard(data: data),
        const SizedBox(height: 16),
        _SpendingChart(dailySpend: data.dailySpend),
        const SizedBox(height: 16),
        if (data.topWasteReasons.isNotEmpty) ...[
          _TopWasteReasonsCard(reasons: data.topWasteReasons),
          const SizedBox(height: 16),
        ],
        if (data.biggestRegret != null) ...[
          _BiggestRegretCard(transaction: data.biggestRegret!),
          const SizedBox(height: 16),
        ],
        _WeekComparisonCard(change: data.weekOverWeekChange),
        const SizedBox(height: 16),
        if (data.suggestions.isNotEmpty) ...[
          _SuggestionsCard(suggestions: data.suggestions),
        ],
      ],
    );
  }
}

class _WeekSummaryCard extends StatelessWidget {
  final InsightsData data;

  const _WeekSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.formatCurrency(data.weekTotal),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Total Spent'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.formatCurrency(data.weekWasted),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const Text('Wasted'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.wastePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: data.wastePercentage > 30 ? Colors.red : Colors.orange,
                        ),
                      ),
                      const Text('Waste Rate'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  final Map<DateTime, double> dailySpend;

  const _SpendingChart({required this.dailySpend});

  @override
  Widget build(BuildContext context) {
    final sortedDates = dailySpend.keys.toList()..sort();
    final maxY = dailySpend.values.fold(0.0, (max, v) => v > max ? v : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barGroups: sortedDates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    final amount = dailySpend[date] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          color: Theme.of(context).colorScheme.primary,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDates.length) {
                            final date = sortedDates[index];
                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Text(
                              dayNames[date.weekday - 1],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopWasteReasonsCard extends StatelessWidget {
  final List<MapEntry<String, double>> reasons;

  const _TopWasteReasonsCard({required this.reasons});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Waste Reasons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...reasons.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BiggestRegretCard extends StatelessWidget {
  final Transaction transaction;

  const _BiggestRegretCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sentiment_dissatisfied, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Biggest Regret',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Formatters.formatCurrency(transaction.amount),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              transaction.merchant,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
            ),
            if (transaction.wasteReason != null) ...[
              const SizedBox(height: 8),
              Text(
                transaction.wasteReason!,
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekComparisonCard extends StatelessWidget {
  final double change;

  const _WeekComparisonCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final isUp = change > 0;
    final color = isUp ? Colors.red : Colors.green;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Compared to last week'),
                  Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  final List<String> suggestions;

  const _SuggestionsCard({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('â€¢ '),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
