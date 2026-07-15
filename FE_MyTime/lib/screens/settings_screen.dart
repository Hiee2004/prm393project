import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/user_setting.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/services/session_store.dart';
import 'package:project/services/settings_api_service.dart';
import 'package:project/shared/widgets/app_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminders = true;
  bool _distractionAlert = true;
  String _themeMode = AppTheme.lunarNewYear;
  String _timeZone = 'Asia/Ho_Chi_Minh';
  int _focusDuration = 25;
  int _breakDuration = 5;
  int _settingsRevision = 0;

  @override
  void initState() {
    super.initState();
    _applySetting(MyTimeStore.instance.setting);
    _loadSettings();
  }

  void _applySetting(UserSetting setting) {
    _focusDuration = setting.defaultFocusMinutes;
    _reminders = setting.notificationEnabled;
    _themeMode = AppTheme.normalizeMode(setting.themeMode);
    _timeZone = setting.timeZone;
  }

  Future<void> _loadSettings() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;
    final requestRevision = _settingsRevision;

    try {
      final setting = await SettingsApiService.instance.getSettings(token);
      if (!mounted || requestRevision != _settingsRevision) return;

      MyTimeStore.instance.updateSetting(setting);
      setState(() => _applySetting(setting));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load settings: $error')),
      );
    }
  }

  Future<void> _saveSettings() async {
    final store = MyTimeStore.instance;
    final previousSetting = store.setting;
    final revision = _settingsRevision;
    final setting = previousSetting.copyWith(
      defaultFocusMinutes: _focusDuration,
      notificationEnabled: _reminders,
      themeMode: _themeMode,
      timeZone: _timeZone,
    );

    store.updateSetting(setting);

    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    try {
      final updated = await SettingsApiService.instance.updateSettings(
        token: token,
        setting: setting,
      );

      if (revision == _settingsRevision) {
        store.updateSetting(updated);
      }
    } catch (error) {
      if (revision == _settingsRevision) {
        store.updateSetting(previousSetting);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save settings: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = MyTimeStore.instance.profile;
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Appearance'),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: scene.navGlow,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(scene.accentIcon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppTheme.labelForMode(_themeMode)} world',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _themeDescription(_themeMode),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('World theme'),
                  subtitle: Text(AppTheme.labelForMode(_themeMode)),
                  trailing: DropdownButton<String>(
                    value: _themeMode,
                    items: AppTheme.selectableModes
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(AppTheme.labelForMode(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() {
                        _themeMode = value;
                        _settingsRevision++;
                      });
                      await _saveSettings();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: const Text('Time zone'),
                  subtitle: Text(_timeZone),
                  trailing: DropdownButton<String>(
                    value: _timeZone,
                    items:
                        const [
                              'Asia/Ho_Chi_Minh',
                              'Asia/Bangkok',
                              'Asia/Tokyo',
                              'Europe/Berlin',
                              'America/New_York',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() {
                        _timeZone = value;
                        _settingsRevision++;
                      });
                      await _saveSettings();
                    },
                  ),
                ),
              ],
            ),
          ),
          const _SectionTitle('Timer'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Focus duration'),
                  trailing: DropdownButton<int>(
                    value: _focusDuration,
                    items: const [25, 45, 60, 90]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;

                      setState(() {
                        _focusDuration = value;
                        _settingsRevision++;
                      });

                      await _saveSettings();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.free_breakfast_outlined),
                  title: const Text('Break duration'),
                  trailing: DropdownButton<int>(
                    value: _breakDuration,
                    items: const [5, 10, 15]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _breakDuration = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const _SectionTitle('Focus Audio'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.library_music_rounded),
                  title: const Text('Ambient audio library'),
                  subtitle: const Text(
                    'Open a dedicated page to assign one file for Rain, Cafe, White Noise, and Ocean.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.focusAudioSettings);
                  },
                ),
              ],
            ),
          ),
          const _SectionTitle('Notifications'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Focus reminders'),
                  value: _reminders,
                  onChanged: (value) async {
                    setState(() {
                      _reminders = value;
                      _settingsRevision++;
                    });

                    await _saveSettings();
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Distraction alert'),
                  value: _distractionAlert,
                  onChanged: (value) {
                    setState(() => _distractionAlert = value);
                  },
                ),
              ],
            ),
          ),
          const _SectionTitle('Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceSoft,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(profile.fullName),
                  subtitle: Text(profile.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              SessionStore.instance.clear();

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

String _themeDescription(String mode) {
  switch (AppTheme.normalizeMode(mode)) {
    case AppTheme.winter:
      return 'Snowy air, icy glass, drifting flakes and a calm blue night.';
    case AppTheme.summer:
      return 'Beach light, ocean motion and warm sunshine across the whole app.';
    case AppTheme.christmas:
      return 'Holiday lights, evergreen glow and a cozy festive night scene.';
    case AppTheme.lunarNewYear:
      return 'Red-gold festival energy with blossoms, fireworks and new-year warmth.';
    default:
      return 'A full-scene world theme across every screen.';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
