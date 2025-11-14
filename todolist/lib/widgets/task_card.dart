// ignore_for_file: deprecated_member_use
// ปิด warning เกี่ยวกับ method เก่าของ Flutter ที่ยังใช้ได้อยู่ (เช่น ColorScheme)

import 'package:flutter/material.dart';                                       // วิดเจ็ตหลักของ Flutter
import 'package:intl/intl.dart';                                              // ใช้จัดรูปแบบวันที่ (เช่น dd/MM/yyyy)
import 'package:provider/provider.dart';                                      // ใช้สื่อสารกับ TaskProvider

import '../models/task.dart';                                                 // โมเดล Task (title, due, priority, isDone)
import '../providers/task_provider.dart';                                     // ตัวจัดการรายการงาน (add/update/delete)

/// วิดเจ็ตแสดงการ์ดงานแต่ละรายการในลิสต์
class TaskCard extends StatelessWidget {
  final Task task;                                                            // งานที่จะแสดงในการ์ดนี้
  final Future<void> Function() onEdit;                                       // ฟังก์ชันแก้ไข (เปิด dialog จากหน้า AddTask)

  /// ถ้าไม่ส่ง onDelete มา จะใช้ provider.delete(task.id) แทน
  final Future<void> Function()? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    this.onDelete,
  });


  // -----------------------------
  // สีหลักที่ใช้ในแอป (โทนเดียวกับ main.dart)
  // -----------------------------
  static const _primary = Color(0xFF4A90E2);                        // ฟ้าหลัก
  static const _mint = Color(0xFF50E3C2);                           // เขียวมิ้นต์
  static const _accentYellow = Color(0xFFFACC15);                   // เหลือง (ปานกลาง)
  static const _errorRed = Color(0xFFEF4444);                       // แดง (สำคัญ/ลบ)


  /// คืนค่าสีตามระดับความสำคัญของงาน
  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return _errorRed;       // แดง = สำคัญมาก
      case TaskPriority.medium:
        return _accentYellow;   // เหลือง = ปานกลาง
      case TaskPriority.low:

      // ignore: unreachable_switch_default
      default:
        return _mint;           // มิ้นต์ = น้อย
    }
  }


  /// แสดง dialog เพื่อยืนยันก่อนลบงาน
  Future<void> _confirmDelete(BuildContext context) async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm Delete'),                               // หัวข้อ dialog
            content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบงานนี้ออก?'),
            actions: [
              TextButton(                                                      // ปุ่มยกเลิก
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(                                                    // ปุ่มยืนยันลบ
                style: FilledButton.styleFrom(backgroundColor: _errorRed),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;                                                                // ถ้าผู้ใช้กดยกเลิกหรือปิด dialog -> false

    if (!ok) return;                                                          // ถ้าไม่ยืนยัน -> ไม่ทำอะไร

    if (onDelete != null) {
      await onDelete!();                                                      // ถ้ามีฟังก์ชัน onDelete ที่ส่งมา -> เรียกใช้งานนั้น
    } else {
      // fallback: ลบผ่าน provider โดยตรง (เช่นเรียกจากหน้า Dashboard)
      // ignore: use_build_context_synchronously
      await context.read<TaskProvider>().delete(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();                                    // ใช้ provider เพื่อ toggle สถานะงานได้

    return Card(
      elevation: 2,                                                                   // เงาจาง ๆ ของการ์ด
      margin: const EdgeInsets.symmetric(vertical: 6),                                // เว้นระยะบน-ล่าง
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),                                     // มุมโค้ง 16 px
      child: ListTile(

        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(                                                            // ช่องติ๊กเสร็จ/ไม่เสร็จ
          value: task.isDone,                                                         // ใช้สถานะปัจจุบันของงาน
          activeColor: _primary,                                                    // สีฟ้าเมื่อถูกติ๊ก
          onChanged: (v) async {                                                      // เมื่อผู้ใช้กดเปลี่ยน
            await provider.toggleDone(task.id, v ?? false);                           // อัปเดตสถานะใน provider
          },
        ),

        title: Text(                                                                  // ชื่อของงาน
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone                                                   // ถ้างานเสร็จแล้ว
            ? TextDecoration.lineThrough                                              // ขีดฆ่าข้อความ
            : null,
          ),
        ),

        subtitle: Row(                                                                // แสดงรายละเอียดด้านล่างชื่อ
          children: [
            if (task.due != null)                                                     // ถ้ามีวันที่กำหนด
              Text(
                DateFormat('dd/MM/yyyy').format(task.due!),                           // แปลงวันที่เป็นข้อความ
                style: const TextStyle(fontSize: 13),
              ),
            const SizedBox(width: 8),
            Container(                                                                // กล่องสีแสดงระดับความสำคัญ
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _priorityColor(task.priority).withOpacity(0.15),               // พื้นหลังโปร่งบาง
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(

                task.priority.name.toUpperCase(),                                    // แสดงชื่อระดับ (LOW / MEDIUM / HIGH)
                style: TextStyle(
                  color: _priorityColor(task.priority),                              // สีตัวอักษรตรงตามระดับ
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        trailing: Row(                                                             // ปุ่มด้านขวาของการ์ด
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(                                                            // ปุ่มแก้ไข
              tooltip: 'Edit',
              icon: const Icon(Icons.edit, color: _accentYellow),
              onPressed: onEdit,                                                   // เรียกฟังก์ชันแก้ไขที่ส่งมาจากภายนอก
            ),
            IconButton(                                                            // ปุ่มลบ
              tooltip: 'Delete',
              icon: const Icon(Icons.delete, color: _errorRed),
              onPressed: () => _confirmDelete(context),                            // เรียก dialog ยืนยันลบ
            ),
          ],
        ),
      ),
    );
  }
}
