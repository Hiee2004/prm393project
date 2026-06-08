import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

enum FocusTaskStatus { planned, focusing, completed }

class FocusTaskModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final int estimatedMinutes;
  final int completedOutputs;
  final int totalOutputs;
  final TaskPriority priority;
  final FocusTaskStatus status;

  const FocusTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.estimatedMinutes,
    required this.completedOutputs,
    required this.totalOutputs,
    required this.priority,
    required this.status,
  });
}

enum TaskFilter { today, priority, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskFilter selectedFilter = TaskFilter.today;

  final List<FocusTaskModel> tasks = const [
    FocusTaskModel(
      id: '1',
      title: 'Hoàn thành UI Flutter',
      description: 'Code giao diện Home, Task List và Focus Timer.',
      time: '09:00 - 10:30',
      estimatedMinutes: 90,
      completedOutputs: 3,
      totalOutputs: 5,
      priority: TaskPriority.high,
      status: FocusTaskStatus.planned,
    ),
    FocusTaskModel(
      id: '2',
      title: 'Ôn lại yêu cầu của thầy',
      description: 'Đọc feedback và chỉnh project theo hướng Focus Task.',
      time: '14:00 - 14:45',
      estimatedMinutes: 45,
      completedOutputs: 1,
      totalOutputs: 3,
      priority: TaskPriority.medium,
      status: FocusTaskStatus.planned,
    ),
    FocusTaskModel(
      id: '3',
      title: 'Tổng hợp nội dung báo cáo',
      description: 'Viết mô tả màn hình và rule nghiệp vụ cho BA.',
      time: '16:00 - 17:00',
      estimatedMinutes: 60,
      completedOutputs: 4,
      totalOutputs: 4,
      priority: TaskPriority.low,
      status: FocusTaskStatus.completed,
    ),
  ];

  List<FocusTaskModel> get filteredTasks {
    if (selectedFilter == TaskFilter.priority) {
      return tasks.where((task) => task.priority == TaskPriority.high).toList();
    }

    if (selectedFilter == TaskFilter.completed) {
      return tasks
          .where((task) => task.status == FocusTaskStatus.completed)
          .toList();
    }

    return tasks;
  }

  void _goToAddTask() {
    Navigator.pushNamed(context, '/add-task');
  }

  void _goToFocus() {
    Navigator.pushNamed(context, '/focus');
  }

  void _goToTaskDetail() {
    Navigator.pushNamed(context, '/task-detail');
  }

