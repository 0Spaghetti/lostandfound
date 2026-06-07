import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../shared/l10n/app_strings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.strings,
    this.onNotificationsTap,
    this.hasUnreadNotifications = false,
  });

  final AppStrings strings;
  final VoidCallback? onNotificationsTap;
  final bool hasUnreadNotifications;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _locationKey = 'settings_location_enabled';
  static const _settingsChannel = MethodChannel('lostandfound/settings');

  bool _notificationsEnabled = true;
  bool _locationEnabled = false;

  bool get _arabic => ref.watch(localeProvider).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _locationEnabled = prefs.getBool(_locationKey) ?? false;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> _setLocation(bool value) async {
    setState(() => _locationEnabled = value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_locationKey, value);
    if (value) {
      await _openSystemSettings();
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('openAppSettings');
      if (!mounted) return;
      _showSnack(widget.strings.systemSettingsOpened);
    } on PlatformException {
      if (!mounted) return;
      _showSnack(widget.strings.locationServicesStatus);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showFaqDialog() {
    final isArabic = _arabic;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 8),
                Text(
                  widget.strings.helpFaq,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildFaqItem(
                    isArabic ? 'س: أين يمكنني استلام البلاغات المستلمة؟' : 'Q: Where can I collect claimed items?',
                    isArabic 
                        ? 'ج: يرجى زيارة البوابة الرئيسية - مبنى 2، مكتب الاستقبال أو مكتب الأمن بوزارة الحرس الجامعي.' 
                        : 'A: Visit the Main Gate Building 2 Front Desk or the Campus Security Office.',
                  ),
                  const Divider(),
                  _buildFaqItem(
                    isArabic ? 'س: ماذا أحتاج لإثبات ملكية غرض؟' : 'Q: What do I need to prove ownership?',
                    isArabic
                        ? 'ج: ستحتاج لإبراز بطاقة جامعية صالحة ووصف علامة مميزة داخل الغرض.'
                        : 'A: You must show a valid Student/Staff ID card and describe a unique detail or contents inside the item.',
                  ),
                  const Divider(),
                  _buildFaqItem(
                    isArabic ? 'س: كم من الوقت يتم الاحتفاظ بالمفقودات؟' : 'Q: How long are found items kept?',
                    isArabic
                        ? 'ج: يتم الاحتفاظ بجميع الموجودات لمدة 90 يوماً قبل التبرع بها أو التخلص منها طبقاً للوائح الجامعة.'
                        : 'A: Items are held for up to 90 days before being donated or disposed of in accordance with campus policies.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  void _showReportProblemDialog() {
    final isArabic = _arabic;
    final problemController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              widget.strings.reportProblem,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'صف المشكلة أو الملاحظات بالتفصيل:' : 'Describe the problem or feedback in detail:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: problemController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'اكتب هنا...' : 'Write here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.strings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final text = problemController.text.trim();
                  if (text.isEmpty) {
                    _showSnack(isArabic ? 'الرجاء كتابة تفاصيل المشكلة' : 'Please describe the problem');
                    return;
                  }
                  Navigator.pop(context);
                  _showSnack(isArabic ? 'شكرًا لك! تم إرسال تقريرك للدعم.' : 'Thank you! Your feedback has been sent to support.');
                },
                child: Text(isArabic ? 'إرسال' : 'Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTermsDialog() {
    final isArabic = _arabic;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              widget.strings.termsPrivacy,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    isArabic ? 'شروط الخدمة والخصوصية' : 'Terms & Privacy Policy',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1D4ED8)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isArabic
                        ? '1. السلامة أولاً: تقابل دائماً في أماكن عامة ومضاءة داخل الحرم الجامعي (مثل مركز الطلبة).\n'
                          '2. الخصوصية: لا تقم بمشاركة أرقام الهاتف الشخصية أو كلمات المرور.\n'
                          '3. المسؤولية: الجامعة لا تتحمل أي مسؤولية عن الممتلكات المتبادلة أو المفقودة بين الأطراف.'
                        : '1. Safety First: Always arrange meetups in well-lit, public campus locations (e.g., Student Center).\n'
                          '2. Privacy: Do not share personal phone numbers, bank details, or passwords.\n'
                          '3. Liability: The university is not liable for items traded, resolved, or exchanged between community members.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isArabic ? 'حسناً' : 'OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isArabic = locale.languageCode == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            strings.settings,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            _SectionLabel(label: strings.preferences),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsSwitchTile(
                  icon: Icons.notifications_none_rounded,
                  title: strings.notifications,
                  value: _notificationsEnabled,
                  onChanged: (value) => unawaited(_setNotifications(value)),
                ),
                _SettingsSwitchTile(
                  icon: Icons.location_on_outlined,
                  title: strings.locationServices,
                  subtitle: strings.locationServicesStatus,
                  value: _locationEnabled,
                  onChanged: (value) => unawaited(_setLocation(value)),
                  onTap: _openSystemSettings,
                ),
                _LanguageTile(
                  strings: strings,
                  locale: locale,
                  onChanged: (newLocale) => ref.read(localeProvider.notifier).setLocale(newLocale),
                ),
                _ThemeTile(
                  strings: strings,
                  value: themeMode,
                  onChanged: (newTheme) => ref.read(themeModeProvider.notifier).setThemeMode(newTheme),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionLabel(label: strings.safetySupport),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsActionTile(
                  icon: Icons.help_outline_rounded,
                  title: strings.helpFaq,
                  onTap: _showFaqDialog,
                ),
                _SettingsActionTile(
                  icon: Icons.report_problem_outlined,
                  title: strings.reportProblem,
                  onTap: _showReportProblemDialog,
                ),
                _SettingsActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: strings.termsPrivacy,
                  onTap: _showTermsDialog,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 72, endIndent: 18, color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      minLeadingWidth: 32,
      contentPadding: const EdgeInsetsDirectional.only(start: 18, end: 16),
      leading: Icon(icon, color: primary, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: primary,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 32,
      contentPadding: const EdgeInsetsDirectional.only(start: 18, end: 16),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9AA6B8),
      ),
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.strings,
    required this.locale,
    required this.onChanged,
  });

  final AppStrings strings;
  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 32,
      contentPadding: const EdgeInsetsDirectional.only(start: 18, end: 16),
      leading: Icon(
        Icons.language_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 30,
      ),
      title: Text(
        strings.language,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.languageCode,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Theme.of(context).cardColor,
          items: [
            DropdownMenuItem(
              value: 'ar',
              child: Text(strings.arabicLanguageName),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text(strings.englishLanguageName),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(Locale(value));
          },
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.strings,
    required this.value,
    required this.onChanged,
  });

  final AppStrings strings;
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 32,
      contentPadding: const EdgeInsetsDirectional.only(start: 18, end: 16),
      leading: Icon(
        Icons.brightness_6_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 30,
      ),
      title: Text(
        strings.theme,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: value,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Theme.of(context).cardColor,
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(strings.themeSystem),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(strings.themeLight),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(strings.themeDark),
            ),
          ],
          onChanged: (theme) {
            if (theme == null) return;
            onChanged(theme);
          },
        ),
      ),
    );
  }
}



BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0x0D0A2758)
            : Colors.black.withValues(alpha: 0.2),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
