import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/models/smart_task_plan.dart';
import 'package:project/services/applied_smart_plan_store.dart';
import 'package:project/services/ai_service.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class SmartTaskPlanArguments {
  const SmartTaskPlanArguments({required this.task});

  final FocusTask task;
}

class SmartTaskPlanScreen extends StatefulWidget {
  const SmartTaskPlanScreen({super.key});

  @override
  State<SmartTaskPlanScreen> createState() => _SmartTaskPlanScreenState();
}

class _SmartTaskPlanScreenState extends State<SmartTaskPlanScreen> {
  FocusTask? _task;
  SmartTaskPlan? _plan;
  String _mode = 'Detailed';
  bool _loading = true;
  bool _applying = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_task != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SmartTaskPlanArguments) {
      _task = args.task;
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    final task = _task;
    final token = SessionStore.instance.token;
    if (task == null || token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in again to generate a smart plan.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final plan = await AiService.instance.generateSmartTaskPlan(
        token: token,
        taskId: task.id,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _applyPlan() async {
    final task = _task;
    final plan = _plan;
    final token = SessionStore.instance.token;
    if (task == null || plan == null || token == null || token.isEmpty) {
      return;
    }

    setState(() => _applying = true);
    try {
      await AppliedSmartPlanStore.instance.saveOriginalTask(
        taskId: task.id,
        task: task,
      );
      final updatedTask = await AiService.instance.applySmartTaskPlan(
        token: token,
        taskId: task.id,
        plan: plan,
      );
      await AppliedSmartPlanStore.instance.savePlan(taskId: task.id, plan: plan);
      MyTimeStore.instance.upsertTaskFromApi(updatedTask);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smart plan applied to this task.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Plan'),
        actions: [
          IconButton(
            tooltip: 'Regenerate',
            onPressed: _loading || _applying ? null : _loadPlan,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadPlan)
          : task == null || plan == null
          ? _ErrorState(message: 'Task plan is not available.', onRetry: _loadPlan)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ModeChip(
                            label: 'Quick',
                            selected: _mode == 'Quick',
                            onTap: () {
                              setState(() => _mode = 'Quick');
                              _loadPlan();
                            },
                          ),
                          _ModeChip(
                            label: 'Detailed',
                            selected: _mode == 'Detailed',
                            onTap: () {
                              setState(() => _mode = 'Detailed');
                              _loadPlan();
                            },
                          ),
                          _ModeChip(
                            label: 'Deadline Rescue',
                            selected: _mode == 'Deadline Rescue',
                            onTap: () {
                              setState(() => _mode = 'Deadline Rescue');
                              _loadPlan();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'AI Analysis',
                  subtitle: 'Suggested scope, focus mode, and timing.',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaPill(label: 'Difficulty ${plan.suggestedDifficulty}/5'),
                      _MetaPill(label: '${plan.suggestedFocusMinutes} min'),
                      _MetaPill(label: plan.recommendedFocusMode),
                      _MetaPill(label: plan.bestTimeOfDay),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'Task Breakdown',
                  subtitle: 'AI-generated steps for finishing this task.',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: plan.breakdown
                        .map(
                          (step) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Text(
                                '${step.order}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(step.title),
                            subtitle: Text('${step.minutes} minutes'),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'Focus Plan',
                  subtitle: 'Suggested work and break structure.',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: plan.pomodoroPlan
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              item.isBreak
                                  ? Icons.free_breakfast_rounded
                                  : Icons.timer_outlined,
                              color: item.isBreak
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                            title: Text(item.label),
                            trailing: Text(
                              '${item.minutes} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'Recommendation',
                  subtitle: 'Why AI suggests this structure.',
                ),
                const SizedBox(height: 10),
                AppCard(child: Text(plan.recommendation)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading || _applying ? null : _loadPlan,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Regenerate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _applying ? null : _applyPlan,
                        icon: _applying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.task_alt_rounded),
                        label: Text(_applying ? 'Applying...' : 'Apply Plan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
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
