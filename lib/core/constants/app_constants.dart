class AppConstants {
  static const String appName = 'CashGuardian';
  static const String currency = 'ETB';
  static const String currencySymbol = 'ETB';

  static const List<String> bankSenders = [
    'CBE',
    'Awash',
    'Dashen',
    'Abyssinia',
    'Wegagen',
    'Telebirr',
    'M-Pesa',
  ];

  static const double defaultDailyBudget = 500.0;
  static const double microSpendingThreshold = 100.0;
  static const int microSpendingCount = 5;

  static const Map<String, int> categoryIcons = {
    'food': 0xe25a,
    'transport': 0xe1d7,
    'shopping': 0xe59c,
    'bills': 0xe8b8,
    'subscription': 0xe065,
    'entertainment': 0xe40f,
    'other': 0xe8fe,
  };

  static const Map<String, int> categoryColors = {
    'food': 0xFFFF9800,
    'transport': 0xFF2196F3,
    'shopping': 0xFFE91E63,
    'bills': 0xFF9C27B0,
    'subscription': 0xFF00BCD4,
    'entertainment': 0xFFFF5722,
    'other': 0xFF607D8B,
  };
}
