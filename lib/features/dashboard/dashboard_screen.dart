import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction.dart';
import '../../shared/widgets/category_icon.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(todayTransactionsProvider);
    final settings = ref.watch(settingsProvider);
    final dailyBudget = settings.dailyBudget;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayTransactionsProvider);
        },
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (transactions) => _buildDashboard(context, ref, transactions, dailyBudget),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    List<Transaction> transactions,
    double dailyBudget,
  ) {
    final totalSpent = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final totalWasted = transactions.where((tx) => tx.isWaste).fold(0.0, (sum, tx) => sum + tx.amount);
    final budgetProgress = dailyBudget > 0 ? (totalSpent / dailyBudget).clamp(0.0, 1.5) : 0.0;

    Color progressColor;
    if (budgetProgress < 0.6) {
      progressColor = Colors.green;
    } else if (budgetProgress < 0.85) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.red;
    }

    final categoryMap = <TransactionCategory, double>{};
    for (final tx in transactions) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    TransactionCategory? topCategory;
    if (sortedCategories.isNotEmpty) {
      topCategory = sortedCategories.first.key;
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Today's Spending",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(totalSpent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (totalWasted > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Wasted: ${Formatters.formatCurrency(totalWasted)}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Budget: ${Formatters.formatCurrency(dailyBudget)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${(budgetProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: progressColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: budgetProgress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(progressColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Remaining: ${Formatters.formatCurrency((dailyBudget - totalSpent).clamp(0, double.infinity))}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.receipt_long,
                        label: 'Transactions',
                        value: '${transactions.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.category,
                        label: 'Top Category',
                        value: topCategory != null
                            ? _categoryName(topCategory)
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.savings,
                        label: 'Remaining',
                        value: Formatters.formatCurrency(
                          (dailyBudget - totalSpent).clamp(0, double.infinity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (sortedCategories.isNotEmpty) ...[
                  const Text(
                    'Spending by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieSections(sortedCategories, totalSpent),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedCategories.take(4).map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(AppConstants.categoryColors[entry.key.name] ?? 0xFF607D8B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _categoryName(entry.key),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionsScreen(),
                          ),
                        );
                      },
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (transactions.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    Text(
                      'Add a transaction or sync your bank SMS',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= 5) return null;
                final tx = transactions[index];
                return _TransactionTile(transaction: tx);
              },
              childCount: transactions.length.clamp(0, 5),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<TransactionCategory, double>> categories,
    double total,
  ) {
    return categories.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: Color(AppConstants.categoryColors[entry.key.name] ?? 0xFF607D8B),
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  String _categoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.subscription:
        return 'Subscription';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CategoryIcon(category: transaction.category),
      title: Text(
        transaction.merchant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_categoryName(transaction.category)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.formatCurrency(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction.isWaste ? Colors.red : null,
            ),
          ),
          Text(
            Formatters.formatTime(transaction.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.subscription:
        return 'Subscription';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}
