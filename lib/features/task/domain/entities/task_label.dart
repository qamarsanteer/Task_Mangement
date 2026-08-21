class TaskLabelOption {
  final String id;
  final int colorValue;

  const TaskLabelOption({required this.id, required this.colorValue});
}

class TaskLabels {
  TaskLabels._();

  static const List<TaskLabelOption> predefined = [
    TaskLabelOption(id: 'work', colorValue: 0xFF3F51B5),
    TaskLabelOption(id: 'personal', colorValue: 0xFF43A047),
    TaskLabelOption(id: 'study', colorValue: 0xFFFF9800),
    TaskLabelOption(id: 'health', colorValue: 0xFFE53935),
    TaskLabelOption(id: 'finance', colorValue: 0xFF00897B),
    TaskLabelOption(id: 'other', colorValue: 0xFF9E9E9E),
  ];

  static TaskLabelOption? byId(String? id) {
    if (id == null) return null;
    for (final label in predefined) {
      if (label.id == id) return label;
    }
    return null;
  }
}