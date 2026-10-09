import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/daily_summary.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/sms_parser.dart';
import '../services/waste_detector.dart';
import '../services/category_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    [TransactionSchema, CategorySchema, DailySummarySchema],
    directory: dir.path,
  );
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return SettingsRepository(prefs);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar not initialized');
  }
  return TransactionRepository(isar);
});

final wasteDetectorProvider = Provider<WasteDetector>((ref) {
  return WasteDetector();
});

final categoryDetectorProvider = Provider<CategoryDetector>((ref) {
  return CategoryDetector();
});

final todayTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final today = DateTime.now();
  return repo.watchTransactionsForDate(today);
});

final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAllTransactions();
});

final weekTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getTransactionsForWeek(DateTime.now());
});

final monthTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getTransactionsForMonth(DateTime.now());
});

final dailyBudgetProvider = StateProvider<double>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return settings.getDailyBudget();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    return SettingsNotifier(null);
  }
  return SettingsNotifier(SettingsRepository(prefs));
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository? _repository;

  SettingsNotifier(this._repository) : super(SettingsState());

  double get dailyBudget => _repository?.getDailyBudget() ?? 500.0;
  String get currency => _repository?.getCurrency() ?? 'ETB';
  bool get notifyAt80 => _repository?.getNotifyAt80() ?? true;
  bool get autoDetectWaste => _repository?.getAutoDetectWaste() ?? true;
  List<String> get bankSenders => _repository?.getBankSenders() ?? [];
  Map<String, double> get categoryBudgets => _repository?.getCategoryBudgets() ?? {};
}

class SettingsState {
  final double dailyBudget;
  final String currency;
  final bool notifyAt80;
  final bool autoDetectWaste;
  final List<String> bankSenders;
  final Map<String, double> categoryBudgets;

  SettingsState({
    this.dailyBudget = 500.0,
    this.currency = 'ETB',
    this.notifyAt80 = true,
    this.autoDetectWaste = true,
    this.bankSenders = const ['CBE', 'Awash', 'Dashen', 'Abyssinia', 'Wegagen', 'Telebirr', 'M-Pesa'],
    Map<String, double>? categoryBudgets,
  }) : categoryBudgets = categoryBudgets ?? {
    'food': 150.0,
    'transport': 100.0,
    'shopping': 100.0,
    'bills': 200.0,
    'subscription': 50.0,
    'entertainment': 50.0,
    'other': 50.0,
  };
}
