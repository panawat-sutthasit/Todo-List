// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Future<void> Function() onEdit;
  /// ถ้าไม่ส่ง onDelete มา จะลบผ่าน provider.delete(task.id) ให้เอง
  final Future<void> Function()? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    this.onDelete,
  });

  // โทนสีตามโปรเจกต์
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
            title: const Text('Confirm Delete'),
            content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบงานนี้ออก?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _errorRed),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    if (onDelete != null) {
      await onDelete!();
    } else {
      // fallback: ลบผ่าน provider
      // ignore: use_build_context_synchronously
      await context.read<TaskProvider>().delete(task.id);
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
            await provider.toggleDone(task.id, v ?? false);
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
              tooltip: 'Edit',
              icon: const Icon(Icons.edit, color: _accentYellow),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete, color: _errorRed),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
