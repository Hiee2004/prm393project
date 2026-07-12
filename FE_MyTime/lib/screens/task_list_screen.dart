import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';

enum TaskStatusFilter { all, todo, processing, completed }

enum TaskPriorityFilter { all, high, medium, low }

enum TaskAction { edit, delete }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  TaskPriorityFilter _priorityFilter = TaskPriorityFilter.all;
  @override
  void initState() {
    super.initState();
    MyTimeStore.instance.loadTasksFromApi();
  }

  List<FocusTask> _filteredTasks(List<FocusTask> tasks) {
    return tasks.where((task) {
      final matchesStatus = switch (_statusFilter) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.todo => task.status == FocusTaskStatus.todo,
        TaskStatusFilter.processing =>
          task.status == FocusTaskStatus.processing,
        TaskStatusFilter.completed => task.status == FocusTaskStatus.completed,
      };

      final matchesPriority = switch (_priorityFilter) {
        TaskPriorityFilter.all => true,
        TaskPriorityFilter.high => task.priority == TaskPriority.high,
        TaskPriorityFilter.medium => task.priority == TaskPriority.medium,
        TaskPriorityFilter.low => task.priority == TaskPriority.low,
      };

      return matchesStatus && matchesPriority;
    }).toList();
  }

  void _openTask(FocusTask task) {
    MyTimeStore.instance.selectTask(task);
    Navigator.pushNamed(context, AppRoutes.taskDetail);
  }

  void _editTask(FocusTask task) {
    Navigator.pushNamed(context, AppRoutes.addTask, arguments: task);
  }

  Future<void> _deleteTask(FocusTask task) async {
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

    if (shouldDelete == true) {
      await MyTimeStore.instance.deleteTask(task);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = MyTimeStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
            icon: const Icon(Icons.home_rounded),
          ),
          IconButton(
            tooltip: 'AI planner',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.aiDashboard),
            icon: const Icon(Icons.smart_toy_rounded),
          ),
          IconButton(
            tooltip: 'Add task',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final tasks = _filteredTasks(store.tasks);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: _TaskHeader(
                    totalTasks: store.tasks.length,
                    visibleTasks: tasks.length,
                    completedTasks: store.completedTaskCount,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _FilterStrip(
                  statusFilter: _statusFilter,
                  priorityFilter: _priorityFilter,
                  onStatusChanged: (value) {
                    setState(() => _statusFilter = value);
                  },
                  onPriorityChanged: (value) {
                    setState(() => _priorityFilter = value);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: AppCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Time Manager',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Generate a task order, timeline, and Pomodoro plan.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.aiDashboard,
                          ),
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (tasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyTasks(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                  sliver: SliverList.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 14);
                    },
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskSwipeActions(
                        task: task,
                        onEdit: () => _editTask(task),
                        onDelete: () => _deleteTask(task),
                        child: _TaskCard(
                          task: task,
                          onTap: () => _openTask(task),
                          onEdit: () => _editTask(task),
                          onDelete: () => _deleteTask(task),
                          onOpenTimeline: () => Navigator.pushNamed(
                            context,
                            AppRoutes.aiDashboard,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
    );
  }
}

class _TaskSwipeActions extends StatelessWidget {
  const _TaskSwipeActions({
    required this.task,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusTask task;
  final Widget child;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('task-${task.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        await onDelete();
        return false;
      },
      background: const _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.secondary,
        icon: Icons.edit_rounded,
        label: 'Edit',
      ),
      secondaryBackground: const _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: AppColors.danger,
        icon: Icons.delete_rounded,
        label: 'Delete',
      ),
      child: child,
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({
    required this.totalTasks,
    required this.visibleTasks,
    required this.completedTasks,
  });

  final int totalTasks;
  final int visibleTasks;
  final int completedTasks;

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
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.72 : 0.88,
            ),
          ],
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
            'Task board',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'A compact list for today and the next tasks.',
            style: TextStyle(color: Color(0xFFE8F5FF)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderMetric(value: '$visibleTasks', label: 'Visible'),
              const SizedBox(width: 10),
              _HeaderMetric(value: '$totalTasks', label: 'Total'),
              const SizedBox(width: 10),
              _HeaderMetric(value: '$completedTasks', label: 'Done'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            Text(label, style: const TextStyle(color: Color(0xFFE8F5FF))),
          ],
        ),
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.statusFilter,
    required this.priorityFilter,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  final TaskStatusFilter statusFilter;
  final TaskPriorityFilter priorityFilter;
  final ValueChanged<TaskStatusFilter> onStatusChanged;
  final ValueChanged<TaskPriorityFilter> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskStatusFilter.values.map((filter) {
                  return _ChoicePill(
                    label: _statusFilterText(filter),
                    selected: statusFilter == filter,
                    onTap: () => onStatusChanged(filter),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Priority',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskPriorityFilter.values.map((filter) {
                  return _ChoicePill(
                    label: _priorityFilterText(filter),
                    selected: priorityFilter == filter,
                    onTap: () => onPriorityChanged(filter),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        key: ValueKey('filter-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.70 : 0.88,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenTimeline,
  });

  final FocusTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaText = [
      '${task.focusMinutes} min focus',
      _formatDate(task.scheduledDate),
      if (task.repeat != TaskRepeat.none) _repeatText(task.repeat),
    ].join(' • ');
    final detailText = [
      '${task.completedOutputCount}/${task.outputs.length} outputs',
      if (task.reminderEnabled) task.reminderTime,
    ].join(' • ');

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _statusColor(task.status).withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _statusIcon(task.status),
              color: _statusColor(task.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: task.isCompleted
                                      ? AppColors.textSecondary
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metaText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Task actions',
                      onPressed: () => _showActions(context),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ],
                ),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoBadge(
                      icon: _statusIcon(task.status),
                      label: _statusText(task.status),
                      color: _statusColor(task.status),
                    ),
                    _InfoBadge(
                      icon: Icons.flag_rounded,
                      label: _priorityText(task.priority),
                      color: _priorityColor(task.priority),
                    ),
                    if (task.reminderEnabled)
                      _InfoBadge(
                        icon: Icons.notifications_active_outlined,
                        label: task.reminderTime,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detailText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'View in AI Timeline',
                      child: InkWell(
                        onTap: onOpenTimeline,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_view_day_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Timeline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.94 : 0.98,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Edit task'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete task',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 52,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                'No tasks found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Try changing the status or priority filter.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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

String _statusFilterText(TaskStatusFilter filter) {
  switch (filter) {
    case TaskStatusFilter.all:
      return 'All statuses';
    case TaskStatusFilter.todo:
      return 'To do';
    case TaskStatusFilter.processing:
      return 'In progress';
    case TaskStatusFilter.completed:
      return 'Completed';
  }
}

IconData _statusIcon(FocusTaskStatus status) {
  switch (status) {
    case FocusTaskStatus.todo:
      return Icons.radio_button_unchecked_rounded;
    case FocusTaskStatus.processing:
      return Icons.timelapse_rounded;
    case FocusTaskStatus.completed:
      return Icons.check_circle_rounded;
  }
}

Color _statusColor(FocusTaskStatus status) {
  switch (status) {
    case FocusTaskStatus.todo:
      return AppColors.primary;
    case FocusTaskStatus.processing:
      return AppColors.warning;
    case FocusTaskStatus.completed:
      return AppColors.success;
  }
}

String _priorityText(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'High priority';
    case TaskPriority.medium:
      return 'Medium priority';
    case TaskPriority.low:
      return 'Low priority';
  }
}

String _priorityFilterText(TaskPriorityFilter filter) {
  switch (filter) {
    case TaskPriorityFilter.all:
      return 'All priorities';
    case TaskPriorityFilter.high:
      return 'High priority';
    case TaskPriorityFilter.medium:
      return 'Medium priority';
    case TaskPriorityFilter.low:
      return 'Low priority';
  }
}

Color _priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return AppColors.danger;
    case TaskPriority.medium:
      return AppColors.primary;
    case TaskPriority.low:
      return AppColors.secondary;
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
