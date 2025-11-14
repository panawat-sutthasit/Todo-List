import 'dart:async';                                              // ใช้ Timer สำหรับหน่วงเวลาใน Splash
import 'package:flutter/material.dart';                           // แพ็กเกจ UI หลักของ Flutter
import 'package:provider/provider.dart';                          // สำหรับ State Management แบบ Provider

import 'pages/add_task_page.dart';                                // หน้าฟอร์มเพิ่มงาน
import 'pages/dashboard_page.dart';                               // หน้าดาชบอร์ด/สรุปงาน + ปฏิทิน
import 'providers/task_provider.dart';                            // ตัวจัดการข้อมูลงาน (โหลด/บันทึก/แก้ไข/ลบ)

void main() async {                                               // เตรียม binding ของ Flutter (ใช้เมื่อมี async ก่อน runApp)
  WidgetsFlutterBinding.ensureInitialized();                      // เริ่มรันแอปหลัก
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {                           // คอนสตรักเตอร์ของ StatelessWidget
  const ToDoApp({super.key});                                     

  @override
  Widget build(BuildContext context) {
    // กำหนดค่าสีหลักที่จะใช้ในธีมของแอป
    const primary = Color(0xFF4A90E2);                          // Primary ฟ้า: สีหลัก
    const secondary = Color(0xFF50E3C2);                        // Secondary มิ้นต์: สีรอง
    const error = Color(0xFFEF4444);                            // Error แดง: ข้อผิดพลาด
    const bg = Color(0xFFF9FAFB);                               // Background สีพื้นหลังทั่วไป
    const text = Color(0xFF1E293B);                             // Text สีตัวอักษรหลัก

    return ChangeNotifierProvider(                                // ให้ทั้งแอปเข้าถึง TaskProvider ตัวเดียวกัน
      create: (_) => TaskProvider()..load(),                      // สร้าง TaskProvider แล้วสั่งโหลดข้อมูลจาก storage
      child: MaterialApp(                                         // โครงแอประดับบนสุด
        debugShowCheckedModeBanner: false,                        // ซ่อนป้าย DEBUG
        title: 'To-Do-List App',                                  // ชื่อแอป (มีผลกับ task switcher บางแพลตฟอร์ม)
        theme: ThemeData(                                         // ธีมหลักของ Material 3
          useMaterial3: true,                                     // เปิดใช้ Material You (M3)
          scaffoldBackgroundColor: bg,                          // สีพื้นหลังของหน้าทั่วไป
          colorScheme: ColorScheme.fromSeed(                      // ชุดสีหลักของแอป
            seedColor: primary,                                 // ใช้ primary เป็น seed
            primary: primary,
            secondary: secondary,
            error: error,
            brightness: Brightness.light,                         // ธีมสว่าง
          ),
          textTheme: const TextTheme(                             // ปรับสไตล์ตัวอักษรค่าเริ่มต้นบางส่วน
            bodyMedium: TextStyle(color: text, fontSize: 14),
          ),
          inputDecorationTheme: InputDecorationTheme(             // สไตล์ TextField ทั้งแอป
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(               // สไตล์ปุ่มแบบ FilledButton
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          chipTheme: ChipThemeData(                              // สไตล์ชิป (แท็บกรอง)
            shape: const StadiumBorder(
              side: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        // เมื่อเปิดแอป ให้แสดง SplashScreen ก่อน แล้วค่อยไปหน้าโครงหลัก AppShell
        home: const SplashScreen(),
      ),
    );
  }
}

/// หน้าสแปลช: แสดงโลโก้/ชื่อแอปประมาณ ~2.5 วินาที แล้วนำทางเข้าหน้า AppShell
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();                                           // เรียกของเดิมก่อน
    Timer(const Duration(milliseconds: 2500), () {               // ตั้งเวลา 2.5 วิ
      if (!mounted) return;                                      // ถ้าหน้าถูกถอดแล้ว ไม่ทำต่อ
      Navigator.of(context).pushReplacement(                     // แทนที่ Splash ด้วยหน้า AppShell
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;                // ดึงชุดสีของธีมมาใช้
    return Scaffold(                                             
      backgroundColor: scheme.primary,                           // พื้นหลังใช้สีหลัก
      body: Center(                                              // จัดกึ่งกลางแนวตั้ง/แนวนอน
        child: Column(
          mainAxisSize: MainAxisSize.min,                        // ใช้พื้นที่เท่าที่จำเป็น
          children: [
            const Icon(Icons.task_alt, size: 96, color: Colors.white),    // ไอคอนใหญ่
            const SizedBox(height: 16),
            const Text(                                                     // ชื่อแอป
              'To-Do-List App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(                                                       // แถบโหลด (ความกว้าง 140)
              width: 140,
              child: LinearProgressIndicator(
                color: Colors.white,                                     // สีแท่งโหลด
                backgroundColor: Colors.white24,                         // สีพื้นแท่งโหลด (จาง)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// โครงหลักของแอป + Bottom Navigation (ซ้าย: Add Task / ขวา: Dashboard)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// เปิดหน้า ADD TASK ก่อนเสมอ
  int _index = 0;                                                           // แท็บที่เปิดอยู่ (เริ่มที่ Add Task)                                                          

  @override
  Widget build(BuildContext context) {
    // ใช้ IndexedStack เพื่อคง state ของแต่ละหน้าไว้เวลาสลับแท็บ
    final pages = const <Widget>[
      AddTaskPage(),                                                       // หน้าเพิ่มงาน
      DashboardPage(),                                                     // หน้าดาชบอร์ด
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),                  // แสดงหน้าตาม index ปัจจุบัน
      bottomNavigationBar: _BottomNav(                                     // แถบนำทางด้านล่าง
        index: _index,
        onTap: (i) => setState(() => _index = i),                          // เปลี่ยนแท็บเมื่อกด
      ),
    );
  }
}

/// แถบนำทางล่าง (ปรับหน้าตาเองให้เข้ากับดีไซน์)
class _BottomNav extends StatelessWidget {
  final int index;                                                        // แท็บที่เลือกอยู่
  final ValueChanged<int> onTap;                                          // callback เมื่อกดแท็บ
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(                                                     // กันชนส่วนโค้ง/ขอบจอ
      top: false,                                                        // ไม่ต้องกันด้านบน (กันเฉพาะล่าง)
      child: Container(
        height: 72,                                                     // ความสูงแถบล่าง
        decoration: const BoxDecoration(
          color: Color(0xFF4A90E2),                                   // สีพื้นหลังแถบ
          boxShadow: [                                                  // เงาด้านบนเล็กน้อย
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, -2),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(                                                     // ปุ่มซ้าย: Add Task
              icon: Icons.add,
              label: 'ADD TASK',
              active: index == 0,                                      // ไฮไลต์ถ้าอยู่แท็บนี้
              onTap: () => onTap(0),
            ),
            _item(                                                     // ปุ่มขวา: Dashboard
              icon: Icons.grid_view_rounded,
              label: 'DASHBOARD',
              active: index == 1,
              onTap: () => onTap(1),
            ),
          ],
        ),
      ),
    );
  }

// วิดเจ็ตย่อยของปุ่มแต่ละอันในแถบนำทาง
  Expanded _item({
    required IconData icon,                                       // ไอคอน
    required String label,                                        // ข้อความใต้ไอคอน
    required bool active,                                         // สถานะถูกเลือกหรือไม่
    required VoidCallback onTap,                                  // เมื่อกด
  }) {
    return Expanded(
      child: InkWell(                                             // ทำให้กดได้ + แอนิเมชันระลอก
        onTap: onTap,
        child: Opacity(                                           // จางลงเล็กน้อยถ้าไม่ใช่แท็บที่เลือก
          opacity: active ? 1 : 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,          // จัดกลางแนวตั้ง
            children: [
              const SizedBox(height: 2),                          // ระยะห่างบนเล็กน้อย
              Icon(icon, color: Colors.white),                  // แสดงไอคอนสีขาว
              const SizedBox(height: 4),
              Text(                                               // ป้ายชื่อปุ่ม
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





