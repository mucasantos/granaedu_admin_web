import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms_admin/models/review_user.dart';

class Review {
  final String id, courseId, courseAuthorId, courseTitle;
  final double rating;
  String? review;
  final ReviewUser reviewUser;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.courseId,
    required this.courseAuthorId,
    required this.courseTitle,
    required this.rating,
    required this.reviewUser,
    required this.createdAt,
    this.review,
  });

  factory Review.fromFirebase(DocumentSnapshot snap) {
    final Map<String, dynamic> d = snap.data() as Map<String, dynamic>;

    final dynamic ratingRaw = d['rating'];
    final double rating = ratingRaw == null
        ? 0.0
        : (ratingRaw is num
            ? ratingRaw.toDouble()
            : double.tryParse(ratingRaw.toString()) ?? 0.0);

    final Timestamp? ts = d['created_at'] as Timestamp?;

    final Map<String, dynamic> userMap =
        (d['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    return Review(
      id: snap.id,
      courseId: (d['course_id']?.toString()) ?? '',
      courseAuthorId: (d['course_author_id']?.toString()) ?? '',
      courseTitle: (d['course_title'] as String?) ?? '',
      rating: rating,
      review: (d['review'] as String?) ?? '',
      createdAt: ts != null ? ts.toDate() : DateTime.now(),
      reviewUser: ReviewUser.fromFirebase(userMap),
    );
  }
}
