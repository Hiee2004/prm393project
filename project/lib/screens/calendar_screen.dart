import 'package:flutter/material.dart';

enum CalendarViewType { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewType selectedView = CalendarViewType.day;

  final List<_CalendarTask> tasks = const [
    _CalendarTask(
      title: 'Hoàn thành UI Flutter',
      time: '09:00 - 10:30',
      dateLabel: 'Mon 15',
      priority: 'High',
      outputs: '3/5 outputs',
      hasConflict: false,
    ),
    _CalendarTask(
      title: 'Ôn lại yêu cầu của thầy',
      time: '14:00 - 14:45',
      dateLabel: 'Mon 15',
      priority: 'Medium',
      outputs: '1/3 outputs',
      hasConflict: false,
    ),
    _CalendarTask(
      title: 'Test Focus Timer',
      time: '16:00 - 17:00',
      dateLabel: 'Tue 16',
      priority: 'High',
      outputs: '0/3 outputs',
      hasConflict: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _Header(),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _CalendarViewSwitcher(
                    selectedView: selectedView,
                    onChanged: (view) {
                      setState(() {
                        selectedView = view;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSelectedView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    if (selectedView == CalendarViewType.day) {
      return _DayView(tasks: tasks);
    }

    if (selectedView == CalendarViewType.week) {
      return _WeekView(tasks: tasks);
    }

    return _MonthView();
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF43E08B), Color(0xFF23C7DD), Color(0xFF8A7CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Focus Calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'View planned focus tasks by day, week or month.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CalendarViewSwitcher extends StatelessWidget {
  final CalendarViewType selectedView;
  final ValueChanged<CalendarViewType> onChanged;

  const _CalendarViewSwitcher({
    required this.selectedView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SwitchButton(
          label: 'Day',
          isSelected: selectedView == CalendarViewType.day,
          onTap: () {
            onChanged(CalendarViewType.day);
          },
        ),
        const SizedBox(width: 10),
        _SwitchButton(
          label: 'Week',
          isSelected: selectedView == CalendarViewType.week,
          onTap: () {
            onChanged(CalendarViewType.week);
          },
        ),
        const SizedBox(width: 10),
        _SwitchButton(
          label: 'Month',
          isSelected: selectedView == CalendarViewType.month,
          onTap: () {
            onChanged(CalendarViewType.month);
          },
        ),
      ],
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF43D982) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF43D982)
                  : const Color(0xFFE5EAF3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF65708A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final List<_CalendarTask> tasks;

  const _DayView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final todayTasks = tasks
        .where((task) => task.dateLabel == 'Mon 15')
        .toList();

    return ListView(
      children: [
        const _ViewTitle(title: 'Today Schedule', subtitle: 'Monday, 15'),

        const SizedBox(height: 16),

        const _TimeLineLabel(time: '09:00'),

        _CalendarTaskCard(
          task: todayTasks[0],
          onTap: () {
            Navigator.pushNamed(context, '/task-detail');
          },
        ),

        const _TimeLineLabel(time: '14:00'),

        _CalendarTaskCard(
          task: todayTasks[1],
          onTap: () {
            Navigator.pushNamed(context, '/task-detail');
          },
        ),

        const _TimeLineLabel(time: '18:00'),

        const _EmptyTimeBlock(),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  final List<_CalendarTask> tasks;

  const _WeekView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final List<_WeekDaySummary> week = [
      const _WeekDaySummary(
        day: 'Mon',
        date: '15',
        planned: 2,
        outputs: 4,
        conflicts: 0,
      ),
      const _WeekDaySummary(
        day: 'Tue',
        date: '16',
        planned: 1,
        outputs: 0,
        conflicts: 1,
      ),
      const _WeekDaySummary(
        day: 'Wed',
        date: '17',
        planned: 3,
        outputs: 2,
        conflicts: 0,
      ),
      const _WeekDaySummary(
        day: 'Thu',
        date: '18',
        planned: 0,
        outputs: 0,
        conflicts: 0,
      ),
      const _WeekDaySummary(
        day: 'Fri',
        date: '19',
        planned: 2,
        outputs: 1,
        conflicts: 0,
      ),
      const _WeekDaySummary(
        day: 'Sat',
        date: '20',
        planned: 1,
        outputs: 1,
        conflicts: 0,
      ),
      const _WeekDaySummary(
        day: 'Sun',
        date: '21',
        planned: 0,
        outputs: 0,
        conflicts: 0,
      ),
    ];

    return ListView(
      children: [
        const _ViewTitle(title: 'Week Overview', subtitle: '15/05 - 21/05'),

        const SizedBox(height: 16),

        ...week.map((day) {
          return _WeekDayCard(
            summary: day,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Open Day View: ${day.day} ${day.date}'),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<int> focusDays = [3, 5, 8, 12, 15, 16, 17, 19, 22, 26];
    final List<int> conflictDays = [16, 22];

    return ListView(
      children: [
        const _ViewTitle(title: 'Month Overview', subtitle: 'May 2026'),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5EAF3)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  _WeekLabel('Mon'),
                  _WeekLabel('Tue'),
                  _WeekLabel('Wed'),
                  _WeekLabel('Thu'),
                  _WeekLabel('Fri'),
                  _WeekLabel('Sat'),
                  _WeekLabel('Sun'),
                ],
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 35,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final int day = index + 1;
                  final bool hasFocus = focusDays.contains(day);
                  final bool hasConflict = conflictDays.contains(day);
                  final bool isToday = day == 15;

                  return _MonthDayCell(
                    day: day,
                    hasFocus: hasFocus,
                    hasConflict: hasConflict,
                    isToday: isToday,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open tasks on May $day')),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const _Legend(),
      ],
    );
  }
}

class _ViewTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ViewTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF07112D),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF65708A), fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _TimeLineLabel extends StatelessWidget {
  final String time;

  const _TimeLineLabel({required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        time,
        style: const TextStyle(
          color: Color(0xFF65708A),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CalendarTaskCard extends StatelessWidget {
  final _CalendarTask task;
  final VoidCallback onTap;

  const _CalendarTaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(task.priority);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: task.hasConflict
                ? Colors.redAccent
                : const Color(0xFFE5EAF3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 72,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF07112D),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${task.time} • ${task.outputs}',
                    style: const TextStyle(
                      color: Color(0xFF65708A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (task.hasConflict) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Schedule conflict',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A94A6)),
          ],
        ),
      ),
    );
  }
}

class _EmptyTimeBlock extends StatelessWidget {
  const _EmptyTimeBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: const Text(
        'No focus task planned',
        style: TextStyle(color: Color(0xFF8A94A6), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  final _WeekDaySummary summary;
  final VoidCallback onTap;

  const _WeekDayCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isBusy = summary.planned > 0;
    final bool hasConflict = summary.conflicts > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasConflict ? Colors.redAccent : const Color(0xFFE5EAF3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isBusy
                    ? const Color(0xFF43D982).withValues(alpha: 0.14)
                    : const Color(0xFFEAF0FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary.day,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF65708A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    summary.date,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF07112D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summary.planned} focus tasks',
                    style: const TextStyle(
                      color: Color(0xFF07112D),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${summary.outputs} outputs • ${summary.conflicts} conflicts',
                    style: TextStyle(
                      color: hasConflict
                          ? Colors.redAccent
                          : const Color(0xFF65708A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A94A6)),
          ],
        ),
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String text;

  const _WeekLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF65708A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final int day;
  final bool hasFocus;
  final bool hasConflict;
  final bool isToday;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.day,
    required this.hasFocus,
    required this.hasConflict,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFFE5EAF3);

    if (isToday) {
      borderColor = const Color(0xFF43D982);
    }

    if (hasConflict) {
      borderColor = Colors.redAccent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFF43D982).withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isToday ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: hasConflict ? Colors.redAccent : const Color(0xFF07112D),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 4),

            if (hasFocus)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasConflict
                      ? Colors.redAccent
                      : const Color(0xFF43D982),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(color: Color(0xFF43D982), text: 'Focus task'),
        SizedBox(width: 16),
        _LegendItem(color: Colors.redAccent, text: 'Conflict'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF65708A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CalendarTask {
  final String title;
  final String time;
  final String dateLabel;
  final String priority;
  final String outputs;
  final bool hasConflict;

  const _CalendarTask({
    required this.title,
    required this.time,
    required this.dateLabel,
    required this.priority,
    required this.outputs,
    required this.hasConflict,
  });
}

class _WeekDaySummary {
  final String day;
  final String date;
  final int planned;
  final int outputs;
  final int conflicts;

  const _WeekDaySummary({
    required this.day,
    required this.date,
    required this.planned,
    required this.outputs,
    required this.conflicts,
  });
}

Color _getPriorityColor(String priority) {
  if (priority == 'High') {
    return const Color(0xFFFF6B6B);
  }

  if (priority == 'Medium') {
    return const Color(0xFFFFB020);
  }

  return const Color(0xFF43D982);
}
