import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart'; // ใช้งาน TaskCard ตรง ๆ

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
      lastDate: DateTime(now.year + 5),
      initialDate: _due ?? now,
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final text = _title.text.trim();
    if (text.isEmpty) return;
    final t = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      due: _due,
      priority: _priority,
    );
    await context.read<TaskProvider>().add(t);
    _title.clear();
    setState(() {
      _due = null;
      _priority = TaskPriority.low;
    });
  }

  Widget _pillTab(BuildContext ctx, String label, TaskFilter f) {
    final isActive = context.watch<TaskProvider>().filter == f;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) {
        context.read<TaskProvider>().filter = f;
        // รีเฟรชลิสต์
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        context.read<TaskProvider>().notifyListeners();
      },
      selectedColor: const Color(0xFF4A90E2),
      labelStyle: TextStyle(
        color: isActive ? Colors.white : const Color(0xFF1E293B),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: StadiumBorder(
        side: BorderSide(
          color: isActive ? const Color(0xFF4A90E2) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TaskProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // ---------- Add Task (2 บรรทัด กันล้นแน่นอน) ----------
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: LayoutBuilder(
                builder: (context, c) {
                  const double h = 48;
                  const double gap = 8;

                  final dateField = SizedBox(
                    height: h,
                    width: 140,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _due == null
                            ? 'ว/ด/ปปปป'
                            : DateFormat('dd/MM/yyyy').format(_due!),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );

                  final priorityField = SizedBox(
                    height: h,
                    width: 140,
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _priority,
                      items: const [
                        DropdownMenuItem(value: TaskPriority.low, child: Text('Low')),
                        DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium')),
                        DropdownMenuItem(value: TaskPriority.high, child: Text('High')),
                      ],
                      onChanged: (v) => setState(() => _priority = v ?? TaskPriority.low),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                  );

                  final addBtn = ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: h, minWidth: 112),
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text('Add Task'),
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // บรรทัดบน: Title เต็มแถว
                      SizedBox(
                        height: h,
                        width: c.maxWidth,
                        child: TextField(
                          controller: _title,
                          onSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            hintText: 'What needs to be done?',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      // บรรทัดล่าง: วันที่ + Priority + Add (Wrap ยืดหยุ่น)
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [dateField, priorityField, addBtn],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------- Tabs + Search ----------
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _pillTab(context, 'All Tasks', TaskFilter.all),
                      _pillTab(context, 'Complete', TaskFilter.completed),
                      _pillTab(context, 'Overdue', TaskFilter.overdue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) {
                      provider.search = v;
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      provider.notifyListeners();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search tasks…..',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ---------- Empty state ----------
          if (provider.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.edit_note,
                      size: 64, color: theme.colorScheme.primary.withOpacity(.35)),
                  const SizedBox(height: 8),
                  Text('No tasks yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Add your first task above to get started!'),
                ],
              ),
            ),

          // ---------- Task list ----------
          for (final t in provider.tasks)
            TaskCard(
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
                          decoration: const InputDecoration(labelText: 'Title'),
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
                                    firstDate: DateTime(now.year - 1),
                                    lastDate: DateTime(now.year + 5),
                                    initialDate: dd ?? now,
                                  );
                                  if (picked != null) dd = picked;
                                },
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(dd == null
                                    ? 'ว/ด/ปปปป'
                                    : DateFormat('dd/MM/yyyy').format(dd!)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<TaskPriority>(
                                value: pp,
                                items: const [
                                  DropdownMenuItem(value: TaskPriority.low, child: Text('Low')),
                                  DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium')),
                                  DropdownMenuItem(value: TaskPriority.high, child: Text('High')),
                                ],
                                onChanged: (v) => pp = v ?? TaskPriority.low,
                                decoration: const InputDecoration(labelText: 'Priority'),
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
                          t.title = ctrl.text.trim().isEmpty ? t.title : ctrl.text.trim();
                          t.due = dd;
                          t.priority = pp;
                          await context.read<TaskProvider>().update(t);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
              // ส่ง onDelete ให้ TaskCard (TaskCard จะถามยืนยันเอง)
              onDelete: () async {
                await context.read<TaskProvider>().removeById(t.id);
              },
            ),

          const SizedBox(height: 100), // เผื่อพื้นที่เหนือ bottom nav
        ],
      ),
    );
  }
}
