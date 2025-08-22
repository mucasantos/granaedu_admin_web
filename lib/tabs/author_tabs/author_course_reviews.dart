import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/mixins/review_mixin.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/services/firebase_service.dart';

import '../../providers/user_data_provider.dart';

final authorCourseReviewsQueryprovider = StateProvider<Query>((ref) {
  final user = ref.read(userDataProvider);
  final query = FirebaseService.authorCourseReviewsQuery(user!.id);
  return query;
});

class AuthorCourseReviews extends ConsumerWidget with ReviewMixin, UserMixin{
  const AuthorCourseReviews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Student Reviews', buttons: [
            // sortButton(context, ref: ref),
          ]),
          buildReviews(context, ref: ref, isAuthorCourses: true, queryProvider: authorCourseReviewsQueryprovider),
        ],
      ),
    );
  }
}
