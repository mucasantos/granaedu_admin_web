import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';

final userDataProvider = StateNotifierProvider<UserData, UserModel?>((ref) {
  return UserData();
});

class UserData extends StateNotifier<UserModel?> {
  UserData() : super(null);

  Future getData() async {
    final user = await FirebaseService().getUserData();
    state = user;
    debugPrint('Got User Data');

    if (user != null) {
      await SupabaseService().syncUserProfile(
        firebaseUid: user.id,
        email: user.email,
        name: user.name,
      );
    }
  }
}
