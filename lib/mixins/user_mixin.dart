import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/models/course.dart';
import 'package:lms_admin/models/user_model.dart';

mixin UserMixin {
  Container getUserImage({
    required UserModel? user,
    double radius = 30,
    double iconSize = 18,
    String? imagePath,
  }) {
    return Container(
      height: radius,
      width: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
        image: _decorationImage(imagePath, user),
      ),
      child: Visibility(
        visible: user == null || user.imageUrl == null,
        child: Icon(
          LineIcons.user,
          size: iconSize,
        ),
      ),
    );
  }

  DecorationImage? _decorationImage(String? imagePath, UserModel? user) {
    if (imagePath != null) {
      return DecorationImage(image: NetworkImage(imagePath));
    } else if (user != null && user.imageUrl != null) {
      return DecorationImage(image: CachedNetworkImageProvider(user.imageUrl!));
    } else {
      return null;
    }
  }

  static Container getUserImageByUrl({
    required String? imageUrl,
    double radius = 30,
    double iconSize = 18,
  }) {
    return Container(
      height: radius,
      width: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
        image: imageUrl != null ? DecorationImage(image: CachedNetworkImageProvider(imageUrl)) : null,
      ),
      child: Visibility(
        visible: imageUrl == null,
        child: Icon(
          LineIcons.user,
          size: iconSize,
        ),
      ),
    );
  }

  String getUserRole(UserModel? user) {
    String role = '';
    if (user != null && user.role != null && user.role!.isNotEmpty) {
      if (user.role!.contains('admin')) {
        role = 'Admin';
      } else if (user.role!.contains('author')) {
        role = 'Author';
      } else {
        role = 'User';
      }
    } else {
      role = 'Tester';
    }

    return role;
  }

  String getUserName(UserModel? user) {
    if (user != null) {
      return user.name;
    } else {
      return 'John Doe';
    }
  }

  static bool hasAccess(UserModel? user) {
    if (user != null && (user.role!.contains('admin') || user.role!.contains('author'))) {
      return true;
    } else {
      return false;
    }
  }

  static bool hasAdminAccess(UserModel? user) {
    if (user != null && (user.role!.contains('admin'))) {
      return true;
    } else {
      return false;
    }
  }

  static bool isAuthor(UserModel? user, Course course) {
    if (user != null && course.author!.id == user.id) {
      return true;
    } else {
      return false;
    }
  }
}
