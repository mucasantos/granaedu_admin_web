import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/tabs/admin_tabs/dashboard/purchase_bar_chart.dart';
import 'package:lms_admin/tabs/admin_tabs/dashboard/user_bar_chart.dart';
import 'package:lms_admin/mixins/course_mixin.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'dashboard_purchases.dart';
import 'dashboard_reviews.dart';
import 'dashboard_tile.dart';
import 'dashboard_providers.dart';
import 'dashboard_top_courses.dart';
import 'dashboard_users.dart';

class Dashboard extends ConsumerWidget with CourseMixin {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              crossAxisCount: Responsive.getCrossAxisCount(context),
              childAspectRatio: 2.5,
            ),
            children: [
              DashboardTile(
                  info: 'Total Users', count: ref.watch(usersCountProvider).value ?? 0, icon: LineIcons.userFriends, bgColor: Colors.orange),
              DashboardTile(
                  info: 'Total Enrolled', count: ref.watch(enrolledCountProvider).value ?? 0, icon: LineIcons.userTie, bgColor: Colors.blue),
              DashboardTile(
                  info: 'Total Subscribed', count: ref.watch(subscriberCountProvider).value ?? 0, icon: LineIcons.userClock, bgColor: Colors.purple),
              DashboardTile(
                  info: 'Total Purchases', count: ref.watch(purchasesCountProvider).value ?? 0, icon: LineIcons.receipt, bgColor: Colors.cyan),
              DashboardTile(
                  info: 'Total Authors', count: ref.watch(authorsCountProvider).value ?? 0, icon: LineIcons.userTag, bgColor: Colors.pinkAccent),
              DashboardTile(info: 'Total Courses', count: ref.watch(coursesCountProvider).value ?? 0, icon: LineIcons.book, bgColor: Colors.green),
              DashboardTile(
                  info: 'Total Notifications',
                  count: ref.watch(notificationsCountProvider).value ?? 0,
                  icon: LineIcons.bell,
                  bgColor: Colors.deepPurple),
              DashboardTile(info: 'Total Reviews', count: ref.watch(reviewsCountProvider).value ?? 0, icon: LineIcons.starAlt, bgColor: Colors.teal),
            ],
          ),
          const SizedBox(height: 20),
          _buildOtherTabs(context),
        ],
      ),
    );
  }

  Widget _buildOtherTabs(BuildContext context) {
    if (Responsive.isDesktopLarge(context)) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 1,
              child: Column(
                children: [UserBarChart(), SizedBox(height: 20), DashboardReviews()],
              )),
          SizedBox(width: 20),
          Flexible(
              flex: 1,
              child: Column(
                children: [PurchaseBarChart(), SizedBox(height: 20), DashboardUsers()],
              )),
          SizedBox(width: 20),
          Flexible(
              flex: 1,
              child: Column(
                children: [DashboardPurchases(), SizedBox(height: 20), DashboardTopCourses()],
              )),
        ],
      );
    } else if (Responsive.isDesktop(context)) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 1,
              child: Column(
                children: [
                  UserBarChart(),
                  SizedBox(height: 20),
                  DashboardReviews(),
                  SizedBox(height: 20),
                  DashboardPurchases(),
                ],
              )),
          SizedBox(width: 20),
          Flexible(
              flex: 1,
              child: Column(
                children: [
                  PurchaseBarChart(),
                  SizedBox(height: 20),
                  DashboardUsers(),
                  SizedBox(height: 20),
                  DashboardTopCourses(),
                ],
              )),
        ],
      );
    } else {
      return const Column(
        children: [
          UserBarChart(),
          SizedBox(height: 20),
          PurchaseBarChart(),
          SizedBox(height: 20),
          DashboardReviews(),
          SizedBox(height: 20),
          DashboardPurchases(),
          SizedBox(height: 20),
          DashboardUsers(),
          SizedBox(height: 20),
          DashboardTopCourses(),
        ],
      );
    }
  }
}
