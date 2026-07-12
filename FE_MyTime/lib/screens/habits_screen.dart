import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/models/habit_tracker.dart';
import 'package:project/services/habit_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_background.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  ProductivityStreakDashboardModel? _dashboard;
  bool _isLoading = true;
  String? _error;
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
    unawaited(_loadDashboard());
  }

  Future<void> _loadDashboard() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in again to load productivity streak.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await HabitApiService.instance.getDashboard(token);
      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Productivity Streak'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _StreakErrorState(message: _error!, onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _ProductivityHero(dashboard: dashboard!),
                      const SizedBox(height: 18),
                      const _RuleCard(),
                      const SizedBox(height: 18),
                      _StreakCalendarCard(
                        month: _calendarMonth,
                        calendar: dashboard.calendar,
                        onPreviousMonth: () {
                          setState(() {
                            _calendarMonth = DateTime(
                              _calendarMonth.year,
                              _calendarMonth.month - 1,
                            );
                          });
                        },
                        onNextMonth: () {
                          setState(() {
                            _calendarMonth = DateTime(
                              _calendarMonth.year,
                              _calendarMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: -1),
    );
  }
}

class _ProductivityHero extends StatelessWidget {
  const _ProductivityHero({required this.dashboard});

  final ProductivityStreakDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6B312), Color(0xFFF18A4D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F6B312),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep the streak alive',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A productive day needs 1 completed task and ${dashboard.minimumFocusMinutes}+ focus minutes.',
                      style: const TextStyle(color: Color(0xFFFFF4DD)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '${dashboard.currentStreak}',
                  label: 'Current streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.workspace_premium_rounded,
                  value: '${dashboard.bestStreak}',
                  label: 'Best streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${dashboard.totalProductiveDays}',
                  label: 'Productive days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFF4DD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: 'How it works',
            subtitle:
                'Your app-wide productivity streak grows only on days that meet both conditions.',
          ),
          SizedBox(height: 14),
          _RuleBullet(text: 'Complete at least 1 task on that day.'),
          SizedBox(height: 10),
          _RuleBullet(
            text: 'Record at least 25 minutes of real focus time on that day.',
          ),
        ],
      ),
    );
  }
}

class _RuleBullet extends StatelessWidget {
  const _RuleBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StreakCalendarCard extends StatelessWidget {
  const _StreakCalendarCard({
    required this.month,
    required this.calendar,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final List<ProductivityStreakDayModel> calendar;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmpty = firstDay.weekday % 7;
    final today = DateTime.now();
    final calendarMap = {
      for (final cell in calendar)
        DateTime(cell.date.year, cell.date.month, cell.date.day): cell,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Calendar',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onPreviousMonth,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: onNextMonth,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    _WeekHeader('Sun'),
                    _WeekHeader('Mon'),
                    _WeekHeader('Tue'),
                    _WeekHeader('Wed'),
                    _WeekHeader('Thu'),
                    _WeekHeader('Fri'),
                    _WeekHeader('Sat'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  runSpacing: 12,
                  children: List.generate(leadingEmpty + daysInMonth, (index) {
                    if (index < leadingEmpty) {
                      return const _CalendarEmptyCell();
                    }

                    final dayNumber = index - leadingEmpty + 1;
                    final date = DateTime(month.year, month.month, dayNumber);
                    final streakDay = calendarMap[date];
                    final isToday =
                        date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;

                    return _CalendarDayCell(
                      dayNumber: dayNumber,
                      streakDay: streakDay,
                      isToday: isToday,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CalendarEmptyCell extends StatelessWidget {
  const _CalendarEmptyCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 48, height: 58);
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.dayNumber,
    required this.streakDay,
    required this.isToday,
  });

  final int dayNumber;
  final ProductivityStreakDayModel? streakDay;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final isProductive = streakDay?.isProductive ?? false;
    final markerColor = isToday
        ? AppColors.warning
        : (isProductive ? const Color(0xFF5BC6FF) : Colors.transparent);
    final textColor = isToday
        ? Colors.white
        : (isProductive ? Colors.white : AppColors.textMuted);

    return SizedBox(
      width: 48,
      height: 58,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isProductive)
              Positioned(
                top: 4,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: markerColor,
                ),
              )
            else if (isToday)
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning,
                ),
              ),
            Positioned(
              top: isProductive ? 13 : 14,
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakErrorState extends StatelessWidget {
  const _StreakErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 12),
              const Text(
                'Could not load productivity streak',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _monthLabel(DateTime value) {
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  return '${months[value.month - 1]} ${value.year}';
}
