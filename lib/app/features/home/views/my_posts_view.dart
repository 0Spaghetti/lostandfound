import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../add_item/add_item_screen.dart';
import '../../details/item_details_screen.dart';
import '../../notifications/notification_screen.dart';

class MyPostsView extends ConsumerWidget {
  const MyPostsView({
    super.key,
    required this.strings,
    required this.onOpenExploreFeed,
    required this.onItemCreated,
  });

  final AppStrings strings;
  final VoidCallback onOpenExploreFeed;
  final VoidCallback onItemCreated;

  Future<void> _openAddItem(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(itemPostRepositoryProvider);
    final created = await Navigator.of(context).push<ItemPost>(
      MaterialPageRoute(
        builder: (_) => AddItemScreen(strings: strings, repository: repository),
      ),
    );

    if (created != null) {
      onItemCreated();
    }
  }

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
    
    final posts = repository.posts
        .where((post) => post.createdBy.userId == 'current-user')
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderBar(
                    title: strings.myPosts,
                    subtitle: strings.appName,
                    onLanguageToggle: () => ref.read(localeProvider.notifier).toggleLocale(),
                    languageLabel: arabic ? 'EN' : 'AR',
                    onNotificationsTap: () => _openNotifications(context),
                    hasUnreadNotifications: notificationRepo.unreadCount > 0,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${posts.length} ${strings.results}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MyPostsEmptyState(
                title: strings.noMyPosts,
                subtitle: strings.myPostsEmptyHint,
                actionLabel: strings.addReport,
                onAction: () => _openAddItem(context, ref),
                secondaryLabel: strings.home,
                onSecondaryAction: onOpenExploreFeed,
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

class _MyPostsEmptyState extends StatelessWidget {
  const _MyPostsEmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.list_alt_rounded,
                size: 48,
                color: Color(0xFF102A5C),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF102A5C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF102A5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (secondaryLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onSecondaryAction,
                icon: const Icon(Icons.explore_outlined),
                label: Text(secondaryLabel!),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: const Color(0xFF1D4ED8),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
