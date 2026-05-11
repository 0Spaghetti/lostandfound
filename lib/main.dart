import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LostFoundCampusApp());
}

enum PostType { lost, found }

enum PostStatus { lost, found, recovered }

enum ItemCategory { electronics, keys, bag, cards, other }

enum DateFilter { any, today, week, month }

class CampusLocation {
  const CampusLocation({
    required this.lat,
    required this.lng,
    required this.placeLabel,
  });

  final double lat;
  final double lng;
  final String placeLabel;

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      placeLabel: json['placeLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'placeLabel': placeLabel,
    };
  }
}

class Poster {
  const Poster({required this.userId, this.contactMethod});

  final String userId;
  final String? contactMethod;

  factory Poster.fromJson(Map<String, dynamic> json) {
    return Poster(
      userId: json['userId'] as String? ?? '',
      contactMethod: json['contactMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'contactMethod': contactMethod,
    };
  }
}

class ItemPost {
  const ItemPost({
    required this.id,
    required this.type,
    required this.status,
    this.title,
    required this.description,
    required this.category,
    required this.photoUrl,
    required this.location,
    required this.dateTime,
    required this.createdBy,
    this.isFavorite = false,
  });

  final String id;
  final PostType type;
  final PostStatus status;
  final String? title;
  final String description;
  final ItemCategory category;
  final String photoUrl;
  final CampusLocation location;
  final DateTime dateTime;
  final Poster createdBy;
  final bool isFavorite;

  ItemPost copyWith({
    PostStatus? status,
    bool? isFavorite,
    String? photoUrl,
  }) {
    return ItemPost(
      id: id,
      type: type,
      status: status ?? this.status,
      title: title,
      description: description,
      category: category,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location,
      dateTime: dateTime,
      createdBy: createdBy,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory ItemPost.fromJson(Map<String, dynamic> json) {
    return ItemPost(
      id: json['id'] as String? ?? '',
      type: PostType.values.byName(json['type'] as String? ?? 'lost'),
      status: PostStatus.values.byName(json['status'] as String? ?? 'lost'),
      title: json['title'] as String?,
      description: json['description'] as String? ?? '',
      category: ItemCategory.values.byName(
        json['category'] as String? ?? 'other',
      ),
      photoUrl: json['photoUrl'] as String? ?? '',
      location: CampusLocation.fromJson(
        Map<String, dynamic>.from(json['location'] as Map),
      ),
      dateTime: DateTime.parse(json['dateTime'] as String),
      createdBy: Poster.fromJson(
        Map<String, dynamic>.from(json['createdBy'] as Map),
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'title': title,
      'description': description,
      'category': category.name,
      'photoUrl': photoUrl,
      'location': location.toJson(),
      'dateTime': dateTime.toIso8601String(),
      'createdBy': createdBy.toJson(),
      'isFavorite': isFavorite,
    };
  }
}

class ItemPostRepository extends ChangeNotifier {
  static const _storageKey = 'lost_found_posts_v1';

  final List<ItemPost> _posts = buildSeedPosts(DateTime.now());
  SharedPreferences? _prefs;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<ItemPost> get posts => List.unmodifiable(_posts);

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      await _save();
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _posts
        ..clear()
        ..addAll(
          decoded.map(
                (entry) => ItemPost.fromJson(Map<String, dynamic>.from(entry as Map)),
          ),
        );
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> addPost(ItemPost post) async {
    _posts.insert(0, post);
    await _save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index < 0) return;
    _posts[index] = _posts[index].copyWith(
      isFavorite: !_posts[index].isFavorite,
    );
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(_posts.map((post) => post.toJson()).toList()),
    );
  }
}

class FilterState {
  const FilterState({
    this.category,
    this.dateFilter = DateFilter.any,
    this.locationLabel,
  });

  final ItemCategory? category;
  final DateFilter dateFilter;
  final String? locationLabel;

  bool get hasActiveFilters {
    return category != null ||
        dateFilter != DateFilter.any ||
        (locationLabel != null && locationLabel!.isNotEmpty);
  }

  FilterState copyWith({
    ItemCategory? category,
    bool clearCategory = false,
    DateFilter? dateFilter,
    String? locationLabel,
    bool clearLocation = false,
  }) {
    return FilterState(
      category: clearCategory ? null : category ?? this.category,
      dateFilter: dateFilter ?? this.dateFilter,
      locationLabel: clearLocation ? null : locationLabel ?? this.locationLabel,
    );
  }
}

class LostFoundCampusApp extends StatelessWidget {
  const LostFoundCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost & Found Campus App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0796A8),
          brightness: Brightness.light,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF12233D),
          displayColor: const Color(0xFF12233D),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDCE4F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDCE4F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0796A8), width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const CampusShell(),
    );
  }
}

