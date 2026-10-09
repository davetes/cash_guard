import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'data/models/transaction.dart';
import 'data/models/category.dart';
import 'data/models/daily_summary.dart';
import 'data/models/transaction_adapter.dart';
import 'data/repositories/settings_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  
  Hive.registerAdapter(TransactionCategoryAdapter());
  Hive.registerAdapter(TransactionSourceAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(DailySummaryAdapter());
  
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<DailySummary>('daily_summaries');

  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(AsyncValue.data(prefs)),
      ],
      child: CashGuardianApp(settingsRepository: settingsRepo),
    ),
  );
}

class CashGuardianApp extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const CashGuardianApp({super.key, required this.settingsRepository});

  @override
  State<CashGuardianApp> createState() => _CashGuardianAppState();
}

class _CashGuardianAppState extends State<CashGuardianApp> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !widget.settingsRepository.isOnboardingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashGuardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _showOnboarding
          ? OnboardingScreen(
              onComplete: () {
                setState(() => _showOnboarding = false);
              },
            )
          : const HomeScreen(),
    );
  }
}
