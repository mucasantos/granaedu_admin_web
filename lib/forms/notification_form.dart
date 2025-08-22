import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/models/notification_model.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../components/text_editors/html_editor.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class NotificationForm extends ConsumerStatefulWidget {
  const NotificationForm({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends ConsumerState<NotificationForm> with TextFields {
  var titleCtlr = TextEditingController();
  final HtmlEditorController controller = HtmlEditorController();
  final _btnCtlr = RoundedLoadingButtonController();
  final formKey = GlobalKey<FormState>();

  _handleSendNotification() async {
    if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        final navigator = Navigator.of(context);
        final String description = await controller.getText();
        if (description.isNotEmpty) {
          _btnCtlr.start();
          await NotificationService().sendCustomNotificationByTopic(_notificationModel(description));
          await FirebaseService().saveNotification(_notificationModel(description));
          _clearFields();
          _btnCtlr.success();
          navigator.pop();
          if (!mounted) return;
          openSuccessToast(context, 'Notification sent successfully!');
        } else {
          if (!mounted) return;
          openFailureToast(context, "Description can't be empty");
        }
      }
    } else {
      openTestingToast(context);
    }
  }

  _clearFields() {
    titleCtlr.clear();
    controller.clear();
  }

  _openPreview() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final String description = await controller.getText();

      if (description.isNotEmpty) {
        if (!mounted) return;
        CustomDialogs().openNotificationDialog(context, notification: _notificationModel(description));
      } else {
        if(!mounted) return;
        openFailureToast(context, "Description can't be empty");
      }
    }
  }

  NotificationModel _notificationModel(String description) {
    final String id = FirebaseService.getUID('notifications');
    final notification = NotificationModel(
      id: id,
      title: titleCtlr.text,
      description: description,
      sentAt: DateTime.now().toUtc(),
      topic: notificationTopicForAll,
    );
    return notification;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 70.0,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ),
        actions: [
          CustomButtons.circleButton(context, icon: Icons.remove_red_eye, onPressed: _openPreview, radius: 20),
          const SizedBox(width: 10),
          CustomButtons.submitButton(
            context,
            buttonController: _btnCtlr,
            text: 'Send',
            onPressed: _handleSendNotification,
            borderRadius: 20,
            width: 120,
            height: 45,
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                    context,
                    controller: titleCtlr,
                    hint: 'Enter Notification Title',
                    title: 'Notification Title *',
                    hasImageUpload: false,
                    validationRequired: true,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  CustomHtmlEditor(
                    title: 'Notification Description',
                    height: 450,
                    controller: controller,
                    hint: 'Enter description',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