class CampusShell extends StatefulWidget {
  const CampusShell({super.key});

  @override
  State<CampusShell> createState() => _CampusShellState();
}

class _CampusShellState extends State<CampusShell> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ItemPostRepository _repository = ItemPostRepository();

  bool _arabic = false;
  int _visibleCount = 8;
  FilterState _filters = const FilterState();
  String _query = '';
  int _navIndex = 0;

  AppStrings get strings => AppStrings(_arabic);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearBottom);
    _repository.addListener(_onRepositoryChanged);
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _visibleCount = 8;
      });
    });
    unawaited(_repository.load());
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
        post.title ?? '',
        post.description,
        categoryLabel(post.category, strings),
        post.location.placeLabel,
        statusLabel(post.status, strings),
      ].join(' ').toLowerCase();

      final matchesQuery = _query.isEmpty || searchable.contains(_query);
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

      return matchesQuery && matchesCategory && matchesLocation && matchesDate;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> _openAddItem() async {
    final created = await Navigator.of(context).push<ItemPost>(
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          strings: strings,
          repository: _repository,
        ),
      ),
    );

    if (created != null) {
      setState(() {
        _navIndex = 0;
        _visibleCount = 8;
      });
    }
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

  Future<void> _toggleFavorite(ItemPost post) async {
    await _repository.toggleFavorite(post.id);
  }

  void _openDetails(ItemPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(
          post: post,
          strings: strings,
          onFavorite: () => _toggleFavorite(post),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderBar(
                        title: strings.home,
                        subtitle: strings.appName,
                        onLanguageToggle: () {
                          setState(() => _arabic = !_arabic);
                        },
                        languageLabel: _arabic ? 'EN' : 'AR',
                      ),
                      const SizedBox(height: 18),
                      SearchField(
                        controller: _searchController,
                        hint: strings.searchHint,
                      ),
                      const SizedBox(height: 14),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          if (_filters.hasActiveFilters ||
                              _query.isNotEmpty)
                            Text(
                              '${_filteredPosts.length} ${strings.results}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_filteredPosts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: strings.noItems,
                    subtitle: strings.emptyHint,
                    onReset: _resetFilters,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 104),
                  sliver: SliverList.separated(
                    itemCount:
                    _filteredPosts.length > _visibleCount
                        ? _visibleCount + 1
                        : _filteredPosts.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= _filteredPosts.take(_visibleCount).length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child:
                          Center(child: CircularProgressIndicator()),
                        );
                      }
                      final visible =
                      _filteredPosts.take(_visibleCount).toList();
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddItem,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.add),
          backgroundColor: const Color(0xFF0796A8),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (index) {
            if (index == 2) {
              _openAddItem();
              return;
            }
            setState(() => _navIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: strings.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.campaign_outlined),
              selectedIcon: const Icon(Icons.campaign_rounded),
              label: strings.reports,
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline_rounded),
              selectedIcon: const Icon(Icons.add_circle_rounded),
              label: strings.addShort,
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_border_rounded),
              selectedIcon: const Icon(Icons.favorite_rounded),
              label: strings.favorites,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: strings.account,
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onLanguageToggle,
    required this.languageLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onLanguageToggle;
  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu',
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0A2758),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7690B4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onLanguageToggle,
          tooltip: 'Language',
          icon: Text(
            languageLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Notifications',
          icon: Badge(
            smallSize: 8,
            backgroundColor: const Color(0xFFE9435A),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.filters,
    required this.strings,
    required this.onFilterTap,
    required this.onReset,
  });

  final FilterState filters;
  final AppStrings strings;
  final VoidCallback onFilterTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final category = filters.category == null
        ? strings.category
        : categoryLabel(filters.category!, strings);
    final date = dateFilterLabel(filters.dateFilter, strings);
    final location = filters.locationLabel ?? strings.location;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipButton(
            icon: Icons.category_outlined,
            label: category,
            active: filters.category != null,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            icon: Icons.calendar_month_outlined,
            label: date,
            active: filters.dateFilter != DateFilter.any,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            icon: Icons.location_on_outlined,
            label: location,
            active: filters.locationLabel != null,
            onTap: onFilterTap,
          ),
          if (filters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onReset,
              tooltip: strings.reset,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
      backgroundColor: active ? const Color(0xFFE2F8FA) : Colors.white,
      side: BorderSide(
        color: active ? const Color(0xFF0796A8) : const Color(0xFFDCE4F0),
      ),
      labelStyle: TextStyle(
        color: active ? const Color(0xFF087889) : const Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class ItemPostCard extends StatelessWidget {
  const ItemPostCard({
    super.key,
    required this.post,
    required this.strings,
    required this.onTap,
    required this.onFavorite,
  });

  final ItemPost post;
  final AppStrings strings;
  final VoidCallback onTap;
  final Future<void> Function() onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
      '${post.title ?? post.description}, ${statusLabel(post.status, strings)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4EAF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0A2758),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPreview(
                photoUrl: post.photoUrl,
                category: post.category,
                size: 92,
                iconSize: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.title ?? post.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0A2758),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(status: post.status, strings: strings),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InfoLine(
                      icon: categoryIcon(post.category),
                      label: categoryLabel(post.category, strings),
                    ),
                    const SizedBox(height: 5),
                    InfoLine(
                      icon: Icons.location_on_outlined,
                      label: post.location.placeLabel,
                    ),
                    const SizedBox(height: 5),
                    InfoLine(
                      icon: Icons.schedule_rounded,
                      label: relativeTime(post.dateTime, strings),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  unawaited(onFavorite());
                },
                tooltip: strings.favorites,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    post.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(post.isFavorite),
                    color: post.isFavorite
                        ? const Color(0xFFE9435A)
                        : const Color(0xFF8A9AB4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8092AD)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.strings});

  final PostStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel(status, strings),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PhotoPreview extends StatelessWidget {
  const PhotoPreview({
    super.key,
    required this.photoUrl,
    required this.category,
    this.size = 120,
    this.iconSize = 50,
  });

  final String photoUrl;
  final ItemCategory category;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return _ItemPhotoFrame(
      photoUrl: photoUrl,
      style: photoStyleForCategory(category),
      size: size,
      iconSize: iconSize,
      borderRadius: 18,
    );
  }
}

