import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/chat_thread_repository.dart';
import '../../data/models.dart';
import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';
import '../add_item/add_item_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../details/item_details_screen.dart';
import '../settings/settings_screen.dart';

class CampusShell extends StatefulWidget {
  const CampusShell({
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
  State<CampusShell> createState() => _CampusShellState();
}

class _CampusShellState extends State<CampusShell> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ItemPostRepository _repository = ItemPostRepository();
  final ChatThreadRepository _chatRepository = ChatThreadRepository();
  late final PageController _pageController;

  int _visibleCount = 8;
  FilterState _filters = const FilterState();
  String _query = '';
  int _navIndex = 0;
  bool _animatingToPage = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  AppStrings get strings => AppStrings.of(context);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navIndex);
    _scrollController.addListener(_loadMoreWhenNearBottom);
    _repository.addListener(_onRepositoryChanged);
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _visibleCount = 8;
      });
    });
    _chatRepository.addListener(_onRepositoryChanged);
    unawaited(_loadRepositories());
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _chatRepository.removeListener(_onRepositoryChanged);
    _pageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRepositories() async {
    await _repository.load();
    await _chatRepository.load(seedPosts: _repository.posts);
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _loadMoreWhenNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 260) {
      final total = _filteredPosts.length;
      if (_visibleCount < total) {
        setState(() {
          _visibleCount = (_visibleCount + 4).clamp(0, total);
        });
      }
    }
  }

  List<ItemPost> get _filteredPosts {
    final now = DateTime.now();
    return _repository.posts.where((post) {
      final searchable = [
        itemPostTitle(post, strings),
        itemPostDescription(post, strings),
        categoryLabel(post.category, strings),
        campusLocationLabel(post.location, strings),
        statusLabel(post.status, strings),
      ].join(' ').toLowerCase();

      final matchesQuery = _query.isEmpty || searchable.contains(_query);
      final matchesStatus =
          _filters.status == null || post.status == _filters.status;
      final matchesCategory =
          _filters.category == null || post.category == _filters.category;
      final matchesLocation =
          _filters.locationLabel == null ||
          post.location.placeLabel == _filters.locationLabel;
      final age = now.difference(post.dateTime);
      final matchesDate = switch (_filters.dateFilter) {
        DateFilter.any => true,
        DateFilter.today => age.inHours < 24,
        DateFilter.week => age.inDays < 7,
        DateFilter.month => age.inDays < 31,
      };

      return matchesQuery &&
          matchesStatus &&
          matchesCategory &&
          matchesLocation &&
          matchesDate;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> _openAddItem() async {
    final created = await Navigator.of(context).push<ItemPost>(
      MaterialPageRoute(
        builder: (_) =>
            AddItemScreen(strings: strings, repository: _repository),
      ),
    );

    if (created != null) {
      setState(() => _visibleCount = 8);
      await _selectTab(2);
    }
  }

  List<ItemPost> get _myPosts {
    return _repository.posts
        .where((post) => post.createdBy.userId == 'current-user')
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<ItemPost> get _favoritePosts {
    return _repository.posts.where((post) => post.isFavorite).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<FilterState>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        initial: _filters,
        strings: strings,
        locations: campusLocations.map((e) => e.placeLabel).toList(),
        locationLabelBuilder: (label) =>
            campusLocationLabelText(label, strings),
      ),
    );

    if (result == null) return;
    setState(() {
      _filters = result;
      _visibleCount = 8;
    });
  }

  void _resetFilters() {
    setState(() {
      _filters = const FilterState();
      _visibleCount = 8;
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.comingSoon),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openExploreFeed({bool resetDiscovery = false}) async {
    if (resetDiscovery) {
      setState(() {
        _filters = const FilterState();
        _query = '';
        _visibleCount = 8;
      });
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    }
    await _selectTab(0);
  }

  Future<void> _toggleFavorite(ItemPost post) async {
    await _repository.toggleFavorite(post.id);
  }

  void _openDetails(ItemPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(
          postId: post.id,
          repository: _repository,
          chatRepository: _chatRepository,
          initialPost: post,
          strings: strings,
        ),
      ),
    );
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
    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _handlePageChanged,
          children: [
            _buildHomeView(),
            _buildFavoritesView(),
            _buildMyPostsView(),
            _buildChatListView(),
            SettingsScreen(
              strings: strings,
              locale: widget.locale,
              themeMode: widget.themeMode,
              onLocaleChanged: widget.onLocaleChanged,
              onThemeModeChanged: widget.onThemeModeChanged,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddItem,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.add),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFDBEAFE),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF6B7280),
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _navIndex,
            height: 76,
            onDestinationSelected: (index) {
              if (_animatingToPage) return;
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
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: strings.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return SafeArea(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumHomeHeader(
                  title: _arabic ? 'مفقودات وموجودات' : 'Lost & Found',
                  subtitle: _arabic ? 'مجتمع جامعتنا' : strings.splashSubtitle,
                  onNotificationsTap: _showComingSoon,
                ),
                PremiumHomeSearchBar(
                  controller: _searchController,
                  hint: _arabic
                      ? 'ابحث عن غرض مفقود أو موجود'
                      : strings.searchHint,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterChipsRow(
                        filters: _filters,
                        strings: strings,
                        onFilterTap: _openFilters,
                        onReset: _resetFilters,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            strings.latestPosts,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const Spacer(),
                          if (_filters.hasActiveFilters || _query.isNotEmpty)
                            Text(
                              '${_filteredPosts.length} ${strings.results}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_filteredPosts.isEmpty)
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
                itemCount: _filteredPosts.length > _visibleCount
                    ? _visibleCount + 1
                    : _filteredPosts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= _filteredPosts.take(_visibleCount).length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final visible = _filteredPosts.take(_visibleCount).toList();
                  final post = visible[index];
                  return ItemPostCard(
                    post: post,
                    strings: strings,
                    onTap: () => _openDetails(post),
                    onFavorite: () => _toggleFavorite(post),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyPostsView() {
    final posts = _myPosts;
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
                    onLanguageToggle: widget.onToggleLanguage,
                    languageLabel: _arabic ? 'EN' : 'AR',
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
                onAction: _openAddItem,
                secondaryLabel: strings.home,
                onSecondaryAction: () =>
                    unawaited(_openExploreFeed(resetDiscovery: true)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 104),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return ItemPostCard(
                    post: post,
                    strings: strings,
                    onTap: () => _openDetails(post),
                    onFavorite: () => _toggleFavorite(post),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesView() {
    final posts = _favoritePosts;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: HeaderBar(
                title: strings.favorites,
                subtitle: strings.appName,
                onLanguageToggle: widget.onToggleLanguage,
                languageLabel: _arabic ? 'EN' : 'AR',
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
                onReset: () =>
                    unawaited(_openExploreFeed(resetDiscovery: true)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 104),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return ItemPostCard(
                    post: post,
                    strings: strings,
                    onTap: () => _openDetails(post),
                    onFavorite: () => _toggleFavorite(post),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatListView() {
    return ChatInboxScreen(
      strings: strings,
      chatRepository: _chatRepository,
      itemRepository: _repository,
      onLanguageToggle: widget.onToggleLanguage,
      languageLabel: _arabic ? 'EN' : 'AR',
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

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.strings,
    required this.locations,
    required this.locationLabelBuilder,
  });

  final FilterState initial;
  final AppStrings strings;
  final List<String> locations;
  final String Function(String location) locationLabelBuilder;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterState _draft = widget.initial;

  static const Color _primary = Color(0xFF102A5C);
  static const Color _surface = Color(0xFFF7FAFF);
  static const Color _border = Color(0xFFD6E0F0);
  static const Color _text = Color(0xFF334155);

  void _selectStatus(PostStatus? status) {
    setState(() {
      _draft = _draft.copyWith(status: status, clearStatus: status == null);
    });
  }

  void _resetAndClose() {
    Navigator.pop(context, const FilterState());
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A102A5C),
              blurRadius: 28,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                Row(
                  children: [
                    Text(
                      strings.filters,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: strings.cancel,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SectionHeader(title: strings.status),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: strings.allStatuses,
                      dotColor: _primary,
                      selected: _draft.status == null,
                      onTap: () => _selectStatus(null),
                    ),
                    _StatusChip(
                      label: strings.lost,
                      dotColor: const Color(0xFFE9435A),
                      selected: _draft.status == PostStatus.lost,
                      onTap: () => _selectStatus(PostStatus.lost),
                    ),
                    _StatusChip(
                      label: strings.found,
                      dotColor: const Color(0xFF15A56E),
                      selected: _draft.status == PostStatus.found,
                      onTap: () => _selectStatus(PostStatus.found),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeader(title: strings.category),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CategoryChip(
                      label: strings.allCategories,
                      icon: Icons.grid_view_rounded,
                      selected: _draft.category == null,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(clearCategory: true),
                      ),
                    ),
                    ...ItemCategory.values.map((category) {
                      return _CategoryChip(
                        label: categoryLabel(category, strings),
                        icon: categoryIcon(category),
                        selected: _draft.category == category,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(category: category),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeader(title: strings.date),
                const SizedBox(height: 8),
                RadioGroup<DateFilter>(
                  groupValue: _draft.dateFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _draft = _draft.copyWith(dateFilter: value));
                  },
                  child: Column(
                    children: DateFilter.values.map((filter) {
                      return RadioListTile<DateFilter>(
                        value: filter,
                        activeColor: _primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text(
                          dateFilterLabel(filter, strings),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _SectionHeader(title: strings.location),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: _draft.locationLabel,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: strings.location,
                    hintText: strings.allLocations,
                    prefixIcon: const Icon(Icons.place_outlined),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _primary, width: 1.4),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(strings.allLocations),
                    ),
                    ...widget.locations.map(
                      (location) => DropdownMenuItem<String?>(
                        value: location,
                        child: Text(widget.locationLabelBuilder(location)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _draft = value == null
                          ? _draft.copyWith(clearLocation: true)
                          : _draft.copyWith(locationLabel: value);
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetAndClose,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(strings.reset),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          foregroundColor: _primary,
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, _draft),
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(strings.apply),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: const Color(0xFF102A5C),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF102A5C);
    const border = Color(0xFFD6E0F0);
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      avatar: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: selected ? primary : const Color(0xFF334155),
      ),
      backgroundColor: const Color(0xFFF7FAFF),
      selectedColor: dotColor.withValues(alpha: 0.12),
      side: BorderSide(color: selected ? dotColor : border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF102A5C);
    const border = Color(0xFFD6E0F0);
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? primary : const Color(0xFF64748B),
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: selected ? primary : const Color(0xFF334155),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE9F0FF),
      side: BorderSide(color: selected ? primary : border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}
