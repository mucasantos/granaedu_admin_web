import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/rating_view.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/forms/course_form.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/course.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/course_preview.dart';
import 'package:lms_admin/utils/custom_cache_image.dart';
import 'package:lms_admin/utils/empty_with_image.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/dashboard/dashboard_providers.dart';
import '../components/custom_buttons.dart';
import '../components/dialogs.dart';

mixin CourseMixin {
  Widget buildCourses(
    BuildContext context, {
    required WidgetRef ref,
    required queryProvider,
    bool isFeaturedPosts = false,
    bool isAuthorTab = false,
  }) {
    return FirestoreQueryBuilder(
      query: ref.watch(queryProvider),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const EmptyPageWithImage(title: 'No courses found');
        }
        return _courseList(context, snapshot: snapshot, isFeaturedPosts: isFeaturedPosts, isAuthorTab: isAuthorTab, ref: ref);
      },
    );
  }

  Widget _courseList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required bool isFeaturedPosts,
    required bool isAuthorTab,
    required WidgetRef ref,
  }) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: snapshot.docs.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (BuildContext listContext, int index) {
          if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
            snapshot.fetchMore();
          }
          final List<Course> courses = snapshot.docs.map((e) => Course.fromFirestore(e)).toList();
          final Course course = courses[index];
          return _buildListItem(context, course, isFeaturedPosts, isAuthorTab, ref);
        },
      ),
    );
  }

  ListTile _buildListItem(BuildContext context, Course course, bool isFeaturedPosts, bool isAuthorTab, WidgetRef ref) {
    return ListTile(
      minVerticalPadding: 20,
      horizontalTitleGap: 30,
      leading: SizedBox(
        height: 60,
        width: 60,
        child: CustomCacheImage(
          imageUrl: course.thumbnailUrl,
          radius: 3,
        ),
      ),
      title: Wrap(
        runSpacing: 10,
        spacing: 0,
        children: [
          Text(course.name),
          const SizedBox(
            width: 10,
          ),
          _buildStatus(context, course)
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text('${course.studentsCount} students'),
              const SizedBox(
                width: 10,
              ),
              Text(
                '${priceStatus[course.priceStatus]}',
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('By ${course.author!.name}')),
          RatingView(rating: course.rating, showText: false)
        ],
      ),
      trailing: _courseMenuButtons(course, isFeaturedPosts, isAuthorTab, context, ref),
    );
  }

  Container _buildStatus(BuildContext context, Course course) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _getStatusColor(course.status)),
      child: Text(
        '${courseStatus[course.status]}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static Color _getStatusColor(String status) {
    //draft
    if (status == courseStatus.keys.elementAt(0)) {
      return Colors.grey.shade500;

      //pending
    } else if (status == courseStatus.keys.elementAt(1)) {
      return Colors.blueAccent;

      //live
    } else if (status == courseStatus.keys.elementAt(2)) {
      return Colors.orangeAccent;

      //archived
    } else {
      return Colors.redAccent;
    }
  }

  String setCourseStatus({
    required Course? course,
    required bool? isAuthorTab,
    required bool isDraft,
  }) {
    if (isDraft) {
      //draft
      return courseStatus.keys.elementAt(0);
    } else {
      if (course != null && course.status == courseStatus.keys.elementAt(2)) {
        //if the course is already live then it stays live
        return courseStatus.keys.elementAt(2);
      } else {
        if (isAuthorTab != null && isAuthorTab == true) {
          //pending
          return courseStatus.keys.elementAt(1);
        } else {
          //live
          return courseStatus.keys.elementAt(2);
        }
      }
    }
  }

  Wrap _courseMenuButtons(Course course, bool isFeaturedPosts, bool isAuthorTab, BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        Visibility(
          //only for live courses and not featured tabs and author courses
          visible: course.status == courseStatus.keys.elementAt(2) && !isFeaturedPosts && !isAuthorTab,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CustomButtons.circleButton(
              context,
              icon: Icons.add,
              tooltip: 'Add to featured',
              onPressed: () => _onAddToFeatured(context, course, ref),
            ),
          ),
        ),
        CustomButtons.circleButton(context, icon: Icons.remove_red_eye, tooltip: 'Preview', onPressed: () => _onPreview(context, course)),
        const SizedBox(width: 8),
        Visibility(
          //not for featured posts and can edit only the author of that course
          visible: !isFeaturedPosts,
          child: CustomButtons.circleButton(context, icon: Icons.edit, tooltip: 'Edit', onPressed: () => _onEdit(context, course, isAuthorTab, ref)),
        ),
        const SizedBox(width: 8),
        Visibility(visible: !isFeaturedPosts, child: _menuButton(context, course, ref)),
        Visibility(
          //only for featured posts
          visible: isFeaturedPosts,
          child:
              CustomButtons.circleButton(context, icon: Icons.close, tooltip: 'Remove', onPressed: () => _onRemoveFeaturedPost(context, course, ref)),
        ),
      ],
    );
  }

  PopupMenuButton _menuButton(BuildContext context, Course course, WidgetRef ref) {
    return PopupMenuButton(
      child: const CircleAvatar(
        radius: 16,
        child: Icon(
          Icons.menu,
          size: 16,
        ),
      ),
      itemBuilder: (popupContext) {
        return [
          PopupMenuItem(
            enabled: (course.status == courseStatus.keys.elementAt(2) || course.status == courseStatus.keys.elementAt(3)) &&
                UserMixin.hasAdminAccess(ref.watch(userDataProvider)),
            child: Text(course.status == courseStatus.keys.elementAt(3) ? 'Publish Course' : 'Archive Course'),
            onTap: () => _handleArchiveCourse(course),
          ),
          PopupMenuItem(
            enabled: course.status == courseStatus.keys.elementAt(1) && UserMixin.hasAdminAccess(ref.watch(userDataProvider)),
            child: const Text('Approve Course'),
            onTap: () => _handleCourseApproval(course),
          ),
          PopupMenuItem(
              enabled: UserMixin.isAuthor(ref.watch(userDataProvider), course),
              child: const Text('Delete Course'),
              onTap: () => _onDelete(context, course, ref)),
        ];
      },
    );
  }

  void _handleArchiveCourse(Course course) async {
    if (course.status == courseStatus.keys.elementAt(3)) {
      course.status = courseStatus.keys.elementAt(2);
    } else {
      course.status = courseStatus.keys.elementAt(3);
    }
    await FirebaseService().saveCourse(course);
  }

  void _handleCourseApproval(Course course) async {
    course.status = courseStatus.keys.elementAt(2);
    await FirebaseService().saveCourse(course);
  }

  void _onRemoveFeaturedPost(context, Course course, WidgetRef ref) async {
    final btnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      title: 'Remove From Feature Course?',
      message: 'Do you want to remove this course from the featured list?',
      actionButtonText: 'Yes, Remove',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          btnController.start();
          await FirebaseService().updateFeaturedCourse(course, false);
          btnController.success();

          if (!context.mounted) return;
          Navigator.pop(context);
          openSuccessToast(context, 'Removed Successfully!');
        } else {
          openTestingToast(context);
        }
      },
      actionBtnController: btnController,
    );
  }

  void _onAddToFeatured(context, Course course, WidgetRef ref) async {
    final addBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      title: 'Assign As A Feature Course?',
      message: 'Do you want to assign this course as a featured course?',
      actionButtonText: 'Add',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          if (course.isFeatured == false) {
            addBtnController.start();
            await FirebaseService().updateFeaturedCourse(course, true);
            addBtnController.success();

            if (!context.mounted) return;
            Navigator.pop(context);
            openSuccessToast(context, 'Added Successfully!');
          } else {
            openToast(context, 'Course is already available!');
          }
        } else {
          openTestingToast(context);
        }
      },
      actionBtnController: addBtnController,
    );
  }

  void _onDelete(context, Course course, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this this?',
      message: 'Warning: All of the data releated to this course will be deleted and this can not be undone!',
      onAction: () async {
        final user = ref.read(userDataProvider);
        if (UserMixin.isAuthor(user, course) || UserMixin.hasAdminAccess(user)) {
          deleteBtnController.start();
          await FirebaseService().deleteContent('courses', course.id);
          ref.invalidate(coursesCountProvider);
          deleteBtnController.success();

          if (!context.mounted) return;
          Navigator.pop(context);
          CustomDialogs.openInfoDialog(context, 'Deleted Successfully!', '');
        } else {
          openTestingToast(context);
        }
      },
    );
  }

  void _onEdit(BuildContext context, Course course, bool isAuthorTab, WidgetRef ref) {
    // if (UserMixin.isAuthor(ref.read(userDataProvider), course)) {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      CustomDialogs.openFullScreenDialog(context, widget: CourseForm(course: course, isAuthorTab: isAuthorTab));
    } else {
      openFailureToast(context, 'Only author can edit their own course');
    }
  }

  void _onPreview(BuildContext context, Course course) {
    CustomDialogs.openResponsiveDialog(context, widget: CoursePreview(course: course), verticalPaddingPercentage: 0.02);
  }
}
