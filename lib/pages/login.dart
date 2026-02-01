import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/app_logo.dart';
import 'package:lms_admin/configs/assets_config.dart';
// import 'package:lms_admin/models/app_settings_model.dart';
// import 'package:lms_admin/pages/verify.dart';
import 'package:lms_admin/providers/auth_state_provider.dart';
import 'package:lms_admin/providers/user_data_provider.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/pages/home.dart';
import 'package:lms_admin/services/auth_service.dart';
import 'package:lms_admin/utils/next_screen.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:svg_flutter/svg.dart';

// import '../tabs/admin_tabs/app_settings/app_setting_providers.dart';

class Login extends ConsumerStatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  var emailCtlr = TextEditingController();
  var passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final RoundedLoadingButtonController _btnCtlr = RoundedLoadingButtonController();
  bool _obsecureText = true;
  IconData _lockIcon = CupertinoIcons.eye_fill;

  _onChangeVisiblity() {
    if (_obsecureText == true) {
      setState(() {
        _obsecureText = false;
        _lockIcon = CupertinoIcons.eye;
      });
    } else {
      setState(() {
        _obsecureText = true;
        _lockIcon = CupertinoIcons.eye_fill;
      });
    }
  }

  void _handleLogin() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _btnCtlr.start();
      UserCredential? userCredential = await AuthService().loginWithEmailPassword(emailCtlr.text, passwordCtrl.text);
      if (userCredential?.user != null) {
        debugPrint('Login Success');
        _checkVerification(userCredential!);
      } else {
        _btnCtlr.reset();
        if (!mounted) return;
        openFailureToast(context, 'Email/Password is invalid');
      }
    }
  }

  _checkVerification(UserCredential userCredential) async {
    final UserRoles role = await AuthService().checkUserRole(userCredential.user!.uid);
    if (role == UserRoles.admin || role == UserRoles.author) {
      ref.read(userRoleProvider.notifier).update((state) => role);

      const bool isVerified = true; // Bypassed purchase verification

      if (isVerified) {
        await ref.read(userDataProvider.notifier).getData();
        if (!mounted) return;
        NextScreen.replaceAnimation(context, const Home());
      }
    } else {
      await AuthService()
          .adminLogout()
          .then((value) => openFailureToast(context, 'Access Denied'));
    }
  }

  // _handleDemoAdminLogin() async {
  //   ref.read(userRoleProvider.notifier).update((state) => UserRoles.guest);
  //   await AuthService().loginAnnonumously().then((value) => NextScreen.replaceAnimation(context, const Home()));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.indigo.withOpacity(0.1),
        child: Row(
          children: [
            Visibility(
              visible: Responsive.isDesktop(context) || Responsive.isDesktopLarge(context),
              child: Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: SvgPicture.asset(
                  AssetsConfig.loginImageString,
                  alignment: Alignment.center,
                  height: 400,
                  width: 400,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Flexible(
              flex: 1,
              // fit: FlexFit.tight,
              child: Form(
                key: formKey,
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getHorizontalPadding(),
                      vertical: 30.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(
                            imageString: AssetsConfig.logo,
                            height: 60,
                            width: 250),
                        Text(
                          'Sign In to the Admin Panel',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              color: Colors.grey.shade100,
                              child: TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                controller: emailCtlr,
                                validator: (value) {
                                  if (value!.isEmpty)
                                    return 'Email is required';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    onPressed: () => emailCtlr.clear(),
                                    icon: const Icon(Icons.clear),
                                  ),
                                  hintText: 'Email Address',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(15),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Text(
                              'Password',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              color: Colors.grey.shade100,
                              child: TextFormField(
                                controller: passwordCtrl,
                                obscureText: _obsecureText,
                                validator: (value) {
                                  if (value!.isEmpty)
                                    return 'Password is required';
                                  return null;
                                },
                                decoration: InputDecoration(
                                    suffixIcon: Wrap(
                                      children: [
                                        IconButton(onPressed: _onChangeVisiblity, icon: Icon(_lockIcon)),
                                        IconButton(onPressed: () => passwordCtrl.clear(), icon: const Icon(Icons.clear)),
                                      ],
                                    ),
                                    hintText: 'Your Password',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(15)),
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                            RoundedLoadingButton(
                              onPressed: _handleLogin,
                              controller: _btnCtlr,
                              color: Theme.of(context).primaryColor,
                              width: MediaQuery.of(context).size.width,
                              borderRadius: 0,
                              height: 55,
                              animateOnTap: false,
                              elevation: 0,
                              child: Text(
                                'Login',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     TextButton(
                            //       child: const Text('Test Demo Admin'),
                            //       onPressed: () => _handleDemoAdminLogin(),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getHorizontalPadding() {
    if (Responsive.isDesktopLarge(context)) {
      return 120;
    } else if (Responsive.isDesktop(context)) {
      return 80;
    } else if (Responsive.isTablet(context)) {
      return 100;
    } else {
      return 30;
    }
  }
}
