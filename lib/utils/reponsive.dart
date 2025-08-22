import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 850;

  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width < 1100 && MediaQuery.of(context).size.width >= 850;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100 && MediaQuery.of(context).size.width <= 1500;

  static bool isDesktopLarge(BuildContext context) => MediaQuery.of(context).size.width > 1500;

  static int getCrossAxisCount(BuildContext context) {
    if (isDesktopLarge(context)) {
      return 4;
    } else if (isDesktop(context)) {
      return 3;
    } else if (isMobile(context)) {
      return 1;
    } else {
      return 2;
    }
  }

  static double getChildAspectRatio(BuildContext context) {
    if (isDesktopLarge(context)) {
      return 3;
    }
    if (isDesktop(context)) {
      return 2.0;
    } else if (isMobile(context)) {
      return 3.0;
    } else {
      return 2.2;
    }
  }

  // static double getChildAspectRatio(BuildContext context) {
  //   if (isDesktopLarge(context)) {
  //     return 2.1;
  //   }
  //   if (isDesktop(context)) {
  //     return 2.0;
  //   } else if (isMobile(context)) {
  //     return 3.0;
  //   } else {
  //     return 2.2;
  //   }
  // }
}
