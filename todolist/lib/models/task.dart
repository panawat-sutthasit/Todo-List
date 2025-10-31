import 'dart:convert';

/// ระดับความสำคัญของงาน
enum TaskPriority { low, medium, high }

/// โมเดลข้อมูลของงานแต่ละรายการ
class Task {
  final String id;             // รหัสเฉพาะของงาน
  String title;                // ชื่อของงาน
  DateTime? due;               // วันที่ครบกำหนด (อาจไม่มี)
  TaskPriority priority;       // ความสำคัญของงาน
  bool isDone;                 // สถานะว่างานนี้เสร็จหรือยัง

  Task({
    required this.id,
    required this.title,
    this.due,
    this.priority = TaskPriority.low,
    this.isDone = false,
  });

  /// แปลง Task ให้เป็น Map (สำหรับบันทึกลง SharedPreferences)
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'due': due?.toIso8601String(),
        'priority': priority.name,
        'isDone': isDone,
      };

  /// แปลง Map กลับเป็น Task (ใช้ตอนโหลดข้อมูลกลับมา)
  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'] ?? '',
        due: map['due'] != null ? DateTime.parse(map['due']) : null,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == map['priority'],
          orElse: () => TaskPriority.low,
        ),
        isDone: map['isDone'] ?? false,
      );

  /// เข้ารหัสรายการ Task ทั้งหมดเป็น JSON string
  static String encodeList(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toMap()).toList());

  /// ถอดรหัส JSON string กลับมาเป็นรายการ Task
  static List<Task> decodeList(String s) =>
      (jsonDecode(s) as List).map((e) => Task.fromMap(e)).toList();
}
