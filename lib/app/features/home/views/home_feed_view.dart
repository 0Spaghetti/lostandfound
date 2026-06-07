import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';

import '../../../data/providers.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../details/item_details_screen.dart';
import '../../notifications/notification_screen.dart';
import '../feed_state.dart';
import '../widgets/filter_sheet.dart';

class HomeFeedView extends ConsumerStatefulWidget {
  const HomeFeedView({
    super.key,
    required this.strings,
  });

  final AppStrings strings;

  @override
  ConsumerState<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends ConsumerState<HomeFeedView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  int _visibleCount = 8;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearBottom);
    _searchController.addListener(() {
      ref.read(feedQueryProvider.notifier).setQuery(_searchController.text);
      if (mounted) {
        setState(() {
          _visibleCount = 8;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMoreWhenNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 260) {
      final total = ref.read(filteredPostsProvider).length;
      if (_visibleCount < total) {
        setState(() {
          _visibleCount = (_visibleCount + 4).clamp(0, total);
        });
      }
    }
  }

  Future<void> _openFilters() async {
    final currentFilters = ref.read(feedFilterProvider);
    final result = await showModalBottomSheet<FilterState>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        initial: currentFilters,
        strings: widget.strings,
        locations: campusLocations.map((e) => e.placeLabel).toList(),
        locationLabelBuilder: (label) => campusLocationLabelText(label, widget.strings),
      ),
    );

    if (result == null) return;
    ref.read(feedFilterProvider.notifier).setFilters(result);
    setState(() {
      _visibleCount = 8;
    });
  }

  void _resetFilters() {
    ref.read(feedFilterProvider.notifier).reset();
    setState(() {
      _visibleCount = 8;
    });
  }

  void _openDetails(ItemPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(
          postId: post.id,
          initialPost: post,
          strings: widget.strings,
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final strings = widget.strings;
    
    final notificationRepo = ref.watch(notificationRepositoryProvider);
    final repository = ref.watch(itemPostRepositoryProvider);
    
    final filters = ref.watch(feedFilterProvider);
    final query = ref.watch(feedQueryProvider);
    final filteredPosts = ref.watch(filteredPostsProvider);

    return SafeArea(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await HapticFeedback.lightImpact();
              await Future<void>.delayed(const Duration(milliseconds: 1200));
              await HapticFeedback.mediumImpact();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(arabic ? 'تم تحديث البلاغات بنجاح!' : 'Campus feed updated successfully!'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumHomeHeader(
                  title: arabic ? 'مفقودات وموجودات' : 'Lost & Found',
                  subtitle: arabic ? 'مجتمع جامعتنا' : strings.splashSubtitle,
                  onNotificationsTap: _openNotifications,
                  hasUnreadNotifications: notificationRepo.unreadCount > 0,
                ),
                PremiumHomeSearchBar(
                  controller: _searchController,
                  hint: arabic ? 'ابحث عن غرض مفقود أو موجود' : strings.searchHint,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterChipsRow(
                        filters: filters,
                        strings: strings,
                        onFilterTap: _openFilters,
                        onReset: _resetFilters,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            strings.latestPosts,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const Spacer(),
                          if (filters.hasActiveFilters || query.isNotEmpty)
                            Text(
                              '${filteredPosts.length} ${strings.results}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (filteredPosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: strings.noItems,
                subtitle: strings.emptyHint,
                resetLabel: strings.reset,
                onReset: _resetFilters,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 104),
              sliver: SliverList.separated(
                itemCount: filteredPosts.length > _visibleCount
                    ? _visibleCount + 1
                    : filteredPosts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= filteredPosts.take(_visibleCount).length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: PostSkeleton(),
                    );
                  }
                  final visible = filteredPosts.take(_visibleCount).toList();
                  final post = visible[index];
                  return FadeInSlide(
                    delay: Duration(milliseconds: (index % 6) * 80),
                    child: ItemPostCard(
                      post: post,
                      strings: strings,
                      onTap: () => _openDetails(post),
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
