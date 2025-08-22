import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/forms/change_password.dart';
import 'package:lms_admin/forms/edit_profile.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/pages/login.dart';
import 'package:lms_admin/providers/auth_state_provider.dart';
import 'package:lms_admin/utils/next_screen.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import '../configs/app_config.dart';
import '../models/user_model.dart';
import '../providers/user_data_provider.dart';
import '../services/auth_service.dart';

mixin AppBarMixin implements UserMixin, Responsive {
  PopupMenuButton buildUserMenuButton(
    BuildContext context, {
    required UserModel? user,
    required WidgetRef ref,
  }) {
    return PopupMenuButton(
      itemBuilder: (context) {
        return userMenus.entries
            .map(
              (e) => PopupMenuItem(
                enabled: user != null,
                value: e.key,
                child: Text(e.value),
              ),
            )
            .toList();
      },
      onSelected: (value) async {
        //Edit Profile
        if (value == userMenus.keys.elementAt(0)) {
          CustomDialogs.openResponsiveDialog(context, widget: EditProfile(user: user!));
        }

        //Logout
        if (value == userMenus.keys.elementAt(2)) {
          await AuthService().adminLogout().then((value) {
            ref.invalidate(userDataProvider);
            ref.invalidate(userRoleProvider);
            NextScreen.replaceAnimation(context, const Login());
          });
        }

        //chnage Password
        if (value == userMenus.keys.elementAt(1)) {
          if (!context.mounted) return;
          CustomDialogs.openResponsiveDialog(context, widget: const ChangePassword());
        }
      },
      child: Row(
        children: [
          getUserImage(user: user, radius: 35),
          const SizedBox(
            width: 10,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getUserName(user),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                getUserRole(user),
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.blueGrey,
            size: 20,
          )
        ],
      ),
    );
  }

  Visibility buildMenuButton(
    BuildContext context, {
    required GlobalKey<ScaffoldState> scaffoldKey,
  }) {
    return Visibility(
      visible: Responsive.isMobile(context) || Responsive.isTablet(context),
      child: IconButton(
          onPressed: () {
            if (!scaffoldKey.currentState!.isDrawerOpen) {
              scaffoldKey.currentState!.openDrawer();
            }
          },
          icon: const Icon(Icons.menu)),
    );
  }

  static Container buildTitleBar(
    BuildContext context, {
    required String title,
    required List<Widget> buttons,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      height: 60,
      width: double.infinity,
      color: AppConfig.titleBarColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue),
          ),
          const Spacer(),
          ...buttons
        ],
      ),
    );
  }
}
