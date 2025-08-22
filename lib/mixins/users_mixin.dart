import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../tabs/admin_tabs/users/users_data_source.dart';
import '../providers/user_data_provider.dart';
import '../tabs/admin_tabs/users/users.dart';
import '../utils/empty_with_image.dart';

final List<String> _columns = [
  'User',
  'Email',
  'Enrolled Courses',
  'Subscription',
  'Platform',
  'Actions',
];

const _itemsPerPage = 10;

mixin UsersMixins {
  Widget buildUsers(
    BuildContext context, {
    required WidgetRef ref,
    required isMobile,
  }) {
    return FirestoreQueryBuilder(
      pageSize: 10,
      query: ref.watch(usersQueryProvider),
      builder: (context, snapshot, _) {
        List<UserModel> users = [];
        users = snapshot.docs.map((e) => UserModel.fromFirebase(e)).toList();
        DataTableSource source = UsersDataSource(users, context, ref);

        if (snapshot.isFetching) return const CircularProgressIndicator.adaptive();
        if (snapshot.docs.isEmpty) return const EmptyPageWithImage(title: 'No users found');

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PaginatedDataTable2(
              rowsPerPage: _itemsPerPage - 1,
              source: source,
              empty: const Center(child: Text('No Users Found')),
              minWidth: 1200,
              wrapInCard: false,
              horizontalMargin: 20,
              columnSpacing: 20,
              fit: FlexFit.tight,
              lmRatio: 2,
              dataRowHeight: isMobile ? 90 : 70,
              onPageChanged: (_) => snapshot.fetchMore(),
              columns: _columns.map((e) => DataColumn(label: Text(e))).toList(),
            ),
          ),
        );
      },
    );
  }

  bool isExpired(UserModel user) {
    final DateTime expireDate = user.subscription!.expireAt;
    final DateTime now = DateTime.now();
    final difference = expireDate.difference(now).inDays;
    if (difference >= 0) {
      return false;
    } else {
      return true;
    }
  }

  Text getEmail(UserModel user, WidgetRef ref) {
    final adminUser = ref.watch(userDataProvider);
    if (adminUser == null) {
      final List filteredEmail = user.email.split('@');
      return Text('*********@${filteredEmail.last}');
    }
    return Text(user.email);
  }

  RichText getSubscription(context, UserModel user) {
    if (user.subscription != null) {
      // ignore: no_leading_underscores_for_local_identifiers
      final bool _isExpired = isExpired(user);
      return RichText(
        text: TextSpan(
          text: user.subscription?.plan,
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            _isExpired
                ? const TextSpan(text: ' (Expired)', style: TextStyle(color: Colors.red))
                : const TextSpan(text: ' (Active)', style: TextStyle(color: Colors.green))
          ],
        ),
      );
    } else {
      return RichText(text: const TextSpan(text: 'None'));
    }
  }
}
