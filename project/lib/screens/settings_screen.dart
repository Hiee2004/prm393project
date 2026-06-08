import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool reminderEnabled = true;
  bool distractionAlertEnabled = true;
  bool darkFocusModeEnabled = true;

  int focusDuration = 25;
  int breakDuration = 5;

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),

                  const SizedBox(height: 24),

                  const _SectionTitle('Focus Settings'),

                  const SizedBox(height: 12),

                  _OptionSelectorCard(
                    title: 'Focus duration',
                    subtitle: 'Default duration for each focus session.',
                    icon: Icons.timer_outlined,
                    values: const [25, 45, 60, 90],
                    selectedValue: focusDuration,
                    suffix: 'min',
                    onChanged: (value) {
                      setState(() {
                        focusDuration = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _OptionSelectorCard(
                    title: 'Break duration',
                    subtitle: 'Short break after a focus session.',
                    icon: Icons.free_breakfast_outlined,
                    values: const [5, 10, 15],
                    selectedValue: breakDuration,
                    suffix: 'min',
                    onChanged: (value) {
                      setState(() {
                        breakDuration = value;
                      });
                    },
                  ),

                  const SizedBox(height: 26),

                  const _SectionTitle('Reminder & Distraction'),

                  const SizedBox(height: 12),

                  _SwitchSettingTile(
                    title: 'Focus reminders',
                    subtitle: 'Notify before your planned focus task starts.',
                    icon: Icons.notifications_active_outlined,
                    value: reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        reminderEnabled = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _SwitchSettingTile(
                    title: 'Distraction alert',
                    subtitle: 'Show reminder when you record distraction.',
                    icon: Icons.block_rounded,
                    value: distractionAlertEnabled,
                    onChanged: (value) {
                      setState(() {
                        distractionAlertEnabled = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _SwitchSettingTile(
                    title: 'Dark focus mode',
                    subtitle:
                        'Use dark screen while focusing to reduce distraction.',
                    icon: Icons.dark_mode_outlined,
                    value: darkFocusModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        darkFocusModeEnabled = value;
                      });
                    },
                  ),

                  const SizedBox(height: 26),

                  const _SectionTitle('Account'),

                  const SizedBox(height: 12),

                  _AccountCard(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _SettingsBottomNavBar(),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),

        const SizedBox(width: 8),

        const Expanded(
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF07112D),
            ),
          ),
        ),

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF43D982).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.settings_rounded, color: Color(0xFF43D982)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF07112D),
      ),
    );
  }
}

class _OptionSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<int> values;
  final int selectedValue;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _OptionSelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
    required this.selectedValue,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingTitleRow(icon: icon, title: title, subtitle: subtitle),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: values.map((value) {
              final bool isSelected = selectedValue == value;

              return ChoiceChip(
                label: Text('$value $suffix'),
                selected: isSelected,
                selectedColor: const Color(0xFF43D982),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF65708A),
                  fontWeight: FontWeight.w800,
                ),
                side: const BorderSide(color: Color(0xFFE5EAF3)),
                onSelected: (_) {
                  onChanged(value);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingCard(
      child: Row(
        children: [
          Expanded(
            child: _SettingTitleRow(
              icon: icon,
              title: title,
              subtitle: subtitle,
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF43D982),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingTitleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF43D982).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF43D982)),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF07112D),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Color(0xFF65708A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43E08B), Color(0xFF23C7DD)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student User',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF07112D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'student@email.com',
                  style: TextStyle(fontSize: 13, color: Color(0xFF65708A)),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A94A6)),
        ],
      ),
    );
  }
}

class _SettingsBottomNavBar extends StatelessWidget {
  const _SettingsBottomNavBar();

  void _onTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tasks');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/focus');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/statistics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE2FFF0),
      onDestinationSelected: (index) {
        _onTap(context, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer_rounded),
          label: 'Focus',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Stats',
        ),
      ],
    );
  }
}
