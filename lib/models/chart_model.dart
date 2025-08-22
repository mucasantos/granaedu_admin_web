import 'package:cloud_firestore/cloud_firestore.dart';

class ChartModel {
  final DateTime timestamp;
  final int count;

  ChartModel({
    required this.timestamp,
    required this.count,
  });

  factory ChartModel.fromFirestore(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>;
    return ChartModel(
      timestamp: (d['timestamp'] as Timestamp).toDate().toLocal(),
      count: d['count'],
    );
  }
}
