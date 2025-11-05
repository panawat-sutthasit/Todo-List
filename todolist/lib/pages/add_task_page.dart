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
  final _dueCtrl = TextEditingController();

  DateTime? _due;
  TaskPriority _priority = TaskPriority.low;

  @override
  void initState() {
    super.initState();
    // ตั้งค่า Due Date เป็น "วันนี้" ทันที
    final now = DateTime.now();
    _due = DateTime(now.year, now.month, now.day);
    _dueCtrl.text = DateFormat('dd/MM/yyyy').format(_due!);
  }

  @override
  void dispose() {
    _title.dispose();
    _dueCtrl.dispose();
    super.dispose();
  }

  // สีตามระดับความสำคัญ
  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return const Color(0xFFEF4444); // แดง
      case TaskPriority.medium:
        return const Color(0xFFFACC15); // เหลือง
      case TaskPriority.low:
      // ignore: unreachable_switch_default
      default:
        return const Color(0xFF50E3C2); // มิ้นต์
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      // ❗ ล็อคไม่ให้เลือกวันที่ย้อนหลัง
      firstDate: todayStart,
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDate: (_due != null && _due!.isAfter(todayStart)) ? _due! : todayStart,
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );

    if (picked != null) {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _due = normalized;
        _dueCtrl.text = DateFormat('dd/MM/yyyy').format(normalized);
      });
    }
  }

  Future<void> _save() async {
    final text = _title.text.trim();

    // ตรวจว่าขั้นต่ำ 3 ตัวอักษร
    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่องานอย่างน้อย 3 ตัวอักษร')),
      );
      return;
    }

    // กันกรณี _due เป็นอดีต (เช่น ได้มาจาก state เก่า / import)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    DateTime effectiveDue = _due ?? todayStart;
    if (effectiveDue.isBefore(todayStart)) {
      effectiveDue = todayStart;
    }

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      due: effectiveDue,
      priority: _priority,
    );

    await context.read<TaskProvider>().add(newTask);

    // รีเซ็ตฟอร์ม: ตั้งวันกลับเป็น "วันนี้"
    _title.clear();
    setState(() {
      _priority = TaskPriority.low;
      _due = todayStart;
      _dueCtrl.text = DateFormat('dd/MM/yyyy').format(todayStart);
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
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title + helper + counter 0/40
                      TextField(
                        controller: _title,
                        maxLength: 40, // แสดง counter อัตโนมัติขวาล่าง
                        decoration: InputDecoration(
                          hintText: 'What needs to be done?',
                          helperText: 'อย่างน้อย 3 ตัวอักษร', // ซ้ายล่าง
                          filled: true,
                          // ignore: deprecated_member_use
                          fillColor: theme.colorScheme.surface.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 12),

                      // Due date + Priority
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Due Date field + helper "เลือกวันที่"
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: AbsorbPointer(
                                    child: TextField(
                                      readOnly: true,
                                      controller: _dueCtrl,
                                      decoration: InputDecoration(
                                        hintText: 'Due Date',
                                        suffixIcon: IconButton(
                                          onPressed: _pickDate,
                                          icon: const Icon(Icons.calendar_today_outlined),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'เลือกวันที่',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Priority field + helper "ระดับความสำคัญของงาน"
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<TaskPriority>(
                                  // ignore: deprecated_member_use
                                  value: _priority,
                                  items: TaskPriority.values.map((p) {
                                    final label = p.name[0].toUpperCase() + p.name.substring(1);
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _priorityColor(p),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(label),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  // ให้ค่าที่ถูกเลือกแสดงสีตามระดับ
                                  selectedItemBuilder: (ctx) =>
                                      TaskPriority.values.map((p) {
                                    final label = p.name[0].toUpperCase() + p.name.substring(1);
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        label,
                                        style: TextStyle(color: _priorityColor(p)),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => _priority = v ?? TaskPriority.low),
                                  decoration: InputDecoration(
                                    hintText: 'Priority',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'ระดับความสำคัญของงาน',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Add button
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
                          label: const Text('Add Task'),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                            horizontal: 16,
                            vertical: 14,
                          ),
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
                      Icon(
                        Icons.edit_note,
                        size: 64,
                        // ignore: deprecated_member_use
                        color: theme.colorScheme.primary.withOpacity(.35),
                      ),
                      const SizedBox(height: 8),
                      Text('No tasks yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('Add your first task above to get started!'),
                    ],
                  ),
                )
              else
                ...provider.tasks.map(
                  (t) => TaskCard(
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
                                        final todayStart = DateTime(now.year, now.month, now.day);
                                        final picked = await showDatePicker(
                                          context: context,
                                          firstDate: todayStart, // ล็อคไม่ให้ย้อนหลัง
                                          lastDate: DateTime(now.year + 5, 12, 31),
                                          initialDate: dd ?? todayStart,
                                        );
                                        if (picked != null) {
                                          dd = DateTime(picked.year, picked.month, picked.day);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today, size: 18),
                                      label: Text(
                                        dd == null
                                            ? 'ว/ด/ปปปป'
                                            : DateFormat('dd/MM/yyyy').format(dd!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<TaskPriority>(
                                      // ignore: deprecated_member_use
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
                                final newTitle = ctrl.text.trim();
                                if (newTitle.isNotEmpty) t.title = newTitle;
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
                    // ไม่ส่ง onDelete เพื่อไม่ให้มี dialog ซ้ำ (TaskCard มี dialog ของตัวเอง)
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
