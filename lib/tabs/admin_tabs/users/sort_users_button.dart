import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'users.dart';

final CollectionReference colRef = FirebaseFirestore.instance.collection('users');

class SortUsersButton extends StatelessWidget {
  const SortUsersButton({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final sortText = ref.watch(sortByUsersTextProvider);

    return PopupMenuButton(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.sort_down,
              color: Colors.grey[800],
            ),
            Visibility(
              visible: Responsive.isMobile(context) ? false : true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Sort By - $sortText',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(Icons.keyboard_arrow_down)
                ],
              ),
            )
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return sortByUsers.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Text(e.value),
          );
        }).toList();
      },
      onSelected: (dynamic value) {
        ref.read(sortByUsersTextProvider.notifier).update((state) => sortByUsers[value].toString());

        if (value == 'all') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'new') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'old') {
          final newQuery = colRef.orderBy('created_at', descending: false);
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'admin') {
          final newQuery = colRef.where('role', arrayContains: 'admin');
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'author') {
          final newQuery = colRef.where('role', arrayContains: 'author');
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'disabled') {
          final newQuery = colRef.where('disabled', isEqualTo: true);
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'subscribed') {
          final newQuery = colRef.where('subscription', isNull: false);
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'android') {
          final newQuery = colRef.where('platform', isEqualTo: 'Android');
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
        if (value == 'ios') {
          final newQuery = colRef.where('platform', isEqualTo: 'iOS');
          ref.read(usersQueryProvider.notifier).update((state) => newQuery);
        }
      },
    );
  }
}
