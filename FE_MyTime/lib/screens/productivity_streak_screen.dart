import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/models/productivity_streak.dart';
import 'package:project/services/productivity_streak_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/services/streak_freeze_store.dart';
import 'package:project/shared/widgets/app_background.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class ProductivityStreakScreen extends StatefulWidget {
  const ProductivityStreakScreen({super.key});

  @override
  State<ProductivityStreakScreen> createState() =>
      _ProductivityStreakScreenState();
}

class _ProductivityStreakScreenState extends State<ProductivityStreakScreen> {
  static const _maxStreakFreezes = 2;

  ProductivityStreakDashboardModel? _dashboard;
  bool _isLoading = true;
  String? _error;
  late DateTime _calendarMonth;
  Set<DateTime> _usedFreezeDates = <DateTime>{};

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
      final dashboard = await ProductivityStreakApiService.instance.getDashboard(
        token,
      );
      final usedFreezeDates = await StreakFreezeStore.instance.getUsedDates(token);
      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _usedFreezeDates = usedFreezeDates
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet();
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
    final streakStats = dashboard == null
        ? null
        : _computeStreakStats(
            calendar: dashboard.calendar,
            frozenDates: _usedFreezeDates,
          );
    final freezeRemaining = _maxStreakFreezes - _usedFreezeDates.length;

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
                      _ProductivityHero(
                        dashboard: dashboard!,
                        streakStats: streakStats!,
                        freezeRemaining: freezeRemaining.clamp(0, _maxStreakFreezes),
                      ),
                      const SizedBox(height: 18),
                      _RuleCard(freezeRemaining: freezeRemaining.clamp(0, _maxStreakFreezes)),
                      const SizedBox(height: 18),
                      _StreakCalendarCard(
                        month: _calendarMonth,
                        calendar: dashboard.calendar,
                        frozenDates: _usedFreezeDates,
                        freezeRemaining: freezeRemaining.clamp(0, _maxStreakFreezes),
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
                        onUseFreeze: _useStreakFreezeForDate,
                      ),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: -1),
    );
  }

  Future<void> _useStreakFreezeForDate(DateTime date) async {
    if (_usedFreezeDates.length >= _maxStreakFreezes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already used the maximum 2 streak freezes.'),
        ),
      );
      return;
    }

    final shouldUse = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use streak freeze?'),
          content: Text(
            'This will restore your streak for ${_formatShortDate(date)} and spend 1 of your 2 streak freezes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Use freeze'),
            ),
          ],
        );
      },
    );

    if (shouldUse != true) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final updatedDates = {..._usedFreezeDates, normalizedDate}.toList()
      ..sort((first, second) => first.compareTo(second));
    if (updatedDates.length > _maxStreakFreezes) {
      return;
    }

    await StreakFreezeStore.instance.saveUsedDates(
      SessionStore.instance.token,
      updatedDates,
    );
    if (!mounted) return;
    setState(() => _usedFreezeDates = updatedDates.toSet());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Streak freeze used for ${_formatShortDate(normalizedDate)}.',
        ),
      ),
    );
  }
}

class _ProductivityHero extends StatelessWidget {
  const _ProductivityHero({
    required this.dashboard,
    required this.streakStats,
    required this.freezeRemaining,
  });

  static const int maxStreakFreezes = 2;

  final ProductivityStreakDashboardModel dashboard;
  final _StreakStats streakStats;
  final int freezeRemaining;

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
                  value: '${streakStats.currentStreak}',
                  label: 'Current streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.workspace_premium_rounded,
                  value: '${streakStats.bestStreak}',
                  label: 'Best streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${streakStats.totalProductiveDays}',
                  label: 'Productive days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.ac_unit_rounded,
                  value: '$freezeRemaining/$maxStreakFreezes',
                  label: 'Streak freeze',
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
  const _RuleCard({required this.freezeRemaining});

