import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/user_info.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/mixins/users_mixin.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_data_provider.dart';

class UsersDataSource extends DataTableSource with UsersMixins, UserMixin {
  final List<UserModel> users;
  final BuildContext context;
  final WidgetRef ref;
  UsersDataSource(this.users, this.context, this.ref);

  void _onCopyUserId(String userId) async {
    if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      Clipboard.setData(ClipboardData(text: userId));
      openSuccessToast(context, 'Copied to clipboard');
    } else {
      openTestingToast(context);
    }
  }

  void _handleUserAccess(UserModel user) {
    final btnCtlr = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      title: user.isDisbaled! ? "Enabled Access to this user?" : "Disbale access to this user?",
      message: user.isDisbaled! ? 'Warning: ${user.name} can access the app and contents' : "Warning: ${user.name} can't access the app and contents",
      actionBtnController: btnCtlr,
      actionButtonText: user.isDisbaled! ? 'Yes, Enable Access' : 'Yes, Disable Access',
      onAction: () async {
        final navigator = Navigator.of(context);
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          btnCtlr.start();
          if (user.isDisbaled!) {
            await FirebaseService().updateUserAccess(userId: user.id, shouldDisable: false);
          } else {
            await FirebaseService().updateUserAccess(userId: user.id, shouldDisable: true);
          }

          btnCtlr.success();
          navigator.pop();
          if (!context.mounted) return;
          openSuccessToast(context, 'User access has been updated!');
        } else {
          openTestingToast(context);
        }
      },
    );
  }

  void _handleAuthorAccess(UserModel user, bool isAuthor) {
    final btnCtlr = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      title: !isAuthor ? "Assign As An Author?" : "Remove Author Access?",
      message: !isAuthor
          ? 'Warning: ${user.name} can access author dashboard and submit courses!'
          : "Warning: ${user.name} can't access the author dashboard!",
      actionBtnController: btnCtlr,
      actionButtonText: !isAuthor ? 'Yes, Enable Access' : 'Yes, Disable Access',
      onAction: () async {
        final navigator = Navigator.of(context);
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          btnCtlr.start();
          if (isAuthor) {
            await FirebaseService().updateAuthorAccess(userId: user.id, shouldAssign: false);
          } else {
            await FirebaseService().updateAuthorAccess(userId: user.id, shouldAssign: true);
          }

          btnCtlr.success();
          navigator.pop();
          if (!context.mounted) return;
          openSuccessToast(context, 'Author access has been updated!');
        } else {
          openTestingToast(context);
        }
      },
    );
  }

  @override
  DataRow getRow(int index) {
    final UserModel user = users[index];

    return DataRow.byIndex(index: index, cells: [
      DataCell(_userName(user)),
      DataCell(getEmail(user, ref)),
      DataCell(_getEnrolledCourses(user)),
      DataCell(getSubscription(context, user)),
      DataCell(_getPlatform(user)),
      DataCell(_actions(user)),
    ]);
  }

  static Text _getEnrolledCourses(UserModel user) {
    return Text(user.enrolledCourses!.length.toString());
  }

  ListTile _userName(UserModel user) {
    return ListTile(
        horizontalTitleGap: 10,
        contentPadding: const EdgeInsets.all(0),
        title: Wrap(
          direction: Axis.horizontal,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 14),
            ),
            Row(
              children: user.role!
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(color: _getColor(e), borderRadius: BorderRadius.circular(3)),
                      child: Text(
                        e,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        leading: getUserImage(user: user));
  }

  static Color _getColor(String role) {
    if (role == 'admin') {
      return Colors.indigoAccent;
    } else if (role == 'author') {
      return Colors.orangeAccent;
    } else {
      return Colors.blueAccent;
    }
  }

  static Text _getPlatform(UserModel user) {
    return Text(user.platform ?? 'Undefined');
  }

  Widget _actions(UserModel user) {
    return Row(
      children: [
        CustomButtons.circleButton(
          context,
          icon: Icons.remove_red_eye,
          tooltip: 'view user info',
          onPressed: () => CustomDialogs.openResponsiveDialog(
            context,
            widget: UserInfo(user: user),
            verticalPaddingPercentage: 0.05,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        _menuButton(user)
      ],
    );
  }

  PopupMenuButton _menuButton(UserModel user) {
    final bool isAuthor = user.role!.contains('author') ? true : false;
    final bool isAdmin = user.role!.contains('admin') ? true : false;

    return PopupMenuButton(
      child: const CircleAvatar(
        radius: 16,
        child: Icon(
          Icons.menu,
          size: 16,
        ),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(child: const Text('Copy User Id'), onTap: () => _onCopyUserId(user.id)),
          PopupMenuItem(
            enabled: !isAdmin,
            child: Text(user.isDisbaled! ? 'Enable User Access' : 'Disable User Access'),
            onTap: () => _handleUserAccess(user),
          ),
          PopupMenuItem(
            enabled: !isAdmin,
            child: Text(isAuthor ? 'Disable Author Access' : 'Assign As Author'),
            onTap: () => _handleAuthorAccess(user, isAuthor),
          ),
        ];
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
