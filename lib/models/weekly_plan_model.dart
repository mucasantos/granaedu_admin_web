class WeeklyPlanModel {
  final String id;
  final String userId;
  final DateTime weekStart;
  final String? level;
  final Map<String, dynamic>? focus;
  final String? logic;
  final bool createdByAi;
  final DateTime? createdAt;
  final Map<String, dynamic>? evaluation;

  WeeklyPlanModel({
    required this.id,
    required this.userId,
    required this.weekStart,
    this.level,
    this.focus,
    this.logic,
    this.createdByAi = true,
    this.createdAt,
    this.evaluation,
  });

  factory WeeklyPlanModel.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanModel(
      id: json['id'],
      userId: json['user_id'],
      weekStart: DateTime.parse(json['week_start']),
      level: json['level'],
      focus: json['focus'],
      logic: json['logic'],
      createdByAi: json['created_by_ai'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      evaluation: json['evaluation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start': weekStart.toIso8601String(),
      'level': level,
      'focus': focus,
      'logic': logic,
      'created_by_ai': createdByAi,
      'evaluation': evaluation,
    };
  }
}
