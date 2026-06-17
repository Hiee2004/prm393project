import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final result = store.latestSession;
          final completionRate = _completionRate(result);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatisticsHero(
                sessions: store.sessions.length,
                time: _formatDuration(store.totalFocusSeconds),
                outputs: store.totalCompletedOutputs,
              ),
              const SizedBox(height: 16),
              _WeeklyProgressCard(result: result),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFFE8F5FF))),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.result});

  final FocusSessionResult? result;

  @override
  Widget build(BuildContext context) {
    final completed = result?.completedOutputs ?? 0;
    final total = result?.totalOutputs == 0 ? 1 : result?.totalOutputs ?? 1;
    final activeBar = (completed / total).clamp(0.0, 1.0);
    final values = [0.2, 0.35, 0.45, activeBar, 0.28, 0.18, 0.3];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Daily completed',
                  subtitle: 'This week focus output progress.',
                ),
              ),
              Text(
                '06/14 - 06/20',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final isActive = index == 3;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: values[index].clamp(0.08, 1.0),
                            child: Container(
                              width: 24,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(days[index]),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          _InlineStat(
            label: 'Task Completion Progress',
            value: '${(activeBar * 100).round()}%',
          ),
          const SizedBox(height: 8),
          const _InlineStat(label: 'Most productive day', value: 'Wednesday'),
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
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceSoft,
                  ),
                ),
                Text(
                  '${(completionRate * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
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
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Clear focus, clear results',
                    style: TextStyle(
                      color: AppColors.primary,
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

  final FocusSessionResult result;

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
                value: '${result.plannedMinutes} minutes',
              ),
              _ResultRow(
                label: 'Actual time',
                value: _formatDuration(result.elapsedSeconds),
              ),
              _ResultRow(
                label: 'Completed outputs',
                value: '${result.completedOutputs}/${result.totalOutputs}',
              ),
              _ResultRow(
                label: 'Completion rate',
                value: '${result.completionPercent}%',
              ),
              _ResultRow(
                label: 'Distractions',
                value: '${result.distractions}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _OutputList(
          title: 'Completed outputs',
          items: result.completedOutputTitles,
          emptyText: 'No outputs were completed.',
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        if (result.unfinishedOutputTitles.isNotEmpty) ...[
          const SizedBox(height: 18),
          _OutputList(
            title: 'Unfinished outputs',
            items: result.unfinishedOutputTitles,
            emptyText: 'No unfinished outputs.',
            icon: Icons.radio_button_unchecked,
            color: AppColors.textMuted,
          ),
        ],
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.taskTitle});

  final String taskTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.task_alt, color: AppColors.primary),
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
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputList extends StatelessWidget {
  const _OutputList({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final String emptyText;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.isEmpty
                ? [
                    ListTile(
                      leading: Icon(Icons.info_outline, color: color),
                      title: Text(emptyText),
                    ),
                  ]
                : items
                      .map(
                        (title) => ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(title),
                        ),
                      )
                      .toList(),
          ),
        ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.bar_chart, size: 58, color: AppColors.primary),
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

double _completionRate(FocusSessionResult? result) {
  if (result == null || result.totalOutputs == 0) return 0;
  return result.completedOutputs / result.totalOutputs;
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';

  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}
