import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';

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

  int _minutes = 45;
  String _priority = 'High';

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

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasOutput = _outputControllers.any(
      (controller) => controller.text.trim().isNotEmpty,
    );
    if (!hasOutput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one output.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task saved.')));
    Navigator.pushReplacementNamed(context, AppRoutes.tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task name'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Please enter task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _minutes,
              decoration: const InputDecoration(labelText: 'Focus time'),
              items: const [25, 45, 60, 90]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('$value minutes'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _minutes = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const ['High', 'Medium', 'Low']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Output checklist',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addOutput,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            ...List.generate(_outputControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _outputControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Output ${index + 1}',
                        ),
                      ),
                    ),
                    IconButton(
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
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save task'),
            ),
          ],
        ),
      ),
    );
  }
}
