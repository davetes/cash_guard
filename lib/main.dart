import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'data/models/transaction.dart';
import 'data/models/category.dart';
import 'data/models/daily_summary.dart';
import 'data/repositories/settings_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TransactionSchema, CategorySchema, DailySummarySchema],
    directory: dir.path,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(AsyncValue.data(prefs)),
        isarProvider.overrideWithValue(AsyncValue.data(isar)),
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
