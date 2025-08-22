import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/models/notification_model.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/services/app_service.dart';

import '../tabs/admin_tabs/notifications.dart';
import '../utils/empty_with_image.dart';

mixin NotificationsMixin {
  Widget buildNotifications(
    BuildContext context, {
    required WidgetRef ref,
  }) {
    return FirestoreQueryBuilder(
      query: ref.watch(notificatiosQueryprovider),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const EmptyPageWithImage(title: 'No notifications found');
        }
        return _notificationsList(context, snapshot: snapshot, ref: ref);
      },
    );
  }

  Widget _notificationsList(BuildContext context, {required FirestoreQueryBuilderSnapshot snapshot, required WidgetRef ref}) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: snapshot.docs.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
            snapshot.fetchMore();
          }
          final List<NotificationModel> notifications = snapshot.docs.map((e) => NotificationModel.fromFirestore(e)).toList();
          final NotificationModel notification = notifications[index];
          return _buildListItem(context, notification, index);
        },
      ),
    );
  }

  ListTile _buildListItem(BuildContext context, NotificationModel notification, int index) {
    return ListTile(
      minVerticalPadding: 10,
      horizontalTitleGap: 20,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        radius: 20,
        child: const Icon(
          LineIcons.bell,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(notification.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            AppService.getNormalText(notification.description),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            AppService.getDateTime(notification.sentAt),
            style: const TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
      trailing: CustomButtons.circleButton(
        context,
        icon: Icons.remove_red_eye,
        onPressed: () => CustomDialogs().openNotificationDialog(context, notification: notification),
      ),
    );
  }
}
