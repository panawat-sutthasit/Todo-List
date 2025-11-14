import 'dart:convert';                                              // นำเข้า lib สำหรับแปลงวัตถุ <-> JSON (encode/decode)

/// ระดับความสำคัญของงาน (กำหนดเป็น enum ให้เลือกค่าได้จำกัดและชัดเจน)
enum TaskPriority { low, medium, high }

/// โมเดลข้อมูลของงานแต่ละรายการ (โครงสร้างข้อมูลหลักของแอป)
class Task {
  final String id;                                                  // รหัสเฉพาะของงาน (unique) ใช้ระบุ/ลบ/อัปเดตได้ถูกตัว
  String title;                                                     // ชื่องาน (แก้ไขได้ภายหลัง จึงไม่เป็น final)
  DateTime? due;                                                    // วันที่ครบกำหนด (อาจว่างได้ -> null)
  TaskPriority priority;                                            // ระดับความสำคัญของงาน (low/medium/high)
  bool isDone;                                                      // สถานะงานเสร็จหรือยัง (true = เสร็จแล้ว)

  // คอนสตรักเตอร์: กำหนดค่าเริ่มต้นและบังคับ field ที่จำเป็น
  Task({
    required this.id,                                               // ต้องมี id เสมอ                                 
    required this.title,                                            // ต้องมี title เสมอ
    this.due,                                                       // due ไม่บังคับ อาจเป็น null
    this.priority = TaskPriority.low,                               // ถ้าไม่ระบุ priority จะเป็น low
    this.isDone = false,                                            // งานใหม่เริ่มต้นเป็นยังไม่เสร็จ
  });


  // ignore: unintended_html_in_doc_comment
  /// แปลง Task เป็น Map<String, dynamic> เพื่อเตรียม serialize เป็น JSON
  /// - เก็บ due เป็นรูปแบบ ISO 8601 string (อ่าน/เขียนง่ายและมาตรฐาน)
  /// - priority เก็บเป็นชื่อ enum (เช่น "low", "medium", "high")
  Map<String, dynamic> toMap() => {
        'id': id,                                                   // เก็บ id
        'title': title,                                             // เก็บชื่อ
        'due': due?.toIso8601String(),                              // ถ้า due != null แปลงเป็น ISO string; ถ้า null เก็บ null
        'priority': priority.name,                                  // เก็บชื่อของ enum (เช่น "low")
        'isDone': isDone,                                           // เก็บสถานะงาน
      };



  /// สร้าง Task กลับจาก Map ที่อ่านมาจาก JSON
  /// - ป้องกันคีย์หาย/เป็น null ด้วยค่าเริ่มต้นที่เหมาะสม
  /// - แปลงสตริงวันที่กลับเป็น DateTime ด้วย DateTime.parse
  /// - แปลงสตริง priority กลับเป็น enum ด้วย firstWhere (ถ้าไม่ตรง คืนค่า low)
  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],                                                          // อ่าน id ตรง ๆ (คาดว่ามีแน่นอน)
        title: map['title'] ?? '',                                              // ถ้าไม่มี title ให้เป็นสตริงว่าง
        due: map['due'] != null                                                 // ถ้ามี due และไม่เป็น null
          ? DateTime.parse(map['due'])                                          // แปลงจาก ISO string -> DateTime
          : null,                                                               // ถ้าไม่มี due ให้เป็น null
        priority: TaskPriority.values.firstWhere(                               // หาค่า enum ที่ชื่อเท่ากับใน map
          (e) => e.name == map['priority'],                                     // เทียบชื่อ (เช่น "medium")
          orElse: () => TaskPriority.low,                                       // ถ้าไม่พบ/ชื่อเพี้ยน -> ให้ค่า low
        ),
        isDone: map['isDone'] ?? false,                                         // ถ้าไม่มี isDone -> false
      );


  /// เข้ารหัสลิสต์ของ Task ทั้งหมดเป็น JSON string
  /// ขั้นตอน: แปลงแต่ละ Task เป็น Map -> รวมเป็น List -> jsonEncode
  static String encodeList(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toMap()).toList());


  /// ถอดรหัส JSON string กลับมาเป็นลิสต์ของ Task
  /// ขั้นตอน: jsonDecode -> ได้ List แบบ dynamic -> map แต่ละตัวเป็น Task.fromMap -> toList()
  static List<Task> decodeList(String s) =>
      (jsonDecode(s) as List).map((e) => Task.fromMap(e)).toList();
}
