import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lostandfound/main.dart';
import 'package:lostandfound/app/data/providers.dart';

void main() {
  testWidgets('shows splash then home for returning users', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lost_found_onboarding_seen_v1': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LostFoundCampusApp(),
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('أحدث البلاغات'), findsOneWidget);
    expect(find.text('سماعات لاسلكية'), findsOneWidget);
    expect(find.text('حقيبة ظهر زرقاء'), findsOneWidget);
  });

  testWidgets('onboarding swipes through pages and continues as guest', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LostFoundCampusApp(),
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Post lost or found items fast'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Use photo + location to match items'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Chat securely with the poster'), findsOneWidget);

    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    final activePrefs = await SharedPreferences.getInstance();
    expect(activePrefs.getBool('onboardingCompleted'), isTrue);
    expect(find.text('Latest posts'), findsOneWidget);
  });

  testWidgets('get started shows location sheet then routes home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LostFoundCampusApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Allow location?'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    final activePrefs = await SharedPreferences.getInstance();
    expect(activePrefs.getBool('onboardingCompleted'), isTrue);
    expect(find.text('Latest posts'), findsOneWidget);
  });

  testWidgets('chat tab shows seeded inbox conversations', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_locale': 'en',
      'onboardingCompleted': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LostFoundCampusApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Staff 42'), findsOneWidget);
    expect(find.text('Wireless earbuds'), findsOneWidget);
    expect(find.textContaining('verify'), findsWidgets);
  });
}
