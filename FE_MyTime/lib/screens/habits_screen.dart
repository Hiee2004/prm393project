import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/models/habit_tracker.dart';
import 'package:project/services/habit_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_background.dart';
import 'package:project/shared/widgets/app_bottom_navigation.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  HabitDashboardModel? _dashboard;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
  }

  Future<void> _loadDashboard() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in again to load habits.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await HabitApiService.instance.getDashboard(token);
      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkInHabit(HabitModel habit) async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await HabitApiService.instance.checkInHabit(
        token: token,
        habitId: habit.id,
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Check-in failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openCreateHabitSheet() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final form = await showModalBottomSheet<_HabitDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateHabitSheet(),
    );

    if (form == null) return;

    setState(() => _isSubmitting = true);
    try {
      await HabitApiService.instance.createHabit(
        token: token,
        payload: form.toJson(),
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Create habit failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _HabitErrorState(message: _error!, onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _HabitHero(progress: dashboard!.progress),
                      const SizedBox(height: 18),
                      _QuickBoostCard(
                        progress: dashboard.progress,
                        habitsCount: dashboard.habits.length,
                      ),
                      const SizedBox(height: 18),
                      _HeatmapCard(cells: dashboard.heatmap),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: SectionHeader(
                              title: 'Your habits',
                              subtitle: 'Daily and weekly streak missions.',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : _openCreateHabitSheet,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (dashboard.habits.isEmpty)
                        AppCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_fire_department_outlined,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No habits yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Create your first streak and start collecting XP.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _openCreateHabitSheet,
                                child: const Text('Create habit'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...dashboard.habits.map(
                          (habit) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _HabitCard(
                              habit: habit,
                              onCheckIn: _isSubmitting
                                  ? null
                                  : () => _checkInHabit(habit),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _openCreateHabitSheet,
        icon: const Icon(Icons.emoji_events_outlined),
        label: const Text('Add streak'),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: -1),
    );
  }
}

class _HabitHero extends StatelessWidget {
  const _HabitHero({required this.progress});

  final UserProgressModel progress;

  @override
  Widget build(BuildContext context) {
    final levelProgress = progress.nextLevelXp == 0
        ? 0.0
        : (progress.xp / progress.nextLevelXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF58CC02), Color(0xFF2E9C1D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3358CC02),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${progress.level}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Build tiny wins into a real streak.',
                      style: TextStyle(color: Color(0xFFEFFFF0)),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.xp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD54A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${progress.xp}/${progress.nextLevelXp} XP to next level',
            style: const TextStyle(color: Color(0xFFEFFFF0)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '${progress.currentStreak}',
                  label: 'Current streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.workspace_premium_rounded,
                  value: '${progress.bestStreak}',
                  label: 'Best streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.task_alt_rounded,
                  value: '${progress.totalHabitCompletions}',
                  label: 'Check-ins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFEFFFF0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickBoostCard extends StatelessWidget {
  const _QuickBoostCard({required this.progress, required this.habitsCount});

  final UserProgressModel progress;
  final int habitsCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _BoostStat(
              label: 'Today goal',
              value:
                  '${math.max(1, habitsCount)} streak${habitsCount == 1 ? '' : 's'}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BoostStat(
              label: 'Reward pace',
              value: '${math.max(1, progress.level) * 15} XP focus',
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostStat extends StatelessWidget {
  const _BoostStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.cells});

  final List<HabitHeatmapCell> cells;

  @override
  Widget build(BuildContext context) {
    final trailingCells = cells.length > 84
        ? cells.sublist(cells.length - 84)
        : cells;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Consistency heatmap',
            subtitle: 'A GitHub-style streak board for your habit energy.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: trailingCells
                .map(
                  (cell) => Tooltip(
                    message:
                        '${_formatDate(cell.date)}: ${cell.count} check-ins',
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _heatColor(cell.intensity),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Color _heatColor(int intensity) {
    switch (intensity) {
      case 4:
        return const Color(0xFF1E7E34);
      case 3:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFF8BD34A);
      case 1:
        return const Color(0xFFCDEB9A);
      default:
        return const Color(0xFFEDE7D3);
    }
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.onCheckIn});

  final HabitModel habit;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(habit.colorHex);
    final progress = habit.targetCount == 0
        ? 0.0
        : (habit.completedCountToday / habit.targetCount).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _iconFromName(habit.iconName),
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habit.description?.isNotEmpty == true
                          ? habit.description!
                          : _frequencyLabel(habit),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${habit.currentStreak} day streak',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetaChip(
                  icon: Icons.today_rounded,
                  label:
                      '${habit.completedCountToday}/${habit.targetCount} today',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetaChip(
                  icon: Icons.emoji_events_outlined,
                  label: 'Best ${habit.bestStreak} days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completion ${(habit.completionRate * 100).round()}% over recent scheduled days',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCheckIn,
              icon: Icon(
                habit.completedToday
                    ? Icons.verified_rounded
                    : Icons.bolt_rounded,
              ),
              label: Text(
                habit.completedToday ? 'Add bonus check-in' : 'Check in now',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitErrorState extends StatelessWidget {
  const _HabitErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 12),
              const Text(
                'Could not load habits',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateHabitSheet extends StatefulWidget {
  const _CreateHabitSheet();

  @override
  State<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<_CreateHabitSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  bool _isWeekly = false;
  TimeOfDay? _reminder;
  final Set<int> _weekDays = {1, 2, 3, 4, 5};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 6, minute: 0),
    );

    if (picked == null) return;
    setState(() => _reminder = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final target = int.tryParse(_targetController.text.trim()) ?? 1;
    Navigator.pop(
      context,
      _HabitDraft(
        title: title,
        description: _descriptionController.text.trim(),
        frequencyType: _isWeekly ? 'Weekly' : 'Daily',
        weekDays: _isWeekly ? (_weekDays.toList()..sort()) : const [],
        targetCount: math.max(1, target),
        reminderTime: _reminder == null
            ? null
            : '${_reminder!.hour.toString().padLeft(2, '0')}:${_reminder!.minute.toString().padLeft(2, '0')}:00',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 24, 12, bottomInset + 12),
      child: AppCard(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create streak',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text('Make it tiny, clear, and easy to repeat every day.'),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Habit title',
                  hintText: 'Read 10 pages',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional note for your habit mission',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target count',
                  hintText: '1',
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('Daily')),
                  ButtonSegment<bool>(value: true, label: Text('Weekly')),
                ],
                selected: {_isWeekly},
                onSelectionChanged: (selection) {
                  setState(() => _isWeekly = selection.first);
                },
              ),
              if (_isWeekly) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final selected = _weekDays.contains(day);
                    return FilterChip(
                      selected: selected,
                      label: Text(_weekDayLabel(day)),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _weekDays.add(day);
                          } else if (_weekDays.length > 1) {
                            _weekDays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.alarm_rounded),
                label: Text(
                  _reminder == null
                      ? 'Choose reminder time'
                      : 'Reminder ${_reminder!.format(context)}',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitDraft {
  const _HabitDraft({
    required this.title,
    required this.description,
    required this.frequencyType,
    required this.weekDays,
    required this.targetCount,
    required this.reminderTime,
  });

  final String title;
  final String description;
  final String frequencyType;
  final List<int> weekDays;
  final int targetCount;
  final String? reminderTime;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description.isEmpty ? null : description,
      'frequencyType': frequencyType,
      'weekDays': weekDays,
      'targetCount': targetCount,
      'reminderTime': reminderTime,
      'colorHex': '#58CC02',
      'iconName': 'local_fire_department_rounded',
    };
  }
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}

String _frequencyLabel(HabitModel habit) {
  if (habit.frequencyType.toLowerCase() != 'weekly') {
    return 'Daily mission';
  }

  if (habit.weekDays.isEmpty) {
    return 'Weekly mission';
  }

  return habit.weekDays.map(_weekDayLabel).join(', ');
}

String _weekDayLabel(int value) {
  const labels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  return labels[value] ?? 'Day';
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'menu_book_rounded':
      return Icons.menu_book_rounded;
    case 'fitness_center_rounded':
      return Icons.fitness_center_rounded;
    case 'self_improvement_rounded':
      return Icons.self_improvement_rounded;
    case 'water_drop_rounded':
      return Icons.water_drop_rounded;
    default:
      return Icons.local_fire_department_rounded;
  }
}

Color _parseColor(String value) {
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) {
    return AppColors.secondary;
  }

  return Color(int.parse('FF$hex', radix: 16));
}
