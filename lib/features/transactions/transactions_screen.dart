import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction.dart';
import '../../shared/widgets/category_icon.dart';
import 'add_transaction_sheet.dart';

final transactionFilterProvider = StateProvider<TransactionCategory?>((ref) => null);
final showWasteOnlyProvider = StateProvider<bool>((ref) => false);

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final wasteOnly = ref.watch(showWasteOnlyProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              wasteOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: wasteOnly ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              ref.read(showWasteOnlyProvider.notifier).state = !wasteOnly;
            },
            tooltip: 'Show waste only',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onSelected: () {
                    ref.read(transactionFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                ...TransactionCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: _categoryName(category),
                      selected: filter == category,
                      onSelected: () {
                        ref.read(transactionFilterProvider.notifier).state = category;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (transactions) {
                var filtered = transactions;
                if (filter != null) {
                  filtered = filtered.where((tx) => tx.category == filter).toList();
                }
                if (wasteOnly) {
                  filtered = filtered.where((tx) => tx.isWaste).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final grouped = _groupByDate(filtered);

                return ListView.builder(
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped.entries.elementAt(index);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...entry.value.map((tx) => _TransactionTile(
                          transaction: tx,
                          onDelete: () => _deleteTransaction(context, ref, tx),
                          onEdit: () => _showEditSheet(context, ref, tx),
                          onTap: () => _showDetails(context, tx),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};

    for (final tx in transactions) {
      final dateKey = Formatters.formatRelativeDate(tx.date);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(tx);
    }

    return grouped;
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(transaction: tx),
    );
  }

  void _showDetails(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _TransactionDetailsSheet(transaction: tx),
    );
  }

  void _deleteTransaction(BuildContext context, WidgetRef ref, Transaction tx) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.deleteTransaction(tx.id);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(todayTransactionsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${tx.merchant}')),
      );
    }
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
        return 'Subscriptions';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(transaction.id.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Transaction'),
              content: const Text('Are you sure you want to delete this transaction?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        } else {
          onEdit();
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onDelete();
        }
      },
      child: ListTile(
        onTap: onTap,
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
            if (transaction.isWaste)
              const Text(
                'Waste',
                style: TextStyle(color: Colors.red, fontSize: 10),
              ),
          ],
        ),
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

class _TransactionDetailsSheet extends ConsumerWidget {
  final Transaction transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIcon(category: transaction.category, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatDateTime(transaction.timestamp),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailRow(label: 'Amount', value: Formatters.formatCurrency(transaction.amount)),
          _DetailRow(label: 'Category', value: _categoryName(transaction.category)),
          _DetailRow(label: 'Source', value: transaction.source.name.toUpperCase()),
          if (transaction.rawText != null)
            _DetailRow(label: 'Raw SMS', value: transaction.rawText!, isMultiLine: true),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mark as waste'),
            subtitle: Text(transaction.wasteReason ?? 'Toggle if this was an unnecessary purchase'),
            value: transaction.isWaste,
            onChanged: (value) async {
              final repo = ref.read(transactionRepositoryProvider);
              transaction.isWaste = value;
              if (!value) {
                transaction.wasteReason = null;
              }
              await repo.updateTransaction(transaction);
              ref.invalidate(allTransactionsProvider);
              ref.invalidate(todayTransactionsProvider);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 16),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiLine;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: isMultiLine ? null : 1,
              overflow: isMultiLine ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
