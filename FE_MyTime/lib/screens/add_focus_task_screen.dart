import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_card.dart';
import 'package:project/shared/widgets/section_header.dart';

class AddTaskArguments {
  const AddTaskArguments({
    required this.scheduledDate,
    this.task,
    this.returnRoute,
  });

  final DateTime scheduledDate;
  final FocusTask? task;
  final String? returnRoute;
}

class AddFocusTaskScreen extends StatefulWidget {
  const AddFocusTaskScreen({super.key});

  @override
  State<AddFocusTaskScreen> createState() => _AddFocusTaskScreenState();
}

class _AddFocusTaskScreenState extends State<AddFocusTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aiPromptController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _outputControllers = [
    TextEditingController(),
  ];

  int _minutes = 25;
  TaskPriority _priority = TaskPriority.high;
  FocusTaskStatus _status = FocusTaskStatus.todo;
  DateTime _scheduledDate = DateTime.now();
  TaskRepeat _repeat = TaskRepeat.none;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  FocusTask? _editingTask;
  bool _initialized = false;
  bool _fillingFromAi = false;
  List<_AiTaskDraft> _aiDraftOptions = const [];
  int _selectedAiDraftIndex = 0;
  Map<int, List<bool>> _selectedOutputsPerDraft = const {};
  String? _returnRoute;

  static const _presetFocusMinutes = [15, 25, 35, 45, 60, 90];
  static const _customDurationValue = -1;
  static const _samplePrompts = [
    'Hoc TOEIC 45 phut, uu tien cao, hom nay, nhac toi luc 6 am',
    'Learn English for 30 minutes tomorrow, medium priority, remind me at 7 pm',
    'Code Flutter bug fix 60 minutes tonight, high priority',
  ];

  bool get _isEditing => _editingTask != null;

  bool get _hasAmbiguousReminder {
    final prompt = _aiPromptController.text.trim().toLowerCase();
    if (prompt.isEmpty) return false;
    final hasReminderKeyword = RegExp(
      r'(remind|reminder|notify|nhac|bao|hen)',
      caseSensitive: false,
    ).hasMatch(prompt);
    final hasTime =
        _AiTaskDraft._extractReminderTimeNormalized(
          _AiTaskDraft._normalizeAiText(prompt),
        ) !=
        null;
    return hasReminderKeyword && !hasTime;
  }

  _AiPromptAnalysis get _promptAnalysis =>
      _AiPromptAnalysis.fromPrompt(_aiPromptController.text.trim());

  List<int> get _durationItems {
    final values = [..._presetFocusMinutes];
    if (!values.contains(_minutes)) values.add(_minutes);
    values.sort();
    return values;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is AddTaskArguments) {
      _scheduledDate = argument.scheduledDate;
      _returnRoute = argument.returnRoute;
      final task = argument.task;
      if (task != null) {
        _loadTaskForEditing(task);
      }
      return;
    }

    if (argument is! FocusTask) return;

    _loadTaskForEditing(argument);
  }

  void _loadTaskForEditing(FocusTask task) {
    _editingTask = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _minutes = task.focusMinutes;
    _priority = task.priority;
    _status = task.status;
    _scheduledDate = task.scheduledDate;
    _repeat = task.repeat;
    _reminderEnabled = task.reminderEnabled;
    _reminderTime = _timeOfDayFromText(task.reminderTime);
    for (final controller in _outputControllers) {
      controller.dispose();
    }
    _outputControllers
      ..clear()
      ..addAll(
        task.outputs.map((output) => TextEditingController(text: output.title)),
      );
    if (_outputControllers.isEmpty) {
      _outputControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _aiPromptController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _outputControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOutput() {
    setState(() => _outputControllers.add(TextEditingController()));
  }

  Future<void> _generateAiDrafts() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please describe the task in Vietnamese or English first.',
          ),
        ),
      );
      return;
    }

    setState(() => _fillingFromAi = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final drafts = _AiTaskDraft.buildOptions(prompt, baseDate: _scheduledDate);
    if (!mounted) return;

    setState(() {
      _aiDraftOptions = drafts;
      _selectedAiDraftIndex = 0;
      _selectedOutputsPerDraft = {
        for (int i = 0; i < drafts.length; i++)
          i: List.generate(drafts[i].outputs.length, (_) => true),
      };
      _fillingFromAi = false;
    });
    if (drafts.isNotEmpty) {
      _applyDraftToForm(drafts.first, _selectedOutputsPerDraft[0] ?? []);
    }
  }

  void _applySamplePrompt(String prompt) {
    setState(() {
      _aiPromptController.text = prompt;
    });
  }

  void _applyDraftToForm(_AiTaskDraft draft, List<bool> selectedOutputs) {
    setState(() {
      _titleController.text = draft.title;
      _descriptionController.text = draft.description;
      _minutes = draft.minutes;
      _priority = draft.priority;
      _scheduledDate = draft.scheduledDate;
      _repeat = draft.repeat;
      _reminderEnabled = draft.reminderEnabled;
      _reminderTime = draft.reminderTime;

      for (final controller in _outputControllers) {
        controller.dispose();
      }

      _outputControllers.clear();
      for (int i = 0; i < draft.outputs.length; i++) {
        final isChecked = i < selectedOutputs.length
            ? selectedOutputs[i]
            : true;
        if (isChecked) {
          _outputControllers.add(TextEditingController(text: draft.outputs[i]));
        }
      }

      if (_outputControllers.isEmpty) {
        _outputControllers.add(TextEditingController());
      }
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) setState(() => _scheduledDate = date);
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) setState(() => _reminderTime = time);
  }

  Future<void> _pickCustomFocusDuration() async {
    final controller = TextEditingController(text: _minutes.toString());

    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom focus duration'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              hintText: 'Example: 50',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
            onSubmitted: (_) => _submitCustomDuration(context, controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitCustomDuration(context, controller),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (value == null) {
      setState(() {});
      return;
    }
    setState(() => _minutes = value);
  }

  void _submitCustomDuration(
    BuildContext context,
    TextEditingController controller,
  ) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid minute value.')),
      );
      return;
    }

    Navigator.pop(context, value.clamp(1, 300));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final outputs = _outputControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one output.')),
      );
      return;
    }

    try {
      final task = _editingTask;
      if (task == null) {
        await MyTimeStore.instance.addTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          focusMinutes: _minutes,
          priority: _priority,
          scheduledDate: _scheduledDate,
          repeat: _repeat,
          reminderEnabled: _reminderEnabled,
          reminderTime: _formatTime(_reminderTime),
          outputs: outputs,
        );
      } else {
        await MyTimeStore.instance.updateTask(
          task: task,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          focusMinutes: _minutes,
          priority: _priority,
          status: _status,
          scheduledDate: _scheduledDate,
          repeat: _repeat,
          reminderEnabled: _reminderEnabled,
          reminderTime: _formatTime(_reminderTime),
          outputs: outputs,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Task updated.' : 'Task added.')),
      );
      if (_returnRoute != null) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.tasks);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'Create focus task'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                children: [
                  Text(
                    'AI task helper',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use Vietnamese or English. AI can detect duration, priority, date, repeat, and reminder (e.g. 8 AM/PM), then suggest options.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aiPromptController,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Describe task for AI',
                      hintText:
                          'Vi du: Hoc TOEIC 45 phut uu tien cao, nhac luc 8 PM hom nay, lap lai hang ngay.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _samplePrompts
                        .map(
                          (prompt) => ActionChip(
                            label: Text(
                              prompt,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _applySamplePrompt(prompt),
                          ),
                        )
                        .toList(),
                  ),
                  if (_aiPromptController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AiPromptHelpCard(
                      analysis: _promptAnalysis,
                      ambiguousReminder: _hasAmbiguousReminder,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _fillingFromAi ? null : _generateAiDrafts,
                      icon: _fillingFromAi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _fillingFromAi
                            ? 'Generating...'
                            : 'Generate AI options',
                      ),
                    ),
                  ),
                  if (_aiDraftOptions.isNotEmpty && _hasAmbiguousReminder) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chưa rõ thời gian nhắc nhở',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'AI phát hiện bạn muốn nhắc nhở nhưng chưa rõ giờ (ví dụ: 8 AM, 8 giờ tối). Mặc định là 9h sáng. Bạn có thể thay đổi giờ nhắc nhở ở phần dưới.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_aiDraftOptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'AI suggestions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_aiDraftOptions.length, (index) {
                      final draft = _aiDraftOptions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AiDraftOptionTile(
                          draft: draft,
                          selected: _selectedAiDraftIndex == index,
                          selectedOutputs:
                              _selectedOutputsPerDraft[index] ?? [],
                          onOutputToggled: (outIdx, isChecked) {
                            setState(() {
                              final currentSelected =
                                  _selectedOutputsPerDraft[index] ?? [];
                              if (outIdx < currentSelected.length) {
                                currentSelected[outIdx] = isChecked;
                              }
                              _selectedAiDraftIndex = index;
                            });
                            _applyDraftToForm(
                              draft,
                              _selectedOutputsPerDraft[index] ?? [],
                            );
                          },
                          onSelect: () {
                            setState(() => _selectedAiDraftIndex = index);
                            _applyDraftToForm(
                              draft,
                              _selectedOutputsPerDraft[index] ?? [],
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: '1. Task information',
              subtitle: 'Name the work and choose how long to focus.',
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Task name'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Please enter a task name';
                      }
                      if (text.length > 180) {
                        return 'Task name must be 180 characters or fewer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Task description',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length > 1000) {
                        return 'Description must be 1000 characters or fewer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_minutes),
                    initialValue: _minutes,
                    decoration: const InputDecoration(
                      labelText: 'Focus duration',
                    ),
                    items: [
                      for (final value in _durationItems)
                        DropdownMenuItem(
                          value: value,
                          child: Text('$value minutes'),
                        ),
                      const DropdownMenuItem(
                        value: _customDurationValue,
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Custom minutes...'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      if (value == _customDurationValue) {
                        _pickCustomFocusDuration();
                        return;
                      }
                      setState(() => _minutes = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pickCustomFocusDuration,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Enter custom minutes'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(
                        value: TaskPriority.high,
                        child: Text('High'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.medium,
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.low,
                        child: Text('Low'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _priority = value);
                    },
                  ),
                ],
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<FocusTaskStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: FocusTaskStatus.todo,
                    child: Text('To do'),
                  ),
                  DropdownMenuItem(
                    value: FocusTaskStatus.processing,
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(
                    value: FocusTaskStatus.completed,
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ],
            const SizedBox(height: 24),
            const SectionHeader(
              title: '2. Schedule and reminder',
              subtitle: 'Plan tasks for past, today, or future dates.',
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Planned date'),
                    subtitle: Text(_formatDate(_scheduledDate)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: DropdownButtonFormField<TaskRepeat>(
                      initialValue: _repeat,
                      decoration: const InputDecoration(labelText: 'Repeat'),
                      items: const [
                        DropdownMenuItem(
                          value: TaskRepeat.none,
                          child: Text('No repeat'),
                        ),
                        DropdownMenuItem(
                          value: TaskRepeat.daily,
                          child: Text('Every day'),
                        ),
                        DropdownMenuItem(
                          value: TaskRepeat.weekly,
                          child: Text('Every week'),
                        ),
                        DropdownMenuItem(
                          value: TaskRepeat.monthly,
                          child: Text('Every month'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _repeat = value);
                      },
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Reminder'),
                    subtitle: Text(
                      _reminderEnabled
                          ? 'Notify at ${_formatTime(_reminderTime)}'
                          : 'No reminder for this task',
                    ),
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() => _reminderEnabled = value);
                    },
                  ),
                  if (_reminderEnabled)
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Reminder time'),
                      subtitle: Text(_formatTime(_reminderTime)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickReminderTime,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: '3. Expected outputs',
                    subtitle: 'Define clear results for the session.',
                  ),
                ),
                TextButton.icon(
                  onPressed: _addOutput,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const Text(
              'An output is a clear result you want after the focus session.',
            ),
            const SizedBox(height: 12),
            ...List.generate(_outputControllers.length, (index) {
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _outputControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Output ${index + 1}',
                            hintText: 'Example: Complete the login screen',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Please enter an output or remove this row';
                            }
                            if (text.length > 180) {
                              return 'Output must be 180 characters or fewer';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete output',
                        onPressed: _outputControllers.length == 1
                            ? null
                            : () {
                                setState(() {
                                  _outputControllers[index].dispose();
                                  _outputControllers.removeAt(index);
                                });
                              },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save changes' : 'Add task'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:00';
}

TimeOfDay _timeOfDayFromText(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return const TimeOfDay(hour: 9, minute: 0);

  final hour = int.tryParse(parts[0]) ?? 9;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

class _AiTaskDraft {
  const _AiTaskDraft({
    required this.label,
    required this.title,
    required this.description,
    required this.minutes,
    required this.priority,
    required this.scheduledDate,
    required this.repeat,
    required this.reminderEnabled,
    required this.reminderTime,
    required this.note,
    required this.outputs,
  });

  final String label;
  final String title;
  final String description;
  final int minutes;
  final TaskPriority priority;
  final DateTime scheduledDate;
  final TaskRepeat repeat;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;
  final String note;
  final List<String> outputs;

  static List<_AiTaskDraft> buildOptions(
    String prompt, {
    required DateTime baseDate,
  }) {
    final normalized = prompt.trim();
    final lower = _normalizeAiText(normalized);

    final minutesMatch = RegExp(
      r'(\d{1,3})\s*(phut|phÃºt|minute|minutes|min)',
      caseSensitive: false,
    ).firstMatch(lower);
    final minutes =
        int.tryParse(minutesMatch?.group(1) ?? '')?.clamp(15, 300) ?? 25;

    final priority = switch (true) {
      _
          when lower.contains('uu tien cao') ||
              lower.contains('Æ°u tiÃªn cao') ||
              lower.contains('high') =>
        TaskPriority.high,
      _
          when lower.contains('uu tien thap') ||
              lower.contains('Æ°u tiÃªn tháº¥p') ||
              lower.contains('low') =>
        TaskPriority.low,
      _ => TaskPriority.medium,
    };

    final repeat = _extractRepeatNormalized(lower);
    final reminderTime = _extractReminderTimeNormalized(lower);
    final reminderEnabled =
        reminderTime != null || _containsReminderNormalized(lower);

    final scheduledDate = switch (true) {
      _ when lower.contains('ngay mai') || lower.contains('ngÃ y mai') =>
        baseDate.add(const Duration(days: 1)),
      _ when lower.contains('hom nay') || lower.contains('hÃ´m nay') =>
        baseDate,
      _ => _extractDate(lower) ?? baseDate,
    };

    final title = _extractTitle(normalized);
    final normalizedDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );

    final exactDraft = _AiTaskDraft(
      label: 'Exact match',
      title: title,
      description: normalized,
      minutes: minutes,
      priority: priority,
      scheduledDate: normalizedDate,
      repeat: repeat,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
      note: 'Closest match to your prompt.',
      outputs: _buildOutputs(title, minutes),
    );

    final quickDraft = _AiTaskDraft(
      label: 'Quick start',
      title: title,
      description: normalized,
      minutes: minutes <= 30 ? minutes : 25,
      priority: priority == TaskPriority.low ? TaskPriority.medium : priority,
      scheduledDate: normalizedDate,
      repeat: repeat,
      reminderEnabled: true,
      reminderTime: reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
      note: 'A lighter version to start quickly, with reminder enabled.',
      outputs: _buildOutputs(title, minutes <= 30 ? minutes : 25),
    );

    final deepDraft = _AiTaskDraft(
      label: 'Deep focus',
      title: title,
      description: normalized,
      minutes: minutes < 45 ? 45 : minutes,
      priority: TaskPriority.high,
      scheduledDate: normalizedDate,
      repeat: repeat,
      reminderEnabled: true,
      note: 'A deeper focus version for important work.',
      reminderTime: reminderTime ?? const TimeOfDay(hour: 8, minute: 30),
      outputs: _buildOutputs(title, minutes < 45 ? 45 : minutes),
    );

    final drafts = [exactDraft, quickDraft, deepDraft];
    final unique = <String>{};
    return drafts.where((item) {
      final key = [
        item.title,
        item.minutes,
        item.priority.name,
        item.repeat.name,
        item.reminderEnabled,
        item.reminderTime.hour,
        item.reminderTime.minute,
      ].join('|');
      return unique.add(key);
    }).toList();
  }

  static DateTime? _extractDate(String input) {
    final slashMatch = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(input);
    if (slashMatch == null) return null;

    final month = int.tryParse(slashMatch.group(1)!);
    final day = int.tryParse(slashMatch.group(2)!);
    final year = int.tryParse(slashMatch.group(3)!);

    if (month == null || day == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static String _extractTitle(String input) {
    var title = input
        .replaceAll(
          RegExp(
            r'(\d{1,3})\s*(phut|minute|minutes|min)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'(uu tien cao|uu tien thap|high|low|medium|priority|trung binh)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'(ngay mai|hom nay|today|tomorrow|\d{1,2}/\d{1,2}/\d{4})',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'((remind me|reminder|notify|nhac toi|nhac)\s*(luc|at)?\s*\d{1,2}([:.h]\d{0,2})?\s*(am|pm|gio|sang|chieu|toi)?)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'(every day|daily|weekly|monthly|hang ngay|hang tuan|hang thang|repeat|lap lai)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'^(tao)\s+(task|lich)\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\b(have|co)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    title = title
        .replaceAll(RegExp(r'^[,.\-\s]+'), '')
        .replaceAll(RegExp(r'[,.\-\s]+$'), '')
        .trim();

    if (title.isEmpty) {
      return 'New focus task';
    }

    final lower = title.toLowerCase();
    if (lower.contains('toeic')) return 'Learn TOEIC';
    if (lower.contains('english')) return 'Learn English';
    if (lower.contains('flutter')) return 'Learn Flutter';
    if (lower.contains('code') || lower.contains('bug')) return 'Coding task';

    return title[0].toUpperCase() + title.substring(1);
  }

  static TaskRepeat _extractRepeatNormalized(String input) {
    if (RegExp(
      r'(every day|daily|hang ngay)',
      caseSensitive: false,
    ).hasMatch(input)) {
      return TaskRepeat.daily;
    }
    if (RegExp(
      r'(weekly|hang tuan|moi tuan)',
      caseSensitive: false,
    ).hasMatch(input)) {
      return TaskRepeat.weekly;
    }
    if (RegExp(
      r'(monthly|hang thang|moi thang)',
      caseSensitive: false,
    ).hasMatch(input)) {
      return TaskRepeat.monthly;
    }
    return TaskRepeat.none;
  }

  static bool _containsReminderNormalized(String input) {
    return RegExp(
      r'(remind|reminder|notify|nhac|bao|hen)',
      caseSensitive: false,
    ).hasMatch(input);
  }

  static TimeOfDay? _extractReminderTimeNormalized(String input) {
    final reminderMatch = RegExp(
      r'(?:remind me|reminder|notify|nhac toi|nhac)\s*(?:luc|at)?\s*(\d{1,2})(?:[:h.](\d{1,2}))?\s*(am|pm|gio|sang|chieu|toi)?',
      caseSensitive: false,
    ).firstMatch(input);

    if (reminderMatch == null) return null;

    var hour = int.tryParse(reminderMatch.group(1) ?? '');
    final minute = int.tryParse(reminderMatch.group(2) ?? '0') ?? 0;
    final suffix = (reminderMatch.group(3) ?? '').toLowerCase();

    if (hour == null) return null;
    if ((suffix == 'pm' || suffix == 'chieu' || suffix == 'toi') && hour < 12) {
      hour += 12;
    }
    if ((suffix == 'am' || suffix == 'sang') && hour == 12) {
      hour = 0;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _normalizeAiText(String input) {
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ắ': 'a',
      'ằ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ấ': 'a',
      'ầ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'é': 'e',
      'è': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ế': 'e',
      'ề': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'í': 'i',
      'ì': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ó': 'o',
      'ò': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ố': 'o',
      'ồ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ớ': 'o',
      'ờ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ứ': 'u',
      'ừ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ý': 'y',
      'ỳ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'đ': 'd',
    };

    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }

  static List<String> _buildOutputs(String title, int minutes) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('toeic') || lowerTitle.contains('english')) {
      if (minutes <= 25) {
        return ['Review key vocabulary', 'Finish one short practice set'];
      }
      return [
        'Review key vocabulary',
        'Practice one focused exercise',
        'Write quick notes from mistakes',
      ];
    }

    if (lowerTitle.contains('code') ||
        lowerTitle.contains('flutter') ||
        lowerTitle.contains('bug')) {
      if (minutes <= 25) {
        return ['Identify the main issue', 'Finish one small coding step'];
      }
      return [
        'Understand the problem clearly',
        'Implement the main fix',
        'Test and review the result',
      ];
    }

    final cleanTitle = title.length > 24
        ? '${title.substring(0, 24)}...'
        : title;
    if (minutes <= 25) {
      return ['Prepare for $cleanTitle', 'Finish one clear outcome'];
    }
    return [
      'Prepare the work for $cleanTitle',
      'Complete the main result',
      'Review and note the next step',
    ];
  }
}

class _AiPromptAnalysis {
  const _AiPromptAnalysis({
    required this.hasDuration,
    required this.hasDate,
    required this.hasReminderKeyword,
    required this.hasReminderTime,
  });

  final bool hasDuration;
  final bool hasDate;
  final bool hasReminderKeyword;
  final bool hasReminderTime;

  bool get isTooVague => !hasDuration && !hasDate && !hasReminderKeyword;

  List<String> get missingHints {
    final hints = <String>[];
    if (!hasDuration) {
      hints.add('Add duration, for example: 30 minutes / 45 phut.');
    }
    if (!hasDate) {
      hints.add('Add date, for example: today / tomorrow / hom nay.');
    }
    if (hasReminderKeyword && !hasReminderTime) {
      hints.add('Add reminder time, for example: 6 am / 8 pm / 7h sang.');
    }
    return hints;
  }

  static _AiPromptAnalysis fromPrompt(String prompt) {
    final lower = _AiTaskDraft._normalizeAiText(prompt);
    return _AiPromptAnalysis(
      hasDuration: RegExp(
        r'(\d{1,3})\s*(minute|minutes|min|phut)',
        caseSensitive: false,
      ).hasMatch(lower),
      hasDate: RegExp(
        r'(today|tomorrow|hom nay|ngay mai|\d{1,2}/\d{1,2}/\d{4})',
        caseSensitive: false,
      ).hasMatch(lower),
      hasReminderKeyword: RegExp(
        r'(remind|reminder|notify|nhac|bao|hen)',
        caseSensitive: false,
      ).hasMatch(lower),
      hasReminderTime:
          _AiTaskDraft._extractReminderTimeNormalized(lower) != null,
    );
  }
}

class _AiPromptHelpCard extends StatelessWidget {
  const _AiPromptHelpCard({
    required this.analysis,
    required this.ambiguousReminder,
  });

  final _AiPromptAnalysis analysis;
  final bool ambiguousReminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warnings = [
      ...analysis.missingHints,
      if (analysis.isTooVague)
        'AI can still suggest something, but the result will be less accurate.',
      if (ambiguousReminder)
        'You mentioned a reminder, but the time is still unclear. AI may fallback to a default time.',
    ];

    if (warnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Good prompt. AI has enough detail to create stronger suggestions.',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Prompt guidance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $warning', style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _AiDraftOptionTile extends StatelessWidget {
  const _AiDraftOptionTile({
    required this.draft,
    required this.selected,
    required this.onSelect,
    required this.selectedOutputs,
    required this.onOutputToggled,
  });

  final _AiTaskDraft draft;
  final bool selected;
  final VoidCallback onSelect;
  final List<bool> selectedOutputs;
  final Function(int index, bool value) onOutputToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.35);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              draft.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(draft.note, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AiMetaPill(label: '${draft.minutes} min'),
                _AiMetaPill(label: _priorityLabel(draft.priority)),
                _AiMetaPill(label: _formatDate(draft.scheduledDate)),
                _AiMetaPill(label: _repeatLabel(draft.repeat)),
                if (draft.reminderEnabled)
                  _AiMetaPill(
                    label: 'Nhắc lúc ${_formatTimeOfDay(draft.reminderTime)}',
                  ),
              ],
            ),
            if (draft.outputs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 6),
              Text(
                'Expected outputs:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              ...List.generate(draft.outputs.length, (outIdx) {
                final isChecked = outIdx < selectedOutputs.length
                    ? selectedOutputs[outIdx]
                    : true;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: isChecked,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            onOutputToggled(outIdx, val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          draft.outputs[outIdx],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isChecked ? null : theme.disabledColor,
                            decoration: isChecked
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiMetaPill extends StatelessWidget {
  const _AiMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'High priority';
    case TaskPriority.medium:
      return 'Medium priority';
    case TaskPriority.low:
      return 'Low priority';
  }
}

String _repeatLabel(TaskRepeat repeat) {
  switch (repeat) {
    case TaskRepeat.none:
      return 'No repeat';
    case TaskRepeat.daily:
      return 'Daily';
    case TaskRepeat.weekly:
      return 'Weekly';
    case TaskRepeat.monthly:
      return 'Monthly';
  }
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final isPm = hour >= 12;
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final suffix = isPm ? 'PM' : 'AM';
  return '$displayHour:$minute $suffix';
}
