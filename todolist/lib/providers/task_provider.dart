import 'package:flutter/foundation.dart';                                     // ใช้ ChangeNotifier และ kDebugMode สำหรับ debug print
import 'package:shared_preferences/shared_preferences.dart';                  // ใช้บันทึก/โหลดข้อมูลแบบ key-value บนอุปกรณ์
import '../models/task.dart';                                                 // โมเดล Task (id/title/due/priority/isDone)

/// ตัวเลือกการกรองรายการงานในมุมมองต่าง ๆ
enum TaskFilter { all, active, completed, overdue }

/// ผู้ให้บริการสถานะ (State) หลักของแอป: เก็บรายการงาน, บริหารการกรอง/ค้นหา, บันทึก/โหลด, และแจ้งเตือน UI
class TaskProvider extends ChangeNotifier {
  static const _storeKey = 'tasks_v1';                                       // คีย์สำหรับเก็บข้อมูล JSON ใน SharedPreferences

  final List<Task> _tasks = [];                                              // ลิสต์เก็บงานทั้งหมด (แหล่งจริง)
  TaskFilter filter = TaskFilter.all;                                        // สถานะการกรองปัจจุบัน (ค่าเริ่มต้น: แสดงทั้งหมด)
  String search = '';                                                        // คำค้นหาปัจจุบัน (ไม่บังคับ)

  // ---------------------------
  // Utilities
  // ---------------------------

  DateTime _normalize(DateTime d) =>                                        // ฟังก์ชัน normalize ให้ DateTime เหลือแค่ ปี-เดือน-วัน (ตัดเวลา)
  DateTime(d.year, d.month, d.day);

    
  DateTime get _today => _normalize(DateTime.now());                       // วันที่วันนี้แบบ normalize (ใช้เปรียบเทียบ overdue)

  // ---------------------------
  // Derived views
  // ---------------------------

