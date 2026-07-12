import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_session.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _startOfWeek(
      MyTimeStore.instance.selectedCalendarDate,
    );
    MyTimeStore.instance.loadSessionsFromApi();
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeekStart,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedWeekStart = _startOfWeek(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final sessions = store.focusSessions;
          final result = sessions.isNotEmpty
              ? _SessionSnapshot.fromBackend(store.latestFocusSession!)
              : (store.latestSession == null
                    ? null
                    : _SessionSnapshot.fromLocal(store.latestSession!));
          final completionRate = _completionRate(result);
          final weeklyStats = _buildWeeklyStats(
            sessions: sessions,
            weekStart: _selectedWeekStart,
          );
          final sessionCount = sessions.isNotEmpty
              ? store.focusSessions.length
              : store.sessions.length;
          final focusTime = sessions.isNotEmpty
              ? _formatDuration(store.totalBackendFocusSeconds)
              : _formatDuration(store.totalFocusSeconds);
          final outputCount = sessions.isNotEmpty
              ? store.totalBackendCompletedOutputs
              : store.totalCompletedOutputs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatisticsHero(
                sessions: sessionCount,
                time: focusTime,
                outputs: outputCount,
              ),
              const SizedBox(height: 16),
              _WeeklyProgressCard(
                weeklyStats: weeklyStats,
                onPreviousWeek: () {
                  setState(() {
                    _selectedWeekStart = _selectedWeekStart.subtract(
                      const Duration(days: 7),
                    );
                  });
                },
                onNextWeek: () {
                  setState(() {
                    _selectedWeekStart = _selectedWeekStart.add(
                      const Duration(days: 7),
                    );
                  });
                },
                onPickWeek: _pickWeek,
              ),
              const SizedBox(height: 16),
              _CompletionCard(
                completedOutputs: result?.completedOutputs ?? 0,
                totalOutputs: result?.totalOutputs ?? 0,
                completionRate: completionRate,
              ),
              const SizedBox(height: 24),
              if (result == null)
                _EmptyResult(
                  onStart: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.focus);
                  },
                )
              else
                _LatestSession(result: result),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.habits);
                },
                icon: const Icon(Icons.local_fire_department_outlined),
                label: const Text('Open Habit Tracker'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to home'),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
    );
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero({
    required this.sessions,
    required this.time,
    required this.outputs,
  });

  final int sessions;
  final String time;
  final int outputs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: scene.navGlow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Statistics',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track sessions, time, and completed outputs.',
            style: TextStyle(color: Color(0xFFE8F5FF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(value: '$sessions', label: 'Sessions'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(value: time, label: 'Time'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(value: '$outputs', label: 'Outputs'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          Text(label, style: const TextStyle(color: Color(0xFFE8F5FF))),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({
    required this.weeklyStats,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onPickWeek,
  });

  final _WeeklyStats weeklyStats;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final Future<void> Function() onPickWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Daily completed',
            subtitle: 'This week focus output progress.',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: onPreviousWeek,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  InkWell(
                    onTap: onPickWeek,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weeklyStats.rangeLabel,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.calendar_month_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: onNextWeek,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(weeklyStats.dailyValues.length, (index) {
                final isActive = index == weeklyStats.mostProductiveDayIndex;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: weeklyStats.dailyValues[index].clamp(
                              0.08,
                              1.0,
                            ),
                            child: Container(
                              width: 24,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary.withValues(
                                        alpha: 0.26,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(weeklyStats.dayLabels[index]),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          _InlineStat(
            label: 'Task Completion Progress',
            value: '${weeklyStats.completionPercent}%',
          ),
          const SizedBox(height: 8),
          _InlineStat(
            label: 'Most productive day',
            value: weeklyStats.mostProductiveDayLabel,
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.completedOutputs,
    required this.totalOutputs,
    required this.completionRate,
  });

  final int completedOutputs;
  final int totalOutputs;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: completionRate,
                    strokeWidth: 18,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.secondary.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                Text(
                  '${(completionRate * 100).round()}%',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Output completion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('$completedOutputs of $totalOutputs outputs completed'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Clear focus, clear results',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestSession extends StatelessWidget {
  const _LatestSession({required this.result});

  final _SessionSnapshot result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Latest session',
          subtitle: 'Detailed result from the last Focus Time.',
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ResultHeader(taskTitle: result.taskTitle),
              const Divider(height: 1),
              _ResultRow(
                label: 'Planned time',
                value: _formatDuration(result.plannedSeconds),
              ),
              _ResultRow(
                label: 'Actual time',
                value: _formatDuration(result.actualFocusSeconds),
              ),
              _ResultRow(
                label: 'Completed outputs',
                value: '${result.completedOutputs}/${result.totalOutputs}',
              ),
              _ResultRow(
                label: 'Completion rate',
                value: '${(_completionRate(result) * 100).round()}%',
              ),
              _ResultRow(
                label: 'Distractions',
                value: '${result.distractionCount}',
              ),
              if (result.completedOutputTitles.isNotEmpty)
                _ResultRow(
                  label: 'Completed',
                  value: result.completedOutputTitles.join(', '),
                ),
              if (result.unfinishedOutputTitles.isNotEmpty)
                _ResultRow(
                  label: 'Remaining',
                  value: result.unfinishedOutputTitles.join(', '),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.taskTitle});

  final String taskTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.task_alt, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              taskTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 58, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          const Text(
            'No statistics yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Complete a focus session to generate your result board.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onStart,
            child: const Text('Start Focus Time'),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStats {
  const _WeeklyStats({
    required this.dailyValues,
    required this.completionPercent,
    required this.mostProductiveDayIndex,
    required this.mostProductiveDayLabel,
    required this.rangeLabel,
  });

  final List<double> dailyValues;
  final int completionPercent;
  final int mostProductiveDayIndex;
  final String mostProductiveDayLabel;
  final String rangeLabel;

  List<String> get dayLabels => const [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
}

_WeeklyStats _buildWeeklyStats({
  required List<FocusSession> sessions,
  required DateTime weekStart,
}) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  final completedByDay = List<int>.filled(7, 0);
  final totalByDay = List<int>.filled(7, 0);

  for (final session in sessions) {
    final date = (session.completedAt ?? session.startedAt).toLocal();
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(weekStart) || day.isAfter(weekEnd)) continue;

    final index = day.difference(weekStart).inDays;
    completedByDay[index] += session.completedOutputs;
    totalByDay[index] += session.totalOutputs;
  }

  final maxCompleted = completedByDay.reduce((a, b) => a > b ? a : b);
  final safeMax = maxCompleted == 0 ? 1 : maxCompleted;
  final dailyValues = completedByDay
      .map((value) => (value / safeMax).clamp(0.08, 1.0))
      .toList();

  final completedSum = completedByDay.fold(0, (sum, item) => sum + item);
  final totalSum = totalByDay.fold(0, (sum, item) => sum + item);
  final completionPercent = totalSum == 0
      ? 0
      : ((completedSum / totalSum) * 100).round();

  final mostProductiveDayIndex = completedByDay.indexOf(maxCompleted);
  const dayLabels = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  final mostProductiveDayLabel = maxCompleted == 0
      ? 'No data'
      : dayLabels[mostProductiveDayIndex];

  return _WeeklyStats(
    dailyValues: dailyValues,
    completionPercent: completionPercent,
    mostProductiveDayIndex: mostProductiveDayIndex < 0
        ? 0
        : mostProductiveDayIndex,
    mostProductiveDayLabel: mostProductiveDayLabel,
    rangeLabel: '${_formatShortDate(weekStart)} - ${_formatShortDate(weekEnd)}',
  );
}

DateTime _startOfWeek(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final difference = local.weekday % 7;
  return local.subtract(Duration(days: difference));
}

double _completionRate(_SessionSnapshot? result) {
  if (result == null || result.totalOutputs == 0) return 0;
  return result.completedOutputs / result.totalOutputs;
}

class _SessionSnapshot {
  const _SessionSnapshot({
    required this.taskTitle,
    required this.plannedSeconds,
    required this.actualFocusSeconds,
    required this.completedOutputs,
    required this.totalOutputs,
    required this.distractionCount,
    this.completedOutputTitles = const [],
    this.unfinishedOutputTitles = const [],
  });

  final String taskTitle;
  final int plannedSeconds;
  final int actualFocusSeconds;
  final int completedOutputs;
  final int totalOutputs;
  final int distractionCount;
  final List<String> completedOutputTitles;
  final List<String> unfinishedOutputTitles;

  factory _SessionSnapshot.fromBackend(FocusSession session) {
    return _SessionSnapshot(
      taskTitle: session.taskTitle,
      plannedSeconds: session.plannedSeconds,
      actualFocusSeconds: session.actualFocusSeconds,
      completedOutputs: session.completedOutputs,
      totalOutputs: session.totalOutputs,
      distractionCount: session.distractionCount,
    );
  }

  factory _SessionSnapshot.fromLocal(FocusSessionResult session) {
    return _SessionSnapshot(
      taskTitle: session.taskTitle,
      plannedSeconds: session.plannedMinutes * 60,
      actualFocusSeconds: session.elapsedSeconds,
      completedOutputs: session.completedOutputs,
      totalOutputs: session.totalOutputs,
      distractionCount: session.distractions,
      completedOutputTitles: session.completedOutputTitles,
      unfinishedOutputTitles: session.unfinishedOutputTitles,
    );
  }
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';

  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

String _formatShortDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
