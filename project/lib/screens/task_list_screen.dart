import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
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

  void _startFocus(FocusTask task) {
    MyTimeStore.instance.startTask(task);
    Navigator.pushNamed(context, AppRoutes.focus);
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
      MyTimeStore.instance.deleteTask(task);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
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
                      return _TaskCard(
                        task: task,
                        onTap: () => _openTask(task),
                        onStart: () => _startFocus(task),
                        onEdit: () => _editTask(task),
                        onDelete: () => _deleteTask(task),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task board',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Plan work, choose focus time, and track outputs.',
            style: TextStyle(color: Color(0xFFE8F5FF)),
          ),
          const SizedBox(height: 16),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
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
    return AppCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                color: AppColors.textSecondary,
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
            const Text(
              'Priority',
              style: TextStyle(
                color: AppColors.textSecondary,
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
            color: selected ? AppColors.primary : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
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
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusTask task;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = task.outputs.isEmpty
        ? 0.0
        : task.completedOutputCount / task.outputs.length;
    final canStart = task.canStartToday;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
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
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text('${task.focusMinutes} min focus'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Task actions',
                onPressed: () => _showActions(context),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
              _InfoBadge(
                icon: Icons.calendar_today_outlined,
                label: _formatDate(task.scheduledDate),
                color: AppColors.primary,
              ),
              if (task.repeat != TaskRepeat.none)
                _InfoBadge(
                  icon: Icons.repeat_rounded,
                  label: _repeatText(task.repeat),
                  color: AppColors.secondary,
                ),
              if (task.reminderEnabled)
                _InfoBadge(
                  icon: Icons.notifications_active_outlined,
                  label: task.reminderTime,
                  color: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: AppColors.primary,
              backgroundColor: AppColors.progressTrack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${task.completedOutputCount}/${task.outputs.length} outputs done',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              if (!canStart && !task.isCompleted)
                Text(
                  'Starts ${_formatDate(task.scheduledDate)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: task.isCompleted
                  ? null
                  : canStart
                  ? onStart
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                task.isCompleted
                    ? 'Completed'
                    : canStart
                    ? 'Focus on this task'
                    : 'Future plan only',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
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
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit task'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Delete task',
                    style: TextStyle(color: AppColors.danger),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 52,
                color: AppColors.primary,
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
