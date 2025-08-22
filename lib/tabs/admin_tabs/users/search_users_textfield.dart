import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/textfields.dart';

import '../../../configs/constants.dart';
import 'users.dart';

final CollectionReference colRef = FirebaseFirestore.instance.collection('users');

class SerachUsersTextField extends StatelessWidget with TextFields {
  const SerachUsersTextField({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final searchFieldCtlr = ref.watch(searchUsersFieldProvider);
    return SizedBox(
      width: 300,
      height: 40,
      child: buildSearchTextField(
        context,
        controller: searchFieldCtlr,
        hint: 'Search by email',
        onClear: () {
          searchFieldCtlr.clear();
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
          ref.read(sortByUsersTextProvider.notifier).update((state) => sortByUsers.values.first);
        },
        onSubmitted: (String value) {
          if (value.isNotEmpty) {
            // ignore: prefer_interpolation_to_compose_strings
            final newQuery = colRef.orderBy('email').startAt([value]).endAt([value + '\uf8ff']);
            ref.read(usersQueryProvider.notifier).update((state) => newQuery);
          }
        },
      ),
    );
  }
}
