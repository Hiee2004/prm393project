import 'package:flutter/material.dart';

class AddFocusTaskScreen extends StatefulWidget {
  const AddFocusTaskScreen({super.key});

  @override
  State<AddFocusTaskScreen> createState() => _AddFocusTaskScreenState();
}

class _AddFocusTaskScreenState extends State<AddFocusTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int selectedMinutes = 45;
  String selectedPriority = 'High';

  final List<TextEditingController> _outputControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    for (final controller in _outputControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addOutputField() {
    setState(() {
      _outputControllers.add(TextEditingController());
    });
  }

  void _removeOutputField(int index) {
    if (_outputControllers.length <= 1) return;

    setState(() {
      _outputControllers[index].dispose();
      _outputControllers.removeAt(index);
    });
  }

  void _saveTask() {
    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final outputs = _outputControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one output checklist.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Focus task saved successfully.')),
    );

    Navigator.pushReplacementNamed(context, '/tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(),

                    const SizedBox(height: 28),

                    const _LabelText('Task name'),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter task name';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Example: Hoàn thành UI Flutter',
                        icon: Icons.task_alt_rounded,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _LabelText('Description'),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        hint: 'Describe what you need to focus on...',
                        icon: Icons.description_outlined,
                      ),
                    ),

                    const SizedBox(height: 26),

                    const _LabelText('Estimated focus time'),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [25, 45, 60, 90].map((minutes) {
                        final bool isSelected = selectedMinutes == minutes;

                        return ChoiceChip(
                          label: Text('$minutes min'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF43D982),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF65708A),
                            fontWeight: FontWeight.w800,
                          ),
                          side: const BorderSide(color: Color(0xFFE5EAF3)),
                          onSelected: (_) {
                            setState(() {
                              selectedMinutes = minutes;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 26),

                    const _LabelText('Priority'),

                    const SizedBox(height: 12),

                    Row(
                      children: ['High', 'Medium', 'Low'].map((priority) {
                        final bool isSelected = selectedPriority == priority;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedPriority = priority;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF43D982)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF43D982)
                                        : const Color(0xFFE5EAF3),
                                  ),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF65708A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _LabelText('Output checklist'),
                        TextButton.icon(
                          onPressed: _addOutputField,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    ...List.generate(_outputControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _outputControllers[index],
                                decoration: _inputDecoration(
                                  hint: 'Output ${index + 1}',
                                  icon: Icons.checklist_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                _removeOutputField(index);
                              },
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _saveTask,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          'Save Focus Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5EAF3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF43D982), width: 1.5),
      ),
    );
  }
}

class _Header extends StatelessWidget {
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
            'Add Focus Task',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF07112D),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;

  const _LabelText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1F2937),
      ),
    );
  }
}
