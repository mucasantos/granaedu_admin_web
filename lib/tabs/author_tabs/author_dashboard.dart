import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import '../../mixins/course_mixin.dart';
import '../../utils/reponsive.dart';
import '../../providers/user_data_provider.dart';
import '../../services/firebase_service.dart';
import '../admin_tabs/dashboard/dashboard_tile.dart';

final authorCoursesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(userDataProvider);
  final int count = await FirebaseService().getAuthorCoursesCount(user!.id);
  return count;
});

final authorReviewsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(userDataProvider);
  final int count = await FirebaseService().getAuthorReviewsCount(user!.id);
  return count;
});

class AuthorDashboard extends ConsumerWidget with CourseMixin {
  const AuthorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async => await ref.refresh(userDataProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  crossAxisCount: Responsive.getCrossAxisCount(context),
                  childAspectRatio: Responsive.getChildAspectRatio(context)),
              children: [
                DashboardTile(info: 'Total Students', count: user?.authorInfo?.students ?? 0, icon: LineIcons.userFriends),
                DashboardTile(info: 'Total Courses', count: ref.watch(authorCoursesCountProvider).value ?? 0, icon: LineIcons.book),
                DashboardTile(info: 'Total Reviews', count: ref.watch(authorReviewsCountProvider).value ?? 0, icon: LineIcons.star),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
