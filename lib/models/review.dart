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
    Map d = snap.data() as Map<String, dynamic>;
    return Review(
      id: snap.id,
      courseId: d['course_id'],
      courseAuthorId: d['course_author_id'],
      courseTitle: d['course_title'],
      rating: d['rating'],
      review: d['review'],
      createdAt: (d['created_at'] as Timestamp).toDate(),
      reviewUser: ReviewUser.fromFirebase(d['user']),
    );
  }
}
