import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/focus_notification_service.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  Timer? _timer;
  FocusTask? _task;
  late int _totalSeconds;
  late int _remainingSeconds;
  final Set<int> _completedIndexes = {};
  int _distractions = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _task = MyTimeStore.instance.selectedTask;
    _totalSeconds = (_task?.focusMinutes ?? 25) * 60;
    _remainingSeconds = _totalSeconds;

    final outputs = _task?.outputs ?? [];
    for (var index = 0; index < outputs.length; index++) {
      if (outputs[index].isCompleted) {
        _completedIndexes.add(index);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(FocusNotificationService.instance.cancel());
    super.dispose();
  }

  void _toggleTimer() {
    final task = _task;
    if (task != null && !task.canStartToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This task can start on ${_formatDate(task.scheduledDate)}.',
          ),
        ),
      );
      return;
    }

    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      unawaited(_showPausedNotification());
      return;
    }

    if (_task != null) {
      MyTimeStore.instance.startTask(_task!);
    }
    setState(() => _isRunning = true);
    unawaited(_showRunningNotification());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        unawaited(
          FocusNotificationService.instance.showCompleted(
            taskTitle: _task?.title ?? 'Focus Time',
          ),
        );
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds % 60 == 0) {
        unawaited(_showRunningNotification());
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    unawaited(FocusNotificationService.instance.cancel());
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
  }

  void _finishSession() {
    final task = _task;
    if (task == null) return;

    _timer?.cancel();
    unawaited(FocusNotificationService.instance.cancel());
    MyTimeStore.instance.completeSession(
      task: task,
      elapsedSeconds: _totalSeconds - _remainingSeconds,
      completedIndexes: _completedIndexes,
      distractions: _distractions,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.statistics);
  }

  Future<void> _showRunningNotification() {
    return FocusNotificationService.instance.showRunning(
      taskTitle: _task?.title ?? 'Focus Time',
      remainingTime: _timeText,
    );
  }

  Future<void> _showPausedNotification() {
    return FocusNotificationService.instance.showPaused(
      taskTitle: _task?.title ?? 'Focus Time',
      remainingTime: _timeText,
    );
  }

  String get _timeText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _clockStatus {
    if (_isRunning) return 'FOCUSING';
    if (_remainingSeconds == _totalSeconds) return 'READY';
    return 'PAUSED';
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final canStart = task?.canStartToday ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Time')),
      body: task == null
          ? _NoTaskView(
              onSelectTask: () {
                Navigator.pushReplacementNamed(context, AppRoutes.tasks);
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!canStart)
                  AppCard(
                    color: AppColors.surfaceSoft,
                    child: Text(
                      'This is a future plan. You can review it now, but Focus Time is available on ${_formatDate(task.scheduledDate)}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                if (!canStart) const SizedBox(height: 12),
                _FocusSessionCard(
                  title: task.title,
                  status: _clockStatus,
                  outputText:
                      '${_completedIndexes.length}/${task.outputs.length} output',
                  time: _timeText,
                  progress: 1 - (_remainingSeconds / _totalSeconds),
                  focusMinutes: task.focusMinutes,
                ),
                const SizedBox(height: 14),
                _FocusControls(
                  isRunning: _isRunning,
                  canStart: canStart,
                  unavailableText:
                      'Available on ${_formatDate(task.scheduledDate)}',
                  onToggle: _toggleTimer,
                  onReset: _resetTimer,
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Session outputs',
                  subtitle: 'Check an output when you complete it.',
                ),
                const SizedBox(height: 8),
                _OutputChecklist(
                  task: task,
                  completedIndexes: _completedIndexes,
                  onChanged: (index, value) {
                    setState(() {
                      if (value) {
                        _completedIndexes.add(index);
                      } else {
                        _completedIndexes.remove(index);
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                _SessionActions(
                  distractions: _distractions,
                  onRecordDistraction: () {
                    setState(() => _distractions++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Distraction recorded.')),
                    );
                  },
                  onFinish: _finishSession,
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

class _FocusSessionCard extends StatelessWidget {
  const _FocusSessionCard({
    required this.title,
    required this.status,
    required this.outputText,
    required this.time,
    required this.progress,
    required this.focusMinutes,
  });

  final String title;
  final String status;
  final String outputText;
  final String time;
  final double progress;
  final int focusMinutes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF6FF), Color(0xFFFFFFFF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$focusMinutes min focus plan',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _FocusClock(time: time, progress: progress),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                _StatusChip(status: status),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          outputText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isRunning = status == 'FOCUSING';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRunning ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isRunning ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _FocusControls extends StatelessWidget {
  const _FocusControls({
    required this.isRunning,
    required this.canStart,
    required this.unavailableText,
    required this.onToggle,
    required this.onReset,
  });

  final bool isRunning;
  final bool canStart;
  final String unavailableText;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canStart ? onToggle : null,
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              canStart ? (isRunning ? 'Pause' : 'Start') : unavailableText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Reset timer',
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _OutputChecklist extends StatelessWidget {
  const _OutputChecklist({
    required this.task,
    required this.completedIndexes,
    required this.onChanged,
  });

  final FocusTask task;
  final Set<int> completedIndexes;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(task.outputs.length, (index) {
        final output = task.outputs[index];
        final checked = completedIndexes.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFECFDF3) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: checked
                  ? AppColors.success.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: AppColors.primary,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            value: checked,
            title: Text(
              output.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: checked
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: output.isCompleted
                ? const Text('Completed in a previous session')
                : null,
            onChanged: output.isCompleted
                ? null
                : (value) => onChanged(index, value ?? false),
          ),
        );
      }),
    );
  }
}

class _SessionActions extends StatelessWidget {
  const _SessionActions({
    required this.distractions,
    required this.onRecordDistraction,
    required this.onFinish,
  });

  final int distractions;
  final VoidCallback onRecordDistraction;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.surfaceSoft,
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: onRecordDistraction,
            icon: const Icon(Icons.warning_amber_rounded),
            label: Text('Record distraction ($distractions)'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Finish and view results'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusClock extends StatelessWidget {
  const _FocusClock({required this.time, required this.progress});

  final String time;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 238,
        height: 238,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 13,
                strokeCap: StrokeCap.round,
                color: AppColors.primary,
                backgroundColor: AppColors.progressTrack,
              ),
            ),
            Container(
              width: 182,
              height: 182,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF8FBFF),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 30,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'remaining',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTaskView extends StatelessWidget {
  const _NoTaskView({required this.onSelectTask});

  final VoidCallback onSelectTask;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text('Select a task before starting Focus Time.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSelectTask,
              child: const Text('Select task'),
            ),
          ],
        ),
      ),
    );
  }
}
