import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/auth_state.dart';

import 'package:lostandfound/l10n/generated/app_localizations.dart';

import 'models.dart';
import 'chat_thread_repository.dart';
import 'notification_repository.dart';
import '../features/home/feed_state.dart';
import '../shared/l10n/app_strings.dart';

// Preference keys
const _localeKey = 'settings_locale';
const _themeModeKey = 'settings_theme_mode';

// Provider for SharedPreferences (overridden at startup in ProviderScope)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden inside ProviderScope');
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_localeKey);
    if (code == 'ar' || code == 'en') {
      return Locale(code!);
    }
    return const Locale('ar');
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await setLocale(next);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_localeKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final name = prefs.getString(_themeModeKey);
    if (name != null) {
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => ThemeMode.light,
      );
    }
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ProfileNameNotifier extends Notifier<String> {
  @override
  String build() {
    ref.watch(authProvider); // React to auth changes
    final firebaseName = FirebaseAuth.instance.currentUser?.displayName;
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;
    return ref.watch(sharedPreferencesProvider).getString('settings_profile_name') ?? '';
  }

  Future<void> setName(String name) async {
    state = name;
    await ref.read(sharedPreferencesProvider).setString('settings_profile_name', name);
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    } catch (_) {}
  }
}

final profileNameProvider = NotifierProvider<ProfileNameNotifier, String>(ProfileNameNotifier.new);

class ProfileEmailNotifier extends Notifier<String> {
  @override
  String build() {
    ref.watch(authProvider); // React to auth changes
    final firebaseEmail = FirebaseAuth.instance.currentUser?.email;
    if (firebaseEmail != null && firebaseEmail.isNotEmpty) return firebaseEmail;
    return ref.watch(sharedPreferencesProvider).getString('settings_profile_email') ?? '';
  }

  Future<void> setEmail(String email) async {
    state = email;
    await ref.read(sharedPreferencesProvider).setString('settings_profile_email', email);
    try {
      await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(email);
    } catch (_) {}
  }
}

final profileEmailProvider = NotifierProvider<ProfileEmailNotifier, String>(ProfileEmailNotifier.new);

class ProfileAvatarNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(sharedPreferencesProvider).getString('settings_profile_avatar');
  }

  Future<void> setAvatar(String? avatar) async {
    state = avatar;
    if (avatar == null) {
      await ref.read(sharedPreferencesProvider).remove('settings_profile_avatar');
    } else {
      await ref.read(sharedPreferencesProvider).setString('settings_profile_avatar', avatar);
    }
  }
}

final profileAvatarProvider = NotifierProvider<ProfileAvatarNotifier, String?>(ProfileAvatarNotifier.new);

// Global NotificationRepository Provider
final notificationRepositoryProvider = ChangeNotifierProvider<NotificationRepository>((ref) {
  final repo = NotificationRepository();
  repo.load();
  return repo;
});

// Global ItemPostRepository Provider (handles auto-match background logic)
final itemPostRepositoryProvider = ChangeNotifierProvider<ItemPostRepository>((ref) {
  final repo = ItemPostRepository();
  final notifRepo = ref.read(notificationRepositoryProvider);
  
  repo.load();
  
  repo.onPostAdded = (post) {
    if (post.type == PostType.lost) {
      final matches = repo.posts.where((existing) =>
        existing.type == PostType.found &&
        existing.category == post.category
      ).toList();

      if (matches.isNotEmpty) {
        final bestMatch = matches.first;
        Future.delayed(const Duration(seconds: 2), () {
          notifRepo.addNotification(
            title: 'Potential Match Found',
            body: 'Someone found an item matching your "${post.title ?? post.description}" at ${bestMatch.location.placeLabel}!',
            type: NotificationType.match,
            associatedItemId: bestMatch.id,
          );
        });
      }
    } else if (post.type == PostType.found) {
      final matches = repo.posts.where((existing) =>
        existing.type == PostType.lost &&
        existing.category == post.category
      ).toList();

      if (matches.isNotEmpty) {
        final bestMatch = matches.first;
        Future.delayed(const Duration(seconds: 2), () {
          notifRepo.addNotification(
            title: 'Item Match Near You',
            body: 'A found "${post.title ?? post.description}" matches a lost item reported near ${bestMatch.location.placeLabel}!',
            type: NotificationType.match,
            associatedItemId: bestMatch.id,
          );
        });
      }
    }
  };
  
  return repo;
});

// Global ChatThreadRepository Provider (handles background incoming messages)
final chatThreadRepositoryProvider = ChangeNotifierProvider<ChatThreadRepository>((ref) {
  final repo = ChatThreadRepository();
  final postRepo = ref.watch(itemPostRepositoryProvider);
  final notifRepo = ref.read(notificationRepositoryProvider);
  
  if (postRepo.isLoaded) {
    repo.load(seedPosts: postRepo.posts);
  }
  
  repo.onIncomingMessage = (thread, message) {
    final senderName = thread.participantId == 'staff-42' ? 'Staff 42' : thread.participantId;
    notifRepo.addNotification(
      title: 'New message from $senderName',
      body: message.text,
      type: NotificationType.chat,
      associatedItemId: thread.itemId,
    );
  };
  
  return repo;
});

// Derived provider for filtered and searched posts
final filteredPostsProvider = Provider<List<ItemPost>>((ref) {
  final query = ref.watch(feedQueryProvider);
  final filters = ref.watch(feedFilterProvider);
  final repository = ref.watch(itemPostRepositoryProvider);
  final posts = repository.posts;
  
  final locale = ref.watch(localeProvider);
  final strings = AppStrings.fromLocals(lookupAppLocalizations(locale));

  final now = DateTime.now();
  return posts.where((post) {
    final searchable = [
      itemPostTitle(post, strings),
      itemPostDescription(post, strings),
      categoryLabel(post.category, strings),
      campusLocationLabel(post.location, strings),
      statusLabel(post.status, strings),
    ].join(' ').toLowerCase();

    final matchesQuery = query.isEmpty || searchable.contains(query);
    final matchesStatus = filters.status == null 
        ? post.status != PostStatus.recovered 
        : post.status == filters.status;
    final matchesCategory = filters.category == null || post.category == filters.category;
    final matchesLocation = filters.locationLabel == null || post.location.placeLabel == filters.locationLabel;
    
    final age = now.difference(post.dateTime);
    final matchesDate = switch (filters.dateFilter) {
      DateFilter.any => true,
      DateFilter.today => age.inHours < 24,
      DateFilter.week => age.inDays < 7,
      DateFilter.month => age.inDays < 31,
    };

    return matchesQuery && matchesStatus && matchesCategory && matchesLocation && matchesDate;
  }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
});
