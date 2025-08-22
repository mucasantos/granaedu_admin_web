import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/forms/notification_form.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/mixins/notifications_mixin.dart';
import 'package:lms_admin/services/firebase_service.dart';

final notificatiosQueryprovider = StateProvider<Query>((ref) {
  final query = FirebaseService.notificationsQuery();
  return query;
});

class Notifications extends ConsumerWidget with NotificationsMixin {
  const Notifications({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Notifications', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Create',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const NotificationForm());
              },
            ),
          ]),
          buildNotifications(context, ref: ref)
        ],
      ),
    );
  }
}
