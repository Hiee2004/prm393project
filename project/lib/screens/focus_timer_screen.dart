import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  static const int _totalSeconds = 25 * 60;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;
  int _distractions = 0;
  bool _isRunning = false;

  final List<_FocusOutput> _outputs = [
    _FocusOutput('Complete the screen title'),
    _FocusOutput('Check the start button'),
    _FocusOutput('Test navigation'),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
  }

  String get _timeText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final completed = _outputs.where((item) => item.isDone).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus timer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Complete Flutter interface',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            _timeText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1 - (_remainingSeconds / _totalSeconds),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _resetTimer,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'Checklist ($completed/${_outputs.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ..._outputs.map(
            (output) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: output.isDone,
              title: Text(output.title),
              onChanged: (value) {
                setState(() => output.isDone = value ?? false);
              },
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _distractions++);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Distraction recorded.')),
              );
            },
            icon: const Icon(Icons.warning),
            label: Text('Record distraction ($_distractions)'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pushReplacementNamed(context, AppRoutes.statistics);
            },
            child: const Text('Finish session'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
    );
  }
}

class _FocusOutput {
  _FocusOutput(this.title);

  final String title;
  bool isDone = false;
}
