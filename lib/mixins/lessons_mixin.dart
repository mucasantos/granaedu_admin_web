import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/forms/lesson_form.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/lesson.dart';
import 'package:lms_admin/services/app_service.dart';
import 'package:lms_admin/utils/article_preview.dart';
import 'package:lms_admin/utils/quiz_preview.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';

class LessonsMixin {
  Widget buildLessons({
    required String courseDocId,
    required String sectionId,
    required bool isMobile,
    required WidgetRef ref,
    required bool isPreview,
  }) {
    return FirestoreQueryBuilder(
      query: FirebaseService.lessonsQuery(courseDocId, sectionId),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const Center(child: Text('No lessons found!'));
        }
        return _lessonList(context, snapshot: snapshot, courseDocId: courseDocId, sectionId: sectionId, ref: ref, isPreview: isPreview);
      },
    );
  }

  Widget _lessonList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required String courseDocId,
    required String sectionId,
    required WidgetRef ref,
    required bool isPreview,
  }) {
    return ReorderableListView.builder(
      physics: isPreview ? const NeverScrollableScrollPhysics() : null,
      onReorder: (oldIndex, newIndex) => _onReorder(context, oldIndex, newIndex, snapshot, courseDocId, sectionId, ref),
      padding: const EdgeInsets.all(10),
      buildDefaultDragHandles: false,
      itemCount: snapshot.docs.length,
      shrinkWrap: true,
      itemBuilder: (BuildContext listContext, int index) {
        if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
          snapshot.fetchMore();
        }
        final List<Lesson> lessons = snapshot.docs.map((e) => Lesson.fromFiresore(e)).toList();
        final Lesson lesson = lessons[index];
        return _buildListItem(context, lesson, courseDocId, sectionId, index, ref, isPreview);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Lesson lesson,
    String courseDocId,
    String sectionId,
    int index,
    WidgetRef ref,
    bool isPreview,
  ) {
    return ReorderableDragStartListener(
      enabled: !isPreview,
      key: Key(index.toString()),
      index: index,
      child: IntrinsicHeight(
        child: Row(
          children: [
            const VerticalDivider(),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Visibility(
                      visible: !isPreview,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                    Text(
                      '${index + 1}.',
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  ],
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CustomButtons.circleButton(
                      context,
                      onPressed: () => _onLessonPreview(context, lesson),
                      icon: Icons.remove_red_eye,
                    ),
                    Visibility(
                      visible: !isPreview,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CustomButtons.circleButton(
                          context,
                          onPressed: () => _onEdit(context, courseDocId, sectionId, lesson),
                          icon: Icons.edit,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: !isPreview,
                      child: CustomButtons.circleButton(
                        context,
                        onPressed: () => _onDeleteLesson(context, courseDocId, sectionId, lesson, ref),
                        icon: Icons.delete,
                      ),
                    ),
                  ],
                ),
                title: Text(lesson.name),
                subtitle: Text(lessonTypes[lesson.contentType].toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLessonPreview(context, Lesson lesson) {
    if (lesson.contentType == lessonTypes.keys.elementAt(0)) {
      //video
      AppService().openLink(context, lesson.videoUrl.toString());
    }
    if (lesson.contentType == lessonTypes.keys.elementAt(1)) {
      //article
      CustomDialogs.openResponsiveDialog(context, widget: ArticlePreview(lesson: lesson));
    }
    if (lesson.contentType == lessonTypes.keys.elementAt(2)) {
      //quiz
      CustomDialogs.openResponsiveDialog(context, widget: QuizPreview(lesson: lesson));
    }
  }

  void _onEdit(context, String courseId, String sectionId, Lesson lesson) {
    CustomDialogs.openResponsiveDialog(
      context,
      verticalPaddingPercentage: 0.02,
      widget: LessonForm(courseDocId: courseId, sectionDocId: sectionId, lesson: lesson),
    );
  }

  void _onDeleteLesson(BuildContext context, String courseDocId, String sectionId, Lesson lesson, WidgetRef ref) async {
    final deleteBtnCtlr = RoundedLoadingButtonController();
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      CustomDialogs.openActionDialog(
        context,
        actionBtnController: deleteBtnCtlr,
        title: 'Delete this lesson?',
        message: 'Warning: All of the contents releated to this lesson will be deleted and this can not be undone!',
        onAction: () async {
          deleteBtnCtlr.start();
          await FirebaseService().deleteLesson(courseDocId, sectionId, lesson.id);
          await FirebaseService().updateLessonCountInCourse(courseDocId, count: (-1));
          deleteBtnCtlr.success();
          if (!context.mounted) return;
          Navigator.pop(context);
        },
      );
    } else {
      openTestingToast(context);
    }
  }

  void _onReorder(
    BuildContext context,
    int oldIndex,
    int newIndex,
    FirestoreQueryBuilderSnapshot snapshot,
    String courseDocId,
    String sectionId,
    WidgetRef ref,
  ) async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      final List<Lesson> lessons = snapshot.docs.map((e) => Lesson.fromFiresore(e)).toList();
      lessons.sort((a, b) => a.order.compareTo(b.order));
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Lesson lesson = lessons.removeAt(oldIndex);
      lessons.insert(newIndex, lesson);
      await FirebaseService().updateLessonsOrder(lessons, courseDocId, sectionId);
    } else {
      openTestingToast(context);
    }
  }
}
