import 'package:flutter/material.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final List<_ChecklistItem> checklist = [
    _ChecklistItem(title: 'Code giao diện Header'),
    _ChecklistItem(title: 'Code Focus Task Card'),
    _ChecklistItem(title: 'Test navigation'),
    _ChecklistItem(title: 'Fix overflow UI'),
  ];

  int get completedCount {
    return checklist.where((item) => item.isDone).length;
  }

  void _startFocus() {
    Navigator.pushNamed(context, '/focus');
  }

  @override
  Widget build(BuildContext context) {
    final double progress = checklist.isEmpty
        ? 0
        : completedCount / checklist.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF43E08B),
                          Color(0xFF23C7DD),
                          Color(0xFF8A7CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Priority',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Hoàn thành UI Flutter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Code giao diện Home, Task List, Add Task và Focus Timer.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: const [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule_rounded,
                          title: 'Time',
                          value: '09:00 - 10:30',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.timer_outlined,
                          title: 'Estimate',
                          value: '90 min',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Output checklist',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF07112D),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$completedCount/${checklist.length} outputs completed',
                    style: const TextStyle(
                      color: Color(0xFF65708A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

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

                  const SizedBox(height: 16),

                  ...List.generate(checklist.length, (index) {
                    final item = checklist[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5EAF3)),
                      ),
                      child: CheckboxListTile(
                        value: item.isDone,
                        activeColor: const Color(0xFF43D982),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            item.isDone = value ?? false;
                          });
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _startFocus,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Start Focus Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43D982),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Task Detail',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF07112D),
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF43D982)),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF65708A), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF07112D),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  final String title;
  bool isDone;

  _ChecklistItem({required this.title, this.isDone = false});
}