  /// มุมมองรายการงานสำหรับใช้แสดงผล (คำนวณจาก _tasks + filter + search + sort)
  List<Task> get tasks {
    Iterable<Task> list = _tasks;                                          // เริ่มจากงานทั้งหมด

    // 1) กรองตาม filter
    switch (filter) {
      case TaskFilter.active:                                             // งานที่ยังไม่เสร็จ
        list = list.where((t) => !t.isDone);
        break;
      case TaskFilter.completed:                                         // งานที่เสร็จแล้ว
        list = list.where((t) => t.isDone);
        break;
      case TaskFilter.overdue:                                          // งานที่เลยกำหนดและยังไม่เสร็จ
        list = list.where(
          (t) => !t.isDone && t.due != null && _normalize(t.due!).isBefore(_today),
        );
        break;
      case TaskFilter.all:                                             // ทั้งหมด (ไม่กรอง)
        break;
    }


    // 2) กรองตาม search (ไม่สนตัวพิมพ์เล็ก/ใหญ่)
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(q));
    }


    // 3) เรียงลำดับ: ตาม due (null ไปท้ายสุด) ถ้า due เท่ากันหรือทั้งคู่ null ให้เรียงตามชื่อ
    final sorted = list.toList()
      ..sort((a, b) {
        if (a.due == null && b.due == null) {                               // ทั้งคู่ไม่มี due -> เรียงตามชื่อ
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        if (a.due == null) return 1;                                       // a ไม่มี due -> ไปท้าย
        if (b.due == null) return -1;                                      // b ไม่มี due -> ไปท้าย
        return a.due!.compareTo(b.due!);                                   // ทั้งคู่มี due -> เทียบวันที่
      });
    return sorted;
  }


  /// คืนรายการงานที่กำหนด “ตรงวัน” ที่ส่งเข้ามา (เทียบแบบ normalize)
  List<Task> tasksOn(DateTime day) {
    final d0 = _normalize(day);                                           // Normalize วันที่เป้าหมาย
    return _tasks.where((t) {
      if (t.due == null) return false;                                    // งานที่ไม่มี due ไม่ถือว่า “อยู่ในวันนั้น”
      final dd = _normalize(t.due!);                                      // Normalize due ของงาน
      return dd == d0;                                                    // วันเดียวกัน = true
    }).toList();
  }


  /// ตัวเลขรวมงานทั้งหมด
  int get total => _tasks.length;

  /// ตัวเลขงานที่เสร็จแล้ว
  int get completed => _tasks.where((t) => t.isDone).length;

  /// ตัวเลขงานที่ยังไม่เสร็จ (pending = total - completed)
  int get pending => total - completed;


  // ---------------------------
  // Persistence
  // ---------------------------


  /// โหลดรายการงานจาก SharedPreferences (ถ้ามี)
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();                // ขอ instance ของ SharedPreferences
      final data = prefs.getString(_storeKey);                            // ดึงสตริง JSON ที่เคยบันทึกไว้
      if (data != null) {
        _tasks
          ..clear()                                                       // ล้างลิสต์เดิม
          ..addAll(Task.decodeList(data));                                // แปลง JSON -> List<Task> แล้วเพิ่มเข้าไป
        notifyListeners();                                                // แจ้ง UI ให้รีเฟรช
      }
    } catch (e) {                                                         // กันข้อผิดพลาด (เช่น JSON พัง)
      if (kDebugMode) {
        print('TaskProvider.load() error: $e');                           // print เฉพาะโหมด debug
      }
      // ถ้าถอดรหัสพัง ให้ข้ามไป (เริ่มรายการว่าง)
    }
  }


  /// บันทึกสถานะ _tasks ปัจจุบันลง SharedPreferences (serialize เป็น JSON)
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();                      // ขอ instance
    await prefs.setString(_storeKey, Task.encodeList(_tasks));                // แปลงลิสต์ -> JSON แล้วบันทึก
  }

  // ---------------------------
  // CRUD
  // ---------------------------

  /// เพิ่มงานใหม่ลงในลิสต์
  Future<void> add(Task t) async {
    _tasks.add(t);                                                           // เพิ่มเข้า _tasks
    await _persist();                                                        // บันทึกลงเครื่อง
    notifyListeners();                                                       // แจ้ง UI ให้รีเฟรช
  }


  /// อัปเดตงานเดิม (หาตาม id แล้วแทนที่)
  Future<void> update(Task t) async {
    final i = _tasks.indexWhere((e) => e.id == t.id);                       // หา index ของงานตาม id
    if (i != -1) {                                                          // ถ้าพบ
      _tasks[i] = t;                                                        // แทนที่ด้วยตัวใหม่
      await _persist();                                                     // บันทึกลงเครื่อง
      notifyListeners();                                                    // รีเฟรช UI
    }
  }


  /// สลับสถานะเสร็จ/ไม่เสร็จของงานตาม id
  Future<void> toggleDone(String id, bool v) async {
    final i = _tasks.indexWhere((e) => e.id == id);                         // หา index ของงานตาม id
    if (i != -1) {
      _tasks[i].isDone = v;                                                 // ตั้งค่า isDone ใหม่
      await _persist();                                                     // บันทึก
      notifyListeners();                                                    // รีเฟรช UI
    }
  }


  /// ลบงานตาม id
  Future<void> delete(String id) async {
    _tasks.removeWhere((e) => e.id == id);                                  // กรองทิ้ง
    await _persist();                                                       // บันทึก
    notifyListeners();                                                      // รีเฟรช UI
  }



  /// alias (ชื่อเมธอดทางลัด) ให้เข้ากับการเรียกใช้งานในบางหน้าจอ (เช่น DashboardPage)
  Future<void> removeById(String id) => delete(id);

  // ---------------------------
  // View state setters (แทนการเรียก notifyListeners() ตรง ๆ)
  // ---------------------------

  /// ตั้งค่า filter แล้วแจ้ง UI
  void setFilter(TaskFilter f) {
    filter = f;
    notifyListeners();
  }

  /// ตั้งค่า search แล้วแจ้ง UI
  void setSearch(String q) {
    search = q;
    notifyListeners();
  }

  // ---------------------------
  // Optional helpers
  // ---------------------------

  /// ลบทุกงานที่ทำเสร็จแล้ว (ใช้สำหรับปุ่ม “Clear completed”)
  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.isDone);                                  // ทิ้งตัวที่ isDone = true
    await _persist();                                                     // บันทึก
    notifyListeners();                                                    // รีเฟรช
  }


  /// ลบงานทั้งหมด (รีเซ็ต)
  Future<void> clearAll() async {
    _tasks.clear();                                                     // ล้างลิสต์
    await _persist();                                                   // บันทึก
    notifyListeners();                                                  // รีเฟรช
  }
}
