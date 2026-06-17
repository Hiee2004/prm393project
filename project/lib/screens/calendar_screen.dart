import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: AnimatedBuilder(
        animation: MyTimeStore.instance,
        builder: (context, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _moveDate(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              _titleText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _moveDate(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<CalendarViewType>(
                        initialValue: _view,
                        decoration: const InputDecoration(labelText: 'View'),
                        items: const [
                          DropdownMenuItem(
                            value: CalendarViewType.day,
                            child: Text('Day'),
                          ),
                          DropdownMenuItem(
                            value: CalendarViewType.week,
                            child: Text('Week'),
                          ),
                          DropdownMenuItem(
                            value: CalendarViewType.month,
                            child: Text('Month'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _view = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildView()),
            ],
          );
        },
      ),
    );
  }

  String get _titleText {
    switch (_view) {
      case CalendarViewType.day:
        return _formatDate(_selectedDate);
      case CalendarViewType.week:
        final start = _weekStart(_selectedDate);
        final end = start.add(const Duration(days: 6));
        return '${_formatShortDate(start)} - ${_formatShortDate(end)}';
      case CalendarViewType.month:
        return '${_monthName(_selectedDate.month)} ${_selectedDate.year}';
    }
  }

  Widget _buildView() {
    switch (_view) {
      case CalendarViewType.day:
        return _DayView(
          date: _selectedDate,
          tasks: MyTimeStore.instance.tasksForDate(_selectedDate),
          onOpenTask: _openTask,
        );
      case CalendarViewType.week:
        return _WeekView(
          weekStart: _weekStart(_selectedDate),
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
              _view = CalendarViewType.day;
            });
          },
        );
      case CalendarViewType.month:
        return _MonthView(
          selectedDate: _selectedDate,
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
              _view = CalendarViewType.day;
            });
          },
        );
    }
  }

  void _moveDate(int direction) {
    setState(() {
      switch (_view) {
        case CalendarViewType.day:
          _selectedDate = _selectedDate.add(Duration(days: direction));
        case CalendarViewType.week:
          _selectedDate = _selectedDate.add(Duration(days: 7 * direction));
        case CalendarViewType.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + direction,
            1,
          );
      }
    });
  }

  void _openTask(FocusTask task) {
    MyTimeStore.instance.selectTask(task);
    Navigator.pushNamed(context, AppRoutes.taskDetail);
  }
}

class _DayView extends StatelessWidget {
  const _DayView({
    required this.date,
    required this.tasks,
    required this.onOpenTask,
  });

  final DateTime date;
  final List<FocusTask> tasks;
  final ValueChanged<FocusTask> onOpenTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 52,
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              Text('No planned tasks on ${_formatDate(date)}.'),
              const SizedBox(height: 8),
              const Text(
                'You can create plans for past or future dates.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskTile(task: task, onTap: () => onOpenTask(task));
      },
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.weekStart, required this.onSelectDate});

  final DateTime weekStart;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = weekStart.add(Duration(days: index));
        final tasks = MyTimeStore.instance.tasksForDate(date);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceSoft,
                child: Text('${date.day}'),
              ),
              title: Text(_weekdayName(date.weekday)),
              subtitle: Text('${tasks.length} planned task(s)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelectDate(date),
            ),
          ),
        );
      },
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.selectedDate, required this.onSelectDate});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final tasks = MyTimeStore.instance.tasksForDate(date);
        final isSelected = DateUtils.isSameDay(date, selectedDate);

        return InkWell(
          onTap: () => onSelectDate(date),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tasks.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});

  final FocusTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            task.canStartToday
                ? Icons.play_circle_outline
                : Icons.event_note_outlined,
            color: task.canStartToday ? AppColors.primary : AppColors.warning,
          ),
          title: Text(task.title),
          subtitle: Text(
            '${task.focusMinutes} min | ${_repeatText(task.repeat)}'
            '${task.reminderEnabled ? ' | Reminder ${task.reminderTime}' : ''}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
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

String _formatDate(DateTime date) {
  return '${_weekdayName(date.weekday)}, ${_formatShortDate(date)}';
}

String _formatShortDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
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