  final int freezeRemaining;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(height: 10),
          _RuleBullet(
            text:
                'You can use a streak freeze on a missed day. Maximum stored freezes: 2. Remaining now: $freezeRemaining.',
          ),
        ],
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
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
    required this.frozenDates,
    required this.freezeRemaining,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onUseFreeze,
  });

  final DateTime month;
  final List<ProductivityStreakDayModel> calendar;
  final Set<DateTime> frozenDates;
  final int freezeRemaining;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function(DateTime date) onUseFreeze;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 340;
          final horizontalPadding = isCompact ? 10.0 : 14.0;
          final spacing = isCompact ? 4.0 : 6.0;
          final availableWidth =
              constraints.maxWidth - (horizontalPadding * 2) - (spacing * 6);
          final cellSize = (availableWidth / 7).clamp(28.0, 42.0);
          final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;

          return Column(
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
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (isCompact) ...[
                      _MonthSwitchButton(
                        tooltip: 'Previous month',
                        onPressed: onPreviousMonth,
                        icon: Icons.chevron_left_rounded,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        if (!isCompact)
                          _MonthSwitchButton(
                            tooltip: 'Previous month',
                            onPressed: onPreviousMonth,
                            icon: Icons.chevron_left_rounded,
                          ),
                        if (!isCompact) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _monthLabel(month),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!isCompact) const SizedBox(width: 4),
                        _MonthSwitchButton(
                          tooltip: 'Next month',
                          onPressed: onNextMonth,
                          icon: Icons.chevron_right_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Expanded(child: _WeekHeader('Sun')),
                        Expanded(child: _WeekHeader('Mon')),
                        Expanded(child: _WeekHeader('Tue')),
                        Expanded(child: _WeekHeader('Wed')),
                        Expanded(child: _WeekHeader('Thu')),
                        Expanded(child: _WeekHeader('Fri')),
                        Expanded(child: _WeekHeader('Sat')),
                      ],
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalCells,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: cellSize,
                      ),
                      itemBuilder: (context, index) {
                        if (index < leadingEmpty ||
                            index >= leadingEmpty + daysInMonth) {
                          return const _CalendarEmptyCell();
                        }

                        final dayNumber = index - leadingEmpty + 1;
                        final date = DateTime(month.year, month.month, dayNumber);
                        final streakDay = calendarMap[date];
                        final isToday =
                            date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final isFrozen = frozenDates.contains(date);

                        return _CalendarDayCell(
                          dayNumber: dayNumber,
                          date: date,
                          streakDay: streakDay,
                          isToday: isToday,
                          isFrozen: isFrozen,
                          canUseFreeze:
                              streakDay != null &&
                              !streakDay.isProductive &&
                              streakDay.completedTaskCount == 0 &&
                              date.isBefore(
                                DateTime(today.year, today.month, today.day + 1),
                              ) &&
                              !isFrozen &&
                              freezeRemaining > 0,
                          onUseFreeze: () => onUseFreeze(date),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthSwitchButton extends StatelessWidget {
  const _MonthSwitchButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 22),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CalendarEmptyCell extends StatelessWidget {
  const _CalendarEmptyCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.dayNumber,
    required this.date,
    required this.streakDay,
    required this.isToday,
    required this.isFrozen,
    required this.canUseFreeze,
    required this.onUseFreeze,
  });

  final int dayNumber;
  final DateTime date;
  final ProductivityStreakDayModel? streakDay;
  final bool isToday;
  final bool isFrozen;
  final bool canUseFreeze;
  final VoidCallback onUseFreeze;

  @override
  Widget build(BuildContext context) {
    final isProductive = streakDay?.isProductive ?? false;
    final completedTaskCount = streakDay?.completedTaskCount ?? 0;
    final isMissedDay = streakDay != null && !isProductive && completedTaskCount == 0;
    final backgroundColor = isFrozen
        ? const Color(0xFFFFE6A7)
        : isProductive
        ? const Color(0xFFFFE6A7)
        : completedTaskCount > 0
        ? const Color(0xFFFFF5DB)
        : isMissedDay
        ? const Color(0xFFDDF3FF)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canUseFreeze ? onUseFreeze : null,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (backgroundColor != Colors.transparent)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                '$dayNumber',
                style: TextStyle(
                  color: isProductive || isMissedDay || isFrozen
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isFrozen)
                const Positioned(
                  top: 2,
                  right: 6,
                  child: Icon(
                    Icons.ac_unit_rounded,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              if (canUseFreeze)
                const Positioned(
                  top: 2,
                  right: 6,
                  child: Icon(
                    Icons.ac_unit_outlined,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              if (isToday)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakErrorState extends StatelessWidget {
  const _StreakErrorState({
    required this.message,
    required this.onRetry,
  });

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
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load productivity streak',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
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

class _StreakStats {
  const _StreakStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalProductiveDays,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalProductiveDays;
}

_StreakStats _computeStreakStats({
  required List<ProductivityStreakDayModel> calendar,
  required Set<DateTime> frozenDates,
}) {
  if (calendar.isEmpty) {
    return const _StreakStats(
      currentStreak: 0,
      bestStreak: 0,
      totalProductiveDays: 0,
    );
  }

  final effectiveDays = <DateTime, bool>{};
  for (final day in calendar) {
    final normalized = DateTime(day.date.year, day.date.month, day.date.day);
    final isFrozen = frozenDates.contains(normalized);
    effectiveDays[normalized] =
        day.isProductive || (isFrozen && day.completedTaskCount == 0);
  }

  final sortedDays = effectiveDays.keys.toList()..sort();
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final totalProductiveDays = effectiveDays.values.where((value) => value).length;

  var bestStreak = 0;
  var runningBest = 0;
  DateTime? previousDate;
  for (final date in sortedDays) {
    final isEffective = effectiveDays[date] ?? false;
    if (!isEffective) {
      runningBest = 0;
      previousDate = date;
      continue;
    }

    if (previousDate != null && date.difference(previousDate).inDays == 1) {
      runningBest += 1;
    } else {
      runningBest = 1;
    }
    if (runningBest > bestStreak) {
      bestStreak = runningBest;
    }
    previousDate = date;
  }

  var currentStreak = 0;
  var cursor = normalizedToday;
  while (effectiveDays[cursor] == true) {
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return _StreakStats(
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    totalProductiveDays: totalProductiveDays,
  );
}

String _monthLabel(DateTime month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[month.month - 1]} ${month.year}';
}