class LargePhotoPreview extends StatelessWidget {
  const LargePhotoPreview({
    super.key,
    required this.photoUrl,
    required this.category,
  });

  final String photoUrl;
  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    return _ItemPhotoFrame(
      photoUrl: photoUrl,
      style: photoStyleForCategory(category),
      size: double.infinity,
      iconSize: 104,
      borderRadius: 22,
      showLargeIcon: true,
    );
  }
}

class _ItemPhotoFrame extends StatelessWidget {
  const _ItemPhotoFrame({
    required this.photoUrl,
    required this.style,
    required this.size,
    required this.iconSize,
    required this.borderRadius,
    this.showLargeIcon = false,
  });

  final String photoUrl;
  final PhotoStyle style;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool showLargeIcon;

  @override
  Widget build(BuildContext context) {
    final bytes = decodePhotoBytes(photoUrl);
    if (bytes != null) {
      final image = Image.memory(bytes, fit: BoxFit.cover);
      if (size.isInfinite) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox.expand(child: image),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size.isInfinite ? null : size,
      height: size.isInfinite ? null : size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -12,
            child: Icon(
              style.icon,
              size: iconSize * (showLargeIcon ? 1.9 : 1.8),
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Center(
            child: Icon(style.icon, size: iconSize, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({
    super.key,
    required this.strings,
    required this.repository,
  });

  final AppStrings strings;
  final ItemPostRepository repository;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  PostType _type = PostType.found;
  ItemCategory? _category;
  CampusLocation? _location;
  String? _photoUrl;
  bool _publishing = false;

  AppStrings get strings => widget.strings;

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoundedSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHandle(),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(strings.camera),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.gallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    final picked = await _pickPhotoDataUri(fromCamera: choice == 'camera');
    if (picked == null) return;
    setState(() {
      _photoUrl = picked;
    });
  }

  Future<String?> _pickPhotoDataUri({required bool fromCamera}) async {
    try {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 82,
        );
        if (xFile == null) return null;
        return dataUriFromBytes(await xFile.readAsBytes());
      }

      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.single.bytes;
      if (bytes == null) return null;
      return dataUriFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openLocationPicker() async {
    final picked = await showDialog<CampusLocation>(
      context: context,
      builder: (_) => LocationPickerDialog(strings: strings),
    );

    if (picked != null) {
      setState(() => _location = picked);
    }
  }

  Future<void> _publish() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_photoUrl == null || _location == null || _category == null || !valid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.validationError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _publishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final post = ItemPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      status: _type == PostType.lost ? PostStatus.lost : PostStatus.found,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!,
      photoUrl: _photoUrl!,
      location: _location!,
      dateTime: DateTime.now(),
      createdBy: Poster(
        userId: 'current-user',
        contactMethod: _contactController.text.trim().isEmpty
            ? 'campus.chat'
            : _contactController.text.trim(),
      ),
    );

    await widget.repository.addPost(post);
    if (!mounted) return;
    setState(() => _publishing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.publishSuccess),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(strings.addReport), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
            children: [
              SegmentedButton<PostType>(
                segments: [
                  ButtonSegment(
                    value: PostType.found,
                    label: Text(strings.found),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                  ),
                  ButtonSegment(
                    value: PostType.lost,
                    label: Text(strings.lost),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (values) {
                  setState(() => _type = values.first);
                },
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(const Size(0, 54)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FieldLabel(strings.addPhoto),
              ImageUploadBox(
                photoUrl: _photoUrl,
                category: _category,
                hasError: _photoUrl == null,
                onTap: _pickImage,
                strings: strings,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.titleOptional,
                  prefixIcon: const Icon(Icons.short_text_rounded),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ItemCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: strings.category,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: ItemCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(categoryLabel(category, strings)),
                  );
                }).toList(),
                validator: (value) =>
                value == null ? strings.requiredField : null,
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: strings.shortDescription,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 72),
                    child: Icon(Icons.edit_note_rounded),
                  ),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 10) return strings.descriptionTooShort;
                  if (length > 200) return strings.descriptionTooLong;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              LocationPickerTile(
                location: _location,
                hasError: _location == null,
                strings: strings,
                onTap: _openLocationPicker,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: strings.contactOptional,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: FilledButton.icon(
            onPressed: _publishing ? null : _publish,
            icon: _publishing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.publish_rounded),
            label: Text(_publishing ? strings.publishing : strings.publish),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFF0796A8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0A2758),
        ),
      ),
    );
  }
}

