class UserProfileModel {
  final String id;
  final String firebaseUid;
  final String? email;
  final String? name;
  final String? level;
  final String? goal;
  final DateTime? createdAt;

  UserProfileModel({
    required this.id,
    required this.firebaseUid,
    this.email,
    this.name,
    this.level,
    this.goal,
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      email: json['email'],
      name: json['name'],
      level: json['level'],
      goal: json['goal'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'name': name,
      'level': level,
      'goal': goal,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
