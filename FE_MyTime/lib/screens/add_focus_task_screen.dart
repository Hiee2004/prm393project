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
  String? _returnRoute;

  static const _presetFocusMinutes = [15, 25, 35, 45, 60, 90];
  static const _customDurationValue = -1;

  bool get _isEditing => _editingTask != null;

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

  void _save() {
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

    final task = _editingTask;
    if (task == null) {
      MyTimeStore.instance.addTask(
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
      MyTimeStore.instance.updateTask(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Task updated.' : 'Task added.')),
    );
    if (_returnRoute != null) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'Create focus task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                      if ((value ?? '').trim().isEmpty) {
                        return 'Please enter a task name';
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
      '${time.minute.toString().padLeft(2, '0')}';
}

TimeOfDay _timeOfDayFromText(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return const TimeOfDay(hour: 9, minute: 0);

  final hour = int.tryParse(parts[0]) ?? 9;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}
