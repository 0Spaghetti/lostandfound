import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../data/chat_thread_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/safety_widgets.dart';
import '../profile/profile_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.itemId,
    required this.otherUserId,
    required this.strings,
    this.itemTitle,
    this.itemPhotoUrl,
    this.itemCategory = ItemCategory.other,
    this.onOpenItemDetails,
  });

  final String threadId;
  final String itemId;
  final String otherUserId;
  final AppStrings strings;
  final String? itemTitle;
  final String? itemPhotoUrl;
  final ItemCategory itemCategory;
  final Future<void> Function()? onOpenItemDetails;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _sendingAttachment = false;

  ChatThread? get _thread => ref.watch(chatThreadRepositoryProvider).threadById(widget.threadId);

  List<ChatMessage> get _messages => _thread?.messages ?? const [];

  bool get _loading => !ref.watch(chatThreadRepositoryProvider).isLoaded;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(chatThreadRepositoryProvider).markRead(widget.threadId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendMessage(text: text);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_sendingAttachment) return;
    final attachmentLabel = widget.strings.imageAttachment;
    setState(() => _sendingAttachment = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1200,
      );
      if (image == null) return;
      await _sendMessage(text: attachmentLabel, attachmentPath: image.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.couldNotAttachImage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingAttachment = false);
    }
  }

  Future<void> _sendMessage({
    required String text,
    String? attachmentPath,
    String? retryForMessageId,
  }) async {
    await ref.read(chatThreadRepositoryProvider).sendMessage(
      threadId: widget.threadId,
      text: text,
      attachmentPath: attachmentPath,
      retryForMessageId: retryForMessageId,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _retryMessage(ChatMessage message) async {
    await _sendMessage(
      text: message.text,
      attachmentPath: message.attachmentPath,
      retryForMessageId: message.id,
    );
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final canDelete = message.isMine(ref.read(chatThreadRepositoryProvider).currentUserId);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(widget.strings.copy),
                onTap: () => Navigator.pop(context, _MessageAction.copy),
              ),
              if (canDelete)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE9435A),
                  ),
                  title: Text(
                    widget.strings.delete,
                    style: const TextStyle(color: Color(0xFFE9435A)),
                  ),
                  onTap: () => Navigator.pop(context, _MessageAction.delete),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == _MessageAction.copy) {
      final text = message.text.isEmpty
          ? widget.strings.imageAttachment
          : message.text;
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.messageCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (action == _MessageAction.delete &&
        message.isMine(ref.read(chatThreadRepositoryProvider).currentUserId)) {
      await ref.read(chatThreadRepositoryProvider).deleteMessage(widget.threadId, message.id);
    }
  }

  Future<void> _confirmSafetyAction(_ChatMenuAction action) async {
    final title = action == _ChatMenuAction.report
        ? widget.strings.reportConversationTitle
        : widget.strings.blockUserTitle;
    final body = action == _ChatMenuAction.report
        ? widget.strings.reportConversationBody
        : widget.strings.blockUserBody;
    final confirmLabel = action == _ChatMenuAction.report
        ? widget.strings.report
        : widget.strings.block;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == _ChatMenuAction.report
              ? widget.strings.conversationReported
              : widget.strings.userBlocked,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).maybePop();
  }

  String get _itemTitle {
    final title = widget.itemTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return '${widget.strings.details} ${widget.itemId}';
  }

  void _viewParticipantProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          strings: widget.strings,
          userId: widget.otherUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typing = ref.watch(chatThreadRepositoryProvider).isTyping(widget.threadId);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icon(Icons.arrow_back_ios_new_rounded, semanticLabel: MaterialLocalizations.of(context).backButtonTooltip),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: _ChatTitle(
          title: displayChatName(
            widget.otherUserId,
            widget.strings.campusMember,
          ),
          subtitle: widget.strings.aboutItem(_itemTitle),
          photoUrl: widget.itemPhotoUrl ?? '',
          category: widget.itemCategory,
          onTap: widget.onOpenItemDetails,
          onProfileTap: _viewParticipantProfile,
        ),
        actions: [
          PopupMenuButton<_ChatMenuAction>(
            tooltip: widget.strings.menu,
            onSelected: (action) => unawaited(_confirmSafetyAction(action)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ChatMenuAction.report,
                child: _MenuItem(
                  icon: Icons.flag_outlined,
                  label: widget.strings.report,
                ),
              ),
              PopupMenuItem(
                value: _ChatMenuAction.block,
                child: _MenuItem(
                  icon: Icons.block_rounded,
                  label: widget.strings.block,
                  color: const Color(0xFFE9435A),
                ),
              ),
            ],
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE4EAF3)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageBody(typing: typing)),
            _Composer(
              controller: _messageController,
              hintText: widget.strings.typeMessage,
              sendingAttachment: _sendingAttachment,
              onAttachImage: () => unawaited(_pickImage(ImageSource.gallery)),
              onCaptureImage: () => unawaited(_pickImage(ImageSource.camera)),
              onSend: () => unawaited(_sendText()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBody({required bool typing}) {
    if (_loading) {
      return const _MessagesLoadingState();
    }

    if (_thread == null || _messages.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          _PinnedItemContextCard(
            title: _itemTitle,
            photoUrl: widget.itemPhotoUrl ?? '',
            category: widget.itemCategory,
            itemType: _thread?.itemType ?? PostType.found,
            locationLabel: _thread?.itemLocationLabel ?? '',
            itemDateTime: _thread?.itemDateTime ?? DateTime.now(),
            strings: widget.strings,
            onTap: widget.onOpenItemDetails,
          ),
          if (_thread?.itemType == PostType.found)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: SafetyGuidanceCard(
                category: widget.itemCategory,
                strings: widget.strings,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: _SafetyNote(),
            ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
          _EmptyConversation(strings: widget.strings),
        ],
      );
    }

    final rows = <Widget>[
      _PinnedItemContextCard(
        title: _itemTitle,
        photoUrl: widget.itemPhotoUrl ?? '',
        category: widget.itemCategory,
        itemType: _thread?.itemType ?? PostType.found,
        locationLabel: _thread?.itemLocationLabel ?? '',
        itemDateTime: _thread?.itemDateTime ?? DateTime.now(),
        strings: widget.strings,
        onTap: widget.onOpenItemDetails,
      ),
      if (_thread?.itemType == PostType.found)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 2),
          child: SafetyGuidanceCard(
            category: widget.itemCategory,
            strings: widget.strings,
          ),
        )
      else
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 2),
          child: _SafetyNote(),
        ),
    ];

    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      final previous = index == 0 ? null : _messages[index - 1];
      if (_needsTimestamp(previous, message)) {
        rows.add(_TimestampSeparator(dateTime: message.createdAt));
      }
      rows.add(
        _MessageBubble(
          key: ValueKey(message.id),
          message: message,
          otherUserId: widget.otherUserId,
          currentUserId: ref.read(chatThreadRepositoryProvider).currentUserId,
          onLongPress: () => unawaited(_showMessageActions(message)),
          onRetry: message.status == ChatMessageStatus.failed
              ? () => unawaited(_retryMessage(message))
              : null,
        ),
      );
    }

    if (typing) {
      rows.add(
        _TypingBubble(
          otherUserId: widget.otherUserId,
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      children: rows,
    );
  }
}

