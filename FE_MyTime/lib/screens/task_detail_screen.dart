import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/models/smart_task_plan.dart';
import 'package:project/screens/smart_task_plan_screen.dart';
import 'package:project/services/applied_smart_plan_store.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int _planVersion = 0;
  bool _restoringPlan = false;

  Future<void> _deleteTask(BuildContext context, FocusTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      try {
        await MyTimeStore.instance.deleteTask(task);
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.tasks,
          (route) => route.isFirst,
        );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _cancelSmartPlan(FocusTask task) async {
    if (_restoringPlan) return;

    final originalTask = await AppliedSmartPlanStore.instance.getOriginalTask(
      task.id,
    );
    if (originalTask == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original task snapshot was not found.')),
      );
      return;
    }

    if (!mounted) return;
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Smart Plan'),
          content: const Text(
            'Restore this task to the version before Smart Plan was applied?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep plan'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (shouldRestore != true || !mounted) return;

    setState(() => _restoringPlan = true);
    try {
      await MyTimeStore.instance.restoreTaskSnapshot(originalTask);
      await AppliedSmartPlanStore.instance.clearPlan(task.id);
      await AppliedSmartPlanStore.instance.clearOriginalTask(task.id);
      if (!mounted) return;
      setState(() {
        _planVersion += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smart Plan cancelled. Task restored.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _restoringPlan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final task = store.selectedTask;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task details')),
            body: const Center(child: Text('Task not found.')),
          );
        }

        final progress = task.outputs.isEmpty
            ? 0.0
            : task.completedOutputCount / task.outputs.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task details'),
            actions: [
              IconButton(
                tooltip: 'Home',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                icon: const Icon(Icons.home_rounded),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addTask,
                    arguments: task,
                  );
                },
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _deleteTask(context, task),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(task.description),
                    const Divider(height: 28),
                    _InfoTile(
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: _statusText(task.status),
                    ),
                    _InfoTile(
                      icon: Icons.timer_outlined,
                      label: 'Focus duration',
                      value: '${task.focusMinutes} minutes',
                    ),
                    _InfoTile(
                      icon: Icons.flag_outlined,
                      label: 'Priority',
                      value: _priorityText(task.priority),
                    ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Planned date',
                      value: _formatDate(task.scheduledDate),
                    ),
                    _InfoTile(
                      icon: Icons.repeat,
                      label: 'Repeat',
                      value: _repeatText(task.repeat),
                    ),
                    _InfoTile(
                      icon: Icons.notifications_outlined,
                      label: 'Reminder',
                      value: task.reminderEnabled
                          ? 'At ${task.reminderTime}'
                          : 'No reminder',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<SmartTaskPlan?>(
                key: ValueKey('${task.id}_$_planVersion'),
                future: AppliedSmartPlanStore.instance.getPlan(task.id),
                builder: (context, snapshot) {
                  final plan = snapshot.data;
                  if (plan == null) return const SizedBox.shrink();

                  return _AppliedPlanCard(
                    plan: plan,
                    restoring: _restoringPlan,
                    onCancel: () => _cancelSmartPlan(task),
                  );
                },
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title:
                    'Output (${task.completedOutputCount}/${task.outputs.length})',
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.progressTrack,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: task.outputs
                      .map(
                        (output) => ListTile(
                          leading: Icon(
                            output.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: output.isCompleted
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          title: Text(output.title),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: task.isCompleted || !task.canStartToday
                    ? null
                    : () {
                        store.startTask(task);
                        Navigator.pushNamed(context, AppRoutes.focus);
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  task.isCompleted
                      ? 'Task completed'
                      : task.canStartToday
                      ? 'Start Focus Time'
                      : 'Available on ${_formatDate(task.scheduledDate)}',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addTask,
                    arguments: task,
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit task'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.smartTaskPlan,
                    arguments: SmartTaskPlanArguments(task: task),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Smart Plan'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.aiDashboard),
                icon: const Icon(Icons.calendar_view_day_rounded),
                label: const Text('View in Timeline'),
              ),
              OutlinedButton.icon(
                onPressed: () => _deleteTask(context, task),
                icon: const Icon(Icons.delete),
                label: const Text('Delete task'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _AppliedPlanCard extends StatelessWidget {
  const _AppliedPlanCard({
    required this.plan,
    required this.restoring,
    required this.onCancel,
  });

  final SmartTaskPlan plan;
  final bool restoring;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applied Smart Plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.recommendedFocusMode} • ${plan.suggestedFocusMinutes} min',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.pomodoroPlan.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    item.isBreak
                        ? Icons.free_breakfast_rounded
                        : Icons.timer_outlined,
                    size: 18,
                    color: item.isBreak
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${item.minutes} min',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: restoring ? null : onCancel,
              icon: restoring
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore_rounded),
              label: Text(restoring ? 'Restoring...' : 'Cancel Smart Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusText(FocusTaskStatus status) {
  switch (status) {
    case FocusTaskStatus.todo:
      return 'To do';
    case FocusTaskStatus.processing:
      return 'In progress';
    case FocusTaskStatus.completed:
      return 'Completed';
  }
}

String _priorityText(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
  }
}

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

String _repeatText(TaskRepeat repeat) {
  switch (repeat) {
    case TaskRepeat.none:
      return 'No repeat';
    case TaskRepeat.daily:
      return 'Daily';
    case TaskRepeat.weekly:
      return 'Weekly';
    case TaskRepeat.monthly:
      return 'Monthly';
  }
}
