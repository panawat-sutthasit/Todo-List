import 'package:flutter/material.dart';                                 // วิดเจ็ตและธีมของ Flutter
import 'package:intl/intl.dart';                                        // จัดรูปแบบวันที่/เวลา
import 'package:provider/provider.dart';                                // ใช้ Provider สำหรับ state management

import '../models/task.dart';                                           // โมเดล Task และ enum TaskPriority
import '../providers/task_provider.dart';                               // ตัวจัดการงาน (เพิ่ม/ลบ/แก้ไข/ค้นหา/โหลด)
import '../widgets/task_card.dart';                                     // การ์ดแสดงรายการงานแต่ละชิ้น

class AddTaskPage extends StatefulWidget {                              // หน้าเพิ่มงานเป็น Stateful (มี state เปลี่ยนได้)
  const AddTaskPage({super.key});                                   

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _title = TextEditingController();                               // คอนโทรลเลอร์ของช่อง Title
  final _dueCtrl = TextEditingController();                             // คอนโทรลเลอร์ของช่องวันที่ (readOnly แสดงผล)

  DateTime? _due;                                                       // ค่าวันที่ครบกำหนดของงาน
  TaskPriority _priority = TaskPriority.low;                            // ค่าระดับความสำคัญเริ่มต้น = Low

  @override
  void initState() {
    super.initState();                                                  // เรียกของเดิมก่อน

    // ตั้งค่า Due Date เป็น "วันนี้" ทันทีเมื่อเข้าเพจ
    final now = DateTime.now();                                         // เวลาปัจจุบัน
    _due = DateTime(now.year, now.month, now.day);                      // normalize เป็นเที่ยงคืนของวันนี้
    _dueCtrl.text = DateFormat('dd/MM/yyyy').format(_due!);             // แสดงผลลงใน TextField
  }

  @override
  void dispose() {
    _title.dispose();                                                   // เคลียร์ resource ของ controller
    _dueCtrl.dispose();
    super.dispose();
  }

