import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return {'lat': lat, 'lng': lng, 'placeLabel': placeLabel};
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
    return {'userId': userId, 'contactMethod': contactMethod};
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
    this.itemColor,
    this.itemBrand,
    this.distinguishingDetails,
    this.locationDetail,
    this.hasReward = false,
    this.isUrgent = false,
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
  final String? itemColor;
  final String? itemBrand;
  final String? distinguishingDetails;
  final String? locationDetail;
  final bool hasReward;
  final bool isUrgent;

  ItemPost copyWith({PostStatus? status, bool? isFavorite, String? photoUrl}) {
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
      itemColor: itemColor,
      itemBrand: itemBrand,
      distinguishingDetails: distinguishingDetails,
      locationDetail: locationDetail,
      hasReward: hasReward,
      isUrgent: isUrgent,
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
      itemColor: json['itemColor'] as String?,
      itemBrand: json['itemBrand'] as String?,
      distinguishingDetails: json['distinguishingDetails'] as String?,
      locationDetail: json['locationDetail'] as String?,
      hasReward: json['hasReward'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
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
      'itemColor': itemColor,
      'itemBrand': itemBrand,
      'distinguishingDetails': distinguishingDetails,
      'locationDetail': locationDetail,
      'hasReward': hasReward,
      'isUrgent': isUrgent,
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
            (entry) =>
                ItemPost.fromJson(Map<String, dynamic>.from(entry as Map)),
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

  Future<void> updatePost(ItemPost post) async {
    final index = _posts.indexWhere((entry) => entry.id == post.id);
    if (index < 0) return;
    _posts[index] = post;
    await _save();
    notifyListeners();
  }

  Future<void> updateStatus(String id, PostStatus status) async {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index < 0) return;
    _posts[index] = _posts[index].copyWith(status: status);
    await _save();
    notifyListeners();
  }

  Future<void> deletePost(String id) async {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index < 0) return;
    _posts.removeAt(index);
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
    this.status,
    this.category,
    this.dateFilter = DateFilter.any,
    this.locationLabel,
  });

  final PostStatus? status;
  final ItemCategory? category;
  final DateFilter dateFilter;
  final String? locationLabel;

  bool get hasActiveFilters {
    return status != null ||
        category != null ||
        dateFilter != DateFilter.any ||
        (locationLabel != null && locationLabel!.isNotEmpty);
  }

  FilterState copyWith({
    PostStatus? status,
    bool clearStatus = false,
    ItemCategory? category,
    bool clearCategory = false,
    DateFilter? dateFilter,
    String? locationLabel,
    bool clearLocation = false,
  }) {
    return FilterState(
      status: clearStatus ? null : status ?? this.status,
      category: clearCategory ? null : category ?? this.category,
      dateFilter: dateFilter ?? this.dateFilter,
      locationLabel: clearLocation ? null : locationLabel ?? this.locationLabel,
    );
  }
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
      createdBy: const Poster(userId: 'staff-17', contactMethod: 'front desk'),
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
      description:
          'Gray sleeve with a charger inside, last seen at the library.',
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
      description:
          'Green reusable bottle missing after lunch at student center.',
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
