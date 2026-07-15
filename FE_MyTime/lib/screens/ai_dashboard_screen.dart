import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/smart_schedule.dart';
import 'package:project/models/smart_task_plan.dart';
import 'package:project/services/applied_smart_plan_store.dart';
import 'package:project/services/ai_service.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';

class AiDashboardScreen extends StatefulWidget {
  const AiDashboardScreen({super.key});

  @override
  State<AiDashboardScreen> createState() => _AiDashboardScreenState();
}

class _AiDashboardScreenState extends State<AiDashboardScreen> {
  DailyScheduleSuggestion? _suggestion;
  SmartSchedulePlan? _plan;
  bool _loading = true;
  bool _generating = false;
  bool _updating = false;
  bool _allowOverlap = false;
  String? _error;
  Map<String, SmartTaskPlan> _appliedPlans = const {};

  void _openScheduledTask(SmartScheduledTask scheduledTask) {
    for (final task in MyTimeStore.instance.tasks) {
      if (task.id == scheduledTask.taskId.toString()) {
        MyTimeStore.instance.selectTask(task);
        Navigator.pushNamed(context, AppRoutes.taskDetail);
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please login again to use smart scheduling.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AiService.instance.getDailySuggestion(token),
        AiService.instance.getTodaySmartSchedule(token),
      ]);
      final suggestion = results[0] as DailyScheduleSuggestion;
      final plan = results[1] as SmartSchedulePlan;
      final appliedPlans = await AppliedSmartPlanStore.instance.getPlansForTasks(
        plan.scheduledTasks.map((task) => task.taskId.toString()),
      );

      if (!mounted) return;
      setState(() {
        _suggestion = suggestion;
        _plan = plan.scheduledTasks.isEmpty ? null : plan;
        _appliedPlans = appliedPlans;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _generateSmartSchedule() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final plan = await AiService.instance.generateSmartSchedule(token);
      final appliedPlans = await AppliedSmartPlanStore.instance.getPlansForTasks(
        plan.scheduledTasks.map((task) => task.taskId.toString()),
      );
      if (!mounted) return;

      setState(() {
        _plan = plan;
        _appliedPlans = appliedPlans;
        _suggestion = DailyScheduleSuggestion(
          suggestion: plan.dailySuggestion,
          highlightTaskTitle: plan.suggestedTaskOrder.isEmpty
              ? null
              : plan.suggestedTaskOrder.first['title']?.toString(),
          highlightScore: _asDouble(
            plan.suggestedTaskOrder.isEmpty
                ? null
                : plan.suggestedTaskOrder.first['aiScore'],
          ),
        );
        _generating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _moveScheduledTask(
    SmartScheduledTask task,
    DateTime newStart,
  ) async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final currentPlan = _plan;
    if (currentPlan == null) return;

    final sourceTask = currentPlan.scheduledTasks.firstWhere(
      (item) => item.id == task.sourceScheduledTaskId,
      orElse: () => task,
    );
    final updatedStart = newStart.subtract(
      Duration(minutes: task.segmentOffsetMinutes),
    );
    final updatedEnd = updatedStart.add(sourceTask.duration);

    setState(() {
      _updating = true;
      _error = null;
    });

    try {
      final updated = await AiService.instance.updateScheduledTask(
        token: token,
        scheduledTaskId: sourceTask.id,
        startTime: updatedStart,
        endTime: updatedEnd,
        allowOverlap: _allowOverlap,
        shiftConflicts: !_allowOverlap,
      );

      if (!mounted) return;

      setState(() {
        final tasks =
            currentPlan.scheduledTasks
                .map((item) => item.id == updated.id ? updated : item)
                .toList()
              ..sort(
                (first, second) => first.startTime.compareTo(second.startTime),
              );

        _plan = SmartSchedulePlan(
          generatedAt: currentPlan.generatedAt,
          dailySuggestion: currentPlan.dailySuggestion,
          suggestedTaskOrder: currentPlan.suggestedTaskOrder,
          scheduledTasks: _recomputeOverlapFlags(tasks),
        );

        _updating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updating = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedTasks = _plan == null
        ? const <SmartScheduledTask>[]
        : _buildDisplayedScheduledTasks(_plan!.scheduledTasks, _appliedPlans);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Schedule'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
            icon: const Icon(Icons.home_rounded),
          ),
          IconButton(
            tooltip: 'Refresh suggestion',
            onPressed: _loading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI Smart Scheduling',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _suggestion?.suggestion ??
                            'Generate a smart schedule and AI will plan your day.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_suggestion?.highlightTaskTitle != null) ...[
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.flag_rounded,
                          label: _suggestion!.highlightTaskTitle!,
                        ),
                      ],
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _allowOverlap,
                        onChanged: (value) {
                          setState(() => _allowOverlap = value);
                        },
                        title: const Text('Allow overlap'),
                        subtitle: Text(
                          _allowOverlap
                              ? 'Dropped tasks can overlap when the day is busy.'
                              : 'Dropped tasks shift forward to avoid conflicts.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generating
                              ? null
                              : _generateSmartSchedule,
                          icon: _generating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.smart_toy_rounded),
                          label: Text(
                            _generating
                                ? 'Generating...'
                                : 'Generate Smart Schedule',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Suggested task order',
                  child: (_plan?.suggestedTaskOrder.isEmpty ?? true)
                      ? const Text(
                          'Generate a schedule to see suggested task order.',
                        )
                      : Column(
                          children: _plan!.suggestedTaskOrder
                              .map((item) => _TaskOrderRow(task: item))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Timeline',
                  child: _plan == null
                      ? const Text(
                          'Your day timeline will appear here after generation.',
                        )
                      : _TimelineBoard(
                          tasks: displayedTasks,
                          preferredStartTime: MyTimeStore
                              .instance
                              .setting
                              .preferredFocusStartTime,
                          preferredEndTime: MyTimeStore
                              .instance
                              .setting
                              .preferredFocusEndTime,
                          updating: _updating,
                          onMoveTask: _moveScheduledTask,
                          onOpenTask: _openScheduledTask,
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TaskOrderRow extends StatelessWidget {
  const _TaskOrderRow({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.72 : 0.94,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title']?.toString() ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${task['focusMinutes']} min • ${task['priority']} • ${task['status']}',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineBoard extends StatelessWidget {
  const _TimelineBoard({
    required this.tasks,
    required this.preferredStartTime,
    required this.preferredEndTime,
    required this.updating,
    required this.onMoveTask,
    required this.onOpenTask,
  });

  final List<SmartScheduledTask> tasks;
  final String? preferredStartTime;
  final String? preferredEndTime;
  final bool updating;
  final Future<void> Function(SmartScheduledTask task, DateTime newStart)
  onMoveTask;
  final void Function(SmartScheduledTask task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final timelineStart = _parseClockTime(preferredStartTime, fallbackHour: 8);
    final timelineEnd = _parseClockTime(preferredEndTime, fallbackHour: 20);
    final slotMinutes = 30;
    final pixelsPerMinute = 2.0;
    final totalMinutes = timelineEnd.inMinutes - timelineStart.inMinutes;
    final totalHeight = totalMinutes * pixelsPerMinute;
    final day = tasks.isEmpty ? DateTime.now() : tasks.first.startTime;
    final placedTasks = _buildPlacedTasks(
      tasks,
      timelineStart,
      pixelsPerMinute,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 340,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: totalHeight,
              child: Stack(
                children: [
                  for (
                    int minute = 0;
                    minute <= totalMinutes;
                    minute += slotMinutes
                  )
                    Positioned(
                      top: minute * pixelsPerMinute - 10,
                      left: 0,
                      child: Text(
                        _formatTimelineLabel(timelineStart.inMinutes + minute),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: totalHeight,
                child: Stack(
                  children: [
                    for (
                      int minute = 0;
                      minute < totalMinutes;
                      minute += slotMinutes
                    )
                      Positioned(
                        top: minute * pixelsPerMinute,
                        left: 0,
                        right: 0,
                        height: slotMinutes * pixelsPerMinute,
                        child: DragTarget<SmartScheduledTask>(
                          onAcceptWithDetails: updating
                              ? null
                              : (details) {
                                  final newStart =
                                      DateTime(
                                        day.year,
                                        day.month,
                                        day.day,
                                      ).add(
                                        Duration(
                                          minutes:
                                              timelineStart.inMinutes + minute,
                                        ),
                                      );
                                  onMoveTask(details.data, newStart);
                                },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                color: candidateData.isEmpty
                                    ? Colors.transparent
                                    : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.08),
                              ),
                            );
                          },
                        ),
                      ),
                    for (final placed in placedTasks)
                      Positioned(
                        top: placed.top,
                        left: placed.left,
                        right: placed.right,
                        height: placed.height,
                        child: _TimelineDraggableCard(
                          task: placed.task,
                          onOpenTask: onOpenTask,
                        ),
                      ),
                    if (updating)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.06),
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(8),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTaskCard extends StatelessWidget {
  const _TimelineTaskCard({required this.task});

  final SmartScheduledTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationMinutes = task.duration.inMinutes;
    final isTiny = durationMinutes <= 30;
    final isCompact = durationMinutes <= 35;
    final segmentLabel = task.segmentLabel;
    final priorityColor = task.priorityScore >= 100
        ? theme.colorScheme.error
        : task.priorityScore >= 60
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final difficultyColor = switch (task.difficulty) {
      >= 5 => const Color(0xFF7C3AED),
      4 => const Color(0xFF2563EB),
      3 => const Color(0xFF16A34A),
      _ => const Color(0xFFF59E0B),
    };

    return Container(
      padding: EdgeInsets.all(isTiny ? 4 : (isCompact ? 7 : 10)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.94 : 0.98,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isBreakSegment
              ? theme.colorScheme.secondary
              : task.isOverlapping
              ? theme.colorScheme.error
              : priorityColor,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.isBreakSegment ? (segmentLabel ?? 'Break') : task.title,
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isTiny ? 12 : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (!task.isBreakSegment)
                Text(
                  '#${task.sessionNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: isTiny ? 9 : null,
                  ),
                ),
            ],
          ),
          if (!task.isBreakSegment &&
              segmentLabel != null &&
              segmentLabel.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                segmentLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: isTiny ? 9 : 11,
                ),
              ),
            ),
          if (isTiny)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '${_formatClock(task.startTime)}-${_formatClock(task.endTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            )
          else if (isCompact)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatClock(task.startTime)}-${_formatClock(task.endTime)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (task.isOverlapping) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${_formatClock(task.startTime)} - ${_formatClock(task.endTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _MiniTag(
                        label: '${task.estimatedMinutes}m',
                        color: task.isBreakSegment
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                      if (task.isFromAppliedPlan)
                        _MiniTag(
                          label: '${task.planSessionCount} parts',
                          color: theme.colorScheme.tertiary,
                        ),
                      _MiniTag(label: 'D${task.difficulty}', color: difficultyColor),
                      _MiniTag(
                        label: 'P${task.priorityScore ~/ 20}',
                        color: priorityColor,
                      ),
                      if (task.isOverlapping)
                        _MiniTag(label: 'Overlap', color: theme.colorScheme.error),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineDraggableCard extends StatelessWidget {
  const _TimelineDraggableCard({
    required this.task,
    required this.onOpenTask,
  });

  final SmartScheduledTask task;
  final void Function(SmartScheduledTask task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: () => onOpenTask(task),
      child: _TimelineTaskCard(task: task),
    );
    final canDrag = !task.isBreakSegment && task.isPrimarySegment;
    if (!canDrag) {
      return card;
    }

    return LongPressDraggable<SmartScheduledTask>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 180, child: _TimelineTaskCard(task: task)),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: card),
      child: card,
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacedTask {
  const _PlacedTask({
    required this.task,
    required this.top,
    required this.height,
    required this.left,
    required this.right,
  });

  final SmartScheduledTask task;
  final double top;
  final double height;
  final double left;
  final double right;
}

List<_PlacedTask> _buildPlacedTasks(
  List<SmartScheduledTask> tasks,
  Duration timelineStart,
  double pixelsPerMinute,
) {
  final sorted = [...tasks]..sort((a, b) => a.startTime.compareTo(b.startTime));
  final placed = <_PlacedTask>[];
  final active = <_PlacedTask>[];

  for (final task in sorted) {
    active.removeWhere(
      (item) => !item.task.endTime.isAfter(task.startTime),
    );
    final column = active.length;
    final top =
        task.startTime
            .difference(
              DateTime(
                task.startTime.year,
                task.startTime.month,
                task.startTime.day,
              ).add(timelineStart),
            )
            .inMinutes *
        pixelsPerMinute;
    final minimumHeight = task.duration.inMinutes <= 30 ? 48 : 60;
    final height = (task.duration.inMinutes * pixelsPerMinute).clamp(
      minimumHeight,
      220,
    );
    final placedTask = _PlacedTask(
      task: task,
      top: top,
      height: height.toDouble(),
      left: 8 + (column * 22),
      right: 8 + (column * 18),
    );
    active.add(placedTask);
    placed.add(placedTask);
  }

  return placed;
}

List<SmartScheduledTask> _buildDisplayedScheduledTasks(
  List<SmartScheduledTask> tasks,
  Map<String, SmartTaskPlan> appliedPlans,
) {
  final expanded = <SmartScheduledTask>[];

  for (final task in tasks) {
    final appliedPlan = appliedPlans[task.taskId.toString()];
    final pomodoroPlan = appliedPlan?.pomodoroPlan ?? const [];
    final focusSegments = pomodoroPlan.where((item) => !item.isBreak).length;

    if (pomodoroPlan.isEmpty || focusSegments == 0) {
      expanded.add(
        task.copyWith(
          sourceScheduledTaskId: task.id,
          segmentOffsetMinutes: 0,
          isPrimarySegment: true,
          planSessionCount: 1,
          isFromAppliedPlan: false,
        ),
      );
      continue;
    }

    var currentStart = task.startTime;
    var focusIndex = 0;
    for (var index = 0; index < pomodoroPlan.length; index++) {
      final segment = pomodoroPlan[index];
      final segmentEnd = currentStart.add(Duration(minutes: segment.minutes));
      expanded.add(
        SmartScheduledTask(
          id: index == 0 ? task.id : (task.id * 1000) + index,
          taskId: task.taskId,
          title: task.title,
          startTime: currentStart,
          endTime: segmentEnd,
          sessionNumber: segment.isBreak ? focusIndex : focusIndex + 1,
          estimatedMinutes: segment.minutes,
          difficulty: task.difficulty,
          priorityScore: task.priorityScore,
          aiScore: task.aiScore,
          isOverlapping: task.isOverlapping,
          segmentLabel: segment.label,
          isBreakSegment: segment.isBreak,
          sourceScheduledTaskId: task.id,
          segmentOffsetMinutes: currentStart
              .difference(task.startTime)
              .inMinutes,
          isPrimarySegment: index == 0,
          planSessionCount: focusSegments,
          isFromAppliedPlan: true,
        ),
      );
      if (!segment.isBreak) {
        focusIndex += 1;
      }
      currentStart = segmentEnd;
    }
  }

  expanded.sort((first, second) => first.startTime.compareTo(second.startTime));
  return _recomputeOverlapFlags(expanded);
}

List<SmartScheduledTask> _recomputeOverlapFlags(
  List<SmartScheduledTask> tasks,
) {
  return tasks.map((task) {
    final overlapping = tasks.any((other) {
      if (other.id == task.id) return false;
      return task.startTime.isBefore(other.endTime) &&
          task.endTime.isAfter(other.startTime);
    });
    return task.copyWith(isOverlapping: overlapping);
  }).toList();
}

Duration _parseClockTime(String? text, {required int fallbackHour}) {
  if (text == null || text.isEmpty) {
    return Duration(hours: fallbackHour);
  }

  final parts = text.split(':');
  if (parts.length < 2) {
    return Duration(hours: fallbackHour);
  }

  return Duration(
    hours: int.tryParse(parts[0]) ?? fallbackHour,
    minutes: int.tryParse(parts[1]) ?? 0,
  );
}

String _formatClock(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatTimelineLabel(int totalMinutes) {
  final hour = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final minute = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
