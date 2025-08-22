import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String name, id, thumbnailUrl;
  final int? orderIndex;
  final DateTime createdAt;

  Category({
    required this.name,
    required this.id,
    required this.thumbnailUrl,
    required this.createdAt,
    this.orderIndex,
  });

  factory Category.fromFirestore(DocumentSnapshot snap) {
    final Map<String, dynamic> d = snap.data() as Map<String, dynamic>;
    final Timestamp? ts = d['created_at'] as Timestamp?;
    return Category(
      id: snap.id,
      name: (d['name'] as String?) ?? '',
      thumbnailUrl: (d['image_url'] as String?) ?? '',
      createdAt: ts != null ? ts.toDate() : DateTime.now(),
      orderIndex: (d['index'] is int) ? d['index'] as int : 0,
    );
  }

  static Map<String, dynamic> getMap(Category d) {
    return {
      'name': d.name,
      'image_url': d.thumbnailUrl,
      'created_at': d.createdAt,
      'index': d.orderIndex
    };
  }
}