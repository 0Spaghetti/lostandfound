import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { match, newPost, chat, system }

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.associatedItemId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String? associatedItemId;

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
      associatedItemId: associatedItemId,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      type: NotificationType.values.byName(json['type'] as String? ?? 'system'),
      isRead: json['isRead'] as bool? ?? false,
      associatedItemId: json['associatedItemId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'associatedItemId': associatedItemId,
    };
  }
}

class NotificationRepository extends ChangeNotifier {
  static const _storageKey = 'lost_found_notifications_v1';
  final List<NotificationModel> _notifications = [];
  SharedPreferences? _prefs;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _notifications.addAll(_buildSeedNotifications());
      await _save();
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _notifications
        ..clear()
        ..addAll(
          decoded.map(
            (entry) => NotificationModel.fromJson(Map<String, dynamic>.from(entry as Map)),
          ),
        );
    }
    _loaded = true;
    notifyListeners();
  }

  List<NotificationModel> _buildSeedNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'n-001',
        title: 'Potential Match Found',
        body: 'Someone found a blue backpack near Engineering College matching your report! Tap to view details.',
        createdAt: now.subtract(const Duration(minutes: 15)),
        type: NotificationType.match,
        associatedItemId: 'p-002', // Matches blue backpack ID
      ),
      NotificationModel(
        id: 'n-002',
        title: 'New Item Near You',
        body: 'A "Wireless earbuds" was posted near your preferred location: Central Library.',
        createdAt: now.subtract(const Duration(hours: 2)),
        type: NotificationType.newPost,
        associatedItemId: 'p-001', // Matches wireless earbuds ID
      ),
      NotificationModel(
        id: 'n-003',
        title: 'New Message',
        body: 'Staff 42 sent you a message about the earbuds you inquired about.',
        createdAt: now.subtract(const Duration(days: 1)),
        type: NotificationType.chat,
        associatedItemId: 'p-001:current-user:staff-42',
      ),
      NotificationModel(
        id: 'n-004',
        title: 'Welcome to Lost & Found!',
        body: 'Verify your profile and customize notification settings to stay updated.',
        createdAt: now.subtract(const Duration(days: 3)),
        type: NotificationType.system,
      ),
    ];
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    await _save();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _save();
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? associatedItemId,
  }) async {
    final newNotif = NotificationModel(
      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: type,
      associatedItemId: associatedItemId,
    );
    _notifications.insert(0, newNotif);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
  }
}
