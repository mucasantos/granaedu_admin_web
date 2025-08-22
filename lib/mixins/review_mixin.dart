import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/rating_view.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/review.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/dashboard/dashboard_providers.dart';
import '../utils/empty_with_image.dart';
import '../components/dialogs.dart';

mixin ReviewMixin {
  Widget buildReviews(
    BuildContext context, {
    required bool isAuthorCourses,
    required queryProvider,
    required WidgetRef ref,
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
          return const EmptyPageWithImage(title: 'No reviews found');
        }
        return _reviewList(context, snapshot: snapshot, ref: ref, isAuthorCourses: isAuthorCourses);
      },
    );
  }

  Widget _reviewList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required bool isAuthorCourses,
    required WidgetRef ref,
  }) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
        itemCount: snapshot.docs.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
            snapshot.fetchMore();
          }
          final List<Review> reviews = snapshot.docs.map((e) => Review.fromFirebase(e)).toList();
          final Review review = reviews[index];
          return _buildListItem(context, review, ref, isAuthorCourses);
        },
      ),
    );
  }

  ListTile _buildListItem(BuildContext context, Review review, WidgetRef ref, bool isAuthorCourses) {
    return ListTile(
      minVerticalPadding: 10,
      horizontalTitleGap: 30,
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium,
          text: review.reviewUser.name,
          children: [
            const TextSpan(text: '  '),
            TextSpan(text: review.courseTitle, style: const TextStyle(color: Colors.blueAccent))
          ]
        ),
      ),
      leading: UserMixin.getUserImageByUrl(imageUrl: review.reviewUser.imageUrl, radius: 40, iconSize: 20),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingView(rating: review.rating),
          Visibility(
            visible: review.review != null,
            child: Text(
              review.review.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade900),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.time,
                size: 18,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(AppService.getDateTime(review.createdAt)),
            ],
          ),
        ],
      ),
      trailing: Visibility(
        visible: !isAuthorCourses,
        child: CustomButtons.circleButton(context, icon: Icons.delete, onPressed: () => _onDelete(context, review, ref))),
    );
  }

  void _onDelete(context, Review review, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this review?',
      message: 'Do you want to delete this user review?\nWarning: This can not be undone.',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          deleteBtnController.start();

          await FirebaseService().deleteContent('reviews', review.id);
          final double avarageRating = await FirebaseService().getCourseAverageRating(review.courseId);
          await FirebaseService().saveCourseRating(review.courseId, avarageRating);

          ref.invalidate(reviewsCountProvider);
          deleteBtnController.success();
          Navigator.pop(context);
          openSuccessToast(context, 'Deleted successfully!');
        } else {
          openTestingToast(context);
        }
      },
    );
  }
}
