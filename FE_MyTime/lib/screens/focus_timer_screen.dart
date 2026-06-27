import 'dart:async';
import 'dart:math' as math;

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

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  StreamSubscription<FocusNotificationAction>? _notificationActionSubscription;
  FocusTask? _task;
  late final AnimationController _hourglassController;
  late int _totalSeconds;
  late int _remainingSeconds;
  final Set<int> _completedIndexes = {};
  int _distractions = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _hourglassController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _notificationActionSubscription = FocusNotificationService.instance.actions
        .listen(_handleNotificationAction);
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
    _notificationActionSubscription?.cancel();
    _hourglassController.dispose();
    unawaited(FocusNotificationService.instance.cancel());
    super.dispose();
  }

  void _selectTask(FocusTask? task) {
    if (task == null || identical(task, _task)) return;

    _timer?.cancel();
    _hourglassController.stop();
    _hourglassController.value = 0;
    unawaited(FocusNotificationService.instance.cancel());
    MyTimeStore.instance.selectTask(task);
    setState(() {
      _task = task;
      _totalSeconds = task.focusMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _completedIndexes
        ..clear()
        ..addAll([
          for (var index = 0; index < task.outputs.length; index++)
            if (task.outputs[index].isCompleted) index,
        ]);
      _distractions = 0;
      _isRunning = false;
    });
  }

  void _changeFocusDuration(int minutes) {
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pause the timer before changing focus duration.'),
        ),
      );
      return;
    }

    final safeMinutes = minutes.clamp(1, 300);
    _timer?.cancel();
    _hourglassController.stop();
    _hourglassController.value = 0;
    unawaited(FocusNotificationService.instance.cancel());

    setState(() {
      _totalSeconds = safeMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
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
      _pauseTimer();
      return;
    }

    _resumeTimer();
  }

  void _handleNotificationAction(FocusNotificationAction action) {
    if (!mounted) return;
    switch (action) {
      case FocusNotificationAction.pause:
        if (_isRunning) _pauseTimer();
      case FocusNotificationAction.resume:
        if (!_isRunning && _remainingSeconds > 0) _resumeTimer();
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    _hourglassController.stop();
    setState(() => _isRunning = false);
    unawaited(_showPausedNotification());
  }

  void _resumeTimer() {
    if (_task != null) {
      MyTimeStore.instance.startTask(_task!);
    }
    setState(() => _isRunning = true);
    _hourglassController.repeat();
    unawaited(_showRunningNotification());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _hourglassController.stop();
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
    _hourglassController.stop();
    _hourglassController.value = 0;
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
    _hourglassController.stop();
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

  int get _focusMinutes => (_totalSeconds / 60).round();

  double get _progress {
    if (_totalSeconds <= 0) return 0;
    return 1 - (_remainingSeconds / _totalSeconds);
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
                _FocusTaskPicker(selectedTask: task, onChanged: _selectTask),
                const SizedBox(height: 14),
                _FocusDurationPicker(
                  minutes: _focusMinutes,
                  enabled: !_isRunning,
                  onChanged: _changeFocusDuration,
                ),
                const SizedBox(height: 14),
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
                AnimatedBuilder(
                  animation: _hourglassController,
                  builder: (context, child) {
                    return _FocusSessionCard(
                      title: task.title,
                      status: _clockStatus,
                      outputText:
                          '${_completedIndexes.length}/${task.outputs.length} output',
                      time: _timeText,
                      progress: _progress,
                      focusMinutes: _focusMinutes,
                      hourglassValue: _progress,
                    );
                  },
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

class _FocusTaskPicker extends StatelessWidget {
  const _FocusTaskPicker({required this.selectedTask, required this.onChanged});

  final FocusTask selectedTask;
  final ValueChanged<FocusTask?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tasks = MyTimeStore.instance.tasks
        .where((task) => !task.isCompleted)
        .toList();
    final hasSelected = tasks.any((task) => identical(task, selectedTask));
    final value = hasSelected ? selectedTask : null;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FocusTask>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          hint: const Text('Choose a focus task'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: tasks.map((task) {
            return DropdownMenuItem(
              value: task,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.hourglass_bottom_rounded,
                      color: AppColors.primaryDark,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${task.focusMinutes} min • ${_formatDate(task.scheduledDate)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FocusDurationPicker extends StatelessWidget {
  const _FocusDurationPicker({
    required this.minutes,
    required this.enabled,
    required this.onChanged,
  });

  final int minutes;
  final bool enabled;
  final ValueChanged<int> onChanged;

  static const _presetMinutes = [15, 25, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final isCustom = !_presetMinutes.contains(minutes);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Focus duration: $minutes min',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!enabled)
                const Text(
                  'Pause to edit',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in _presetMinutes)
                ChoiceChip(
                  label: Text('$value min'),
                  selected: minutes == value,
                  onSelected: enabled ? (_) => onChanged(value) : null,
                ),
              ChoiceChip(
                label: Text(isCustom ? '$minutes min' : 'Custom'),
                selected: isCustom,
                avatar: const Icon(Icons.edit_rounded, size: 16),
                onSelected: enabled
                    ? (_) => _showCustomDurationDialog(context)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDurationDialog(BuildContext context) async {
    final controller = TextEditingController(text: minutes.toString());

    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom focus duration'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              hintText: 'Example: 35',
            ),
            onSubmitted: (_) => _submitCustomDuration(context, controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitCustomDuration(context, controller),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (value != null) onChanged(value);
  }

  void _submitCustomDuration(
    BuildContext context,
    TextEditingController controller,
  ) {
    final minutes = int.tryParse(controller.text.trim());
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid minute value.')),
      );
      return;
    }

    Navigator.pop(context, minutes);
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
    required this.hourglassValue,
  });

  final String title;
  final String status;
  final String outputText;
  final String time;
  final double progress;
  final int focusMinutes;
  final double hourglassValue;

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
                colors: [Color(0xFFFFF3CF), Color(0xFFFFFFFF)],
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
                _FocusClock(
                  time: time,
                  progress: progress,
                  hourglassValue: hourglassValue,
                ),
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
  const _FocusClock({
    required this.time,
    required this.progress,
    required this.hourglassValue,
  });

  final String time;
  final double progress;
  final double hourglassValue;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final safeHourglassValue = hourglassValue.clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF0), Color(0xFFFFE7AB)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedHourglass(
                    value: safeHourglassValue,
                    size: 318,
                    color: const Color(0xFFB87922),
                  ),
                  Positioned(
                    bottom: 86,
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.96,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            time,
                            key: ValueKey(time),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Focus Time',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: safeProgress,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedHourglass extends StatelessWidget {
  const AnimatedHourglass({
    super.key,
    required this.value,
    required this.size,
    required this.color,
  });

  final double value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HourglassPainter(value: value, color: color),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final v = value.clamp(0.0, 1.0);
    final w = size.width;
    final h = size.height;
    final midX = w / 2;

    final topY = h * 0.12;
    final neckY = h * 0.50;
    final bottomY = h * 0.88;

    final glassTopLeft = w * 0.25;
    final glassTopRight = w * 0.75;
    final glassBottomLeft = w * 0.25;
    final glassBottomRight = w * 0.75;

    final woodDark = Color.lerp(color, const Color(0xFF7A4A15), 0.20)!;
    final woodLight = Color.lerp(color, const Color(0xFFFFD06A), 0.45)!;
    final sandColor = AppColors.primary;
    final sandLight = const Color(0xFFFFE08A);

    final glowPaint = Paint()
      ..color = sandColor.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(midX, h * 0.52),
        width: w * 0.62,
        height: h * 0.70,
      ),
      glowPaint,
    );

    final topCapRect = Rect.fromCenter(
      center: Offset(midX, h * 0.065),
      width: w * 0.70,
      height: h * 0.105,
    );
    final bottomCapRect = Rect.fromCenter(
      center: Offset(midX, h * 0.935),
      width: w * 0.70,
      height: h * 0.105,
    );

    void drawWoodCap(Rect rect) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.height / 2),
      );
      canvas.drawShadow(Path()..addRRect(rrect), Colors.black26, 7, true);
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [woodLight, color, woodDark],
          ).createShader(rect),
      );
      canvas.drawOval(
        Rect.fromLTWH(
          rect.left + rect.width * 0.08,
          rect.top + rect.height * 0.06,
          rect.width * 0.84,
          rect.height * 0.38,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
    }

    drawWoodCap(topCapRect);
    drawWoodCap(bottomCapRect);

    final postPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [woodDark, woodLight, woodDark],
      ).createShader(Rect.fromLTWH(0, topY, w, bottomY - topY));

    final leftPost = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.185, h * 0.095, w * 0.035, h * 0.81),
      const Radius.circular(999),
    );
    final rightPost = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.78, h * 0.095, w * 0.035, h * 0.81),
      const Radius.circular(999),
    );
    canvas.drawRRect(leftPost, postPaint);
    canvas.drawRRect(rightPost, postPaint);

    final glassPath = Path()
      ..moveTo(glassTopLeft, topY)
      ..cubicTo(w * 0.28, h * 0.25, w * 0.38, h * 0.40, midX, neckY)
      ..cubicTo(
        w * 0.62,
        h * 0.60,
        w * 0.72,
        h * 0.75,
        glassBottomRight,
        bottomY,
      )
      ..lineTo(glassBottomLeft, bottomY)
      ..cubicTo(w * 0.28, h * 0.75, w * 0.38, h * 0.60, midX, neckY)
      ..cubicTo(w * 0.62, h * 0.40, w * 0.72, h * 0.25, glassTopRight, topY)
      ..close();

    canvas.drawShadow(glassPath, Colors.black26, 8, true);

    final glassRect = Rect.fromLTWH(
      glassTopLeft,
      topY,
      glassTopRight - glassTopLeft,
      bottomY - topY,
    );

    canvas.save();
    canvas.clipPath(glassPath);

    canvas.drawPath(
      glassPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.74),
            Colors.white.withValues(alpha: 0.22),
            sandLight.withValues(alpha: 0.16),
          ],
        ).createShader(glassRect),
    );

    final upperSandBase = neckY - 6;
    final upperSandTop = topY + 25 + (h * 0.14 * v);
    final topSandLeft = glassTopLeft + 18 + (w * 0.10 * v);
    final topSandRight = glassTopRight - 18 - (w * 0.10 * v);

    if (v < 0.98) {
      final topSand = Path()
        ..moveTo(topSandLeft, upperSandTop)
        ..quadraticBezierTo(
          midX,
          upperSandTop + 10 + math.sin(v * math.pi * 2) * 2,
          topSandRight,
          upperSandTop,
        )
        ..cubicTo(w * 0.67, h * 0.31, w * 0.58, h * 0.42, midX, upperSandBase)
        ..cubicTo(
          w * 0.42,
          h * 0.42,
          w * 0.33,
          h * 0.31,
          topSandLeft,
          upperSandTop,
        )
        ..close();

      canvas.drawPath(
        topSand,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sandLight, sandColor],
          ).createShader(Rect.fromLTWH(0, upperSandTop, w, upperSandBase)),
      );
    }

    if (v > 0.02) {
      final lowerHeight = h * (0.06 + 0.21 * v);
      final bottomSandTop = bottomY - 25 - lowerHeight;
      final bottomSand = Path()
        ..moveTo(glassBottomLeft + 17, bottomY - 24)
        ..quadraticBezierTo(
          midX,
          bottomSandTop - math.sin(v * math.pi * 2) * 3,
          glassBottomRight - 17,
          bottomY - 24,
        )
        ..lineTo(glassBottomRight - 9, bottomY - 10)
        ..lineTo(glassBottomLeft + 9, bottomY - 10)
        ..close();

      canvas.drawPath(
        bottomSand,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sandLight, sandColor],
          ).createShader(Rect.fromLTWH(0, bottomSandTop, w, lowerHeight + 30)),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(midX, bottomSandTop + 7),
          width: w * (0.10 + 0.12 * v),
          height: h * 0.026,
        ),
        Paint()..color = sandLight.withValues(alpha: 0.72),
      );
    }

    if (v > 0.01 && v < 0.99) {
      final streamX = midX + math.sin(v * math.pi * 24) * 1.6;
      canvas.drawLine(
        Offset(midX, neckY - 5),
        Offset(streamX, neckY + h * 0.24),
        Paint()
          ..color = sandColor.withValues(alpha: 0.90)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    final shinePath = Path()
      ..moveTo(w * 0.36, topY + 18)
      ..cubicTo(w * 0.28, h * 0.28, w * 0.38, h * 0.37, w * 0.47, neckY - 8)
      ..cubicTo(w * 0.38, h * 0.62, w * 0.31, h * 0.76, w * 0.35, bottomY - 22);

    canvas.drawPath(
      shinePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    canvas.restore();

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = color.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final rimPaint = Paint()
      ..color = woodDark.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.28, topY + 1),
      Offset(w * 0.72, topY + 1),
      rimPaint,
    );
    canvas.drawLine(
      Offset(w * 0.28, bottomY - 1),
      Offset(w * 0.72, bottomY - 1),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
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
