import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.strings,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final AppStrings strings;
  final Locale locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _locationKey = 'settings_location_enabled';
  static const _signedInKey = 'settings_signed_in';
  static const _settingsChannel = MethodChannel('lostandfound/settings');

  bool _notificationsEnabled = true;
  bool _locationEnabled = false;
  bool _signedIn = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _locationEnabled = prefs.getBool(_locationKey) ?? false;
      _signedIn = prefs.getBool(_signedInKey) ?? true;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> _setLocation(bool value) async {
    setState(() => _locationEnabled = value);
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> _setSignedIn(bool value) async {
    setState(() => _signedIn = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, value);
    _showSnack(value ? widget.strings.signIn : widget.strings.signedOut);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showComingSoon() {
    _showSnack(widget.strings.comingSoon);
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        children: [
          HeaderBar(
            title: strings.settings,
            subtitle: strings.appName,
            onLanguageToggle: _showComingSoon,
            languageLabel: '',
          ),
          const SizedBox(height: 22),
          _ProfileCard(
            signedIn: _signedIn,
            strings: strings,
            onEdit: _showComingSoon,
          ),
          const SizedBox(height: 28),
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
                locale: widget.locale,
                onChanged: widget.onLocaleChanged,
              ),
              _ThemeTile(
                strings: strings,
                value: widget.themeMode,
                onChanged: widget.onThemeModeChanged,
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
                onTap: _showComingSoon,
              ),
              _SettingsActionTile(
                icon: Icons.report_problem_outlined,
                title: strings.reportProblem,
                onTap: _showComingSoon,
              ),
              _SettingsActionTile(
                icon: Icons.privacy_tip_outlined,
                title: strings.termsPrivacy,
                onTap: _showComingSoon,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionLabel(label: strings.account),
          const SizedBox(height: 10),
          _AccountButton(
            label: _signedIn ? strings.signOut : strings.signIn,
            signedIn: _signedIn,
            onPressed: () => unawaited(_setSignedIn(!_signedIn)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.signedIn,
    required this.strings,
    required this.onEdit,
  });

  final bool signedIn;
  final AppStrings strings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = signedIn ? strings.demoUserName : strings.continueAsGuest;
    final email = signedIn ? strings.demoUserEmail : strings.signIn;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFE8EEF7),
            child: Icon(
              signedIn ? Icons.person_rounded : Icons.person_outline_rounded,
              color: const Color(0xFF1D55D8),
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: Color(0xFF1D55D8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.demoUniversity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF53657E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: strings.editProfile,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
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
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 72, endIndent: 18),
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
    return ListTile(
      minLeadingWidth: 32,
      contentPadding: const EdgeInsetsDirectional.only(start: 18, end: 16),
      leading: Icon(icon, color: const Color(0xFF1D55D8), size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF1D55D8),
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
      leading: Icon(icon, color: const Color(0xFF1D55D8), size: 30),
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
      leading: const Icon(
        Icons.language_rounded,
        color: Color(0xFF1D55D8),
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
      leading: const Icon(
        Icons.brightness_6_outlined,
        color: Color(0xFF1D55D8),
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

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.label,
    required this.signedIn,
    required this.onPressed,
  });

  final String label;
  final bool signedIn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = signedIn ? const Color(0xFFE94335) : const Color(0xFF1D55D8);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(signedIn ? Icons.logout_rounded : Icons.login_rounded),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        foregroundColor: color,
        side: const BorderSide(color: Color(0xFFE4EAF3)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE4EAF3)),
    boxShadow: const [
      BoxShadow(color: Color(0x0D0A2758), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}
