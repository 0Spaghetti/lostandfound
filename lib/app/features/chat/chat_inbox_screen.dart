import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_thread_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';
import '../details/item_details_screen.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({
    super.key,
    required this.strings,
    required this.onLanguageToggle,
    required this.languageLabel,
    required this.onOpenExploreFeed,
    this.onNotificationsTap,
    this.hasUnreadNotifications = false,
  });

  final AppStrings strings;
  final VoidCallback onLanguageToggle;
  final String languageLabel;
  final VoidCallback onOpenExploreFeed;
  final VoidCallback? onNotificationsTap;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRepository = ref.watch(chatThreadRepositoryProvider);
    final threads = chatRepository.threads;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: HeaderBar(
                title: strings.chat,
                subtitle: strings.appName,
                onLanguageToggle: onLanguageToggle,
                languageLabel: languageLabel,
                onNotificationsTap: onNotificationsTap,
                hasUnreadNotifications: hasUnreadNotifications,
              ),
            ),
          ),
          if (!chatRepository.isLoaded)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (threads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: strings.chat,
                subtitle: strings.chatsEmptyHint,
                resetLabel: strings.home,
                onReset: onOpenExploreFeed,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 104),
              sliver: SliverList.separated(
                itemCount: threads.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return _ChatThreadCard(
                    thread: thread,
                    strings: strings,
                    typing: chatRepository.isTyping(thread.id),
                    onTap: () => _openThread(context, ref, thread),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openThread(BuildContext context, WidgetRef ref, ChatThread thread) async {
    final chatRepository = ref.read(chatThreadRepositoryProvider);
    await chatRepository.markRead(thread.id);
    if (!context.mounted) return;

    final post = _findPost(ref, thread.itemId);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
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

  ItemPost? _findPost(WidgetRef ref, String itemId) {
    final itemRepository = ref.read(itemPostRepositoryProvider);
    final index = itemRepository.posts.indexWhere((post) => post.id == itemId);
    if (index < 0) return null;
    return itemRepository.posts[index];
  }
}

class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({
    required this.thread,
    required this.strings,
    required this.typing,
    required this.onTap,
  });

  final ChatThread thread;
  final AppStrings strings;
  final bool typing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = thread.lastMessage;
    final snippet = typing
        ? strings.typeMessage.replaceAll('...', '')
        : lastMessage?.text ?? strings.startConversation;
    final unread = thread.unreadCount > 0;

    return Semantics(
      button: true,
      label:
          '${displayChatName(thread.participantId, strings.campusMember)}, '
          '${thread.itemTitle}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  PhotoPreview(
                    photoUrl: thread.itemPhotoUrl,
                    category: thread.itemCategory,
                    size: 58,
                    iconSize: 26,
                    borderRadius: 14,
                  ),
                  PositionedDirectional(
                    end: -5,
                    bottom: -5,
                    child: UserAvatar(
                      userId: thread.participantId,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayChatName(
                              thread.participantId,
                              strings.campusMember,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: unread
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                ),
                          ),
                        ),
                        Text(
                          relativeTime(thread.updatedAt, strings),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: unread
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: typing
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF6B7280),
                                  fontWeight: unread
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              thread.unreadCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
