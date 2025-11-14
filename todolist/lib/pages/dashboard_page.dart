import 'package:flutter/material.dart';                                            // วิดเจ็ตพื้นฐานของ Flutter
import 'package:intl/intl.dart';                                                   // ใช้จัดรูปแบบวันที่/เวลา
import 'package:provider/provider.dart';                                           // ใช้ Provider จัดการ state
import 'package:table_calendar/table_calendar.dart';                               // วิดเจ็ตปฏิทินสำเร็จรูป

import '../providers/task_provider.dart';                                          // ตัวจัดการรายการงานทั้งหมด
import '../widgets/task_card.dart';                                                // การ์ดแสดงงานแต่ละชิ้น

// ignore: unused_import
import '../models/task.dart';                                                      // โมเดล Task (มีใช้ในคอมเมนต์/อนาคต)

class DashboardPage extends StatefulWidget {                                       // หน้า Dashboard เป็น Stateful
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDay = DateTime.now();                                            // วันที่ที่ปฏิทินโฟกัสอยู่ (เดือนนี้)
  DateTime? _selectedDay;                                                           // วันที่ผู้ใช้เลือกในปฏิทิน

  // ค่าเดือน/ปี สำหรับดรอปดาวน์ควบคุมปฏิทินด้านบน
  late int _visibleMonth;
  late int _visibleYear;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();                                                 // ค่าเริ่มต้น = วันนี้
    _focusedDay = DateTime(                                                        // โฟกัสที่วันแรกของเดือนปัจจุบัน
      DateTime.now().year, 
      DateTime.now().month, 
      1
      );

