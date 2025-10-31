import 'package:flutter/material.dart';

enum Priority {low, meduim, high}

class TodoItem {
  final String title;
  final DateTime? due;
  final Priority priority;
  final bool done;

  TodoItem({
    required this.title,
    this.due,
    required this.priority,
    this.done = false,
  });

  TodoItem copyWith({
    String? title,
    DateTime? due,
    Priority? priority,
    bool? done,
  }) {
    return TodoItem(
      title: title ?? this.title, 
      due: due ?? this.due,
      priority: priority ?? this.priority,
      done: done ?? this.done
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "due": due?.toIso8601String(),
      "priority": priority.name,
      "done": done
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json["title"] ?? "",
      due: json["due"] != null ? DateTime.parse(json["due"]) : null,
      priority: Priority.values.firstWhere(
        (p) => p.name == json["priority"],
        orElse: () => Priority.meduim,
      ),
      done: json["done"] ?? false
    );
  }
}

String priorityLabel(Priority p) {
  switch (p) {
    case Priority.low:
      return "Low";
    case Priority.meduim:
      return "Meduim";
    case Priority.high:
      return "High";
  }
}

Color priorityColor(Priority p, ColorScheme scheme) {
  switch (p) {
    case Priority.low:
      return scheme.tertiary;
    case Priority.meduim:
      return scheme.primary;
    case Priority.high:
      return scheme.error;
  }
}