  // คืนสีตามระดับความสำคัญของงาน (สำหรับใช้ในดรอปดาวน์)
  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);                             // แดง = High
      case TaskPriority.medium:
        return const Color(0xFFFACC15);                             // เหลือง = Medium
      case TaskPriority.low:
      // ignore: unreachable_switch_default
      default:
        return const Color(0xFF50E3C2);                             // มิ้นต์ = Low
    }
  }

  Future<void> _pickDate() async {                                    // เปิด DatePicker ให้ผู้ใช้เลือกวัน
    final now = DateTime.now();                                       // ตอนนี้
    final todayStart = DateTime(now.year, now.month, now.day);        // เที่ยงคืนของวันนี้

    final picked = await showDatePicker(                              // แสดง dialog ปฏิทิน
      context: context,
      
      // ❗ ล็อคไม่ให้เลือกวันที่ย้อนหลัง
      firstDate: todayStart,
      lastDate: DateTime(now.year + 5, 12, 31),                      // อนาคตได้ถึง 5 ปี

      // ถ้ามี _due และอยู่หลังวันนี้ ให้เริ่มที่ _due ไม่งั้นเริ่มที่วันนี้
      initialDate: (_due != null && _due!.isAfter(todayStart)) ? _due! : todayStart,
      helpText: 'เลือกวันที่',                                           // ชื่อหัวปฏิทิน
      cancelText: 'ยกเลิก',                                           // ปุ่มยกเลิก
      confirmText: 'ตกลง',                                           // ปุ่มตกลง
    );

    if (picked != null) {                                                     // ถ้าเลือกได้
      final normalized = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _due = normalized;                                                    // เก็บค่าใหม่
        _dueCtrl.text = DateFormat('dd/MM/yyyy').format(normalized);          // อัปเดตแสดงผล
      });
    }
  }

  Future<void> _save() async {                                                // บันทึกงานใหม่
    final text = _title.text.trim();                                          // ตัดช่องว่างหัวท้าย

    // ตรวจความยาวขั้นต่ำของชื่อเรื่อง
    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่องานอย่างน้อย 3 ตัวอักษร')),
      );
      return;                                                                 // ยกเลิกถ้าสั้นเกินไป
    }

    // ป้องกันกรณีวันที่ย้อนหลัง (เช่น state เก่าหรือ import)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    DateTime effectiveDue = _due ?? todayStart;                               // ถ้า null ให้เป็นวันนี้
    if (effectiveDue.isBefore(todayStart)) {                                  // ถ้าย้อนหลัง
      effectiveDue = todayStart;                                              // บังคับเป็นวันนี้
    }

    final newTask = Task(                                                     // สร้างอ็อบเจ็กต์ Task ใหม่
      id: DateTime.now().millisecondsSinceEpoch.toString(),                   // id จาก timestamp
      title: text,                                                            // ชื่อเรื่อง
      due: effectiveDue,                                                      // วันครบกำหนด (ผ่านการตรวจแล้ว)
      priority: _priority,                                                    // ระดับความสำคัญ
    );

    await context.read<TaskProvider>().add(newTask);                          // ส่งให้ Provider บันทึก

    // รีเซ็ตฟอร์มกลับเป็นค่าเริ่มต้น (และตั้งวันกลับเป็นวันนี้)
    _title.clear();                                                           // ล้างช่องชื่อ
    setState(() {
      _priority = TaskPriority.low;                                           // ตั้ง Priority = Low
      _due = todayStart;                                                      // ตั้ง Due = วันนี้
      _dueCtrl.text = DateFormat('dd/MM/yyyy').format(todayStart);            // อัปเดตแสดงผล
    });
  }

  // ปุ่มชิปกรองรายการ: All / Complete / Overdue
  Widget _pillTab(String label, TaskFilter filter) {
    final provider = context.watch<TaskProvider>();                           // ฟังค่า filter ปัจจุบัน
    final isActive = provider.filter == filter;                               // เทียบว่าแท็บนี้ถูกเลือกไหม
    return ChoiceChip(
      label: Text(label),                                                     // ชื่อแท็บ
      selected: isActive,                                                     // สถานะเลือก
      onSelected: (_) {                                                       // เมื่อกด
        provider.filter = filter;                                             // อัปเดตค่า filter


        // แจ้งผู้ฟังให้รีเฟรช (เพราะเราเปลี่ยนพร็อพภายนอก)
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        provider.notifyListeners();
      },
      selectedColor: const Color(0xFF4A90E2),                               // สีพื้นเมื่อเลือก
      labelStyle: TextStyle(
        color: isActive ? Colors.white : const Color(0xFF1E293B),         // สีตัวอักษร
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,                                        // สีพื้นตอนยังไม่เลือก
      side: const BorderSide(color: Color(0xFFE2E8F0)),                     // เส้นขอบชิป
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);                                         // ธีมปัจจุบัน
    final provider = context.watch<TaskProvider>();                          // ฟังรายการงาน/การเปลี่ยนแปลง

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,             // พื้นหลังเพจ
      body: SafeArea(                                                        // อย่าให้ชนรอยบาก/ขอบจอ
        child: SingleChildScrollView(                                        // เลื่อนทั้งหน้าได้ (กันคีย์บอร์ดล้น)
          padding: const EdgeInsets.all(16),                                 // ระยะขอบทั้งสี่ด้าน
          child: Column(
            children: [

              // ---------- Add Task Card ----------
              Card(                                                          // กล่องฟอร์มเพิ่มงาน
                elevation: 3,                                                // เงานิดหน่อย
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),                   // มุมโค้ง 24
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),                         // ระยะห่างภายใน
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,          // ให้ลูกยืดเต็มแนวนอน
                    children: [

                      // ช่องกรอก Title + helper + counter 0/40
                      TextField(
                        controller: _title,                                  // ผูกคอนโทรลเลอร์ชื่อเรื่อง
                        maxLength: 40,                                       // จำกัด 40 ตัวอักษร (มีตัวนับอัตโนมัติ)
                        decoration: InputDecoration(
                          hintText: 'What needs to be done?',                // ข้อความใบ้ในช่อง
                          helperText: 'อย่างน้อย 3 ตัวอักษร',                   // ข้อความช่วยด้านล่างซ้าย
                          
          
                          filled: true,                                     // พื้นหลังทึบอ่อนๆ
                          // ignore: deprecated_member_use
                          fillColor: theme.colorScheme.surface.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),       // มุมโค้ง 16
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,                                // ระยะขอบซ้าย/ขวา
                            vertical: 14,                                  // ระยะขอบบน/ล่าง
                          ),
                        ),
                        textInputAction: TextInputAction.next,            // ปุ่มคีย์บอร์ด = Next
                        onSubmitted: (_) => _save(),                      // กด Enter แล้วบันทึก
                      ),
                      const SizedBox(height: 12),                         // เว้นระยะแนวตั้ง

                      // แถว: Due date + Priority
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // คอลัมน์ซ้าย: ช่องวันที่ + helper "เลือกวันที่"
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(                                            // ให้ทั้งกล่องแตะแล้วเปิดปฏิทิน
                                  onTap: _pickDate,
                                  child: AbsorbPointer(                                     // กันไม่ให้พิมพ์ตรงๆ (readOnly)
                                    child: TextField(
                                      readOnly: true,                                       // อ่านอย่างเดียว
                                      controller: _dueCtrl,                                 // ผูกกับข้อความวันที่ dd/MM/yyyy
                                      decoration: InputDecoration(
                                        hintText: 'Due Date',                               // ใบ้ถ้ายังไม่มีค่า
                                        suffixIcon: IconButton(                             // ไอคอนปฏิทินด้านขวา
                                          onPressed: _pickDate,                             // กดแล้วเปิด DatePicker
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
                                Row(
                                  children: [
                                    const SizedBox(width: 20),                                   // ดันข้อความให้เยื้องนิดๆ
                                    const Text(
                                      'เลือกวันที่',                                                // คำอธิบายใต้ช่องวันที่
                                      style: TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),                                            // ระยะห่างระหว่างคอลัมน์

                          // Priority field + helper "ระดับความสำคัญของงาน"
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<TaskPriority>(                          // ดรอปดาวน์เลือกระดับ

                                  // ignore: deprecated_member_use
                                  value: _priority,                                               // ค่าเริ่มต้น
                                  items: TaskPriority.values.map((p) {                            // สร้างตัวเลือกจาก enum
                                    final label = p.name[0].toUpperCase() + p.name.substring(1);  
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Container(                                           // จุดสีเล็กๆ ตามระดับ
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _priorityColor(p),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(label),                                       // ชื่อระดับ (Low/Medium/High)
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  // ปรับสีข้อความของค่าที่ “ถูกเลือก” ในช่องให้เป็นสีตามระดับ
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
                                    hintText: 'Priority',                                   // ใบ้ถ้ายังไม่เลือก
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
                                Row(
                                  children: [
                                    const SizedBox(width: 20,),
                                    const Text(
                                      'ระดับความสำคัญของงาน',                                      // คำอธิบายใต้ช่อง Priority
                                      style: TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),                                     // เว้นระยะก่อนปุ่ม

                      // ปุ่ม Add Task
                      SizedBox(
                        height: 52,                                                  // ความสูงปุ่ม
                        child: FilledButton.icon(                                    // ปุ่มสไตล์ Filled + ไอคอน
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
                          onPressed: _save,                                          // เมื่อกดให้บันทึกงาน
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Add Task'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),                                       // เว้นระยะก่อนบล็อกกรอง/ค้นหา


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
                      Wrap(                                                   // แถวชิปกรอง (ล้นแล้วตัดบรรทัดได้)
                        spacing: 8,
                        children: [
                          _pillTab('All Tasks', TaskFilter.all),             // ทั้งหมด
                          _pillTab('Complete', TaskFilter.completed),        // เสร็จแล้ว
                          _pillTab('Overdue', TaskFilter.overdue),           // เกินกำหนด
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(                                             // ช่องค้นหาข้อความในชื่อเรื่อง
                        onChanged: (v) {
                          provider.search = v;                               // อัปเดตคำค้นใน Provider

                          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                          provider.notifyListeners();                        // รีเฟรชลิสต์ทันที
                        },
                        decoration: InputDecoration(
                          hintText: 'Search tasks…',                         // ใบ้ในช่องค้นหา
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

              const SizedBox(height: 16),                                         // เว้นระยะก่อนรายการงาน

              // ---------- Task list ----------
              if (provider.tasks.isEmpty)                                         // ถ้ายังไม่มีงาน
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
                ...provider.tasks.map(                                    // วนรายการงานที่ผ่าน filter/search แล้ว
                  (t) => TaskCard(
                    task: t,                                              // ส่งงานไปให้การ์ดแสดง
                    onEdit: () async {                                    // เมื่อกดแก้ไขบนการ์ด
                      final ctrl = TextEditingController(text: t.title);  // คุมช่องชื่อ
                      DateTime? dd = t.due;                               // วันที่เดิม
                      TaskPriority pp = t.priority;                       // ระดับเดิม
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
                                    child: OutlinedButton.icon(             // ปุ่มเลือกวันใหม่
                                      onPressed: () async {
                                        final now = DateTime.now();
                                        final todayStart = DateTime(now.year, now.month, now.day);
                                        final picked = await showDatePicker(
                                          context: context,
                                          firstDate: todayStart, // ❗ ล็อคไม่ให้ย้อนหลัง
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
                                    child: DropdownButtonFormField<TaskPriority>(     // เลือกระดับใหม่
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
                            TextButton(                                             // ปุ่มยกเลิก
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(                                           // ปุ่มบันทึก
                              onPressed: () async {
                                final newTitle = ctrl.text.trim();
                                if (newTitle.isNotEmpty) t.title = newTitle;        // อัปเดตชื่อถ้าไม่ว่าง
                                t.due = dd;                                         // อัปเดตวัน
                                t.priority = pp;                                    // อัปเดตระดับ
                                await context.read<TaskProvider>().update(t);       // เซฟผ่าน Provider
                                if (context.mounted) Navigator.pop(context);        // ปิดไดอะล็อก
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                    // ไม่ส่ง onDelete เพื่อใช้ dialog ยืนยันลบจาก TaskCard เพียงชุดเดียว (กันซ้ำ)
                  ),
                ),
              const SizedBox(height: 100),                    // เผื่อที่ให้ bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