class _PinnedItemContextCard extends StatelessWidget {
  const _PinnedItemContextCard({
    required this.title,
    required this.photoUrl,
    required this.category,
    required this.itemType,
    required this.locationLabel,
    required this.itemDateTime,
    required this.strings,
    required this.onTap,
  });

  final String title;
  final String photoUrl;
  final ItemCategory category;
  final PostType itemType;
  final String locationLabel;
  final DateTime itemDateTime;
  final AppStrings strings;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final statusLabel = itemType == PostType.lost
        ? strings.lost
        : strings.found;
    final statusColor = itemType == PostType.lost
        ? const Color(0xFFE9435A)
        : const Color(0xFF15803D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: onTap == null ? null : () => unawaited(onTap!()),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0x0D0A2758)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PinnedContextMetaLine(
                      icon: Icons.location_on_outlined,
                      text: locationLabel.isEmpty
                          ? categoryLabel(category, strings)
                          : campusLocationLabelText(locationLabel, strings),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 5),
                    _PinnedContextMetaLine(
                      icon: Icons.calendar_month_outlined,
                      text: longDate(itemDateTime, strings),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PhotoPreview(
                photoUrl: photoUrl,
                category: category,
                size: 72,
                iconSize: 30,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedContextMetaLine extends StatelessWidget {
  const _PinnedContextMetaLine({
    required this.icon,
    required this.text,
    required this.fontSize,
    required this.fontWeight,
  });

  final IconData icon;
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0796A8)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatTitle extends StatelessWidget {
  const _ChatTitle({
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.category,
    required this.onTap,
    required this.onProfileTap,
  });

  final String title;
  final String subtitle;
  final String photoUrl;
  final ItemCategory category;
  final Future<void> Function()? onTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: PhotoPreview(
                photoUrl: photoUrl,
                category: category,
                size: 44,
                iconSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (onTap != null)
                  GestureDetector(
                    onTap: () => unawaited(onTap!()),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F2C3A) : const Color(0xFFEAF7F9);
    final border = isDark ? const Color(0xFF163E51) : const Color(0xFFD4EFF3);
    final iconColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF087889);
    final textColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0B6371);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.of(context).chatSafetyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.otherUserId,
    required this.currentUserId,
    required this.onLongPress,
    required this.onRetry,
  });

