import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../shared/l10n/app_strings.dart';
import '../add_item/add_item_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/auth_state.dart';
import '../auth/login_screen.dart';
import 'feed_state.dart';
import 'views/favorites_view.dart';
import 'views/home_feed_view.dart';
import 'views/my_posts_view.dart';

class CampusShell extends ConsumerStatefulWidget {
  const CampusShell({super.key});

  @override
  ConsumerState<CampusShell> createState() => _CampusShellState();
}

class _CampusShellState extends ConsumerState<CampusShell> {
  late final PageController _pageController;
  int _navIndex = 0;
  bool _animatingToPage = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  AppStrings get strings => AppStrings.of(context);
  ItemPostRepository get _repository => ref.read(itemPostRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openAddItem() async {
    if (ref.read(authProvider).isGuest) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final created = await Navigator.of(context).push<ItemPost>(
      MaterialPageRoute(
        builder: (_) => AddItemScreen(strings: strings, repository: _repository),
      ),
    );

    if (created != null) {
      ref.read(feedFilterProvider.notifier).reset();
      ref.read(feedQueryProvider.notifier).clear();
      await _selectTab(2);
    }
  }

  Future<void> _openExploreFeed({bool resetDiscovery = false}) async {
    if (resetDiscovery) {
      ref.read(feedFilterProvider.notifier).reset();
      ref.read(feedQueryProvider.notifier).clear();
    }
    await _selectTab(0);
  }

  Future<void> _selectTab(int index) async {
    if (_navIndex == index) return;
    setState(() => _navIndex = index);

    if (!_pageController.hasClients) return;
    _animatingToPage = true;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
    _animatingToPage = false;
  }

  void _handlePageChanged(int index) {
    if (_navIndex == index) return;
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(itemPostRepositoryProvider);
    ref.watch(chatThreadRepositoryProvider);
    
    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _handlePageChanged,
          children: [
            HomeFeedView(strings: strings),
            FavoritesView(
              strings: strings,
              onOpenExploreFeed: () => _openExploreFeed(resetDiscovery: true),
            ),
            MyPostsView(
              strings: strings,
              onOpenExploreFeed: () => _openExploreFeed(resetDiscovery: true),
              onItemCreated: () => _openExploreFeed(resetDiscovery: true),
            ),
            ChatInboxScreen(
              strings: strings,
              onLanguageToggle: () => ref.read(localeProvider.notifier).toggleLocale(),
              languageLabel: _arabic ? 'EN' : 'AR',
              onNotificationsTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
              },
              hasUnreadNotifications: ref.watch(notificationRepositoryProvider).unreadCount > 0,
            ),
            ProfileScreen(strings: strings),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddItem,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.add),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.75),
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _navIndex,
            height: 76,
            onDestinationSelected: (index) {
              if (_animatingToPage) return;
              if (index != 0 && ref.read(authProvider).isGuest) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                return;
              }
              unawaited(_selectTab(index));
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: strings.home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_border_rounded),
                selectedIcon: const Icon(Icons.favorite_rounded),
                label: strings.favorites,
              ),
              NavigationDestination(
                icon: const Icon(Icons.list_alt_outlined),
                selectedIcon: const Icon(Icons.list_alt_rounded),
                label: strings.myPosts,
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: const Icon(Icons.chat_bubble_rounded),
                label: strings.chat,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: strings.profile,
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
