import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';

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
        children: [
          const _SectionTitle('Timer'),
          ListTile(
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
          const Divider(),
          const _SectionTitle('Notifications'),
          SwitchListTile(
            title: const Text('Focus reminders'),
            value: _reminders,
            onChanged: (value) => setState(() => _reminders = value),
          ),
          SwitchListTile(
            title: const Text('Distraction alert'),
            value: _distractionAlert,
            onChanged: (value) => setState(() => _distractionAlert = value),
          ),
          SwitchListTile(
            title: const Text('Dark focus mode'),
            value: _darkFocusMode,
            onChanged: (value) => setState(() => _darkFocusMode = value),
          ),
          const Divider(),
          const _SectionTitle('Account'),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Student User'),
            subtitle: Text('student@email.com'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
