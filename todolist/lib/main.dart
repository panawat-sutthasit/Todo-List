import 'package:flutter/material.dart';
import 'package:todolist/todo_list_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // สร้าง base theme ก่อน เพื่ออ้าง colorScheme ได้

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TodoListPage(),
    );
  }
}
