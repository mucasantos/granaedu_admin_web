import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRoles { admin, author, guest, none }

final userRoleProvider = StateProvider<UserRoles>((ref) => UserRoles.none);
