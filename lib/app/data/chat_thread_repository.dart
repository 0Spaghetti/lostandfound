import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

enum ChatMessageStatus { sending, delivered, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.status,
    this.attachmentPath,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final String? attachmentPath;

  bool isMine(String currentUserId) => senderId == currentUserId;

  ChatMessage copyWith({ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      text: text,
      createdAt: createdAt,
      status: status ?? this.status,
      attachmentPath: attachmentPath,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: ChatMessageStatus.values.byName(
        json['status'] as String? ?? ChatMessageStatus.delivered.name,
      ),
      attachmentPath: json['attachmentPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'attachmentPath': attachmentPath,
    };
  }
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.itemId,
    required this.participantId,
    required this.itemTitle,
    required this.itemPhotoUrl,
    required this.itemCategory,
    required this.itemType,
    required this.itemLocationLabel,
    required this.itemDateTime,
    required this.updatedAt,
    required this.messages,
    this.unreadCount = 0,
  });

  final String id;
  final String itemId;
  final String participantId;
  final String itemTitle;
  final String itemPhotoUrl;
  final ItemCategory itemCategory;
  final PostType itemType;
  final String itemLocationLabel;
  final DateTime itemDateTime;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final int unreadCount;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  ChatThread copyWith({
    String? itemTitle,
    String? itemPhotoUrl,
    ItemCategory? itemCategory,
    PostType? itemType,
    String? itemLocationLabel,
    DateTime? itemDateTime,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id,
      itemId: itemId,
      participantId: participantId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemPhotoUrl: itemPhotoUrl ?? this.itemPhotoUrl,
      itemCategory: itemCategory ?? this.itemCategory,
      itemType: itemType ?? this.itemType,
      itemLocationLabel: itemLocationLabel ?? this.itemLocationLabel,
      itemDateTime: itemDateTime ?? this.itemDateTime,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      participantId: json['participantId'] as String? ?? '',
      itemTitle: json['itemTitle'] as String? ?? '',
      itemPhotoUrl: json['itemPhotoUrl'] as String? ?? '',
      itemCategory: ItemCategory.values.byName(
        json['itemCategory'] as String? ?? ItemCategory.other.name,
      ),
      itemType: PostType.values.byName(
        json['itemType'] as String? ?? PostType.found.name,
      ),
      itemLocationLabel: json['itemLocationLabel'] as String? ?? '',
      itemDateTime:
          DateTime.tryParse(json['itemDateTime'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'participantId': participantId,
      'itemTitle': itemTitle,
      'itemPhotoUrl': itemPhotoUrl,
      'itemCategory': itemCategory.name,
      'itemType': itemType.name,
      'itemLocationLabel': itemLocationLabel,
      'itemDateTime': itemDateTime.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}

class ChatThreadRepository extends ChangeNotifier {
  ChatThreadRepository({this.currentUserId = 'current-user'});

  static const _storageKey = 'lost_found_chat_threads_v1';

  final String currentUserId;
  final List<ChatThread> _threads = [];
  final Set<String> _typingThreadIds = {};
  SharedPreferences? _prefs;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<ChatThread> get threads {
    return List.unmodifiable(
      List<ChatThread>.from(_threads)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  bool isTyping(String threadId) => _typingThreadIds.contains(threadId);

  ChatThread? threadById(String threadId) {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) return null;
    return _threads[index];
  }

  ChatThread? threadForItem(String itemId, String participantId) {
    final id = buildThreadKey(itemId, currentUserId, participantId);
    return threadById(id);
  }

  Future<void> load({required List<ItemPost> seedPosts}) async {
    if (_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _threads
        ..clear()
        ..addAll(_seedThreads(seedPosts, DateTime.now()));
      await _save();
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _threads
          ..clear()
          ..addAll(
            decoded.map(
              (entry) =>
                  ChatThread.fromJson(Map<String, dynamic>.from(entry as Map)),
            ),
          );
      } catch (_) {
        _threads
          ..clear()
          ..addAll(_seedThreads(seedPosts, DateTime.now()));
        await _save();
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<ChatThread> openThreadForPost(ItemPost post, String itemTitle) async {
    if (!_loaded) {
      await load(seedPosts: [post]);
    }

    final participantId = post.createdBy.userId == currentUserId
        ? 'campus-support'
        : post.createdBy.userId;
    final id = buildThreadKey(post.id, currentUserId, participantId);
    final index = _threads.indexWhere((thread) => thread.id == id);
    if (index >= 0) {
      _threads[index] = _threads[index].copyWith(
        itemTitle: itemTitle,
        itemPhotoUrl: post.photoUrl,
        itemCategory: post.category,
        itemType: post.type,
        itemLocationLabel: post.location.placeLabel,
        itemDateTime: post.dateTime,
        unreadCount: 0,
      );
      await _save();
      notifyListeners();
      return _threads[index];
    }

    final now = DateTime.now();
    final thread = ChatThread(
      id: id,
      itemId: post.id,
      participantId: participantId,
      itemTitle: itemTitle,
      itemPhotoUrl: post.photoUrl,
      itemCategory: post.category,
      itemType: post.type,
      itemLocationLabel: post.location.placeLabel,
      itemDateTime: post.dateTime,
      updatedAt: now,
      messages: const [],
    );
    _threads.add(thread);
    await _save();
    notifyListeners();
    return thread;
  }

  Future<void> markRead(String threadId) async {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0 || _threads[index].unreadCount == 0) return;
    _threads[index] = _threads[index].copyWith(unreadCount: 0);
    await _save();
    notifyListeners();
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
    String? attachmentPath,
    String? retryForMessageId,
  }) async {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) return;

    final now = DateTime.now();
    final message = ChatMessage(
      id: retryForMessageId ?? 'msg-${now.microsecondsSinceEpoch}',
      senderId: currentUserId,
      text: text,
      createdAt: now,
      status: ChatMessageStatus.sending,
      attachmentPath: attachmentPath,
    );

    _replaceThreadMessage(index, message, retryForMessageId);
    await _save();
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 760));
    final latestIndex = _threads.indexWhere((thread) => thread.id == threadId);
    if (latestIndex < 0) return;

    final shouldFail = text.toLowerCase().contains('fail');
    _updateMessageStatus(
      latestIndex,
      message.id,
      shouldFail ? ChatMessageStatus.failed : ChatMessageStatus.delivered,
    );
    await _save();
    notifyListeners();

    if (!shouldFail) {
      unawaited(_simulateAutoResponse(threadId, message));
    }
  }

  Future<void> deleteMessage(String threadId, String messageId) async {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) return;

    final thread = _threads[index];
    final messages = thread.messages
        .where((message) => message.id != messageId)
        .toList(growable: false);
    _threads[index] = thread.copyWith(
      messages: messages,
      updatedAt: messages.isEmpty ? thread.updatedAt : messages.last.createdAt,
    );
    await _save();
    notifyListeners();
  }

  void _replaceThreadMessage(
    int threadIndex,
    ChatMessage message,
    String? retryForMessageId,
  ) {
    final thread = _threads[threadIndex];
    final messages = List<ChatMessage>.from(thread.messages);
    if (retryForMessageId == null) {
      messages.add(message);
    } else {
      final messageIndex = messages.indexWhere(
        (entry) => entry.id == retryForMessageId,
      );
      if (messageIndex >= 0) {
        messages[messageIndex] = message;
      }
    }
    _threads[threadIndex] = thread.copyWith(
      messages: messages,
      updatedAt: message.createdAt,
    );
  }

  void _updateMessageStatus(
    int threadIndex,
    String messageId,
    ChatMessageStatus status,
  ) {
    final thread = _threads[threadIndex];
    final messages = List<ChatMessage>.from(thread.messages);
    final messageIndex = messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (messageIndex < 0) return;
    messages[messageIndex] = messages[messageIndex].copyWith(status: status);
    _threads[threadIndex] = thread.copyWith(messages: messages);
  }

  Future<void> _simulateAutoResponse(
    String threadId,
    ChatMessage userMessage,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    final typingIndex = _threads.indexWhere((thread) => thread.id == threadId);
    if (typingIndex < 0) return;
    _typingThreadIds.add(threadId);
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1050));
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) return;

    final thread = _threads[index];
    final now = DateTime.now();
    final response = ChatMessage(
      id: 'msg-${now.microsecondsSinceEpoch}',
      senderId: thread.participantId,
      text: _autoResponseFor(thread, userMessage.text),
      createdAt: now,
      status: ChatMessageStatus.delivered,
    );
    _typingThreadIds.remove(threadId);
    _threads[index] = thread.copyWith(
      messages: [...thread.messages, response],
      updatedAt: now,
      unreadCount: thread.unreadCount + 1,
    );
    await _save();
    notifyListeners();
  }

  String _autoResponseFor(ChatThread thread, String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('where') || lower.contains('location')) {
      return thread.itemType == PostType.found
          ? 'I can meet near the reported location. Does the item description match yours?'
          : 'I last had it near that area. I can share a few identifying details.';
    }
    if (lower.contains('photo') || lower.contains('picture')) {
      return 'A clear photo helps. Please compare the color, size, and any unique marks.';
    }

    return switch (thread.itemCategory) {
      ItemCategory.electronics =>
        thread.itemType == PostType.found
            ? 'Please mention the model or any lock-screen detail before pickup.'
            : 'Thanks for checking. I can confirm the device model and case color.',
      ItemCategory.keys =>
        'Can you describe the key ring or any attached tag so we can verify it?',
      ItemCategory.bag =>
        'Please describe one item inside the bag before we arrange handoff.',
      ItemCategory.cards =>
        'For privacy, share only the initials or last digits needed to verify ownership.',
      ItemCategory.other =>
        'Thanks for reaching out. Let us verify one detail before arranging a safe meetup.',
    };
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(_threads.map((thread) => thread.toJson()).toList()),
    );
  }

  List<ChatThread> _seedThreads(List<ItemPost> posts, DateTime now) {
    final candidates = posts
        .where((post) => post.createdBy.userId != currentUserId)
        .take(4)
        .toList();
    if (candidates.isEmpty) return const [];

    return candidates.asMap().entries.map((entry) {
      final offset = entry.key;
      final post = entry.value;
      final participantId = post.createdBy.userId;
      final firstTime = now.subtract(Duration(hours: 5 + offset * 7));
      final secondTime = firstTime.add(const Duration(minutes: 8));
      final messages = [
        ChatMessage(
          id: 'seed-${post.id}-1',
          senderId: participantId,
          text: _seedOpening(post),
          createdAt: firstTime,
          status: ChatMessageStatus.delivered,
        ),
        ChatMessage(
          id: 'seed-${post.id}-2',
          senderId: currentUserId,
          text: _seedReply(post),
          createdAt: secondTime,
          status: ChatMessageStatus.delivered,
        ),
      ];
      return ChatThread(
        id: buildThreadKey(post.id, currentUserId, participantId),
        itemId: post.id,
        participantId: participantId,
        itemTitle: post.title ?? post.description,
        itemPhotoUrl: post.photoUrl,
        itemCategory: post.category,
        itemType: post.type,
        itemLocationLabel: post.location.placeLabel,
        itemDateTime: post.dateTime,
        updatedAt: secondTime,
        unreadCount: offset == 0 ? 1 : 0,
        messages: messages,
      );
    }).toList();
  }

  String _seedOpening(ItemPost post) {
    return post.type == PostType.found
        ? 'Hi, I saw your found report. I think this might be mine.'
        : 'Hi, I may have seen this item near campus. Can you confirm a detail?';
  }

  String _seedReply(ItemPost post) {
    return switch (post.category) {
      ItemCategory.electronics =>
        'Sure. I can verify the case color and the device model.',
      ItemCategory.keys =>
        'Yes, there is a small detail on the key ring I can describe.',
      ItemCategory.bag =>
        'I can confirm one notebook and the color of the zipper.',
      ItemCategory.cards => 'I can share initials only for verification.',
      ItemCategory.other =>
        'Thanks. I can describe it before we arrange pickup.',
    };
  }
}

String buildThreadKey(String itemId, String userA, String userB) {
  final participants = [userA, userB]..sort();
  return '$itemId:${participants.join(':')}';
}
