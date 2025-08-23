import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/side_menu.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/user_model.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/l10n/app_localizations.dart';
import '../../../pages/home.dart';

final dashboardUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final List<UserModel> users = await FirebaseService().getLatestUsers(5);
  return users;
});

class DashboardUsers extends ConsumerWidget {
  const DashboardUsers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(dashboardUsersProvider);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.shade300,
        )
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).dashboardNewUsers,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                  onPressed: () {
                    ref.read(menuIndexProvider.notifier).update((state) => 6);
                    ref.read(pageControllerProvider.notifier).state.jumpToPage(6);
                  },
                  child: Text(AppLocalizations.of(context).commonViewAll))
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: users.when(
              data: (data) {
                return Column(
                  children: data.map((user) {
                    return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        leading: UserMixin.getUserImageByUrl(imageUrl: user.imageUrl),
                        title: Text(user.name),
                        subtitle: Text(AppLocalizations.of(context).dashboardEnrolledCourses(user.enrolledCourses?.length ?? 0)));
                  }).toList(),
                );
              },
              error: (a, b) => Container(),
              loading: () => Container(),
            ),
          )
        ],
      ),
    );
  }
}
