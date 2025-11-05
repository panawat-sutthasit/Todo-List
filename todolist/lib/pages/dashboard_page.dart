import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
// ignore: unused_import
import '../models/task.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ค่าเดือน/ปี สำหรับดรอปดาวน์
  late int _visibleMonth;
  late int _visibleYear;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _visibleMonth = _focusedDay.month;
    _visibleYear = _focusedDay.year;
  }

  // เลื่อนเดือน (+/-) ข้ามปีได้
  void _changeMonth(int delta) {
    final d = DateTime(_visibleYear, _visibleMonth + delta, 1);
    setState(() {
      _focusedDay = d;
      _visibleMonth = d.month;
      _visibleYear = d.year;
    });
  }

  // กระโดดมาวันนี้
  void _goToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _focusedDay = DateTime(today.year, today.month, 1);
      _visibleMonth = today.month;
      _visibleYear = today.year;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    // สร้างรายการเดือน/ปีสำหรับดรอปดาวน์
    final int startYear = DateTime.now().year - 5;
    final int endYear = DateTime.now().year + 5;
    final months = List.generate(12, (i) => i + 1);
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    // ====== คำนวณสรุป "เฉพาะวัน" ที่เลือก ======
    final selected = _selectedDay ?? DateTime.now();
    final tasksOfDay = provider.tasksOn(selected);
    final totalDay = tasksOfDay.length;
    final completedDay = tasksOfDay.where((t) => t.isDone).length;
    final pendingDay = totalDay - completedDay;

    // ====== Overdue (ทั้งระบบ) ======
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final overdueAll = provider.tasks
        .where((t) => !t.isDone && t.due != null && t.due!.isBefore(todayOnly))
        .length;

    // event markers บนปฏิทิน
    // ignore: no_leading_underscores_for_local_identifiers
    List<dynamic> _eventsLoader(DateTime day) => provider.tasksOn(day);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'My Tasks Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary (อิง "วัน" ที่เลือก)
          Row(
            children: [
              _summaryCard('TOTAL (SELECTED)', '$totalDay', theme),
              const SizedBox(width: 8),
              _summaryCard('COMPLETED', '$completedDay', theme),
              const SizedBox(width: 8),
              _summaryCard('PENDING', '$pendingDay', theme),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _summaryCard(
                'OVERDUE (ALL)',
                '$overdueAll',
                theme,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 48,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Selected: ${DateFormat('dd MMM yyyy').format(selected)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ปฏิทิน + แถบควบคุม
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // แถบควบคุมเดือน/ปี/Today
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(.6), // ignore: deprecated_member_use
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous month',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        DropdownButton<int>(
                          value: _visibleMonth,
                          underline: const SizedBox.shrink(),
                          onChanged: (m) {
                            if (m == null) return;
                            setState(() {
                              _visibleMonth = m;
                              _focusedDay = DateTime(_visibleYear, _visibleMonth, 1);
                            });
                          },
                          items: months
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(DateFormat.MMMM().format(DateTime(2000, m))),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _visibleYear,
                          underline: const SizedBox.shrink(),
                          onChanged: (y) {
                            if (y == null) return;
                            setState(() {
                              _visibleYear = y;
                              _focusedDay = DateTime(_visibleYear, _visibleMonth, 1);
                            });
                          },
                          items: years
                              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                              .toList(),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _goToday,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Today'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  TableCalendar<dynamic>(
                    headerVisible: false,
                    firstDay: DateTime(2000, 1, 1),
                    lastDay: DateTime(2100, 12, 31),
                    focusedDay: DateTime(_visibleYear, _visibleMonth, 1),
                    selectedDayPredicate: (day) =>
                        _selectedDay != null &&
                        day.year == _selectedDay!.year &&
                        day.month == _selectedDay!.month &&
                        day.day == _selectedDay!.day,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _visibleMonth = focusedDay.month;
                        _visibleYear = focusedDay.year;
                      });
                    },
                    eventLoader: _eventsLoader,
                    calendarFormat: CalendarFormat.month,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(.15), // ignore: deprecated_member_use
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: const Color(0xFF50E3C2),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekendStyle: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // งานของ "วันที่เลือก"
          Text(
            'Tasks on ${DateFormat('dd MMM yyyy').format(selected)}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          if (tasksOfDay.isNotEmpty)
            ...tasksOfDay.map(
              (t) => TaskCard(
                task: t,
                onEdit: () async {
                  // สามารถเปิด dialog แก้ไขที่หน้า AddTask ก็ได้หากต้องการ
                },
                onDelete: () async {
                  // เรียกเมธอดลบใน provider (ตั้งชื่อตามโปรเจกต์ของฟูกิ)
                  await provider.delete(t.id);
                },
              ),
            )
          else
            const Text('No tasks on this day.'),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, ThemeData theme, {Color? color}) {
    final fg = color ?? theme.colorScheme.onSurface;
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(blurRadius: 8, color: Color(0x11000000), offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: fg)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
