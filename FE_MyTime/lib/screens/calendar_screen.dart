import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/screens/add_focus_task_screen.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_card.dart';

enum CalendarViewType { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewType _view = CalendarViewType.day;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final store = MyTimeStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Create task',
            onPressed: _openCreateTask,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _MonthCalendarCard(
                selectedDate: _selectedDate,
                onPreviousMonth: () => _moveMonth(-1),
                onNextMonth: () => _moveMonth(1),
                onSelectDate: (date) {
                  setState(() => _selectedDate = date);
                  store.updateSelectedCalendarDate(date);
                },
              ),
              const SizedBox(height: 14),
              _ViewModeSelector(
                value: _view,
                onChanged: (value) {
                  setState(() => _view = value);
                },
              ),
              const SizedBox(height: 18),
              _AgendaHeader(view: _view, selectedDate: _selectedDate),
              const SizedBox(height: 10),
              _buildAgendaView(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTask,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildAgendaView() {
    switch (_view) {
      case CalendarViewType.day:
        return _DayAgenda(
          date: _selectedDate,
          tasks: MyTimeStore.instance.tasksForDate(_selectedDate),
          onOpenTask: _openTask,
          onEditTask: _editTask,
          onDeleteTask: _deleteTask,
        );
      case CalendarViewType.week:
        return _WeekAgenda(
          selectedDate: _selectedDate,
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
              _view = CalendarViewType.day;
            });
            MyTimeStore.instance.updateSelectedCalendarDate(date);
          },
          onOpenTask: _openTask,
          onEditTask: _editTask,
          onDeleteTask: _deleteTask,
        );
      case CalendarViewType.month:
        return _MonthAgenda(
          selectedDate: _selectedDate,
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
              _view = CalendarViewType.day;
            });
            MyTimeStore.instance.updateSelectedCalendarDate(date);
          },
          onOpenTask: _openTask,
          onEditTask: _editTask,
          onDeleteTask: _deleteTask,
        );
    }
  }

  void _moveMonth(int direction) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
        _selectedDate.day,
      );
    });
  }

  void _openTask(FocusTask task) {
    MyTimeStore.instance.selectTask(task);
    Navigator.pushNamed(context, AppRoutes.taskDetail);
  }

  void _editTask(FocusTask task) {
    Navigator.pushNamed(
      context,
      AppRoutes.addTask,
      arguments: AddTaskArguments(
        scheduledDate: task.scheduledDate,
        task: task,
        returnRoute: AppRoutes.calendar,
      ),
    );
  }

  Future<void> _deleteTask(FocusTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text('Delete "${task.title}" from the calendar?'),
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

    if (shouldDelete != true) return;
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

  Future<void> _openCreateTask() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.addTask,
      arguments: AddTaskArguments(
        scheduledDate: _selectedDate,
        returnRoute: AppRoutes.calendar,
      ),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(selectedDate.year, selectedDate.month);
    final firstOffset = monthStart.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final totalCells = ((firstOffset + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_monthName(selectedDate.month)} ${selectedDate.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Selected ${_formatShortDateWithYear(selectedDate)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _WeekdayLabel('S'),
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: 40,
            ),
            itemBuilder: (context, index) {
              final date = monthStart.add(Duration(days: index - firstOffset));
              final inMonth = date.month == selectedDate.month;
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final isToday = DateUtils.isSameDay(date, today);
              final taskCount = MyTimeStore.instance.tasksForDate(date).length;

              return _CalendarDayCell(
                date: date,
                inMonth: inMonth,
                isSelected: isSelected,
                isToday: isToday,
                taskCount: taskCount,
                onTap: () => onSelectDate(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.inMonth,
    required this.isSelected,
    required this.isToday,
    required this.taskCount,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool isSelected;
  final bool isToday;
  final int taskCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasTasks = taskCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : hasTasks
              ? AppColors.surfaceSoft
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isToday
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : inMonth
                    ? AppColors.textPrimary
                    : AppColors.textMuted.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (hasTasks)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  const _ViewModeSelector({required this.value, required this.onChanged});

  final CalendarViewType value;
  final ValueChanged<CalendarViewType> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _ModeChip(
            label: 'Day',
            selected: value == CalendarViewType.day,
            onTap: () => onChanged(CalendarViewType.day),
          ),
          _ModeChip(
            label: 'Week',
            selected: value == CalendarViewType.week,
            onTap: () => onChanged(CalendarViewType.week),
          ),
          _ModeChip(
            label: 'Month',
            selected: value == CalendarViewType.month,
            onTap: () => onChanged(CalendarViewType.month),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({required this.view, required this.selectedDate});

  final CalendarViewType view;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final title = switch (view) {
      CalendarViewType.day => 'Activities for the day',
      CalendarViewType.week => 'Activities for the week',
      CalendarViewType.month => 'Activities for the month',
    };
    final subtitle = switch (view) {
      CalendarViewType.day => _formatLongDate(selectedDate),
      CalendarViewType.week => _weekRangeText(selectedDate),
      CalendarViewType.month =>
        '${_monthName(selectedDate.month)} ${selectedDate.year}',
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.event_note_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _DayAgenda extends StatelessWidget {
  const _DayAgenda({
    required this.date,
    required this.tasks,
    required this.onOpenTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime date;
  final List<FocusTask> tasks;
  final ValueChanged<FocusTask> onOpenTask;
  final ValueChanged<FocusTask> onEditTask;
  final Future<void> Function(FocusTask task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _EmptyAgenda(
        title: 'No planned tasks',
        message: 'There is no activity on ${_formatShortDateWithYear(date)}.',
      );
    }

    return Column(
      children: tasks
          .map(
            (task) => _TaskTile(
              task: task,
              onTap: () => onOpenTask(task),
              onEdit: () => onEditTask(task),
              onDelete: () => onDeleteTask(task),
            ),
          )
          .toList(),
    );
  }
}

class _WeekAgenda extends StatelessWidget {
  const _WeekAgenda({
    required this.selectedDate,
    required this.onSelectDate,
    required this.onOpenTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<FocusTask> onOpenTask;
  final ValueChanged<FocusTask> onEditTask;
  final Future<void> Function(FocusTask task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final start = _weekStart(selectedDate);

    return Column(
      children: List.generate(7, (index) {
        final date = start.add(Duration(days: index));
        final tasks = MyTimeStore.instance.tasksForDate(date);
        final isSelected = DateUtils.isSameDay(date, selectedDate);

        return _DayGroupCard(
          date: date,
          tasks: tasks,
          selected: isSelected,
          onSelectDate: () => onSelectDate(date),
          onOpenTask: onOpenTask,
          onEditTask: onEditTask,
          onDeleteTask: onDeleteTask,
        );
      }),
    );
  }
}

class _MonthAgenda extends StatelessWidget {
  const _MonthAgenda({
    required this.selectedDate,
    required this.onSelectDate,
    required this.onOpenTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<FocusTask> onOpenTask;
  final ValueChanged<FocusTask> onEditTask;
  final Future<void> Function(FocusTask task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final groups = <Widget>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final tasks = MyTimeStore.instance.tasksForDate(date);
      if (tasks.isEmpty) continue;
      groups.add(
        _DayGroupCard(
          date: date,
          tasks: tasks,
          selected: DateUtils.isSameDay(date, selectedDate),
          onSelectDate: () => onSelectDate(date),
          onOpenTask: onOpenTask,
          onEditTask: onEditTask,
          onDeleteTask: onDeleteTask,
        ),
      );
    }

    if (groups.isEmpty) {
      return _EmptyAgenda(
        title: 'No activities this month',
        message: 'Create a plan and it will appear on this calendar.',
      );
    }

    return Column(children: groups);
  }
}

class _DayGroupCard extends StatelessWidget {
  const _DayGroupCard({
    required this.date,
    required this.tasks,
    required this.selected,
    required this.onSelectDate,
    required this.onOpenTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final DateTime date;
  final List<FocusTask> tasks;
  final bool selected;
  final VoidCallback onSelectDate;
  final ValueChanged<FocusTask> onOpenTask;
  final ValueChanged<FocusTask> onEditTask;
  final Future<void> Function(FocusTask task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        color: selected ? const Color(0xFFF8FBFF) : AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onSelectDate,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _weekdayName(date.weekday),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tasks.isEmpty
                              ? 'No planned tasks'
                              : '${tasks.length} planned task(s)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...tasks.map(
                (task) => _CompactTaskTile(
                  task: task,
                  onTap: () => onOpenTask(task),
                  onEdit: () => onEditTask(task),
                  onDelete: () => onDeleteTask(task),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return _SwipeTaskActions(
      task: task,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _TaskIcon(task: task),
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: task.isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(_taskSubtitle(task)),
            trailing: _TaskCompletionButton(task: task),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _CompactTaskTile extends StatelessWidget {
  const _CompactTaskTile({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return _SwipeTaskActions(
      task: task,
      onEdit: onEdit,
      onDelete: onDelete,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _TaskIcon(task: task, small: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: task.isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _taskSubtitle(task),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _TaskCompletionButton(task: task),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCompletionButton extends StatelessWidget {
  const _TaskCompletionButton({required this.task});

  final FocusTask task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        MyTimeStore.instance.setTaskCompleted(task, !task.isCompleted);
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: task.isCompleted ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: task.isCompleted ? AppColors.primary : AppColors.textMuted,
            width: 1.6,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: task.isCompleted ? Colors.white : Colors.transparent,
        ),
      ),
    );
  }
}

class _SwipeTaskActions extends StatelessWidget {
  const _SwipeTaskActions({
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
      key: ValueKey('calendar-${task.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        await onDelete();
        return false;
      },
      background: const _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.secondary,
        icon: Icons.edit_rounded,
        label: 'Edit',
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.danger,
        icon: Icons.delete_rounded,
        label: 'Delete',
      ),
      child: child,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
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

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({required this.task, this.small = false});

  final FocusTask task;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final canStart = task.canStartToday;

    return Container(
      width: small ? 34 : 42,
      height: small ? 34 : 42,
      decoration: BoxDecoration(
        color: canStart ? AppColors.primary : AppColors.warning,
        borderRadius: BorderRadius.circular(small ? 12 : 15),
      ),
      child: Icon(
        canStart ? Icons.play_arrow_rounded : Icons.event_note_rounded,
        color: Colors.white,
        size: small ? 19 : 24,
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _weekStart(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday % 7));
}

String _taskSubtitle(FocusTask task) {
  return '${task.focusMinutes} min | ${_repeatText(task.repeat)}'
      '${task.reminderEnabled ? ' | Reminder ${task.reminderTime}' : ''}';
}

String _weekRangeText(DateTime date) {
  final start = _weekStart(date);
  final end = start.add(const Duration(days: 6));
  return '${_formatShortDateWithYear(start)} - ${_formatShortDateWithYear(end)}';
}

String _formatLongDate(DateTime date) {
  return '${_weekdayName(date.weekday)}, ${_formatShortDateWithYear(date)}';
}

String _formatShortDateWithYear(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

String _monthName(int month) {
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
  return months[month - 1];
}

String _weekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return weekdays[weekday - 1];
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
