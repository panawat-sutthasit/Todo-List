import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Future<void> Function() onEdit;
  /// ถ้าไม่ส่ง onDelete มา จะลบผ่าน provider.removeById(task.id) ให้เอง
  final Future<void> Function()? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    this.onDelete,
  });

  // พาเล็ตสีตามโปรเจกต์
  static const _primary = Color(0xFF4A90E2);
  static const _mint = Color(0xFF50E3C2);
  static const _accentYellow = Color(0xFFFACC15);
  static const _errorRed = Color(0xFFEF4444);

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return _errorRed;       // แดง
      case TaskPriority.medium:
        return _accentYellow;   // เหลือง
      case TaskPriority.low:
      // ignore: unreachable_switch_default
      default:
        return _mint;           // มิ้นต์
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: Text('ต้องการลบ “${task.title}” จริงๆ ใช่ไหม?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _errorRed),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ลบ'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    if (onDelete != null) {
      await onDelete!();
    } else {
      // fallback: ลบผ่าน provider ถ้าไม่ได้ส่ง callback มา
      // ignore: use_build_context_synchronously
      final prov = context.read<TaskProvider>();
      // ignore: unnecessary_null_comparison
      if (prov.removeById != null) {
        await prov.removeById(task.id);
      // ignore: dead_code
      } else {
        // เผื่อบางโปรเจกต์มีเมธอดชื่ออื่น
        // ให้ลองลบแบบกรอง list แล้ว notify แทน (ปรับใช้ตามโปรเจกต์จริง)
        await prov.removeById(task.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: task.isDone,
          activeColor: _primary,
          onChanged: (v) async {
            task.isDone = v ?? false;
            await provider.update(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (task.due != null)
              Text(
                DateFormat('dd/MM/yyyy').format(task.due!),
                style: const TextStyle(fontSize: 13),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: _priorityColor(task.priority).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(
                  color: _priorityColor(task.priority),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'แก้ไข',
              icon: const Icon(Icons.edit, color: _accentYellow),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'ลบ',
              icon: const Icon(Icons.delete, color: _errorRed),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