    _visibleMonth = _focusedDay.month;                                             // เดือนที่แสดงบนดรอปดาวน์
    _visibleYear = _focusedDay.year;                                               // ปีที่แสดงบนดรอปดาวน์
  }

  // เปลี่ยนเดือนที่แสดงบนปฏิทิน (delta = +1 หรือ -1)
  void _changeMonth(int delta) {
    final d = DateTime(_visibleYear, _visibleMonth + delta, 1);                    // เดือนใหม่ (คำนวณข้ามปีได้)
    setState(() {
      _focusedDay = d;                                                             // โฟกัสเดือนใหม่
      _visibleMonth = d.month;                                                     // อัปเดตค่าในดรอปดาวน์เดือน
      _visibleYear = d.year;                                                       // อัปเดตค่าในดรอปดาวน์ปี
    });
  }

  // ปุ่ม "Today" — เลื่อนไปวันนี้แล้วรีเซ็ตดรอปดาวน์
  void _goToday() {
    final today = DateTime.now();                                                  // เวลาปัจจุบัน
    setState(() {
      _selectedDay = today;                                                        // วันที่เลือก = วันนี้
      _focusedDay = DateTime(today.year, today.month, 1);                          // โฟกัสวันแรกของเดือนนี้
      _visibleMonth = today.month;                                                 // ดรอปดาวน์เดือน = เดือนปัจจุบัน
      _visibleYear = today.year;                                                   // ดรอปดาวน์ปี = ปีปัจจุบัน
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();                              // ฟังการเปลี่ยนแปลงของงานทั้งหมด
    final theme = Theme.of(context);                                             // ใช้ธีมปัจจุบันช่วยจัดสไตล์

    // ====== เตรียมรายการเดือน/ปีสำหรับดรอปดาวน์ ======
    final int startYear = DateTime.now().year - 5;                               // ปีเริ่มต้นให้เลือก (ย้อนหลัง 5 ปี)
    final int endYear = DateTime.now().year + 5;                                 // ปีสุดท้ายให้เลือก (อนาคต 5 ปี)
    final months = List.generate(12, (i) => i + 1);                              // สร้างลิสต์เดือน 1–12
    final years = List.generate(                                                 // สร้างลิสต์ปีตามช่วงที่กำหนด
      endYear - startYear + 1,
       (i) => startYear + i
      );

    // ====== คำนวณสรุป "เฉพาะวัน" ที่เลือก ======
    final selected = _selectedDay ?? DateTime.now();                             // ถ้า _selectedDay เป็น null ใช้วันนี้
    final tasksOfDay = provider.tasksOn(selected);                               // งานทั้งหมดของวันนั้น (ผ่าน helper)
    final totalDay = tasksOfDay.length;                                          // จำนวนงานทั้งหมดของวันนั้น
    final completedDay = tasksOfDay
    .where((t) => t.isDone)
    .length;
    final pendingDay = totalDay - completedDay;                                 // งานที่ยังไม่เสร็จในวันนั้น

    // ====== คำนวณ Overdue (ทุกวันในระบบ) ======
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);                   // normalize เป็นวันวันนี้
    final overdueAll = provider.tasks                                           // ดูจากงานทั้งหมดในระบบ
        .where(
          (t) =>
           !t.isDone &&                                                         // ยังไม่เสร็จ
           t.due != null &&                                                     // มีวันครบกำหนด
           t.due!.isBefore(todayOnly),                                          // และวันนั้นอยู่ก่อนวันนี้ = เกินกำหนด
        )
        .length;

    // ฟังก์ชันสำหรับบอก TableCalendar ว่าแต่ละวันมี "event" เท่าไร (ใช้แสดงจุดใต้วันที่)
    // ignore: no_leading_underscores_for_local_identifiers
    List<dynamic> _eventsLoader(DateTime day) => provider.tasksOn(day);

    return SafeArea(
      child: ListView(                                                          // เนื้อหาทั้งหน้าเป็น List เลื่อนแนวตั้ง
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [

          // ---------------- Header ด้านบน ----------------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),                                // พื้นหลังฟ้า
              borderRadius: BorderRadius.circular(12),                         // มุมโค้ง 12
            ),
            alignment: Alignment.center,
            child: const Text(
              'My Tasks Dashboard',                                            // ชื่อหัวหน้า Dashboard
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---------------- สรุปของ "วันที่เลือก" ----------------
          Row(
            children: [
              _summaryCard('TOTAL', '$totalDay', theme),                      // จำนวนงานทั้งหมดของวัน
              const SizedBox(width: 8),
              _summaryCard('COMPLETED', '$completedDay', theme),              // จำนวนงานเสร็จ
              const SizedBox(width: 8),
              _summaryCard('PENDING', '$pendingDay', theme),                  // จำนวนงานที่ยังไม่เสร็จ
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _summaryCard(
                'OVERDUE (ALL)',                                             // งานเกินกำหนด (ทุกวันในระบบ)
                '$overdueAll',
                theme,
                color: const Color(0xFFEF4444),                            // ใช้สีแดงเน้น
              ),

              // ตรงนี้เคยมี Text แสดงวันเลือก แต่คอมเมนต์ออกแล้ว (เผื่ออยากใช้ทีหลัง)
              // const SizedBox(width: 8),
              // Expanded(
              //   child: Container(
              //     height: 48,
              //     alignment: Alignment.centerRight,
              //     child: Text(
              //       'Selected: ${DateFormat('dd MMM yyyy').format(selected)}',
              //       style: theme.textTheme.bodySmall,
              //     ),
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------- ปฏิทิน + แถบควบคุม ----------------
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [

                  // ========== แถบควบคุมเดือน/ปี/Today ==========
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(

                      // ignore: deprecated_member_use
                      color: theme.colorScheme.surface.withOpacity(.6), // พื้นหลังโปร่งขาว
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous month',                    // คำใบ้เมื่อ hover
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),

                        // ดรอปดาวน์เลือกเดือน
                        DropdownButton<int>(
                          value: _visibleMonth,                        // เดือนที่เลือกตอนนี้
                          underline: const SizedBox.shrink(),          // ไม่ต้องโชว์เส้นใต้
                          onChanged: (m) {
                            if (m == null) return;
                            setState(() {
                              _visibleMonth = m;                      // อัปเดตเดือนที่มองเห็น
                              _focusedDay = DateTime(
                                _visibleYear,
                                 _visibleMonth,
                                  1,                                 // โฟกัสวันแรกของเดือน        
                                );
                            });
                          },

                          items: months                             // สร้างตัวเลือกเดือนจากลิสต์ 1–12
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      DateFormat.MMMM().format(    // ชื่อเดือน (January, February, …)
                                        DateTime(2000, m)
                                        )
                                      ),
                                  ))
                              .toList(),
                        ),

                        const SizedBox(width: 8),
                        // ดรอปดาวน์เลือกปี
                        DropdownButton<int>(
                          value: _visibleYear,                     // ปีที่แสดงตอนนี้
                          underline: const SizedBox.shrink(),
                          onChanged: (y) {
                            if (y == null) return;
                            setState(() {
                              _visibleYear = y;                     // อัปเดตปีที่มองเห็น
                              _focusedDay = DateTime(
                                _visibleYear,
                                 _visibleMonth, 
                                 1
                                );                                  // โฟกัสวันแรกของเดือน/ปีใหม่
                            });
                          },      

                          items: years                              // สร้างตัวเลือกจากช่วงปี
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                   child: Text('$y')              // แสดงปีเป็นข้อความ
                                  )
                                )
                              .toList(),
                        ),

                        IconButton(
                          tooltip: 'Next month',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),

                        const Spacer(),                                         // ดันปุ่ม Today ไปชิดขวา
                        TextButton.icon(
                          onPressed: _goToday,                                  // กดแล้วกลับมาวันนี้
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text(''),                                // ไม่แสดงข้อความ (ใช้ไอคอนอย่างเดียว)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ========== ตัวปฏิทินจริง ==========
                  TableCalendar<dynamic>(
                    headerVisible: false,                                       
                    firstDay: DateTime(2000, 1, 1),                             // ไม่ใช้ header ของวิดเจ็ต (เราใช้ของเราเองด้านบน)
                    lastDay: DateTime(2100, 12, 31),                            // วันแรกที่เลื่อนได้
                    focusedDay: DateTime(                                       // เดือนที่กำลังโฟกัสอยู่
                      _visibleYear,
                       _visibleMonth, 
                       1
                    ),

                    // เช็คว่า day ที่จะวาดตรงกับวันที่เลือกหรือไม่
                    selectedDayPredicate: (day) =>
                        _selectedDay != null &&
                        day.year == _selectedDay!.year &&
                        day.month == _selectedDay!.month &&
                        day.day == _selectedDay!.day,

                    // เมื่อผู้ใช้จิ้มเลือกวันในปฏิทิน
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;               // เก็บวันที่เลือกใหม่
                        _focusedDay = focusedDay;                 // อัปเดตโฟกัส (สำหรับ TableCalendar)
                      });
                    },

                    // เมื่อเลื่อนเดือน (swipe หรือจากปฏิทินภายใน)
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;                 // อัปเดตวันที่โฟกัส
                        _visibleMonth = focusedDay.month;         // ซิงค์กับดรอปดาวน์เดือน
                        _visibleYear = focusedDay.year;           // ซิงค์กับดรอปดาวน์ปี
                      });
                    },

                    eventLoader: _eventsLoader,                  // บอกว่ามี event กี่ตัวในแต่ละวัน
                    calendarFormat: CalendarFormat.month,        // แสดงแบบทั้งเดือน
                    availableGestures:                           // เลื่อนปฏิทินแนวนอนได้
                    AvailableGestures.horizontalSwipe,
                    calendarStyle: CalendarStyle(

                      // สไตล์ของวัน "วันนี้"
                      todayDecoration: BoxDecoration(

                        // ignore: deprecated_member_use
                        color: const Color(0xFF4A90E2).withOpacity(.15), 
                        shape: BoxShape.circle,
                      ),

                      // สไตล์ของวัน "ที่ถูกเลือก"
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                      ),

                      // จุดแสดง event ใต้วันที่
                      markerDecoration: BoxDecoration(
                        color: const Color(0xFF50E3C2),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,                   // แสดงจุดสูงสุด 3 จุดต่อวัน
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekendStyle: TextStyle(              // เน้นวันเสาร์-อาทิตย์
                        fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),


          // ---------------- รายการงานของ "วันที่เลือก" ----------------
          Text(
            'Tasks on ${DateFormat('dd MMM yyyy').format(selected)}',                     // หัวข้อพร้อมวันที่
            style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700
          ),
          ),
          const SizedBox(height: 8),

          if (tasksOfDay.isNotEmpty)                                                    // ถ้าวันนี้มีงาน
            ...tasksOfDay.map(
              (t) => TaskCard(
                task: t,                                                                // งานแต่ละตัวส่งเข้า TaskCard
                onEdit: () async {
                  // ตรงนี้เว้นไว้ก่อน ถ้าต้องการ dialog แก้ไขเพิ่มในอนาคต
                },
                onDelete: () async {
                  // ลบผ่าน provider ตาม id ของงาน
                  await provider.delete(t.id);
                },
              ),
            )
          else                                                                         // ถ้าวันนี้ไม่มีงาน
            const Text('No tasks on this day.'),

          const SizedBox(height: 100),                                                // ช่องว่างเผื่อ bottom nav ไม่ทับ
        ],
      ),
    );
  }


  // วิดเจ็ตกล่องสรุปยอดด้านบน (ใช้ได้ทั้ง TOTAL / COMPLETED / PENDING / OVERDUE)
  Widget _summaryCard(
    String label,                                             // ข้อความหัว (TOTAL / COMPLETED / ...)
    String value,                                             // ตัวเลขที่จะแสดง
    ThemeData theme,                                          // ธีมหลัก (ใช้สีตัวอักษร/ขนาดฟอนต์)
    {Color? color}                                            // ถ้าส่งมาก็ใช้เป็นสีตัวอักษร (เช่น OVERDUE เป็นสีแดง)
    ) {

    final fg = color ?? theme.colorScheme.onSurface;          // สีตัวอักษร (default = onSurface)
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,                    // สีพื้นหลังการ์ด
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8, 
              color: Color(0x11000000),                      // เงาจาง ๆ ใต้การ์ด
              offset: Offset(0, 2)),
          ],
        ),

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,                      // จัดกึ่งกลางแนวตั้ง
          children: [
            Text(
              value,
               style: TextStyle(                                           // แสดงตัวเลขสรุป
                fontWeight: FontWeight.w800,
                 fontSize: 18, 
                 color: fg
                )
              ),

            const SizedBox(height: 2),
            Text(
              label,                                                     // แสดงชื่อหัว (TOTAL / OVERDUE / ...)
               style: theme.textTheme.labelSmall
               ?.copyWith(color: fg), 
               textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
