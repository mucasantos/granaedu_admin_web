import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms_admin/models/question.dart';

class Lesson {
  final String id;
  final String name;
  final int order;
  final String? videoUrl;
  final String contentType;
  final String? description;
  final List<Question>? questions;

  Lesson({
    required this.id,
    required this.name,
    required this.order,
    required this.contentType,
    this.videoUrl,
    this.description,
    this.questions,
  });

  factory Lesson.fromFiresore(DocumentSnapshot snap) {
    Map d = snap.data() as Map<String, dynamic>;
    return Lesson(
      id: snap.id,
      name: d['name'],
      order: d['order'],
      videoUrl: d['video_url'],
      contentType: d['content_type'],
      description: d['description'],
      questions: d['quiz'] == null ? [] : List<Question>.from(d['quiz'].map((x) => Question.fromMap(x))),
    );
  }

  static Map<String, dynamic> getMap(Lesson d) {
    return {
      'name': d.name,
      'order': d.order,
      'video_url': d.videoUrl,
      'content_type': d.contentType,
      'description': d.description,
      'quiz': d.questions?.map((e) => Question.getMap(e)).toList(),
    };
  }
}
