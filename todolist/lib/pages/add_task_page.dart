import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _title = TextEditingController();
  DateTime? _due;
  TaskPriority _priority = TaskPriority.low;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _due ?? now,
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null) {
      setState(() => _due = picked);
    }
  }

  Future<void> _save() async {
    final text = _title.text.trim();
    if (text.isEmpty) return;
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      due: _due,
      priority: _priority,
    );
    await context.read<TaskProvider>().add(newTask);
    _title.clear();
    setState(() {
      _due = null;
      _priority = TaskPriority.low;
    });
  }

  Widget _pillTab(String label, TaskFilter filter) {
    final provider = context.watch<TaskProvider>();
    final isActive = provider.filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) {
        provider.filter = filter;
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        provider.notifyListeners();
      },
      selectedColor: const Color(0xFF4A90E2),
      labelStyle: TextStyle(
        color: isActive ? Colors.white : const Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---------- Add Task Card ----------
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _title,
                        maxLength: 40,
                        decoration: InputDecoration(
                          hintText: 'What needs to be done?',
                          counterText: '',
                          filled: true,
                          fillColor:
                              // ignore: deprecated_member_use
                              theme.colorScheme.surface.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // วันที่
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: _due == null
                                        ? ''
                                        : DateFormat('dd/MM/yyyy')
                                            .format(_due!),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Due Date',
                                    suffixIcon: IconButton(
                                      onPressed: _pickDate,
                                      icon: const Icon(
                                          Icons.calendar_today_outlined),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Priority
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              // ignore: deprecated_member_use
                              value: _priority,
                              items: const [
                                DropdownMenuItem(
                                    value: TaskPriority.low,
                                    child: Text('Low')),
                                DropdownMenuItem(
                                    value: TaskPriority.medium,
                                    child: Text('Medium')),
                                DropdownMenuItem(
                                    value: TaskPriority.high,
                                    child: Text('High')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _priority = v!),
                              decoration: InputDecoration(
                                hintText: 'Priority',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _save,
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text("Add Task"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- Filter Tabs ----------
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          _pillTab('All Tasks', TaskFilter.all),
                          _pillTab('Complete', TaskFilter.completed),
                          _pillTab('Overdue', TaskFilter.overdue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) {
                          provider.search = v;
                          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                          provider.notifyListeners();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search tasks…',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------- Task list ----------
              if (provider.tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.edit_note,
                          size: 64,
                          // ignore: deprecated_member_use
                          color: theme.colorScheme.primary.withOpacity(.35)),
                      const SizedBox(height: 8),
                      Text('No tasks yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('Add your first task above to get started!'),
                    ],
                  ),
                )
              else
                ...provider.tasks.map((t) => TaskCard(
                      task: t,
                      onEdit: () async {
                        final ctrl = TextEditingController(text: t.title);
                        DateTime? dd = t.due;
                        TaskPriority pp = t.priority;
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Edit Task'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: ctrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Title'),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            firstDate:
                                                DateTime(now.year - 1),
                                            lastDate:
                                                DateTime(now.year + 5),
                                            initialDate: dd ?? now,
                                          );
                                          if (picked != null) dd = picked;
                                        },
                                        icon: const Icon(
                                            Icons.calendar_today, size: 18),
                                        label: Text(dd == null
                                            ? 'ว/ด/ปปปป'
                                            : DateFormat('dd/MM/yyyy')
                                                .format(dd!)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child:
                                          DropdownButtonFormField<TaskPriority>(
                                        // ignore: deprecated_member_use
                                        value: pp,
                                        items: const [
                                          DropdownMenuItem(
                                              value: TaskPriority.low,
                                              child: Text('Low')),
                                          DropdownMenuItem(
                                              value: TaskPriority.medium,
                                              child: Text('Medium')),
                                          DropdownMenuItem(
                                              value: TaskPriority.high,
                                              child: Text('High')),
                                        ],
                                        onChanged: (v) =>
                                            pp = v ?? TaskPriority.low,
                                        decoration: const InputDecoration(
                                            labelText: 'Priority'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  t.title = ctrl.text.trim().isEmpty
                                      ? t.title
                                      : ctrl.text.trim();
                                  t.due = dd;
                                  t.priority = pp;
                                  await context
                                      .read<TaskProvider>()
                                      .update(t);
                                  if (context.mounted)
                                    // ignore: curly_braces_in_flow_control_structures
                                    Navigator.pop(context);
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                                'คุณแน่ใจหรือไม่ว่าต้องการลบงานนี้ออก?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // ignore: use_build_context_synchronously
                          await context.read<TaskProvider>().delete(t.id);
                        }
                      },
                    )),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
