import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/add_task_page.dart';
import 'pages/dashboard_page.dart';
import 'providers/task_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4A90E2);     // Primary (ฟ้า)
    const secondary = Color(0xFF50E3C2);   // Secondary (มิ้นต์)
    const error = Color(0xFFEF4444);       // Error (แดง)
    const bg = Color(0xFFF9FAFB);          // Background
    const text = Color(0xFF1E293B);        // Text

    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..load(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'To-Do',
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
            bodyMedium: TextStyle(color: text),
          ),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

/// เปลือกแอพ + Bottom Navigation (Add Task ซ้าย / Dashboard ขวา)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // เปิดที่ Dashboard ก่อน ตามโปรโตไทป์
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final pages = const [AddTaskPage(), DashboardPage()];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// แถบนำทางด้านล่าง (ติดล่าง, สี primary, กดได้ทั้งสองปุ่ม)
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF4A90E2),
        boxShadow: [BoxShadow(blurRadius: 10, offset: Offset(0, -2), color: Color(0x22000000))],
      ),
      child: Row(
        children: [
          _item(icon: Icons.add, label: 'ADD TASK', active: index == 0, onTap: () => onTap(0)),
          _item(icon: Icons.grid_view_rounded, label: 'DASHBOARD', active: index == 1, onTap: () => onTap(1)),
        ],
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
          opacity: active ? 1 : 0.75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
