import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _bankSenderController = TextEditingController();
  double _dailyBudget = 500.0;
  String _currency = 'ETB';
  bool _notifyAt80 = true;
  bool _autoDetectWaste = true;
  List<String> _bankSenders = [];
  Map<String, double> _categoryBudgets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = ref.read(settingsProvider);
    setState(() {
      _dailyBudget = settings.dailyBudget;
      _currency = settings.currency;
      _notifyAt80 = settings.notifyAt80;
      _autoDetectWaste = settings.autoDetectWaste;
      _bankSenders = List.from(settings.bankSenders);
      _categoryBudgets = Map.from(settings.categoryBudgets);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _bankSenderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Budget'),
          ListTile(
            title: const Text('Daily Budget'),
            subtitle: Text('ETB ${_dailyBudget.toStringAsFixed(0)}'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _dailyBudget,
                min: 100,
                max: 5000,
                divisions: 49,
                label: 'ETB ${_dailyBudget.toStringAsFixed(0)}',
                onChanged: (value) {
                  setState(() => _dailyBudget = value);
                },
                onChangeEnd: (value) {
                  _saveDailyBudget(value);
                },
              ),
            ),
          ),
          ExpansionTile(
            title: const Text('Category Budgets'),
            children: TransactionCategory.values.map((cat) {
              return ListTile(
                title: Text(_categoryName(cat)),
                trailing: SizedBox(
                  width: 120,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'ETB ',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: (_categoryBudgets[cat.name] ?? 0).toStringAsFixed(0),
                    ),
                    onSubmitted: (value) {
                      final budget = double.tryParse(value) ?? 0;
                      setState(() {
                        _categoryBudgets[cat.name] = budget;
                      });
                      _saveCategoryBudgets();
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(),
          _SectionHeader(title: 'Preferences'),
          ListTile(
            title: const Text('Currency'),
            trailing: DropdownButton<String>(
              value: _currency,
              items: const [
                DropdownMenuItem(value: 'ETB', child: Text('ETB')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'KES', child: Text('KES')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                  _saveCurrency(value);
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Notify at 80% budget'),
            subtitle: const Text('Get notified when you reach 80% of daily budget'),
            value: _notifyAt80,
            onChanged: (value) {
              setState(() => _notifyAt80 = value);
              _saveNotifyAt80(value);
            },
          ),
          SwitchListTile(
            title: const Text('Auto-detect waste'),
            subtitle: const Text('Automatically flag suspicious transactions'),
            value: _autoDetectWaste,
            onChanged: (value) {
              setState(() => _autoDetectWaste = value);
              _saveAutoDetectWaste(value);
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Bank SMS Senders'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bankSenderController,
                    decoration: const InputDecoration(
                      hintText: 'Add bank name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addBankSender,
                ),
              ],
            ),
          ),
          ..._bankSenders.map((bank) {
            return ListTile(
              title: Text(bank),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeBankSender(bank),
              ),
            );
          }),
          const Divider(),
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync SMS Now'),
            subtitle: const Text('Scan bank messages for new transactions'),
            onTap: _syncSms,
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export transactions as JSON'),
            onTap: _exportData,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
            title: Text('Clear All Data', style: TextStyle(color: Colors.red.shade700)),
            subtitle: const Text('Delete all transactions permanently'),
            onTap: _clearAllData,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _categoryName(dynamic category) {
    switch (category.name) {
      case 'food':
        return 'Food';
      case 'transport':
        return 'Transport';
      case 'shopping':
        return 'Shopping';
      case 'bills':
        return 'Bills';
      case 'subscription':
        return 'Subscription';
      case 'entertainment':
        return 'Entertainment';
      case 'other':
        return 'Other';
      default:
        return category.name;
    }
  }

  void _addBankSender() {
    final bank = _bankSenderController.text.trim();
    if (bank.isNotEmpty && !_bankSenders.contains(bank)) {
      setState(() {
        _bankSenders.add(bank);
      });
      _saveBankSenders();
      _bankSenderController.clear();
    }
  }

  void _removeBankSender(String bank) {
    setState(() {
      _bankSenders.remove(bank);
    });
    _saveBankSenders();
  }

  void _saveDailyBudget(double budget) {
    ref.read(settingsProvider.notifier);
  }

  void _saveCategoryBudgets() {}

  void _saveCurrency(String currency) {}

  void _saveNotifyAt80(bool value) {}

  void _saveAutoDetectWaste(bool value) {}

  void _saveBankSenders() {}

  void _syncSms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SMS sync coming soon...')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon...')),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data clearing coming soon...')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

enum TransactionCategory {
  food,
  transport,
  shopping,
  bills,
  subscription,
  entertainment,
  other,
}