  @override
  Widget build(BuildContext context) {
    final List<FocusTaskModel> displayTasks = filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _Header(onAddPressed: _goToAddTask),
                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FocusSummaryCard(
                    totalTasks: tasks.length,
                    completedTasks: tasks
                        .where(
                          (task) => task.status == FocusTaskStatus.completed,
                        )
                        .length,
                    totalOutputs: tasks.fold<int>(
                      0,
                      (sum, task) => sum + task.totalOutputs,
                    ),
                    completedOutputs: tasks.fold<int>(
                      0,
                      (sum, task) => sum + task.completedOutputs,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FilterTabs(
                    selectedFilter: selectedFilter,
                    onChanged: (filter) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: displayTasks.isEmpty
                      ? const _EmptyTaskState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: displayTasks.length,
                          itemBuilder: (context, index) {
                            final task = displayTasks[index];

                            return _FocusTaskListCard(
                              task: task,
                              onTap: _goToTaskDetail,
                              onStartFocus: _goToFocus,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddTask,
        backgroundColor: const Color(0xFF43D982),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      bottomNavigationBar: const _TaskBottomNavBar(),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _Header({required this.onAddPressed});

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
              IconButton(
                onPressed: onAddPressed,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Today Focus Tasks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose your important tasks and focus on one task at a time.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FocusSummaryCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int totalOutputs;
  final int completedOutputs;

  const _FocusSummaryCard({
    required this.totalTasks,
    required this.completedTasks,
    required this.totalOutputs,
    required this.completedOutputs,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalOutputs == 0
        ? 0
        : completedOutputs / totalOutputs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Focus Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF07112D),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MiniSummaryItem(
                  value: '$completedTasks/$totalTasks',
                  label: 'Tasks Done',
                  icon: Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _MiniSummaryItem(
                  value: '$completedOutputs/$totalOutputs',
                  label: 'Outputs',
                  icon: Icons.task_alt_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFEAF0FA),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF43D982),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MiniSummaryItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF43D982), size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF07112D),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF65708A)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final TaskFilter selectedFilter;
  final ValueChanged<TaskFilter> onChanged;

  const _FilterTabs({required this.selectedFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: 'Today',
          isSelected: selectedFilter == TaskFilter.today,
          onTap: () {
            onChanged(TaskFilter.today);
          },
        ),
        const SizedBox(width: 10),
        _FilterChipButton(
          label: 'Priority',
          isSelected: selectedFilter == TaskFilter.priority,
          onTap: () {
            onChanged(TaskFilter.priority);
          },
        ),
        const SizedBox(width: 10),
        _FilterChipButton(
          label: 'Completed',
          isSelected: selectedFilter == TaskFilter.completed,
          onTap: () {
            onChanged(TaskFilter.completed);
          },
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
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
          height: 42,
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
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusTaskListCard extends StatelessWidget {
  final FocusTaskModel task;
  final VoidCallback onTap;
  final VoidCallback onStartFocus;

  const _FocusTaskListCard({
    required this.task,
    required this.onTap,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = task.totalOutputs == 0
        ? 0
        : task.completedOutputs / task.totalOutputs;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5EAF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PriorityIndicator(priority: task.priority),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PriorityBadge(priority: task.priority),
                      const SizedBox(height: 6),
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF07112D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF65708A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _InfoItem(icon: Icons.schedule_rounded, text: task.time),
                _InfoItem(
                  icon: Icons.timer_outlined,
                  text: '${task.estimatedMinutes}m',
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEAF0FA),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPriorityColor(task.priority),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${task.completedOutputs}/${task.totalOutputs} outputs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF65708A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _StatusBadge(status: task.status),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: task.status == FocusTaskStatus.completed
                        ? null
                        : onStartFocus,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'Start Focus',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43D982),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E5EE),
                      disabledForegroundColor: const Color(0xFF8A94A6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF65708A)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF65708A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityIndicator({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 72,
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    String text;

    if (priority == TaskPriority.high) {
      text = 'High Priority';
    } else if (priority == TaskPriority.medium) {
      text = 'Medium Priority';
    } else {
      text = 'Low Priority';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _getPriorityColor(priority),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FocusTaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (status == FocusTaskStatus.planned) {
      text = 'Planned';
      color = const Color(0xFF23C7DD);
    } else if (status == FocusTaskStatus.focusing) {
      text = 'Focusing';
      color = const Color(0xFF8A7CF6);
    } else {
      text = 'Completed';
      color = const Color(0xFF43D982);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 76,
              color: const Color(0xFF43D982).withValues(alpha: 0.7),
            ),

            const SizedBox(height: 18),

            const Text(
              'No focus task found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF07112D),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create a focus task to start planning your productive day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF65708A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBottomNavBar extends StatelessWidget {
  const _TaskBottomNavBar();

  void _onTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      return;
    } else if (index == 2) {
      Navigator.pushNamed(context, '/focus');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/statistics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 1,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE2FFF0),
      onDestinationSelected: (index) {
        _onTap(context, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer_rounded),
          label: 'Focus',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Stats',
        ),
      ],
    );
  }
}

Color _getPriorityColor(TaskPriority priority) {
  if (priority == TaskPriority.high) {
    return const Color(0xFFFF6B6B);
  }

  if (priority == TaskPriority.medium) {
    return const Color(0xFFFFB020);
  }

  return const Color(0xFF43D982);
}
