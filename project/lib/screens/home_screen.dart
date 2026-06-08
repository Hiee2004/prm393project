import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goToRoute(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
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
                  const _HomeHeader(),

                  const SizedBox(height: 28),

                  const _SectionTitle(
                    title: 'Today Focus Overview',
                    subtitle:
                        'Track your focus tasks, focus time, outputs and distractions.',
                  ),

                  const SizedBox(height: 16),

                  const _StatGrid(),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Priority Focus Task',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF07112D),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _goToRoute(context, '/tasks');
                        },
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: Color(0xFF43C982),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _FocusTaskCard(
                    title: 'Hoàn thành UI Flutter',
                    time: '09:00 - 10:30',
                    progress: '3/5 outputs',
                    priority: 'High Priority',
                    onStartFocus: () {
                      _goToRoute(context, '/focus');
                    },
                  ),

                  _FocusTaskCard(
                    title: 'Ôn lại yêu cầu của thầy',
                    time: '14:00 - 14:45',
                    progress: '1/3 outputs',
                    priority: 'Medium Priority',
                    onStartFocus: () {
                      _goToRoute(context, '/focus');
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _goToRoute(context, '/tasks');
                      },
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text(
                        'Plan Today Focus Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43D982),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _goToRoute(context, '/statistics');
                      },
                      icon: const Icon(Icons.insights_rounded),
                      label: const Text(
                        'View End Day Summary',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF07112D),
                        side: const BorderSide(color: Color(0xFFDDE4F0)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _goToRoute(context, '/calendar');
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text(
                        'View Focus Calendar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF07112D),
                        side: const BorderSide(color: Color(0xFFDDE4F0)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43E08B), Color(0xFF23C7DD), Color(0xFF8A7CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43E08B).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Good morning 👋',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Ready to focus today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Choose one important task and avoid distractions.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF07112D),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF65708A),
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                title: 'Focus Tasks',
                value: '3',
                subtitle: 'planned today',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer_outlined,
                title: 'Focus Time',
                value: '90m',
                subtitle: 'completed',
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.block_rounded,
                title: 'Distractions',
                value: '2',
                subtitle: 'times today',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.task_alt_rounded,
                title: 'Outputs',
                value: '5/8',
                subtitle: 'checked',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF43D982), size: 28),

          const SizedBox(height: 18),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF07112D),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
          ),
        ],
      ),
    );
  }
}

class _FocusTaskCard extends StatelessWidget {
  final String title;
  final String time;
  final String progress;
  final String priority;
  final VoidCallback onStartFocus;

  const _FocusTaskCard({
    required this.title,
    required this.time,
    required this.progress,
    required this.priority,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF43D982),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority,
                      style: const TextStyle(
                        color: Color(0xFF43C982),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF07112D),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF65708A),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.checklist_rounded,
                size: 18,
                color: Color(0xFF65708A),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  progress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF65708A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onStartFocus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43D982),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Start Focus',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  void _onTap(BuildContext context, int index) {
    if (index == 0) return;

    if (index == 1) {
      Navigator.pushNamed(context, '/tasks');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/focus');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/statistics');
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
