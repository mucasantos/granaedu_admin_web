import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';

final usersCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('users');
  return count;
});

final purchasesCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('purchases');
  return count;
});

final notificationsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('notifications');
  return count;
});

final reviewsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('reviews');
  return count;
});

final coursesCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCourseCount();
  return count;
});

final subscriberCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getSubscribedUsersCount();
  return count;
});

final enrolledCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getEnrolledUsersCount();
  return count;
});

final authorsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getAuthorsCount();
  return count;
});

final totalXPProvider = FutureProvider<int>((ref) async {
  final int count = await FirebaseService().getTotalXP();
  return count;
});

final averageStreakProvider = FutureProvider<double>((ref) async {
  final double avg = await FirebaseService().getAverageStreak();
  return avg;
});

final activeTodayProvider = FutureProvider<int>((ref) async {
  final int count = await FirebaseService().getDailyActiveUsersCount();
  return count;
});