  final ChatMessage message;
  final String otherUserId;
  final String currentUserId;
  final VoidCallback onLongPress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine(currentUserId);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(mine ? 22 : 6),
      bottomRight: Radius.circular(mine ? 6 : 22),
    );
    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding: EdgeInsets.all(message.attachmentPath == null ? 14 : 8),
            decoration: BoxDecoration(
              gradient: mine
                  ? const LinearGradient(
                      colors: [Color(0xFF1C63E8), Color(0xFF123EBD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: mine ? null : Theme.of(context).cardColor,
              borderRadius: radius,
              border: mine ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0x0D0A2758)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.attachmentPath != null) ...[
                  _BubbleImage(path: message.attachmentPath!),
                  if (message.text.isNotEmpty) const SizedBox(height: 8),
                ],
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: mine ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          _MessageMeta(message: message, mine: mine, onRetry: onRetry),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            UserAvatar(
              userId: otherUserId,
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.file(
        File(path),
        width: 210,
        height: 145,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 210,
            height: 130,
            color: const Color(0xFFE8EEF7),
            child: const Icon(
              Icons.image_outlined,
              color: Color(0xFF6C7892),
              size: 42,
            ),
          );
        },
      ),
    );
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({
    required this.message,
    required this.mine,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool mine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(message.createdAt);
    final color = message.status == ChatMessageStatus.failed
        ? const Color(0xFFE9435A)
        : const Color(0xFF7B879D);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (mine) ...[
          const SizedBox(width: 5),
          if (message.status == ChatMessageStatus.sending)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            )
          else if (message.status == ChatMessageStatus.delivered)
            const Icon(
              Icons.done_all_rounded,
              color: Color(0xFF1C63E8),
              size: 17,
            )
          else ...[
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE9435A),
              size: 16,
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                ),
                child: Text(AppStrings.of(context).retry),
              ),
          ],
        ],
      ],
    );
  }
}

class _TimestampSeparator extends StatelessWidget {
  const _TimestampSeparator({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sameDay =
        now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    final label = sameDay
        ? '${AppStrings.of(context).today}, ${DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(dateTime)}'
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).add_jm().format(dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6C7892),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.otherUserId});

  final String otherUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          UserAvatar(
            userId: otherUserId,
            size: 32,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(22),
              ),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0x0D0A2758)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const _PulsingDots(),
          ),
        ],
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 28,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              double progress = _controller.value - delay;
              if (progress < 0) progress += 1.0;
              final double value = (1.0 - (progress - 0.5).abs() * 2.0).clamp(0.0, 1.0);
              final double translation = -5.0 * value;
              return Transform.translate(
                offset: Offset(0, translation),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.4 + 0.6 * value),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hintText,
    required this.sendingAttachment,
    required this.onAttachImage,
    required this.onCaptureImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final bool sendingAttachment;
  final VoidCallback onAttachImage;
  final VoidCallback onCaptureImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0x0F0A2758)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ComposerIconButton(
              tooltip: AppStrings.of(context).attachImage,
              onPressed: sendingAttachment ? null : onAttachImage,
              icon: Icons.attach_file_rounded,
              loading: sendingAttachment,
            ),
            const SizedBox(width: 8),
            _ComposerIconButton(
              tooltip: AppStrings.of(context).camera,
              onPressed: sendingAttachment ? null : onCaptureImage,
              icon: Icons.photo_camera_outlined,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              height: 42,
              child: IconButton.filled(
                tooltip: AppStrings.of(context).send,
                onPressed: onSend,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF123EBD),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                icon: Icon(Icons.send_rounded, size: 20, semanticLabel: AppStrings.of(context).send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.loading = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 42,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF475569),
          disabledForegroundColor: const Color(0xFF94A3B8),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 22),
      ),
    );
  }
}

class _MessagesLoadingState extends StatelessWidget {
  const _MessagesLoadingState();

  @override
  Widget build(BuildContext context) {
    Widget bubble({required bool mine, required double width}) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: width,
          height: 58,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFD9E6FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: mine ? null : Border.all(color: const Color(0xFFE4EAF3)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      children: [
        const _SafetyNote(),
        const SizedBox(height: 18),
        bubble(mine: true, width: 270),
        bubble(mine: false, width: 210),
        bubble(mine: true, width: 245),
        bubble(mine: false, width: 260),
      ],
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFE8EEF7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.forum_outlined,
            size: 46,
            color: Color(0xFF102A5C),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.startConversation,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF0A2758),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.startConversationHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF12233D);
    return Row(
      children: [
        Icon(icon, size: 19, color: effectiveColor),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: effectiveColor)),
      ],
    );
  }
}

enum _MessageAction { copy, delete }

enum _ChatMenuAction { report, block }

bool _needsTimestamp(ChatMessage? previous, ChatMessage current) {
  if (previous == null) return true;
  final gap = current.createdAt.difference(previous.createdAt);
  return gap.inMinutes.abs() >= 20 ||
      previous.createdAt.day != current.createdAt.day;
}

String displayChatName(String raw, String fallback) {
  final name = raw.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (name.isEmpty) return fallback;
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String chatInitials(String raw, String fallback) {
  final name = displayChatName(raw, fallback);
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
