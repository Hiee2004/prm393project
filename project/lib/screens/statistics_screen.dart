import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Today summary',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.check_circle,
                  value: '3/5',
                  label: 'Tasks',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.timer,
                  value: '90 min',
                  label: 'Focus time',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.warning,
                  value: '2',
                  label: 'Distractions',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily goal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(value: 0.7, minHeight: 10),
          const SizedBox(height: 8),
          const Text('70% completed'),
          const SizedBox(height: 24),
          const Text(
            'Completed outputs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.check),
                  title: Text('Create home screen'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.check),
                  title: Text('Create task list screen'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.check),
                  title: Text('Fix UI overflow warning'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Reflection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write a short note about your day',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            child: const Text('Back to home'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 4),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
