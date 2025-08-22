import 'package:flutter/cupertino.dart';
import 'package:line_icons/line_icons.dart';

// --------- Don't edit these -----------

const String notificationTopicForAll = 'all';

const Map<int, List<dynamic>> menuList = {
  0: ['Dashboard', LineIcons.pieChart],
  1: ['Courses', LineIcons.book],
  2: ['Featured', LineIcons.bomb],
  3: ['Categories', CupertinoIcons.grid],
  4: ['Tags', LineIcons.tags],
  5: ['Reviews', LineIcons.starAlt],
  6: ['Users', LineIcons.userFriends],
  7: ['Notifications', LineIcons.bell],
  8: ['Purchases', LineIcons.receipt],
  9: ['Ads', LineIcons.dollarSign],
  10: ['Settings', CupertinoIcons.settings],
 };

const Map<int, List<dynamic>> menuListAuthor = {
  0: ['Dashboard', LineIcons.pieChart],
  1: ['My Courses', LineIcons.book],
  2: ['Reviews', LineIcons.starAlt],
};

const Map<String, String> courseStatus = {'draft': 'Draft', 'pending': 'Pending', 'live': 'Live', 'archive': 'Archived'};

const Map<String, String> lessonTypes = {'video': 'Video', 'article': 'Article', 'quiz': 'Quiz'};

const Map<String, String> priceStatus = {'free': 'Free', 'premium': 'Premium'};

const Map<String, String> sortByCourse = {
  'all': 'All',
  'live': 'Published',
  'draft': 'Drafts',
  'pending': 'Pending',
  'archive': 'Archived',
  'featured': 'Featured Courses',
  'new': 'Newest First',
  'old': 'Oldest First',
  'free': 'Free Courses',
  'premium': 'Premium Courses',
  'high-rating': 'High Rating',
  'low-rating': 'Low Rating',
  'category': 'Category',
  'author': 'Author',
};

const Map<String, String> sortByUsers = {
  'all': 'All',
  'new': 'Newest First',
  'old': 'Oldest First',
  'admin': 'Admins',
  'author': 'Authors',
  'disabled': "Disabled Users",
  'subscribed': "Subscribed Users",
  'android': 'Android Users',
  'ios': 'iOS Users'
};

const Map<String, String> sortByReviews = {
  'all': 'All',
  'high-rating': 'High to Low Rating',
  'low-rating': 'Low to High Rating',
  'new': 'Newest First',
  'old': 'Oldest First',
  'course': 'Course'
};

const Map<String, String> sortByPurchases = {
  'all': 'All',
  'new': 'Newest First',
  'old': 'Oldest First',
  'active': 'Active',
  'expired': 'Expired',
  'android': 'Android Platform',
  'ios': 'iOS Platform',
};

const Map<String, String> userMenus = {
  'edit': 'Edit Profile',
  'password': 'Change Password',
  'logout': 'Logout',
};
