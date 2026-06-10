import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final List<_ChecklistItem> _items = [
    _ChecklistItem('Create header'),
    _ChecklistItem('Create task card'),
    _ChecklistItem('Test navigation'),
    _ChecklistItem('Fix overflow'),
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((item) => item.isDone).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Task detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Complete Flutter interface',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Build Home, Task List, Add Task and Focus Timer screens.',
          ),
          const Divider(height: 32),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule),
            title: Text('Time'),
            subtitle: Text('09:00 - 10:30'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.timer),
            title: Text('Estimate'),
            subtitle: Text('90 minutes'),
          ),
          const SizedBox(height: 8),
          Text(
            'Checklist ($completed/${_items.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: completed / _items.length),
          const SizedBox(height: 8),
          ..._items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: item.isDone,
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => item.isDone = value ?? false);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.focus);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start focus session'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  _ChecklistItem(this.title);

  final String title;
  bool isDone = false;
}
