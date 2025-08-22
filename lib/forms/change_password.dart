import 'package:flutter/material.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/services/auth_service.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../components/custom_buttons.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> with TextFields {
  final formKey = GlobalKey<FormState>();
  final btnController = RoundedLoadingButtonController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  _handleSubmit() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      btnController.start();
      final navigator = Navigator.of(context);
      bool changed = await AuthService().changePassword(
        oldPasswordController.text.trim(),
        newPasswordController.text.trim(),
      );
      if (changed) {
        btnController.success();
        await Future.delayed(const Duration(seconds: 1));
        navigator.pop();
        if (!mounted) return;
        CustomDialogs.openInfoDialog(context, 'Password has been changed successfully!', '');
      } else {
        btnController.reset();
        if (!mounted) return;
        CustomDialogs.openInfoDialog(context, 'Failure in changing password', 'Please try again');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          width: 300,
          buttonController: btnController,
          text: 'Change Password',
          onPressed: _handleSubmit,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black,
                  ))),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(context,
                  controller: oldPasswordController, hint: 'Old Password', title: 'Old Password *', isPassword: true, hasImageUpload: false),
              const SizedBox(
                height: 30,
              ),
              buildTextField(context,
                  controller: newPasswordController, hint: 'New Password', title: 'New Password *', isPassword: true, hasImageUpload: false),
            ],
          ),
        ),
      ),
    );
  }
}
