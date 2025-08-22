import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/mixins/course_mixin.dart';
import '../../forms/course_form.dart';
import '../../components/custom_buttons.dart';
import '../../components/dialogs.dart';
import '../../providers/user_data_provider.dart';

final authorCoursesQueryprovider = StateProvider.family<Query, String>((ref, authorId) {
  final query = FirebaseFirestore.instance.collection('courses').where('author.id', isEqualTo: authorId);
  return query;
});

class AuthorCourses extends ConsumerWidget with CourseMixin {
  const AuthorCourses({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'My Courses', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              text: 'Create Course',
              onPressed: () {
                CustomDialogs.openFullScreenDialog(
                  context,
                  widget: const CourseForm(
                    course: null,
                    isAuthorTab: true,
                  ),
                );
              },
            ),
          ]),
          buildCourses(context, ref: ref, isAuthorTab: true, queryProvider: authorCoursesQueryprovider(user!.id)),
        ],
      ),
    );
  }
}
