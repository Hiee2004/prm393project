import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';

enum TaskPriority { high, medium, low }

enum FocusTaskStatus { planned, completed }

class FocusTaskModel {
  const FocusTaskModel({
    required this.title,
    required this.description,
    required this.time,
    required this.estimatedMinutes,
    required this.completedOutputs,
    required this.totalOutputs,
    required this.priority,
    required this.status,
  });

  final String title;
  final String description;
  final String time;
  final int estimatedMinutes;
  final int completedOutputs;
  final int totalOutputs;
  final TaskPriority priority;
  final FocusTaskStatus status;
}

enum TaskFilter { all, highPriority, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskFilter _filter = TaskFilter.all;

  static const _tasks = [
    FocusTaskModel(
      title: 'Complete Flutter interface',
      description: 'Build Home, Task List and Focus Timer screens.',
      time: '09:00 - 10:30',
      estimatedMinutes: 90,
      completedOutputs: 3,
      totalOutputs: 5,
      priority: TaskPriority.high,
      status: FocusTaskStatus.planned,
    ),
    FocusTaskModel(
      title: 'Review project requirements',
      description: 'Read feedback and update the project.',
      time: '14:00 - 14:45',
      estimatedMinutes: 45,
      completedOutputs: 1,
      totalOutputs: 3,
      priority: TaskPriority.medium,
      status: FocusTaskStatus.planned,
    ),
    FocusTaskModel(
      title: 'Write report',
      description: 'Describe screens and application features.',
      time: '16:00 - 17:00',
      estimatedMinutes: 60,
      completedOutputs: 4,
      totalOutputs: 4,
      priority: TaskPriority.low,
      status: FocusTaskStatus.completed,
    ),
  ];

  List<FocusTaskModel> get _displayTasks {
    switch (_filter) {
      case TaskFilter.highPriority:
        return _tasks
            .where((task) => task.priority == TaskPriority.high)
            .toList();
      case TaskFilter.completed:
        return _tasks
            .where((task) => task.status == FocusTaskStatus.completed)
            .toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addTask);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<TaskFilter>(
              initialValue: _filter,
              decoration: const InputDecoration(labelText: 'Filter'),
              items: const [
                DropdownMenuItem(
                  value: TaskFilter.all,
                  child: Text('All tasks'),
                ),
                DropdownMenuItem(
                  value: TaskFilter.highPriority,
                  child: Text('High priority'),
                ),
                DropdownMenuItem(
                  value: TaskFilter.completed,
                  child: Text('Completed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _filter = value);
              },
            ),
          ),
          Expanded(
            child: _displayTasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _displayTasks.length,
                    itemBuilder: (context, index) {
                      final task = _displayTasks[index];
                      final isCompleted =
                          task.status == FocusTaskStatus.completed;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.assignment,
                                color: isCompleted ? Colors.green : Colors.blue,
                              ),
                              title: Text(task.title),
                              subtitle: Text(
                                '${task.description}\n'
                                '${task.time} - ${task.estimatedMinutes} minutes',
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                _priorityText(task.priority),
                                style: TextStyle(
                                  color: _priorityColor(task.priority),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.taskDetail,
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value:
                                          task.completedOutputs /
                                          task.totalOutputs,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${task.completedOutputs}/'
                                    '${task.totalOutputs}',
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: isCompleted
                                        ? null
                                        : () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.focus,
                                            );
                                          },
                                    child: const Text('Start'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
    );
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

Color _priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.low:
      return Colors.green;
  }
}