class ImageUploadBox extends StatelessWidget {
  const ImageUploadBox({
    super.key,
    required this.photoUrl,
    required this.category,
    required this.hasError,
    required this.onTap,
    required this.strings,
  });

  final String? photoUrl;
  final ItemCategory? category;
  final bool hasError;
  final VoidCallback onTap;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFE9435A)
        : const Color(0xFFBFD2E6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: photoUrl == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 44,
              color: Color(0xFF2D7DF0),
            ),
            const SizedBox(height: 10),
            Text(
              strings.tapToUpload,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              strings.cameraGalleryHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        )
            : Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: PhotoPreview(
                photoUrl: photoUrl!,
                category: category ?? ItemCategory.other,
                size: 140,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton.filled(
                onPressed: onTap,
                icon: const Icon(Icons.edit_rounded),
                tooltip: strings.changePhoto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPickerTile extends StatelessWidget {
  const LocationPickerTile({
    super.key,
    required this.location,
    required this.hasError,
    required this.strings,
    required this.onTap,
  });

  final CampusLocation? location;
  final bool hasError;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasError ? const Color(0xFFE9435A) : const Color(0xFFDCE4F0),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF0A7590)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                location?.placeLabel ?? strings.pickLocation,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: location == null
                      ? const Color(0xFF8A9AB4)
                      : const Color(0xFF12233D),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  CampusLocation? _selected = campusLocations.first;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(strings.pickLocation),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniMapPreview(location: _selected ?? campusLocations.first),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  setState(() => _selected = campusLocations.first),
              icon: const Icon(Icons.my_location_rounded),
              label: Text(strings.useCurrentGps),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<CampusLocation>(
              groupValue: _selected,
              onChanged: (value) => setState(() => _selected = value),
              child: Column(
                children: campusLocations.map((location) {
                  return RadioListTile<CampusLocation>(
                    value: location,
                    selected: _selected == location,
                    contentPadding: EdgeInsets.zero,
                    title: Text(location.placeLabel),
                    subtitle: Text(
                      '${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)}',
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: Text(strings.apply),
        ),
      ],
    );
  }
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.strings,
    required this.locations,
  });

  final FilterState initial;
  final AppStrings strings;
  final List<String> locations;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterState _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return RoundedSheet(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Text(
                  strings.filters,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: strings.cancel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(strings.category, style: sectionLabelStyle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(strings.allCategories),
                  selected: _draft.category == null,
                  onSelected: (_) => setState(
                        () => _draft = _draft.copyWith(clearCategory: true),
                  ),
                ),
                ...ItemCategory.values.map((category) {
                  return ChoiceChip(
                    avatar: Icon(categoryIcon(category), size: 18),
                    label: Text(categoryLabel(category, strings)),
                    selected: _draft.category == category,
                    onSelected: (_) => setState(
                          () => _draft = _draft.copyWith(category: category),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            Text(strings.date, style: sectionLabelStyle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DateFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(dateFilterLabel(filter, strings)),
                  selected: _draft.dateFilter == filter,
                  onSelected: (_) => setState(
                        () => _draft = _draft.copyWith(dateFilter: filter),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _draft.locationLabel,
              decoration: InputDecoration(
                labelText: strings.location,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(strings.allLocations),
                ),
                ...widget.locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }),
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
                    onPressed: () {
                      setState(() => _draft = const FilterState());
                    },
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(strings.reset),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
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
                    label: Text(strings.applyFilters),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFF0796A8),
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
    );
  }
}

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({
    super.key,
    required this.post,
    required this.strings,
    required this.onFavorite,
  });

  final ItemPost post;
  final AppStrings strings;
  final Future<void> Function() onFavorite;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late ItemPost _post = widget.post;

  Future<void> _toggleFavorite() async {
    await widget.onFavorite();
    if (!mounted) return;
    setState(() {
      _post = _post.copyWith(isFavorite: !_post.isFavorite);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.details),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            tooltip: strings.favorites,
            icon: Icon(
              _post.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.05,
                  child: Hero(
                    tag: 'photo-${_post.id}',
                    child: LargePhotoPreview(
                      photoUrl: _post.photoUrl,
                      category: _post.category,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: StatusBadge(status: _post.status, strings: strings),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '1 / 3',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _post.title ?? _post.description,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0A2758),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _post.type == PostType.found
                  ? strings.reportedFound
                  : strings.reportedLost,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            DetailPanel(
              children: [
                DetailRow(
                  icon: categoryIcon(_post.category),
                  label: strings.category,
                  value: categoryLabel(_post.category, strings),
                ),
                DetailRow(
                  icon: Icons.location_on_outlined,
                  label: strings.location,
                  value: _post.location.placeLabel,
                ),
                DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: strings.dateTime,
                  value: longDate(_post.dateTime),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(strings.description, style: sectionLabelStyle(context)),
            const SizedBox(height: 8),
            Text(
              _post.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF334155),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Text(strings.mapLocation, style: sectionLabelStyle(context)),
            const SizedBox(height: 10),
            MiniMapPreview(location: _post.location),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${strings.contacting} ${_post.createdBy.contactMethod ?? _post.createdBy.userId}',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(strings.contact),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFF0796A8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF3)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
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
              color: const Color(0xFF64748B),
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

class MiniMapPreview extends StatelessWidget {
  const MiniMapPreview({super.key, required this.location});

  final CampusLocation location;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: CampusMapPainter())),
            Align(
              alignment: const Alignment(0.16, -0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0796A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(blurRadius: 12, color: Color(0x18000000)),
                      ],
                    ),
                    child: Text(
                      location.placeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minorRoadPaint = Paint()
      ..color = const Color(0xFFD9E2EA)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final lawnPaint = Paint()..color = const Color(0xFFCFE8C9);
    final buildingPaint = Paint()..color = const Color(0xFFE7D8BA);

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.64, size.height * 0.08, 86, 62),
      lawnPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.62, 104, 46),
        const Radius.circular(8),
      ),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72, size.height * 0.58, 84, 44),
        const Radius.circular(8),
      ),
      buildingPaint,
    );

    final path = Path()
      ..moveTo(-20, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.2,
        size.width * 0.58,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.7,
        size.width + 20,
        size.height * 0.64,
      );
    canvas.drawPath(path, roadPaint);

    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.42, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.38),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.18),
      minorRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onReset,
  });

  final String title;
  final String subtitle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE2F8FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                size: 52,
                color: Color(0xFF0796A8),
              ),
            ),
            const SizedBox(height: 18),
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
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedSheet extends StatelessWidget {
  const RoundedSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD5DEEA),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

