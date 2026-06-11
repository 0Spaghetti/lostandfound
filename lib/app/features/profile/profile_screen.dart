import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models.dart';
import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../auth/auth_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.strings,
    this.userId, // Null or 'current-user' means Personal Mode; other means Public Mode!
    this.openEditOnStart = false,
  });

  final AppStrings strings;
  final String? userId;
  final bool openEditOnStart;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = false;

  bool get _signedIn => ref.watch(authProvider).isAuthenticated;

  bool get _isPersonal =>
      widget.userId == null || widget.userId == 'current-user';

  String get _targetUserId =>
      _isPersonal ? 'current-user' : widget.userId!;

  bool get _arabic => ref.watch(localeProvider).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfileData());
    if (widget.openEditOnStart && _isPersonal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditProfileDialog();
      });
    }
  }

  Future<void> _loadProfileData() async {
    // Initial profile loading handled by providers
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    _showSnack(widget.strings.signedOut);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showEditProfileDialog() {
    if (!_signedIn) {
      _showSnack(
        _arabic
            ? 'سجل الدخول لتعديل الملف'
            : 'Please sign in to edit your profile.',
      );
      return;
    }
    final nameController = TextEditingController(text: ref.read(profileNameProvider));
    final emailController = TextEditingController(text: ref.read(profileEmailProvider));

    showDialog<void>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              _arabic ? 'تعديل الملف الشخصي' : 'Edit Profile',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: _arabic ? 'الاسم' : 'Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: _arabic ? 'البريد الإلكتروني' : 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.strings.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  if (name.isEmpty || email.isEmpty) {
                    _showSnack(
                      _arabic ? 'الرجاء ملء جميع الحقول' : 'Please fill all fields',
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await ref.read(profileNameProvider.notifier).setName(name);
                  await ref.read(profileEmailProvider.notifier).setEmail(email);
                  await HapticFeedback.mediumImpact();
                  _showSnack(
                    _arabic
                        ? 'تم تحديث الملف الشخصي'
                        : 'Profile updated successfully!',
                  );
                },
                child: Text(widget.strings.saveChanges),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePhoto() async {
    if (!_signedIn) {
      _showSnack(
        _arabic
            ? 'سجل الدخول لتغيير الصورة'
            : 'Please sign in to change your photo.',
      );
      return;
    }
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
          child: RoundedSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Text(
                    _arabic ? 'صورة الملف الشخصي' : 'Profile Picture',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(_arabic ? 'الكاميرا' : widget.strings.camera, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(_arabic ? 'المعرض' : widget.strings.gallery, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                const Divider(height: 24, indent: 18, endIndent: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Text(
                    _arabic ? 'اختر شخصية رقمية مميزة:' : 'Choose a premium preset avatar:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: avatarPresets.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final preset = avatarPresets[index];
                      final currentAvatar = ref.watch(profileAvatarProvider);
                      final isSelected = currentAvatar == preset.id;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context, preset.id);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: preset.gradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: preset.gradient.colors.last.withValues(alpha: isSelected ? 0.4 : 0.15),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(preset.emoji, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _arabic
                                          ? (preset.id == 'avatar_student'
                                              ? 'طالب'
                                              : preset.id == 'avatar_tech'
                                                  ? 'تقني'
                                                  : preset.id == 'avatar_security'
                                                      ? 'أمن'
                                                      : 'دليل')
                                          : (preset.id == 'avatar_student'
                                              ? 'Student'
                                              : preset.id == 'avatar_tech'
                                                  ? 'Tech'
                                                  : preset.id == 'avatar_security'
                                                      ? 'Security'
                                                      : 'Guide'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;

    if (choice.startsWith('avatar_')) {
      await ref.read(profileAvatarProvider.notifier).setAvatar(choice);
      _showSnack(
        _arabic
            ? 'تم تحديث الصورة الشخصية!'
            : 'Avatar updated successfully!',
      );
      return;
    }

    // Capture photo from camera or gallery
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      final dataUri = dataUriFromBytes(bytes);
      await ref.read(profileAvatarProvider.notifier).setAvatar(dataUri);
      _showSnack(
        _arabic
            ? 'تم تحديث الصورة الشخصية!'
            : 'Avatar updated successfully!',
      );
    } catch (_) {
      _showSnack(
        _arabic ? 'عذراً، تعذر تحميل الصورة' : 'Could not attach image',
      );
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          strings: widget.strings,
        ),
      ),
    );
  }

  Future<void> _contactUser() async {
    final posts = ref.read(itemPostRepositoryProvider).posts
        .where((p) => p.createdBy.userId == _targetUserId)
        .toList();
    if (posts.isEmpty) {
      _showSnack(
        _arabic
            ? 'لا يوجد بلاغات نشطة للتواصل بخصوصها'
            : 'No active reports to contact about.',
      );
      return;
    }
    final post = posts.first;
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allPosts = ref.watch(itemPostRepositoryProvider).posts;
    final userPosts =
        allPosts.where((p) => p.createdBy.userId == _targetUserId).toList();

    final totalCount = userPosts.length;
    final recoveredCount =
        userPosts.where((p) => p.status == PostStatus.recovered).length;
    final lostCount = userPosts
        .where((p) => p.type == PostType.lost && p.status == PostStatus.lost)
        .length;
    final foundCount = userPosts
        .where((p) => p.type == PostType.found && p.status == PostStatus.found)
        .length;

    // Achievements calculation
    final hasFirstReport = totalCount >= 1;
    final hasRecoveredFive = recoveredCount >= 1; // Unlocks dynamic reunion master
    final hasActiveMember = totalCount >= 3;

    final refName = ref.watch(profileNameProvider);
    final refEmail = ref.watch(profileEmailProvider);

    final name = _isPersonal
        ? (_signedIn ? (refName.isEmpty ? widget.strings.demoUserName : refName) : widget.strings.continueAsGuest)
        : _targetUserId.replaceAll(RegExp(r'[_-]+'), ' ').trim();

    final email = _isPersonal
        ? (_signedIn ? (refEmail.isEmpty ? widget.strings.demoUserEmail : refEmail) : widget.strings.signIn)
        : '${_targetUserId.replaceAll(RegExp(r'[_-]+'), '')}@uni.edu';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            _isPersonal
                ? (_arabic ? 'الملف الشخصي' : 'My Profile')
                : (_arabic ? 'الملف التعريفي' : 'User Profile'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: !_isPersonal
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: [
            if (_isPersonal)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: _openSettings,
                tooltip: widget.strings.settings,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // User Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : const Color(0x060A2758),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      UserAvatar(
                        userId: _targetUserId,
                        size: 76,
                      ),
                      if (_isPersonal && _signedIn)
                        PositionedDirectional(
                          bottom: 0,
                          end: 0,
                          child: InkWell(
                            onTap: _changePhoto,
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.strings.demoUniversity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Header
            Text(
              _arabic ? 'الإحصائيات' : 'User Statistics',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0A2758),
              ),
            ),
            const SizedBox(height: 12),

            // Statistics Grid Layout
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: _arabic ? 'إجمالي البلاغات' : 'Total Posts',
                  value: totalCount.toString(),
                  icon: Icons.list_alt_rounded,
                  color: const Color(0xFF1D4ED8),
                ),
                _buildStatCard(
                  title: _arabic ? 'تم استردادها' : 'Recovered Items',
                  value: recoveredCount.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF15A56E),
                ),
                _buildStatCard(
                  title: _arabic ? 'أغراض مفقودة' : 'Lost Items',
                  value: lostCount.toString(),
                  icon: Icons.info_outline_rounded,
                  color: const Color(0xFFE9435A),
                ),
                _buildStatCard(
                  title: _arabic ? 'أغراض موجودة' : 'Found Items',
                  value: foundCount.toString(),
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFE2B84C),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Achievements Header
            Text(
              _arabic ? 'الإنجازات والميداليات' : 'Community Achievements',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0A2758),
              ),
            ),
            const SizedBox(height: 12),

            // Achievements Row Carousel
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildAchievementBadge(
                    title: _arabic ? 'البلاغ الأول' : 'First Report',
                    subtitle: _arabic ? 'نشر أول غرض' : 'Posted first item',
                    emoji: '🏆',
                    unlocked: hasFirstReport,
                  ),
                  const SizedBox(width: 12),
                  _buildAchievementBadge(
                    title: _arabic ? 'سفير الم شمل' : 'Reunion Master',
                    subtitle: _arabic ? 'أعاد غرض مفقود' : 'Recovered an item',
                    emoji: '🤝',
                    unlocked: hasRecoveredFive,
                  ),
                  const SizedBox(width: 12),
                  _buildAchievementBadge(
                    title: _arabic ? 'عضو نشط' : 'Active Member',
                    subtitle: _arabic ? '٣ بلاغات نشطة' : '3+ total posts',
                    emoji: '🌟',
                    unlocked: hasActiveMember,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Header
            Text(
              _arabic ? 'إجراءات سريعة' : 'Quick Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0A2758),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Actions Buttons Panel
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  if (_isPersonal) ...[
                    _buildActionTile(
                      icon: Icons.edit_rounded,
                      title: widget.strings.editProfile,
                      onTap: _showEditProfileDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildActionTile(
                      icon: Icons.photo_library_rounded,
                      title: _arabic ? 'تغيير الصورة الشخصية' : 'Change Avatar',
                      onTap: _changePhoto,
                    ),
                    const Divider(height: 1, indent: 56),
                  ] else ...[
                    _buildActionTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: _arabic ? 'إرسال رسالة فورية' : 'Send Message',
                      onTap: _contactUser,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const Divider(height: 1, indent: 56),
                  ],
                  if (_isPersonal)
                    _buildActionTile(
                      icon: Icons.logout_rounded,
                      title: _signedIn ? widget.strings.signOut : widget.strings.signIn,
                      color: _signedIn ? const Color(0xFFE94335) : Theme.of(context).colorScheme.primary,
                      onTap: () => unawaited(_handleLogout()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.1) : const Color(0x04000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required String title,
    required String subtitle,
    required String emoji,
    required bool unlocked,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? (isDark ? const Color(0x2E60A5FA) : const Color(0xFFF0F6FF))
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: unlocked ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      minLeadingWidth: 32,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9AA6B8),
      ),
      onTap: onTap,
    );
  }
}
