import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/screens/smart_task_plan_screen.dart';
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
  static const int _tasksPerDayPage = 10;

  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  TaskPriorityFilter _priorityFilter = TaskPriorityFilter.all;
  @override
  void initState() {
    super.initState();
    MyTimeStore.instance.loadTasksFromApi();
  }

  List<FocusTask> _filteredTasks(List<FocusTask> tasks) {
    final filtered = tasks.where((task) {
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

    filtered.sort((first, second) {
      final firstDate = DateTime(
        first.scheduledDate.year,
        first.scheduledDate.month,
        first.scheduledDate.day,
      );
      final secondDate = DateTime(
        second.scheduledDate.year,
        second.scheduledDate.month,
        second.scheduledDate.day,
      );
      final byDate = firstDate.compareTo(secondDate);
      if (byDate != 0) return byDate;
      if (first.isCompleted != second.isCompleted) {
        return first.isCompleted ? 1 : -1;
      }
      return first.title.toLowerCase().compareTo(second.title.toLowerCase());
    });
    return filtered;
  }

  List<_TaskDayGroup> _groupTasksByDate(List<FocusTask> tasks) {
    final grouped = <DateTime, List<FocusTask>>{};
    for (final task in tasks) {
      final key = DateTime(
        task.scheduledDate.year,
        task.scheduledDate.month,
        task.scheduledDate.day,
      );
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final dates = grouped.keys.toList()..sort();
    return [
      for (final date in dates) _TaskDayGroup(date: date, tasks: grouped[date]!),
    ];
  }

  void _openTask(FocusTask task) {
    MyTimeStore.instance.selectTask(task);
    Navigator.pushNamed(context, AppRoutes.taskDetail);
  }

  void _editTask(FocusTask task) {
    Navigator.pushNamed(context, AppRoutes.addTask, arguments: task);
  }

  void _openSmartPlan(FocusTask task) {
    Navigator.pushNamed(
      context,
      AppRoutes.smartTaskPlan,
      arguments: SmartTaskPlanArguments(task: task),
    );
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
      try {
        await MyTimeStore.instance.deleteTask(task);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
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
          final dayGroups = _groupTasksByDate(tasks);

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
                    itemCount: dayGroups.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 14);
                    },
                    itemBuilder: (context, index) {
                      final group = dayGroups[index];
                      return _TaskDayGroupCard(
                        key: ValueKey(
                          'task-day-${group.date.year}-${group.date.month}-${group.date.day}-${group.tasks.length}',
                        ),
                        date: group.date,
                        tasks: group.tasks,
                        tasksPerPage: _tasksPerDayPage,
                        onOpenTask: _openTask,
                        onEditTask: _editTask,
                        onDeleteTask: _deleteTask,
                        onOpenSmartPlan: _openSmartPlan,
                        onOpenTimeline: () => Navigator.pushNamed(
                          context,
                          AppRoutes.aiDashboard,
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

class _TaskDayGroup {
  const _TaskDayGroup({required this.date, required this.tasks});

  final DateTime date;
  final List<FocusTask> tasks;
}

class _TaskDayGroupCard extends StatefulWidget {
  const _TaskDayGroupCard({
    super.key,
    required this.date,
    required this.tasks,
    required this.tasksPerPage,
    required this.onOpenTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onOpenSmartPlan,
    required this.onOpenTimeline,
  });

  final DateTime date;
  final List<FocusTask> tasks;
  final int tasksPerPage;
  final ValueChanged<FocusTask> onOpenTask;
  final ValueChanged<FocusTask> onEditTask;
  final Future<void> Function(FocusTask task) onDeleteTask;
  final ValueChanged<FocusTask> onOpenSmartPlan;
  final VoidCallback onOpenTimeline;

  @override
  State<_TaskDayGroupCard> createState() => _TaskDayGroupCardState();
}

class _TaskDayGroupCardState extends State<_TaskDayGroupCard> {
  int _pageIndex = 0;

  @override
  void didUpdateWidget(covariant _TaskDayGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPage = _pageCount - 1;
    if (_pageIndex > maxPage) {
      _pageIndex = maxPage < 0 ? 0 : maxPage;
    }
  }

  int get _pageCount {
    return (widget.tasks.length / widget.tasksPerPage).ceil().clamp(1, 9999);
  }

  List<FocusTask> get _visibleTasks {
    final start = _pageIndex * widget.tasksPerPage;
    final end = (start + widget.tasksPerPage).clamp(0, widget.tasks.length);
    return widget.tasks.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTasks = widget.tasks.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(widget.date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalTasks task(s) planned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pageCount > 1)
                _InlinePager(
                  currentPage: _pageIndex + 1,
                  totalPages: _pageCount,
                  onPrevious: _pageIndex == 0
                      ? null
                      : () => setState(() => _pageIndex--),
                  onNext: _pageIndex >= _pageCount - 1
                      ? null
                      : () => setState(() => _pageIndex++),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._visibleTasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TaskSwipeActions(
                task: task,
                onEdit: () => widget.onEditTask(task),
                onDelete: () => widget.onDeleteTask(task),
                child: _TaskCard(
                  task: task,
                  onTap: () => widget.onOpenTask(task),
                  onEdit: () => widget.onEditTask(task),
                  onDelete: () => widget.onDeleteTask(task),
                  onOpenSmartPlan: () => widget.onOpenSmartPlan(task),
                  onOpenTimeline: widget.onOpenTimeline,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InlinePager extends StatelessWidget {
  const _InlinePager({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous page',
          visualDensity: VisualDensity.compact,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          '$currentPage/$totalPages',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        IconButton(
          tooltip: 'Next page',
          visualDensity: VisualDensity.compact,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
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
    required this.onOpenSmartPlan,
    required this.onOpenTimeline,
  });

  final FocusTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenSmartPlan;
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compactActions = constraints.maxWidth < 265;

                    if (compactActions) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detailText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _TaskActionChip(
                                icon: Icons.auto_awesome_rounded,
                                label: 'Smart Plan',
                                backgroundColor: const Color(0xFFFFF2D9),
                                foregroundColor: AppColors.primary,
                                tooltip: 'Create Smart Plan',
                                onTap: onOpenSmartPlan,
                              ),
                              _TaskActionChip(
                                icon: Icons.calendar_view_day_rounded,
                                label: 'Timeline',
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.10),
                                foregroundColor: theme.colorScheme.primary,
                                tooltip: 'View in AI Timeline',
                                onTap: onOpenTimeline,
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
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
                        _TaskActionChip(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Smart Plan',
                          backgroundColor: const Color(0xFFFFF2D9),
                          foregroundColor: AppColors.primary,
                          tooltip: 'Create Smart Plan',
                          onTap: onOpenSmartPlan,
                        ),
                        const SizedBox(width: 4),
                        _TaskActionChip(
                          icon: Icons.calendar_view_day_rounded,
                          label: 'Timeline',
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          foregroundColor: theme.colorScheme.primary,
                          tooltip: 'View in AI Timeline',
                          onTap: onOpenTimeline,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    );
                  },
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
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Create Smart Plan'),
                  onTap: () {
                    Navigator.pop(context);
                    onOpenSmartPlan();
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

class _TaskActionChip extends StatelessWidget {
  const _TaskActionChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foregroundColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
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
