import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id, title, description, topic;
  final DateTime sentAt;

  NotificationModel({required this.id, required this.title, required this.description, required this.topic, required this.sentAt});

  factory NotificationModel.fromFirestore(DocumentSnapshot snapshot) {
    final Map<String, dynamic> d = snapshot.data() as Map<String, dynamic>;
    return NotificationModel(
      id: snapshot.id,
      title: d['title'],
      description: d['description'],
      topic: d['topic'],
      sentAt: (d['sent_at'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> getMap(NotificationModel d) {
    return {
      'title': d.title,
      'description': d.description,
      'topic': d.topic,
      'sent_at': d.sentAt,
    };
  }
}
