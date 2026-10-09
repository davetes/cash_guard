import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/daily_summary.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/sms_parser.dart';
import '../services/waste_detector.dart';
import '../services/category_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hiveInitializedProvider = FutureProvider<bool>((ref) async {
  await Hive.initFlutter();
  
  Hive.registerAdapter(TransactionCategoryAdapter());
  Hive.registerAdapter(TransactionSourceAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(DailySummaryAdapter());
  
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<DailySummary>('daily_summaries');
  
  return true;
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final transactionBoxProvider = Provider<Box<Transaction>>((ref) {
  return Hive.box<Transaction>('transactions');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return SettingsRepository(prefs);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final box = ref.watch(transactionBoxProvider);
  return TransactionRepository(box);
});

final wasteDetectorProvider = Provider<WasteDetector>((ref) {
  return WasteDetector();
});

final categoryDetectorProvider = Provider<CategoryDetector>((ref) {
  return CategoryDetector();
});

final todayTransactionsProvider = Provider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final today = DateTime.now();
  return repo.getTransactionsForDate(today);
});

final allTransactionsProvider = Provider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAllTransactions();
});

final weekTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionsForWeek(DateTime.now());
});

final monthTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionsForMonth(DateTime.now());
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
