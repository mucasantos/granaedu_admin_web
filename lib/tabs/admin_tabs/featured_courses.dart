import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/mixins/course_mixin.dart';

final featuredCoursesQueryprovider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('courses').where('featured', isEqualTo: true);
  return query;
});

class FeaturedCourses extends ConsumerWidget with CourseMixin {
  const FeaturedCourses({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Featured Courses', buttons: []),
          buildCourses(context, ref: ref, isFeaturedPosts: true, queryProvider: featuredCoursesQueryprovider)
        ],
      ),
    );
  }
}