TextStyle? sectionLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w900,
    color: const Color(0xFF0A2758),
  );
}

class PhotoStyle {
  const PhotoStyle({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
}

PhotoStyle photoStyleForCategory(ItemCategory category) {
  return switch (category) {
    ItemCategory.electronics => const PhotoStyle(
      icon: Icons.headphones_rounded,
      colors: [Color(0xFFE8F1FF), Color(0xFF3578F6)],
    ),
    ItemCategory.keys => const PhotoStyle(
      icon: Icons.key_rounded,
      colors: [Color(0xFFFFC97C), Color(0xFF9A5B10)],
    ),
    ItemCategory.bag => const PhotoStyle(
      icon: Icons.backpack_rounded,
      colors: [Color(0xFF45678F), Color(0xFF0A2758)],
    ),
    ItemCategory.cards => const PhotoStyle(
      icon: Icons.credit_card_rounded,
      colors: [Color(0xFFFDA4AF), Color(0xFFE11D48)],
    ),
    ItemCategory.other => const PhotoStyle(
      icon: Icons.inventory_2_rounded,
      colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)],
    ),
  };
}

Uint8List? decodePhotoBytes(String photoUrl) {
  if (!photoUrl.startsWith('data:')) return null;
  final commaIndex = photoUrl.indexOf(',');
  if (commaIndex < 0) return null;
  try {
    return base64Decode(photoUrl.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

String dataUriFromBytes(Uint8List bytes) {
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

IconData categoryIcon(ItemCategory category) {
  return switch (category) {
    ItemCategory.electronics => Icons.headphones_rounded,
    ItemCategory.keys => Icons.key_rounded,
    ItemCategory.bag => Icons.backpack_rounded,
    ItemCategory.cards => Icons.credit_card_rounded,
    ItemCategory.other => Icons.more_horiz_rounded,
  };
}

String categoryLabel(ItemCategory category, AppStrings strings) {
  return switch (category) {
    ItemCategory.electronics => strings.electronics,
    ItemCategory.keys => strings.keys,
    ItemCategory.bag => strings.bag,
    ItemCategory.cards => strings.cards,
    ItemCategory.other => strings.other,
  };
}

String statusLabel(PostStatus status, AppStrings strings) {
  return switch (status) {
    PostStatus.lost => strings.lost,
    PostStatus.found => strings.found,
    PostStatus.recovered => strings.recovered,
  };
}

Color statusColor(PostStatus status) {
  return switch (status) {
    PostStatus.lost => const Color(0xFFE9435A),
    PostStatus.found => const Color(0xFF15A56E),
    PostStatus.recovered => const Color(0xFF2D7DF0),
  };
}

String dateFilterLabel(DateFilter filter, AppStrings strings) {
  return switch (filter) {
    DateFilter.any => strings.anyTime,
    DateFilter.today => strings.today,
    DateFilter.week => strings.last7Days,
    DateFilter.month => strings.last30Days,
  };
}

String relativeTime(DateTime value, AppStrings strings) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(1, 59)} ${strings.minutesAgo}';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} ${strings.hoursAgo}';
  }
  if (difference.inDays == 1) return strings.yesterday;
  return '${difference.inDays} ${strings.daysAgo}';
}

String longDate(DateTime value) {
  final month = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month ${value.day}, ${value.year} - $hour:$minute';
}

class AppStrings {
  const AppStrings(this.ar);

  final bool ar;

  String get appName =>
      ar ? 'تطبيق المفقودات والموجودات' : 'Lost & Found Campus App';
  String get home => ar ? 'الرئيسية' : 'Home';
  String get searchHint => ar ? 'ابحث عن عنصر...' : 'Search for an item...';
  String get latestPosts => ar ? 'أحدث البلاغات' : 'Latest posts';
  String get category => ar ? 'الفئة' : 'Category';
  String get date => ar ? 'التاريخ' : 'Date';
  String get location => ar ? 'الموقع' : 'Location';
  String get add => ar ? 'إضافة' : 'Add';
  String get addShort => ar ? 'بلاغ' : 'Post';
  String get reports => ar ? 'البلاغات' : 'Reports';
  String get favorites => ar ? 'المفضلة' : 'Favorites';
  String get account => ar ? 'الحساب' : 'Account';
  String get lost => ar ? 'مفقود' : 'Lost';
  String get found => ar ? 'موجود' : 'Found';
  String get recovered => ar ? 'تم الاستلام' : 'Recovered';
  String get filters => ar ? 'الفلاتر' : 'Filters';
  String get applyFilters => ar ? 'تطبيق الفلاتر' : 'Apply filters';
  String get apply => ar ? 'تطبيق' : 'Apply';
  String get reset => ar ? 'إعادة تعيين' : 'Reset';
  String get cancel => ar ? 'إلغاء' : 'Cancel';
  String get allCategories => ar ? 'كل الفئات' : 'All categories';
  String get allLocations => ar ? 'كل المواقع' : 'All locations';
  String get anyTime => ar ? 'أي وقت' : 'Any time';
  String get today => ar ? 'اليوم' : 'Today';
  String get last7Days => ar ? 'آخر 7 أيام' : 'Last 7 days';
  String get last30Days => ar ? 'آخر 30 يوم' : 'Last 30 days';
  String get electronics => ar ? 'إلكترونيات' : 'Electronics';
  String get keys => ar ? 'مفاتيح' : 'Keys';
  String get bag => ar ? 'حقيبة' : 'Bag';
  String get cards => ar ? 'بطاقات' : 'Cards';
  String get other => ar ? 'أخرى' : 'Other';
  String get noItems => ar ? 'لا توجد عناصر' : 'No items found';
  String get emptyHint => ar
      ? 'جرّب تغيير البحث أو إعادة تعيين الفلاتر.'
      : 'Try a different search or reset filters.';
  String get results => ar ? 'نتيجة' : 'results';
  String get addReport => ar ? 'أضف بلاغ' : 'Add report';
  String get addPhoto => ar ? 'أضف صورة العنصر' : 'Add item photo';
  String get tapToUpload => ar ? 'اضغط لرفع صورة' : 'Tap to upload photo';
  String get cameraGalleryHint =>
      ar ? 'الكاميرا أو المعرض' : 'Camera or gallery';
  String get camera => ar ? 'الكاميرا' : 'Camera';
  String get gallery => ar ? 'المعرض' : 'Gallery';
  String get useSamplePhoto => ar ? 'استخدم صورة تجريبية' : 'Use sample photo';
  String get changePhoto => ar ? 'تغيير الصورة' : 'Change photo';
  String get titleOptional => ar ? 'عنوان مختصر (اختياري)' : 'Title (optional)';
  String get shortDescription => ar ? 'وصف مختصر' : 'Short description';
  String get pickLocation => ar ? 'اختر الموقع' : 'Pick location';
  String get useCurrentGps => ar ? 'استخدم موقعي الحالي' : 'Use current GPS';
  String get contactOptional =>
      ar ? 'طريقة التواصل (اختياري)' : 'Contact method (optional)';
  String get publish => ar ? 'نشر' : 'Publish';
  String get publishing => ar ? 'جار النشر...' : 'Publishing...';
  String get publishSuccess =>
      ar ? 'تم نشر البلاغ بنجاح' : 'Report published successfully';
  String get validationError => ar
      ? 'أكمل الصورة والوصف والفئة والموقع.'
      : 'Complete photo, description, category, and location.';
  String get requiredField => ar ? 'هذا الحقل مطلوب' : 'This field is required';
  String get descriptionTooShort =>
      ar ? 'اكتب 10 أحرف على الأقل' : 'Use at least 10 characters';
  String get descriptionTooLong =>
      ar ? 'الحد الأقصى 200 حرف' : 'Maximum is 200 characters';
  String get details => ar ? 'التفاصيل' : 'Details';
  String get reportedFound => ar ? 'تم العثور عليها' : 'Reported as found';
  String get reportedLost => ar ? 'تم فقدانها' : 'Reported as lost';
  String get description => ar ? 'الوصف' : 'Description';
  String get mapLocation => ar ? 'الموقع على الخريطة' : 'Map location';
  String get dateTime => ar ? 'التاريخ والوقت' : 'Date and time';
  String get contact => ar ? 'تواصل' : 'Contact';
  String get contacting => ar ? 'جار فتح التواصل مع' : 'Contacting';
  String get minutesAgo => ar ? 'دقيقة' : 'min ago';
  String get hoursAgo => ar ? 'ساعة' : 'hr ago';
  String get daysAgo => ar ? 'يوم' : 'days ago';
  String get yesterday => ar ? 'أمس' : 'Yesterday';
}

final List<CampusLocation> campusLocations = [
  const CampusLocation(
    lat: 32.8872,
    lng: 13.1913,
    placeLabel: 'Main Gate - Building 2',
  ),
  const CampusLocation(
    lat: 32.8891,
    lng: 13.1931,
    placeLabel: 'Engineering College',
  ),
  const CampusLocation(
    lat: 32.8868,
    lng: 13.1964,
    placeLabel: 'Central Library',
  ),
  const CampusLocation(
    lat: 32.8884,
    lng: 13.1982,
    placeLabel: 'Student Center',
  ),
  const CampusLocation(lat: 32.8904, lng: 13.1948, placeLabel: 'Science Hall'),
];

List<ItemPost> buildSeedPosts(DateTime now) {
  return [
    ItemPost(
      id: 'p-001',
      type: PostType.found,
      status: PostStatus.found,
      title: 'Wireless earbuds',
      description:
      'White earbuds were found on the bench near the main gate entrance.',
      category: ItemCategory.electronics,
      photoUrl: '',
      location: campusLocations[0],
      dateTime: now.subtract(const Duration(minutes: 45)),
      createdBy: const Poster(
        userId: 'staff-42',
        contactMethod: 'security desk',
      ),
    ),
    ItemPost(
      id: 'p-002',
      type: PostType.lost,
      status: PostStatus.lost,
      title: 'Blue backpack',
      description:
      'Lost a navy backpack with notebooks and a calculator after class.',
      category: ItemCategory.bag,
      photoUrl: '',
      location: campusLocations[1],
      dateTime: now.subtract(const Duration(hours: 3)),
      createdBy: const Poster(
        userId: 'student-18',
        contactMethod: 'campus chat',
      ),
    ),
    ItemPost(
      id: 'p-003',
      type: PostType.found,
      status: PostStatus.found,
      title: 'Black water bottle',
      description: 'A black metal bottle was found at a library study desk.',
      category: ItemCategory.other,
      photoUrl: '',
      location: campusLocations[2],
      dateTime: now.subtract(const Duration(hours: 7)),
      createdBy: const Poster(
        userId: 'student-22',
        contactMethod: 'library desk',
      ),
    ),
    ItemPost(
      id: 'p-004',
      type: PostType.lost,
      status: PostStatus.lost,
      title: 'Keys with ring',
      description: 'Set of keys with a silver ring and small black tag.',
      category: ItemCategory.keys,
      photoUrl: '',
      location: campusLocations[0],
      dateTime: now.subtract(const Duration(days: 1, hours: 2)),
      createdBy: const Poster(
        userId: 'student-73',
        contactMethod: '055-100-212',
      ),
    ),
    ItemPost(
      id: 'p-005',
      type: PostType.found,
      status: PostStatus.recovered,
      title: 'Student ID card',
      description: 'Student ID card was recovered by its owner this morning.',
      category: ItemCategory.cards,
      photoUrl: '',
      location: campusLocations[3],
      dateTime: now.subtract(const Duration(days: 2)),
      createdBy: const Poster(
        userId: 'admin-3',
        contactMethod: 'student affairs',
      ),
      isFavorite: true,
    ),
    ItemPost(
      id: 'p-006',
      type: PostType.lost,
      status: PostStatus.lost,
      title: 'Tablet device',
      description: 'Lost a tablet in a black case after the biology lecture.',
      category: ItemCategory.electronics,
      photoUrl: '',
      location: campusLocations[4],
      dateTime: now.subtract(const Duration(days: 3, hours: 4)),
      createdBy: const Poster(
        userId: 'student-91',
        contactMethod: 'campus chat',
      ),
    ),
    ItemPost(
      id: 'p-007',
      type: PostType.found,
      status: PostStatus.found,
      title: 'Parking access card',
      description:
      'Access card found near the student center vending machines.',
      category: ItemCategory.cards,
      photoUrl: '',
      location: campusLocations[3],
      dateTime: now.subtract(const Duration(days: 4)),
      createdBy: const Poster(
        userId: 'staff-17',
        contactMethod: 'front desk',
      ),
    ),
    ItemPost(
      id: 'p-008',
      type: PostType.found,
      status: PostStatus.found,
      title: 'Small keychain',
      description: 'Keychain found outside the engineering lab staircase.',
      category: ItemCategory.keys,
      photoUrl: '',
      location: campusLocations[1],
      dateTime: now.subtract(const Duration(days: 6, hours: 5)),
      createdBy: const Poster(
        userId: 'student-11',
        contactMethod: 'campus chat',
      ),
    ),
    ItemPost(
      id: 'p-009',
      type: PostType.lost,
      status: PostStatus.lost,
      title: 'Gray laptop sleeve',
      description: 'Gray sleeve with a charger inside, last seen at the library.',
      category: ItemCategory.electronics,
      photoUrl: '',
      location: campusLocations[2],
      dateTime: now.subtract(const Duration(days: 9)),
      createdBy: const Poster(userId: 'student-64', contactMethod: 'email'),
    ),
    ItemPost(
      id: 'p-010',
      type: PostType.found,
      status: PostStatus.found,
      title: 'Sports bag',
      description: 'Black sports bag found near the science hall courtyard.',
      category: ItemCategory.bag,
      photoUrl: '',
      location: campusLocations[4],
      dateTime: now.subtract(const Duration(days: 13)),
      createdBy: const Poster(
        userId: 'staff-8',
        contactMethod: 'security desk',
      ),
    ),
    ItemPost(
      id: 'p-011',
      type: PostType.lost,
      status: PostStatus.lost,
      title: 'Reusable bottle',
      description: 'Green reusable bottle missing after lunch at student center.',
      category: ItemCategory.other,
      photoUrl: '',
      location: campusLocations[3],
      dateTime: now.subtract(const Duration(days: 18)),
      createdBy: const Poster(
        userId: 'student-38',
        contactMethod: 'campus chat',
      ),
    ),
    ItemPost(
      id: 'p-012',
      type: PostType.found,
      status: PostStatus.recovered,
      title: 'Dorm room keys',
      description: 'Dorm keys were returned to the housing office.',
      category: ItemCategory.keys,
      photoUrl: '',
      location: campusLocations[0],
      dateTime: now.subtract(const Duration(days: 24)),
      createdBy: const Poster(
        userId: 'housing-1',
        contactMethod: 'housing office',
      ),
    ),
  ];
}
