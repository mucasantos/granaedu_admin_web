import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseHistory {
  final String id, userId, userName, userEmail, plan, price, platform;
  final String? purchaseId, userImageUrl;
  final DateTime purchaseAt, expireAt;

  PurchaseHistory({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.plan,
    required this.purchaseAt,
    required this.expireAt,
    this.purchaseId,
    required this.price,
    this.userImageUrl,
    required this.platform
  });

  factory PurchaseHistory.fromFirestore(DocumentSnapshot snapshot) {
    final d = snapshot.data() as Map<String, dynamic>;
    return PurchaseHistory(
      id: snapshot.id,
      userId: d['user_id'],
      userName: d['user_name'],
      plan: d['plan'],
      userEmail: d['user_email'],
      purchaseAt: (d['purchase_at'] as Timestamp).toDate().toLocal(),
      expireAt: (d['expire_at'] as Timestamp).toDate().toLocal(),
      price: d['price'],
      purchaseId: d['purchase_id'],
      userImageUrl: d['user_image_url'],
      platform: d['platform'] ?? 'Android',
    );
  }
}