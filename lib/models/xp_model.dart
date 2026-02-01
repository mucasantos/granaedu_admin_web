class XpWalletModel {
  final String userId;
  final int xpBalance;
  final int streakDays;
  final DateTime? lastCheckin;

  XpWalletModel({
    required this.userId,
    this.xpBalance = 0,
    this.streakDays = 0,
    this.lastCheckin,
  });

  factory XpWalletModel.fromJson(Map<String, dynamic> json) {
    return XpWalletModel(
      userId: json['user_id'],
      xpBalance: json['xp_balance'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      lastCheckin: json['last_checkin'] != null ? DateTime.parse(json['last_checkin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'xp_balance': xpBalance,
      'streak_days': streakDays,
      'last_checkin': lastCheckin?.toIso8601String(),
    };
  }
}

class XpTransactionModel {
  final String id;
  final String userId;
  final int amount;
  final String? reason;
  final DateTime? createdAt;

  XpTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.reason,
    this.createdAt,
  });

  factory XpTransactionModel.fromJson(Map<String, dynamic> json) {
    return XpTransactionModel(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'],
      reason: json['reason'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'reason': reason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
