import 'dart:async';

import 'package:flutter/material.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  Timer? _timer;

  int totalSeconds = 25 * 60;
  bool isRunning = false;
  int distractionCount = 0;

  final List<_FocusOutput> outputs = [
    _FocusOutput(title: 'Code giao diện Header'),
    _FocusOutput(title: 'Code nút Start Focus'),
    _FocusOutput(title: 'Test navigation'),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startOrPause() {
    if (isRunning) {
      _timer?.cancel();
      setState(() {
        isRunning = false;
      });
      return;
    }

    setState(() {
      isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (totalSeconds <= 0) {
        timer.cancel();
        setState(() {
          isRunning = false;
        });
        return;
      }

      setState(() {
        totalSeconds--;
      });
    });
  }

  void _markDistraction() {
    setState(() {
      distractionCount++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Distraction recorded. Try to return to focus.'),
      ),
    );
  }

  void _finishSession() {
    _timer?.cancel();

    Navigator.pushReplacementNamed(context, '/statistics');
  }

  String get formattedTime {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final int completedOutputs = outputs
        .where((output) => output.isDone)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                      const Expanded(
                        child: Text(
                          'Focus Mode',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Hoàn thành UI Flutter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isRunning ? 'Focusing now' : 'Ready to focus',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 42),

                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF43D982),
                        width: 9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF43D982,
                          ).withValues(alpha: 0.18),
                          blurRadius: 35,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  Row(
                    children: [
                      Expanded(
                        child: _DarkInfoCard(
                          title: 'Outputs',
                          value: '$completedOutputs/${outputs.length}',
                          icon: Icons.checklist_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkInfoCard(
                          title: 'Distractions',
                          value: '$distractionCount',
                          icon: Icons.block_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: ListView.builder(
                      itemCount: outputs.length,
                      itemBuilder: (context, index) {
                        final output = outputs[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CheckboxListTile(
                            value: output.isDone,
                            activeColor: const Color(0xFF43D982),
                            checkColor: Colors.white,
                            title: Text(
                              output.title,
                              style: TextStyle(
                                color: Colors.white,
                                decoration: output.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                output.isDone = value ?? false;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _markDistraction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'I got distracted',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _startOrPause,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43D982),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            isRunning ? 'Pause' : 'Start',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _finishSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF111827),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Finish',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
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

class _DarkInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DarkInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF43D982), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusOutput {
  final String title;
  bool isDone;

  _FocusOutput({required this.title, this.isDone = false});
}
