import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/add_task_page.dart';
import 'pages/dashboard_page.dart';
import 'providers/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // สีหลักตามดีไซน์
    const primary = Color(0xFF4A90E2);   // Primary (ฟ้า)
    const secondary = Color(0xFF50E3C2); // Secondary (มิ้นต์)
    const error = Color(0xFFEF4444);     // Error (แดง)
    const bg = Color(0xFFF9FAFB);        // Background
    const text = Color(0xFF1E293B);      // Text

    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..load(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'To-Do-List App',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            secondary: secondary,
            error: error,
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: text, fontSize: 14),
          ),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: const StadiumBorder(
              side: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        // เริ่มที่ Splash ก่อน แล้วค่อยเข้า AppShell
        home: const SplashScreen(),
      ),
    );
  }
}

/// Splash ก่อนเข้าแอพ ~2.5 วิ
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, size: 96, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'To-Do-List App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// โครงหลัก + Bottom Navigation (ซ้าย: Add Task / ขวา: Dashboard)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// เปิดหน้า ADD TASK ก่อนเสมอ
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // ใช้ IndexedStack เพื่อคงสภาพหน้าเวลาสลับแท็บ
    final pages = const <Widget>[
      AddTaskPage(),
      DashboardPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// แถบนำทางล่างแบบคัสตอม (ตรงตามดีไซน์)
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFF4A90E2),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, -2),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(
              icon: Icons.add,
              label: 'ADD TASK',
              active: index == 0,
              onTap: () => onTap(0),
            ),
            _item(
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

  Expanded _item({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: active ? 1 : 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 2),
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
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
