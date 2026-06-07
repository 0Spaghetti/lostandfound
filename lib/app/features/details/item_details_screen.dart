import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';
import '../add_item/add_item_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class ItemDetailsScreen extends ConsumerStatefulWidget {
  const ItemDetailsScreen({
    super.key,
    required this.postId,
    required this.strings,
    this.initialPost,
  });

  final String postId;
  final ItemPost? initialPost;
  final AppStrings strings;

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  final PageController _carouselController = PageController();
  late final ItemPostRepository _itemPostRepository;

  ItemPost? _post;
  bool _loading = true;
  bool _error = false;
  bool _deleted = false;
  int _pageIndex = 0;
  bool _poppedForDelete = false;
  bool _resolvedOnce = false;

  bool get _isOwner => _post?.createdBy.userId == 'current-user';

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _loading = widget.initialPost == null;
    _itemPostRepository = ref.read(itemPostRepositoryProvider);
    _itemPostRepository.addListener(_syncFromRepository);
    unawaited(_resolvePost());
  }

  @override
  void dispose() {
    _itemPostRepository.removeListener(_syncFromRepository);
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _resolvePost() async {
    final repository = ref.read(itemPostRepositoryProvider);
    if (!repository.isLoaded) {
      await repository.load();
      if (!mounted) return;
    }

    final index = repository.posts.indexWhere(
      (post) => post.id == widget.postId,
    );
    if (index >= 0) {
      setState(() {
        _post = repository.posts[index];
        _loading = false;
        _error = false;
        _deleted = false;
        _resolvedOnce = true;
      });
      return;
    }

    if (_resolvedOnce || widget.initialPost != null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = false;
        _deleted = true;
      });
      _schedulePopForDeleted();
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = true;
      _resolvedOnce = true;
    });
  }

  void _syncFromRepository() {
    final repository = ref.read(itemPostRepositoryProvider);
    final index = repository.posts.indexWhere(
      (post) => post.id == widget.postId,
    );
    if (!mounted) return;

    if (index >= 0) {
      setState(() {
        _post = repository.posts[index];
        _loading = false;
        _error = false;
        _deleted = false;
        _resolvedOnce = true;
      });
      return;
    }

    if (_resolvedOnce && _post != null) {
      setState(() {
        _deleted = true;
        _loading = false;
        _error = false;
      });
      _schedulePopForDeleted();
    }
  }

  void _schedulePopForDeleted() {
    if (_poppedForDelete) return;
    _poppedForDelete = true;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900)).then((_) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
      }),
    );
  }

  Future<void> _toggleFavorite() async {
    final post = _post;
    if (post == null) return;
    await ref.read(itemPostRepositoryProvider).toggleFavorite(post.id);
  }

  Future<void> _markRecovered() async {
    final post = _post;
    if (post == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.strings.markRecovered),
        content: Text(widget.strings.markRecoveredConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.strings.apply),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(itemPostRepositoryProvider).updateStatus(post.id, PostStatus.recovered);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.strings.reportUpdated),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deletePost() async {
    final post = _post;
    if (post == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.strings.delete),
        content: Text(widget.strings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.strings.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(itemPostRepositoryProvider).deletePost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.strings.itemDeleted),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openChat() async {
    final post = _post;
    if (post == null) return;
    final thread = await ref.read(chatThreadRepositoryProvider).openThreadForPost(
      post,
      itemPostTitle(post, widget.strings),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          threadId: thread.id,
          itemId: post.id,
          otherUserId: thread.participantId,
          strings: widget.strings,
          itemTitle: itemPostTitle(post, widget.strings),
          itemPhotoUrl: post.photoUrl,
          itemCategory: post.category,
          onOpenItemDetails: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemDetailsScreen(
                  postId: post.id,
                  strings: widget.strings,
                  initialPost: post,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _editPost() async {
    final post = _post;
    if (post == null) return;
    await Navigator.of(context).push<ItemPost>(
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          strings: widget.strings,
          repository: ref.read(itemPostRepositoryProvider),
          existingPost: post,
        ),
      ),
    );
  }

  void _openMap() {
    final post = _post;
    if (post == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.strings.openMap),
        content: MiniMapPreview(location: post.location),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.cancel),
          ),
        ],
      ),
    );
  }

  void _viewProfile() {
    final post = _post;
    if (post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          strings: widget.strings,
          userId: post.createdBy.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.strings.details),
        centerTitle: true,
        actions: [
          if (post != null && _isOwner)
            PopupMenuButton<_DetailAction>(
              onSelected: (action) {
                switch (action) {
                  case _DetailAction.edit:
                    unawaited(_editPost());
                    break;
                  case _DetailAction.delete:
                    unawaited(_deletePost());
                    break;
                  case _DetailAction.markRecovered:
                    unawaited(_markRecovered());
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _DetailAction.edit,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(widget.strings.edit),
                    ],
                  ),
                ),
                if (post.status != PostStatus.recovered)
                  PopupMenuItem(
                    value: _DetailAction.markRecovered,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(widget.strings.markRecovered),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: _DetailAction.delete,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFE9435A),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.strings.delete,
                        style: const TextStyle(color: Color(0xFFE9435A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const _DetailsSkeleton()
          : _error
          ? _DetailsErrorState(
              title: widget.strings.noItems,
              subtitle: widget.strings.emptyHint,
              retryLabel: widget.strings.retry,
              onRetry: _resolvePost,
            )
          : _deleted
          ? _DeletedState(
              title: widget.strings.itemDeleted,
              subtitle: widget.strings.itemDeletedMessage,
            )
          : _DetailsBody(
              post: post!,
              strings: widget.strings,
              controller: _carouselController,
              pageIndex: _pageIndex,
              onPageChanged: (index) => setState(() => _pageIndex = index),
              onMapTap: _openMap,
              onProfileTap: _viewProfile,
            ),
      bottomNavigationBar: _loading || _error || _deleted || post == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0x140A2758)
                          : Colors.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(widget.strings.chat),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: _toggleFavorite,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      icon: Icon(
                        post.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: post.isFavorite
                            ? const Color(0xFFE9435A)
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.post,
    required this.strings,
    required this.controller,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onMapTap,
    required this.onProfileTap,
  });

  final ItemPost post;
  final AppStrings strings;
  final PageController controller;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onMapTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final pages = [
      Hero(
        tag: 'photo-${post.id}',
        child: LargePhotoPreview(
          photoUrl: post.photoUrl,
          category: post.category,
        ),
      ),
      Stack(
        fit: StackFit.expand,
        children: [
          LargePhotoPreview(photoUrl: post.photoUrl, category: post.category),
          Positioned(
            left: 16,
            top: 16,
            child: _OverlayPill(label: strings.openMap),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _OverlayPill(label: strings.location),
          ),
        ],
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(18),
        child: _PosterSummary(
          post: post,
          strings: strings,
          onTap: onProfileTap,
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      children: [
        AspectRatio(
          aspectRatio: 1.06,
          child: Stack(
            children: [
              PageView(
                controller: controller,
                onPageChanged: onPageChanged,
                children: pages,
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Row(
                  children: [
                    _TypePill(
                      label: post.type == PostType.lost
                          ? strings.lost
                          : strings.found,
                      color: post.type == PostType.lost
                          ? const Color(0xFFE9435A)
                          : const Color(0xFF15A56E),
                    ),
                    const SizedBox(width: 8),
                    _TypePill(
                      label: _detailsStatusLabel(post, strings),
                      color: post.status == PostStatus.recovered
                          ? const Color(0xFF2D7DF0)
                          : const Color(0xFF102A5C),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == pageIndex ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == pageIndex
                            ? const Color(0xFF102A5C)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Hero(
          tag: 'title-${post.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              itemPostTitle(post, strings),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0A2758),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              post.type == PostType.found
                  ? strings.reportedFound
                  : strings.reportedLost,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              longDate(post.dateTime, strings),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DetailPanel(
          children: [
            DetailRow(
              icon: categoryIcon(post.category),
              label: strings.category,
              value: categoryLabel(post.category, strings),
            ),
            DetailRow(
              icon: Icons.location_on_outlined,
              label: strings.location,
              value: campusLocationLabel(post.location, strings),
            ),
            if (post.locationDetail != null && post.locationDetail!.isNotEmpty)
              DetailRow(
                icon: Icons.apartment_rounded,
                label: strings.locationDetail,
                value: post.locationDetail!,
              ),
            DetailRow(
              icon: Icons.schedule_rounded,
              label: strings.dateTime,
              value: relativeTime(post.dateTime, strings),
            ),
            if (post.itemColor != null && post.itemColor!.isNotEmpty)
              DetailRow(
                icon: Icons.palette_outlined,
                label: strings.itemColor,
                value: post.itemColor!,
              ),
            if (post.itemBrand != null && post.itemBrand!.isNotEmpty)
              DetailRow(
                icon: Icons.sell_outlined,
                label: strings.itemBrand,
                value: post.itemBrand!,
              ),
            if (post.distinguishingDetails != null &&
                post.distinguishingDetails!.isNotEmpty)
              DetailRow(
                icon: Icons.fingerprint_rounded,
                label: strings.distinguishingDetails,
                value: post.distinguishingDetails!,
              ),
            if (post.isUrgent)
              DetailRow(
                icon: Icons.priority_high_rounded,
                label: strings.urgentReport,
                value: strings.urgentReportHint,
              ),
            if (post.hasReward)
              DetailRow(
                icon: Icons.volunteer_activism_outlined,
                label: strings.rewardOffered,
                value: strings.rewardOfferedHint,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(strings.description, style: sectionLabelStyle(context)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text(
            itemPostDescription(post, strings),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(strings.mapLocation, style: sectionLabelStyle(context)),
            const Spacer(),
            TextButton.icon(
              onPressed: onMapTap,
              icon: const Icon(Icons.map_outlined),
              label: Text(strings.openMap),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MiniMapPreview(location: post.location),
        const SizedBox(height: 18),
        _PosterCard(post: post, strings: strings, onTap: onProfileTap),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180A2758),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class DetailPanel extends StatelessWidget {
  const DetailPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A7590)),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.post,
    required this.strings,
    required this.onTap,
  });

  final ItemPost post;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = post.createdBy.userId.isEmpty
        ? strings.postedBy
        : post.createdBy.userId.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final initials = name.isEmpty
        ? '?'
        : name
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x060A2758),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF102A5C),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0A2758),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contactMethodLabel(post.createdBy.contactMethod, strings),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (post.createdBy.contactMethod != null && post.createdBy.contactMethod!.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_all_rounded, size: 20),
              tooltip: strings.copy,
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
              onPressed: () async {
                final contact = post.createdBy.contactMethod!;
                await Clipboard.setData(ClipboardData(text: contact));
                await HapticFeedback.lightImpact();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.localeName == 'ar' ? 'تم نسخ جهة الاتصال!' : 'Contact copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(strings.viewProfile),
          ),
        ],
      ),
    );
  }
}

class _PosterSummary extends StatelessWidget {
  const _PosterSummary({
    required this.post,
    required this.strings,
    required this.onTap,
  });

  final ItemPost post;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = post.createdBy.userId.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF102A5C),
          child: Text(
            name.isEmpty
                ? '?'
                : name
                      .split(' ')
                      .where((part) => part.isNotEmpty)
                      .take(2)
                      .map((part) => part[0].toUpperCase())
                      .join(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? strings.postedBy : name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0A2758),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contactMethodLabel(post.createdBy.contactMethod, strings),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(strings.viewProfile)),
      ],
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    Widget bar([double width = double.infinity, double height = 14]) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          Container(
            height: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 18),
          bar(240, 24),
          const SizedBox(height: 10),
          bar(140),
          const SizedBox(height: 18),
          Container(
            height: 112,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 18),
          bar(160, 18),
          const SizedBox(height: 8),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 18),
          bar(140, 18),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }
}

String _detailsStatusLabel(ItemPost post, AppStrings strings) {
  return post.status == PostStatus.recovered ? strings.recovered : strings.open;
}

class _DetailsErrorState extends StatelessWidget {
  const _DetailsErrorState({
    required this.title,
    required this.subtitle,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Color(0xFFE9435A),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedState extends StatelessWidget {
  const _DeletedState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 54,
              color: Color(0xFFE9435A),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DetailAction { edit, delete, markRecovered }
