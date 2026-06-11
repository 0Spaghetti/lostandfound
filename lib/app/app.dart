import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lostandfound/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/providers.dart';
import 'features/home/campus_shell.dart';
import 'features/startup/startup_screen.dart';
import 'shared/l10n/app_strings.dart';
import 'utils/theme.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';

const _onboardingCompletedKey = 'onboardingCompleted';
const _legacyOnboardingSeenKey = 'lost_found_onboarding_seen_v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LostFoundCampusApp(),
    ),
  );
}

class LostFoundCampusApp extends ConsumerWidget {
  const LostFoundCampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppStrings.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppStartupGate(),
    );
  }
}


class AppStartupGate extends ConsumerStatefulWidget {
  const AppStartupGate({super.key});

  @override
  ConsumerState<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends ConsumerState<AppStartupGate> {
  bool _ready = false;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Permission.notification.request();
    final prefs = ref.read(sharedPreferencesProvider);
    final seenOnboarding =
        (prefs.getBool(_onboardingCompletedKey) ?? false) ||
        (prefs.getBool(_legacyOnboardingSeenKey) ?? false);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _showOnboarding = !seenOnboarding;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!_ready) {
      return const SplashScreen();
    }
    if (_showOnboarding) {
      return OnboardingScreen(
        onContinue: () async {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setBool(_onboardingCompletedKey, true);
          await prefs.setBool(_legacyOnboardingSeenKey, true);
          if (!mounted) return;
          setState(() => _showOnboarding = false);
        },
      );
    }

    if (authState.isAuthenticated || authState.isGuest) {
      return const CampusShell();
    }
    return const LoginScreen();
  }
}

