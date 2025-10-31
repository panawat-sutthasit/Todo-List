import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

enum TaskFilter { all, active, completed, overdue }

class TaskProvider extends ChangeNotifier {
  static const _storeKey = 'tasks_v1';

  final List<Task> _tasks = [];
  TaskFilter filter = TaskFilter.all;
  String search = '';

  // ---------------------------
  // Utilities
  // ---------------------------
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get _today => _normalize(DateTime.now());

  // ---------------------------
  // Derived views
  // ---------------------------
  List<Task> get tasks {
    Iterable<Task> list = _tasks;

    // filter
    switch (filter) {
      case TaskFilter.active:
        list = list.where((t) => !t.isDone);
        break;
      case TaskFilter.completed:
        list = list.where((t) => t.isDone);
        break;
      case TaskFilter.overdue:
        list = list.where(
          (t) => !t.isDone && t.due != null && _normalize(t.due!).isBefore(_today),
        );
        break;
      case TaskFilter.all:
        break;
    }

    // search (case-insensitive)
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(q));
    }

    // sort: due (null last) แล้วค่อยตามชื่อ
    final sorted = list.toList()
      ..sort((a, b) {
        if (a.due == null && b.due == null) {
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        if (a.due == null) return 1;
        if (b.due == null) return -1;
        return a.due!.compareTo(b.due!);
      });
    return sorted;
  }

  List<Task> tasksOn(DateTime day) {
    final d0 = _normalize(day);
    return _tasks.where((t) {
      if (t.due == null) return false;
      final dd = _normalize(t.due!);
      return dd == d0;
    }).toList();
  }

  int get total => _tasks.length;
  int get completed => _tasks.where((t) => t.isDone).length;
  int get pending => total - completed;

  // ---------------------------
  // Persistence
  // ---------------------------
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storeKey);
      if (data != null) {
        _tasks
          ..clear()
          ..addAll(Task.decodeList(data));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('TaskProvider.load() error: $e');
      }
      // ถ้าถอดรหัสพัง ให้ข้ามไป (เริ่มรายการว่าง)
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, Task.encodeList(_tasks));
  }

  // ---------------------------
  // CRUD
  // ---------------------------
  Future<void> add(Task t) async {
    _tasks.add(t);
    await _persist();
    notifyListeners();
  }

  Future<void> update(Task t) async {
    final i = _tasks.indexWhere((e) => e.id == t.id);
    if (i != -1) {
      _tasks[i] = t;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id, bool v) async {
    final i = _tasks.indexWhere((e) => e.id == id);
    if (i != -1) {
      _tasks[i].isDone = v;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _tasks.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  // alias ให้ตรงกับที่ DashboardPage ใช้
  Future<void> removeById(String id) => delete(id);

  // ---------------------------
  // View state setters (แทนการเรียก notifyListeners() ตรง ๆ)
  // ---------------------------
  void setFilter(TaskFilter f) {
    filter = f;
    notifyListeners();
  }

  void setSearch(String q) {
    search = q;
    notifyListeners();
  }

  // ---------------------------
  // Optional helpers
  // ---------------------------
  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.isDone);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _tasks.clear();
    await _persist();
    notifyListeners();
  }
}
