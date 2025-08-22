import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/mixins/users_mixin.dart';
import 'package:lms_admin/models/course.dart';
import 'package:lms_admin/models/user_model.dart';
import 'package:lms_admin/services/app_service.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/utils/custom_cache_image.dart';

final enrolledCoursesProvider = FutureProvider.autoDispose.family<List<Course>, List>((ref, courseIds) async {
  if (courseIds.isEmpty) return [];
  final courses = await FirebaseService().getUserCourses(courseIds);
  return courses;
});

final wishlistProvider = FutureProvider.autoDispose.family<List<Course>, List>((ref, courseIds) async {
  if (courseIds.isEmpty) return [];
  final courses = await FirebaseService().getUserCourses(courseIds);
  return courses;
});

class UserInfo extends ConsumerWidget with UsersMixins, UserMixin {
  const UserInfo({Key? key, required this.user}) : super(key: key);

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledCourses = ref.watch(enrolledCoursesProvider(user.enrolledCourses ?? []));
    final wishList = ref.watch(wishlistProvider(user.wishList ?? []));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  getUserImage(user: user, radius: 100, iconSize: 40),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text('Account Created: ${AppService.getDateTime(user.createdAt)}'),
                  const SizedBox(height: 5),
                  getEmail(user, ref),
                  const SizedBox(height: 5),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Subscription: '),
                      getSubscription(context, user),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      spacing: 10,
                      children: user.role!
                          .map((e) => Chip(
                              label: Text(
                                e,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Theme.of(context).primaryColor))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enrolled Courses (${enrolledCourses.value?.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  enrolledCourses.when(
                    skipError: true,
                    loading: () => Container(),
                    error: (error, stackTrace) => Container(),
                    data: (data) => data.isEmpty
                        ? const Text('No courses found')
                        : Column(
                            children: data
                                .map((e) => CourseTileBasic(
                                      course: e,
                                      user: user,
                                      showProgress: true,
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wishlist (${wishList.value?.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  wishList.when(
                    skipError: true,
                    loading: () => Container(),
                    error: (error, stackTrace) => Container(),
                    data: (data) => data.isEmpty
                        ? const Text('No courses found')
                        : Column(
                            children: data
                                .map((e) => CourseTileBasic(
                                      course: e,
                                      user: user,
                                      showProgress: false,
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CourseTileBasic extends StatelessWidget {
  const CourseTileBasic({Key? key, required this.course, required this.user, required this.showProgress}) : super(key: key);
  final Course course;
  final UserModel user;
  final bool? showProgress;

  @override
  Widget build(BuildContext context) {
    List validIds = user.completedLessons!.where((element) => element.toString().contains(course.id)).toList();
    final double courseProgess = validIds.isEmpty ? 0 : (validIds.length / course.lessonsCount);
    final String courseProgesString = (courseProgess * 100).toStringAsFixed(0);

    return ListTile(
      isThreeLine: showProgress ?? false,
      horizontalTitleGap: 20,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      title: Text(course.name),
      leading: SizedBox(
        height: 60,
        width: 60,
        child: CustomCacheImage(imageUrl: course.thumbnailUrl, radius: 3),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By ${course.author?.name}'),
          Visibility(
            visible: showProgress ?? false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  width: 200,
                  child: LinearProgressIndicator(
                    value: courseProgess,
                    borderRadius: BorderRadius.circular(20),
                    minHeight: 5,
                    color: Colors.orange.shade300,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
                Text('$courseProgesString% completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
