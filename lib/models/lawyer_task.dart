class LawyerTask {
  final String id;
  final String lawyerId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;

  LawyerTask({
    required this.id,
    required this.lawyerId,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
  });

  factory LawyerTask.fromMap(Map<String, dynamic> map) {
    return LawyerTask(
      id: map['id'],
      lawyerId: map['lawyer_id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      isCompleted: map['is_completed'] ?? false,
    );
  }
}
