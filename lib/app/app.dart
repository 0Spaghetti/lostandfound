import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lostandfound/l10n/generated/app_localizations.dart';

import 'features/home/campus_shell.dart';
import 'features/startup/startup_screen.dart';
import 'shared/l10n/app_strings.dart';

const _defaultLocale = Locale('ar');
const _onboardingCompletedKey = 'onboardingCompleted';
const _legacyOnboardingSeenKey = 'lost_found_onboarding_seen_v1';
const _localeKey = 'settings_locale';
const _themeModeKey = 'settings_theme_mode';

void main() {
  runApp(const LostFoundCampusApp());
}

class LostFoundCampusApp extends StatefulWidget {
  const LostFoundCampusApp({super.key});

  @override
  State<LostFoundCampusApp> createState() => _LostFoundCampusAppState();
}

class _LostFoundCampusAppState extends State<LostFoundCampusApp> {
  Locale _locale = _defaultLocale;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    final themeName = prefs.getString(_themeModeKey);
    if (!mounted) return;
    setState(() {
      if (localeCode == 'ar' || localeCode == 'en') {
        _locale = Locale(localeCode!);
      }
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      );
    });
  }

  void _toggleLocale() {
    final next = _locale.languageCode == 'ar'
        ? const Locale('en')
        : _defaultLocale;
    unawaited(_setLocale(next));
  }

  Future<void> _setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      onGenerateTitle: (context) => AppStrings.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: AppStartupGate(
        locale: _locale,
        themeMode: _themeMode,
        onToggleLanguage: _toggleLocale,
        onLocaleChanged: (locale) => unawaited(_setLocale(locale)),
        onThemeModeChanged: (mode) => unawaited(_setThemeMode(mode)),
      ),
    );
  }
}

ThemeData _buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF9FAFB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D4ED8),
      brightness: Brightness.light,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFF111827),
      displayColor: const Color(0xFF111827),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

ThemeData _buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D7DF0),
      brightness: Brightness.dark,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFFE2E8F0),
      displayColor: const Color(0xFFE2E8F0),
    ),
  );
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    required this.locale,
    required this.themeMode,
    required this.onToggleLanguage,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final VoidCallback onToggleLanguage;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _ready = false;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding =
        (prefs.getBool(_onboardingCompletedKey) ?? false) ||
        (prefs.getBool(_legacyOnboardingSeenKey) ?? false);
    await Future<void>.delayed(const Duration(milliseconds: 2400));

    if (!mounted) return;
    setState(() {
      _showOnboarding = !seenOnboarding;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SplashScreen();
    }
    return _showOnboarding
        ? OnboardingScreen(
            onContinue: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_onboardingCompletedKey, true);
              await prefs.setBool(_legacyOnboardingSeenKey, true);
              if (!mounted) return;
              setState(() => _showOnboarding = false);
            },
          )
        : CampusShell(
            locale: widget.locale,
            themeMode: widget.themeMode,
            onToggleLanguage: widget.onToggleLanguage,
            onLocaleChanged: widget.onLocaleChanged,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
  }
}
