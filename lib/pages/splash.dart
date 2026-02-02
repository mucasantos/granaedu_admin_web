import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/app_logo.dart';
import 'package:lms_admin/configs/assets_config.dart';
// import 'package:lms_admin/models/app_settings_model.dart';
import 'package:lms_admin/pages/login.dart';
// import 'package:lms_admin/pages/verify.dart';
import 'package:lms_admin/providers/user_data_provider.dart';
import 'package:lms_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:lms_admin/utils/next_screen.dart';
import 'package:lms_admin/utils/toasts.dart';
import '../providers/auth_state_provider.dart';
import '../services/auth_service.dart';
import 'home.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _InitialScreen1State();
}

class _InitialScreen1State extends ConsumerState<SplashScreen> {
  late StreamSubscription<User?> _auth;

  @override
  void initState() {
    _auth = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _checkVerification(user);
      } else {
        NextScreen.replaceAnimation(context, const Login());
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _auth.cancel();
    super.dispose();
  }

  _checkVerification(User user) async {
    final UserRoles role = await AuthService().checkUserRole(user.uid);

    if (role == UserRoles.admin || role == UserRoles.author) {
      ref.read(userRoleProvider.notifier).update((state) => role);

      const bool isVerified = true; // Bypassed purchase verification

      if (isVerified) {
        // First ensure settings are loaded and Supabase is initialized
        await ref.read(appSettingsProvider.future);

        // Then get user data which triggers syncUserProfile
        await ref.read(userDataProvider.notifier).getData();
        if (!mounted) return;
        NextScreen.replaceAnimation(context, const Home());
      }
    } else {
      // Not ADMIN or AUTHOR
      await AuthService().adminLogout().then((value) {
        openFailureToast(context, 'Access Denied');
        NextScreen.replaceAnimation(context, const Login());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: AppLogo(imageString: AssetsConfig.logo, width: 300)),
    );
  }
}
