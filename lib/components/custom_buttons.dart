import 'package:flutter/material.dart';
import 'package:lms_admin/configs/app_config.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

class CustomButtons {
  static OutlinedButton customOutlineButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color bgColor = Colors.transparent,
    Color foregroundColor = AppConfig.themeColor,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(15),
          backgroundColor: bgColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          )),
      icon: Icon(
        icon,
      ),
      label: Visibility(
        visible: !Responsive.isMobile(context),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foregroundColor),
        ),
      ),
      onPressed: onPressed,
    );
  }

  static RoundedLoadingButton submitButton(
    BuildContext context, {
    required RoundedLoadingButtonController buttonController,
    required String text,
    required VoidCallback onPressed,
    double? borderRadius,
    double? width,
    double? height,
    double? elevation,
    Color? bgColor,
  }) {
    return RoundedLoadingButton(
      onPressed: onPressed,
      animateOnTap: false,
      color: bgColor ?? Theme.of(context).primaryColor,
      width: width ?? MediaQuery.of(context).size.width,
      elevation: 0,
      height: height ?? 50,
      borderRadius: borderRadius ?? 0,
      controller: buttonController,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    );
  }

  static TextButton normalButton(
    BuildContext context, {
    required String text,
    Color? bgColor,
    double? radius,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
          backgroundColor: bgColor ?? Theme.of(context).primaryColor,
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius ?? 25))),
      child: Text(
        'Okay',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  static CircleAvatar circleButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    Color? bgColor,
    double? radius,
    String? tooltip,
    Color? iconColor,
  }) {
    return CircleAvatar(
      radius: radius ?? 16,
      backgroundColor: bgColor ?? Colors.grey.shade300,
      child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: iconColor ?? Theme.of(context).primaryColor,
            size: 16,
          )),
    );
  }
}
