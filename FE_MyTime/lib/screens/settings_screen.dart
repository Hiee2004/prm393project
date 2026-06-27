import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/shared/widgets/app_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminders = true;
  bool _distractionAlert = true;
  bool _darkFocusMode = false;
  int _focusDuration = 25;
  int _breakDuration = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    onChanged: (value) {
                      if (value != null) setState(() => _focusDuration = value);
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
          const _SectionTitle('Notifications'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Focus reminders'),
                  value: _reminders,
                  onChanged: (value) => setState(() => _reminders = value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Distraction alert'),
                  value: _distractionAlert,
                  onChanged: (value) {
                    setState(() => _distractionAlert = value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark focus mode'),
                  value: _darkFocusMode,
                  onChanged: (value) => setState(() => _darkFocusMode = value),
                ),
              ],
            ),
          ),
          const _SectionTitle('Account'),
          const AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceSoft,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text('Student User'),
              subtitle: Text('student@email.com'),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
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
