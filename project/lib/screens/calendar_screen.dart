import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';

enum CalendarViewType { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewType _view = CalendarViewType.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<CalendarViewType>(
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
          ),
          Expanded(child: _buildView()),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
    );
  }

  Widget _buildView() {
    switch (_view) {
      case CalendarViewType.day:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const Text(
              'Monday, June 15',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _TaskTile(
              time: '09:00',
              title: 'Complete Flutter interface',
              onTap: _openTask,
            ),
            _TaskTile(
              time: '14:00',
              title: 'Review project requirements',
              onTap: _openTask,
            ),
          ],
        );
      case CalendarViewType.week:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: const [
            _DayTile(day: 'Monday', taskCount: 2),
            _DayTile(day: 'Tuesday', taskCount: 1),
            _DayTile(day: 'Wednesday', taskCount: 3),
            _DayTile(day: 'Thursday', taskCount: 0),
            _DayTile(day: 'Friday', taskCount: 2),
          ],
        );
      case CalendarViewType.month:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 30,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final day = index + 1;
            return Card(
              color: day == 15 ? Colors.blue.shade100 : Colors.white,
              child: Center(child: Text('$day')),
            );
          },
        );
    }
  }

  void _openTask() {
    Navigator.pushNamed(context, AppRoutes.taskDetail);
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.time,
    required this.title,
    required this.onTap,
  });

  final String time;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(time),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.taskCount});

  final String day;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(day),
        subtitle: Text('$taskCount tasks'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
