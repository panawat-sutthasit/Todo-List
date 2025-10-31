import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/models/todo_item.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {

  final _formkey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();

  DateTime? _dueDate;
  Priority _priority = Priority.meduim;

  int? _editingIndex;

  final List<TodoItem> _items = [];

  Future<void> _saveItemsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((item) => item.toJson()).toList();
    final jsonStr = jsonEncode(data);
    debugPrint("Saving tools: $jsonStr");
    await prefs.setString('todos', jsonStr);
    debugPrint("Saved!");
    
  }

  Future<void> _loadItemsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('todos');
    if (raw == null) return;

    final List decoded = jsonDecode(raw);
    setState(() {
      _items.clear();
      _items.addAll(decoded.map((m) => TodoItem.fromJson(m as Map<String, dynamic>)));
    });
  }

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    _dueDate = DateTime(today.year, today.month, today.day);

    _dueDateCtrl.text = DateFormat('dd/MM/yy').format(_dueDate!);

    _loadItemsFromStorage();
  }

  @override
  void dispose() { 
    // TODO: implement dispose
    _titleCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context, 
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1), 
      lastDate: DateTime(now.year+3),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง'
    );
    if (result != null) {
      setState(() {
        _dueDate = DateTime(result.year, result.month, result.day);
        _dueDateCtrl.text = DateFormat('dd/MM/yy').format(_dueDate!);
      });
    }
  }


  InputDecoration _input(String label, {String? hint, String? helper, Widget? prefixIcon, Widget? suffixIcon}) {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant, width: 1.4)
    );

    return InputDecoration(
      // labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: border,
      enabledBorder: border.copyWith(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
      ),
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
    );
  }

  void _resetForm() {
    final today = DateTime.now();

    final resetDate = DateTime(today.year, today.month, today.day);
        
    _titleCtrl.clear();
    _dueDate = resetDate;
    _dueDateCtrl.text = DateFormat('dd/MM/yy').format(resetDate);
    _priority = Priority.meduim;
    _editingIndex = null;
  }

  void _handleSubmit() {
    if (!(_formkey.currentState?.validate() ?? false)) return;

    final itemData = TodoItem(
      title: _titleCtrl.text.trim(), 
      due: _dueDate,
      priority: _priority,
      done: _editingIndex == null
       ? false
       : _items[_editingIndex!].done,
    );
        
    setState(() {
      if (_editingIndex == null) {
        _items.add(itemData);
      } else {
        _items[_editingIndex!] = itemData;
      }
    });

    _saveItemsToStorage();

    _resetForm();
  }

  void _startEdit(int index) {
    final target = _items[index];

    setState(() {
      _editingIndex = index;
      _titleCtrl.text = target.title;
      _dueDate = target.due;

      if (target.due != null) {
        _dueDateCtrl.text = DateFormat('dd/MM/yy').format(target.due!);
      } else {
        _dueDateCtrl.text = '';
      }

      _priority = target.priority;
    });
  }

  @override
  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;

    final isEditing = _editingIndex != null;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text("My Tasks", style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600
        ),),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 720,
                        // minHeight: constraints.maxHeight - 40
                      ),
                      child: Card(
                        elevation: 2,
                        color: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: scheme.outlineVariant.withOpacity(0.4),
                            width: 1,
                          )
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formkey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _titleCtrl,
                                      maxLength: 40,
                                      textInputAction: TextInputAction.next,
                                      decoration: _input(
                                        'ชื่องาน',
                                        hint: 'What needs to be done?',
                                        helper: 'อย่างน้อย 3 ตัวอักษร'
                                        // prefixIcon: const Icon(Icons.edit_outlined)
                                      ),
                                      validator: (v) {
                                        final t = v?.trim() ?? '';
                                        if (t.isEmpty) return 'กรุณากรอกชื่องาน';
                                        if (t.length < 3) return 'ชื่องานควรยาวเกิน 3 ตัวอักษร';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16,),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _pickDate,
                                            child: AbsorbPointer(
                                              child: TextField(
                                                controller: _dueDateCtrl,
                                                readOnly: true,
                                                decoration: _input(
                                                  "",
                                                  // prefixIcon: const Icon(Icons.event_outlined),
                                                  suffixIcon: IconButton(
                                                    onPressed: _pickDate,
                                                    icon: const Icon(Icons.calendar_today_outlined),
                                                    tooltip: "เลือกวันที่",
                                                  )
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12,),
                                        Expanded(
                                          child: DropdownButtonFormField<Priority>(
                                            value: _priority,
                                            decoration: _input(
                                              '',
                                            ),
                                            icon: const Icon(Icons.arrow_drop_down_rounded),
                                            // style: const TextStyle(color: Colors.red),
                                            items: Priority.values.map((p) {
                                              return DropdownMenuItem(
                                                value: p,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.circle,
                                                      size: 10,
                                                      color: priorityColor(p, scheme),
                                                    ),
                                                    const SizedBox(width: 8,),
                                                    Text(priorityLabel(p))
                                                  ],
                                                )
                                              );
                                            }).toList(),
                                            onChanged: (p) {
                                              if (p != null) {
                                                setState(() {
                                                  _priority = p;
                                                });
                                              }
                                            },
                                          )
                                        ),
                                        SizedBox(width: 12,),
                                      ],
                                    ),
                                    SizedBox(height: 12,),
                                    
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: scheme.primary,
                                          foregroundColor: scheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600
                                          )
                                        ),
                                        onPressed: () {
                                          _handleSubmit();
                                        },
                                        icon: Icon(isEditing ? Icons.save : Icons.add_task_rounded),
                                        label: Text(isEditing ? "Save Change" : "Add Task"),
                                      ), 
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24,),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final dueText = item.due != null
                        ? DateFormat('dd MMM yyyy').format(item.due!)
                        : "No due date";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outlineVariant.withOpacity(0.4),
                            width: 1,
                          ),
                          color: scheme.surfaceContainerLowest
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _items[index] = TodoItem(
                                    title: item.title,
                                    due: item.due,
                                    priority: item.priority,
                                    done: !item.done
                                  );
                                });

                                _saveItemsToStorage();
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: 2
                                  ),
                                  color: item.done ? scheme.primary.withOpacity(0.1) : Colors.transparent
                                ),
                                child: item.done 
                                  ? Icon(Icons.check, size: 18, color: scheme.primary)
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 12,),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(width: 6,),
                                      Expanded(
                                        child: Text(
                                          item.title, 
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600, 
                                            fontSize: 20, 
                                            color: scheme.onSurface,
                                            decoration: item.done
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6,),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: priorityColor(item.priority, scheme).withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(50)
                                        ),
                                        child: Text(priorityLabel(item.priority), style: TextStyle(color: priorityColor(item.priority, scheme), fontSize: 12, fontWeight: FontWeight.w500),)
                                      ),
                                      SizedBox(width: 6,),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: scheme.onSurfaceVariant.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(50)
                                        ),
                                        child: Text(dueText, style: TextStyle(color: scheme.surfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),)
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton.outlined(
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    side: BorderSide(
                                      color: Colors.yellow,
                                      width: 1
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.circular(12)
                                    ),
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.yellow.shade600
                                  ),
                                  onPressed: () {
                                    _startEdit(index);
                                  }, 
                                  icon: const Icon(Icons.edit, size: 20,)
                                ),
                                // SizedBox(width: ,),
                                IconButton.outlined(
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    side: BorderSide(
                                      color: Colors.yellow,
                                      width: 1
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.circular(12)
                                    ),
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red.shade600
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_editingIndex == index) {
                                        _resetForm();
                                      }
                                      _items.removeAt(index);
                                    });

                                    _saveItemsToStorage();
                                  }, 
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 20,)
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                )
              ),
            );
          }
        )
      ),
    );
  }
}