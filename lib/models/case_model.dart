class CaseModel {
  final String id;
  final String clientId;
  final String lawyerId;
  final String title;
  final String? description;
  final String status;
  final List<TimelineItem> timeline;
  final DateTime createdAt;

  CaseModel({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    required this.title,
    this.description,
    this.status = 'ongoing',
    this.timeline = const [],
    required this.createdAt,
  });

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    return CaseModel(
      id: map['id'],
      clientId: map['client_id'],
      lawyerId: map['lawyer_id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      timeline: (map['timeline'] as List? ?? [])
          .map((item) => TimelineItem.fromMap(item))
          .toList(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class TimelineItem {
  final String title;
  final String description;
  final DateTime date;

  TimelineItem({
    required this.title,
    required this.description,
    required this.date,
  });

  factory TimelineItem.fromMap(Map<String, dynamic> map) {
    return TimelineItem(
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
