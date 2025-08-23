import 'package:flutter/material.dart';
import 'package:lms_admin/components/html_body.dart';
import 'package:lms_admin/utils/next_screen.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/models/notification_model.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:lms_admin/l10n/app_localizations.dart';

class CustomDialogs {
  static openInfoDialog(context, title, message) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return PointerInterceptor(
            child: SimpleDialog(
              contentPadding: const EdgeInsets.all(50),
              elevation: 0,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 10,
                ),
                Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blueGrey)),
                const SizedBox(
                  height: 30,
                ),
                Center(child: CustomButtons.normalButton(context, text: AppLocalizations.of(context).commonOk))
              ],
            ),
          );
        });
  }

  static openActionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onAction,
    required RoundedLoadingButtonController actionBtnController,
    String actionButtonText = 'Yes, Delete',
  }) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(50),
            elevation: 0,
            children: <Widget>[
              Text(title, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(
                height: 10,
              ),
              Text(message, style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w400)),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomButtons.submitButton(context,
                      buttonController: actionBtnController,
                      bgColor: Colors.redAccent,
                      text: actionButtonText == 'Yes, Delete' ? AppLocalizations.of(context).dialogYesDelete : actionButtonText,
                      width: 200,
                      onPressed: onAction,
                      borderRadius: 25),
                  const SizedBox(width: 10),
                  CustomButtons.submitButton(
                    context,
                    buttonController: RoundedLoadingButtonController(),
                    text: AppLocalizations.of(context).commonNo,
                    width: 100,
                    borderRadius: 25,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            ],
          );
        });
  }

  static openFormDialog(
    BuildContext context, {
    required Widget widget,
    num? horizontalPaddingPercentage,
    num? verticalPaddingPercentage,
  }) {
    final num hP = horizontalPaddingPercentage ?? 0.25;
    final num vP = verticalPaddingPercentage ?? 0.20;
    return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * hP,
              vertical: MediaQuery.of(context).size.height * vP,
            ),
            child: widget,
          );
        });
  }

  static openModalDialog(
    BuildContext context, {
    required Widget widget,
  }) {
    return showModalBottomSheet(
        showDragHandle: true,
        context: context,
        builder: (context) {
          return widget;
        });
  }

  static openFullScreenDialog(
    BuildContext context, {
    required Widget widget,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => widget),
    );
  }

  openNotificationDialog(
    BuildContext context, {
    required NotificationModel notification,
  }) {
    return showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          child: PointerInterceptor(
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0.5,
                title: Text(AppLocalizations.of(context).notificationsPreviewTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ))
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(notification.title, style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    HtmlBody(
                      content: notification.description,
                      isVideoEnabled: true,
                      isimageEnabled: true,
                      isIframeVideoEnabled: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static openResponsiveDialog(
    BuildContext context, {
    required Widget widget,
    double? verticalPaddingPercentage = 0.1,
  }) {
    if (!Responsive.isMobile(context)) {
      openFormDialog(context, widget: widget, verticalPaddingPercentage: verticalPaddingPercentage);
    } else {
      NextScreen.popup(context, widget);
    }
  }
}
