import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms_admin/models/author.dart';

import 'course_meta.dart';

class Course {
  final String name, id, thumbnailUrl, priceStatus;
  String status;
  final DateTime createdAt;
  var updatedAt;
  List? tagIDs;
  String? videoUrl;
  String? categoryId;
  final Author? author;
  final int studentsCount;
  final double rating;
  final CourseMeta courseMeta;
  final int lessonsCount;
  bool? isFeatured;

  Course({
    required this.name,
    required this.id,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.createdAt,
    this.updatedAt,
    this.tagIDs,
    required this.categoryId,
    required this.status,
    required this.author,
    required this.studentsCount,
    required this.rating,
    required this.priceStatus,
    required this.courseMeta,
    required this.lessonsCount,
    this.isFeatured,
  });

  factory Course.fromFirestore(DocumentSnapshot snap) {
    final Map<String, dynamic> d = snap.data() as Map<String, dynamic>;

    final Timestamp? createdTs = d['created_at'] as Timestamp?;
    final dynamic ratingRaw = d['rating'];
    final double rating = ratingRaw == null ? 0.0 : (ratingRaw is num ? ratingRaw.toDouble() : double.tryParse(ratingRaw.toString()) ?? 0.0);
    final dynamic studentsRaw = d['students'];
    final int students = studentsRaw is int ? studentsRaw : int.tryParse(studentsRaw?.toString() ?? '') ?? 0;

    return Course(
      id: snap.id,
      name: (d['name'] as String?) ?? '',
      thumbnailUrl: (d['image_url'] as String?) ?? '',
      createdAt: createdTs != null ? createdTs.toDate() : DateTime.now(),
      updatedAt: d['updated_at'],
      videoUrl: d['video_url'] as String?,
      tagIDs: d['tag_ids'] is List ? d['tag_ids'] as List : [],
      categoryId: d['cat_id']?.toString(),
      status: (d['status'] as String?) ?? '',
      author: d['author'] != null ? Author.fromMap(d['author']) : null,
      priceStatus: (d['price_status'] as String?) ?? '',
      rating: rating,
      studentsCount: students,
      courseMeta: CourseMeta.fromMap((d['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{}),
      isFeatured: (d['featured'] as bool?) ?? false,
      lessonsCount: (d['lessons_count'] is int) ? d['lessons_count'] as int : int.tryParse(d['lessons_count']?.toString() ?? '') ?? 0,
    );
  }

  static Map<String, dynamic> getMap(Course d) {
    return {
      'name': d.name,
      'image_url': d.thumbnailUrl,
      'created_at': d.createdAt,
      'updated_at': d.updatedAt,
      'video_url': d.videoUrl,
      'status': d.status,
      'tag_ids': d.tagIDs,
      'cat_id': d.categoryId,
      'author': d.author != null ? Author.getMap(d.author!) : null,
      'price_status': d.priceStatus,
      'rating': d.rating,
      'students': d.studentsCount,
      'meta': CourseMeta.getMap(d.courseMeta),
      'lessons_count': d.lessonsCount,
    };
  }
}
