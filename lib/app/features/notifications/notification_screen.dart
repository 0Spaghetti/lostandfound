import 'package:flutter/material.dart';
import '../../data/chat_thread_repository.dart';
import '../../data/models.dart';
import '../../data/notification_repository.dart';
import '../../shared/l10n/app_strings.dart';
import '../chat/chat_screen.dart';
import '../details/item_details_screen.dart';
import '../profile/profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.repository,
    required this.itemRepository,
    required this.chatRepository,
  });

  final NotificationRepository repository;
  final ItemPostRepository itemRepository;
  final ChatThreadRepository chatRepository;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  AppStrings get strings => AppStrings.of(context);

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Group notifications into Today, Yesterday, and Earlier
  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    for (final notif in list) {
      if (notif.createdAt.isAfter(todayStart)) {
        today.add(notif);
      } else if (notif.createdAt.isAfter(yesterdayStart)) {
        yesterday.add(notif);
      } else {
        earlier.add(notif);
      }
    }

    return {
      'today': today,
      'yesterday': yesterday,
      'earlier': earlier,
    };
  }

  Future<void> _handleTap(NotificationModel notification) async {
    // Mark as read
    await widget.repository.markAsRead(notification.id);

    if (notification.type == NotificationType.system) {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              strings: strings,
              repository: widget.itemRepository,
              chatRepository: widget.chatRepository,
              openEditOnStart: true,
            ),
          ),
        );
      }
      return;
    }

    if (notification.associatedItemId == null) return;

    if (notification.type == NotificationType.chat) {
      final threads = widget.chatRepository.threads;
      final threadIdx = threads.indexWhere((t) => t.id == notification.associatedItemId);
      if (threadIdx >= 0) {
        final thread = threads[threadIdx];
        final postIdx = widget.itemRepository.posts.indexWhere((p) => p.id == thread.itemId);
        final post = postIdx >= 0 ? widget.itemRepository.posts[postIdx] : null;

        if (mounted) {
          await widget.chatRepository.markRead(thread.id);
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                repository: widget.chatRepository,
                itemRepository: widget.itemRepository,
                threadId: thread.id,
                itemId: thread.itemId,
                otherUserId: thread.participantId,
                strings: strings,
                itemTitle: post == null
                    ? thread.itemTitle
                    : itemPostTitle(post, strings),
                itemPhotoUrl: post?.photoUrl ?? thread.itemPhotoUrl,
                itemCategory: post?.category ?? thread.itemCategory,
                onOpenItemDetails: post == null
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(
                              postId: post.id,
                              repository: widget.itemRepository,
                              chatRepository: widget.chatRepository,
                              strings: strings,
                              initialPost: post,
                            ),
                          ),
                        );
                      },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.itemDeletedMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      final index = widget.itemRepository.posts.indexWhere((p) => p.id == notification.associatedItemId);
      if (index >= 0) {
        final post = widget.itemRepository.posts[index];
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsScreen(
                postId: post.id,
                repository: widget.itemRepository,
                chatRepository: widget.chatRepository,
                strings: strings,
                initialPost: post,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.itemDeletedMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _confirmClearAll() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(strings.clearAllConfirm),
            content: Text(strings.clearAllConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.repository.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.allNotificationsCleared),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(strings.delete),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNotifs = widget.repository.notifications;
    final grouped = _groupNotifications(allNotifs);

    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            strings.notifications,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: allNotifs.isEmpty
              ? null
              : [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'read') {
                        await widget.repository.markAllAsRead();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.allNotificationsMarkedRead),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } else if (value == 'clear') {
                        _confirmClearAll();
                      }
                    },
                    icon: const Icon(Icons.more_vert_rounded),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            const Icon(Icons.mark_chat_read_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(strings.markAllRead),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_sweep_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.clearAll,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
        ),
        body: allNotifs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.noNotifications,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.notificationsEmptyHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            strings.home,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (grouped['today']!.isNotEmpty) ...[
                    _buildSectionHeader(strings.today),
                    ...grouped['today']!.map((n) => _buildNotificationCard(n)),
                  ],
                  if (grouped['yesterday']!.isNotEmpty) ...[
                    _buildSectionHeader(strings.yesterday),
                    ...grouped['yesterday']!.map((n) => _buildNotificationCard(n)),
                  ],
                  if (grouped['earlier']!.isNotEmpty) ...[
                    _buildSectionHeader(
                      _arabic ? 'سابقاً' : 'Earlier',
                    ),
                    ...grouped['earlier']!.map((n) => _buildNotificationCard(n)),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4, right: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glowing types gradients and icons
    late final Gradient gradient;
    late final IconData icon;

    switch (notification.type) {
      case NotificationType.match:
        gradient = const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.auto_awesome_rounded;
        break;
      case NotificationType.newPost:
        gradient = const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.campaign_rounded;
        break;
      case NotificationType.chat:
        gradient = const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.chat_bubble_rounded;
        break;
      case NotificationType.system:
        gradient = const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon = Icons.verified_user_rounded;
        break;
    }

    final accentColor = gradient.colors.last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) async {
          await widget.repository.deleteNotification(notification.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.notificationDeleted),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        child: InkWell(
          onTap: () => _handleTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Standard Container card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Theme.of(context).cardColor
                      : (isDark ? const Color(0x1F2D7DF0) : const Color(0xFFF0F6FF)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notification.isRead
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                        : (isDark ? const Color(0xFF1D4ED8) : const Color(0xFFDBEAFE)),
                    width: notification.isRead ? 1 : 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notificationTitle(notification, strings),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: notification.isRead ? FontWeight.w800 : FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                relativeTime(notification.createdAt, strings),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: notification.isRead
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF1D4ED8),
                                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notificationBody(notification, strings),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Glass Accent border for unread cards (RTL friendly)
              if (!notification.isRead)
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  start: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),

              // Small unread dot
              if (!notification.isRead)
                PositionedDirectional(
                  top: 14,
                  end: 14,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D4ED8),
                      shape: BoxShape.circle,
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
