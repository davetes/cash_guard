import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _dailyBudgetKey = 'daily_budget';
  static const String _currencyKey = 'currency';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _notifyAt80Key = 'notify_at_80';
  static const String _autoDetectWasteKey = 'auto_detect_waste';
  static const String _bankSendersKey = 'bank_senders';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  double getDailyBudget() {
    return _prefs.getDouble(_dailyBudgetKey) ?? 500.0;
  }

  Future<void> setDailyBudget(double budget) async {
    await _prefs.setDouble(_dailyBudgetKey, budget);
  }

  String getCurrency() {
    return _prefs.getString(_currencyKey) ?? 'ETB';
  }

  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_currencyKey, currency);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_onboardingCompleteKey, complete);
  }

  bool getNotifyAt80() {
    return _prefs.getBool(_notifyAt80Key) ?? true;
  }

  Future<void> setNotifyAt80(bool notify) async {
    await _prefs.setBool(_notifyAt80Key, notify);
  }

  bool getAutoDetectWaste() {
    return _prefs.getBool(_autoDetectWasteKey) ?? true;
  }

  Future<void> setAutoDetectWaste(bool detect) async {
    await _prefs.setBool(_autoDetectWasteKey, detect);
  }

  List<String> getBankSenders() {
    return _prefs.getStringList(_bankSendersKey) ??
        ['CBE', 'Awash', 'Dashen', 'Abyssinia', 'Wegagen', 'Telebirr', 'M-Pesa'];
  }

  Future<void> setBankSenders(List<String> senders) async {
    await _prefs.setStringList(_bankSendersKey, senders);
  }

  Map<String, double> getCategoryBudgets() {
    final String? stored = _prefs.getString('category_budgets');
    if (stored == null) {
      return {
        'food': 150.0,
        'transport': 100.0,
        'shopping': 100.0,
        'bills': 200.0,
        'subscription': 50.0,
        'entertainment': 50.0,
        'other': 50.0,
      };
    }
    final Map<String, double> budgets = {};
    final pairs = stored.split(',');
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        budgets[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
      }
    }
    return budgets;
  }

  Future<void> setCategoryBudgets(Map<String, double> budgets) async {
    final String stored = budgets.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _prefs.setString('category_budgets', stored);
  }
}
