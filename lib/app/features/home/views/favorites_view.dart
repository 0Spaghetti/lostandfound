import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../details/item_details_screen.dart';
import '../../notifications/notification_screen.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({
    super.key,
    required this.strings,
    required this.onOpenExploreFeed,
  });

  final AppStrings strings;
  final Future<void> Function() onOpenExploreFeed;

  void _openDetails(BuildContext context, ItemPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(
          postId: post.id,
          initialPost: post,
          strings: strings,
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final repository = ref.watch(itemPostRepositoryProvider);
    final notificationRepo = ref.watch(notificationRepositoryProvider);
    
    final posts = repository.posts.where((post) => post.isFavorite).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: HeaderBar(
                title: strings.favorites,
                subtitle: strings.appName,
                onLanguageToggle: () => ref.read(localeProvider.notifier).toggleLocale(),
                languageLabel: arabic ? 'EN' : 'AR',
                onNotificationsTap: () => _openNotifications(context),
                hasUnreadNotifications: notificationRepo.unreadCount > 0,
              ),
            ),
          ),
          if (posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: strings.favorites,
                subtitle: strings.emptyHint,
                resetLabel: strings.home,
                onReset: () {
                  unawaited(onOpenExploreFeed());
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 104),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return FadeInSlide(
                    delay: Duration(milliseconds: (index % 6) * 80),
                    child: ItemPostCard(
                      post: post,
                      strings: strings,
                      onTap: () => _openDetails(context, post),
                      onFavorite: () => repository.toggleFavorite(post.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
