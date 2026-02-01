class DailyTaskModel {
  final String id;
  final String planId;
  final String userId;
  final int dayOfWeek;
  final String? skill;
  final Map<String, dynamic>? content;
  final bool completed;
  final DateTime? completedAt;

  DailyTaskModel({
    required this.id,
    required this.planId,
    required this.userId,
    required this.dayOfWeek,
    this.skill,
    this.content,
    this.completed = false,
    this.completedAt,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      id: json['id'],
      planId: json['plan_id'],
      userId: json['user_id'],
      dayOfWeek: json['day_of_week'],
      skill: json['skill'],
      content: json['content'],
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'skill': skill,
      'content': content,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
