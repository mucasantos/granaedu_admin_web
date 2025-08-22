import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../configs/constants.dart';
import '../../../mixins/appbar_mixin.dart';
import '../../../utils/reponsive.dart';
import 'sort_users_button.dart';
import '../../../mixins/textfields.dart';
import '../../../mixins/users_mixin.dart';
import 'search_users_textfield.dart';

final usersQueryProvider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('users').orderBy('created_at');
  return query;
});

final sortByUsersTextProvider = StateProvider<String>((ref) => sortByUsers.entries.first.value);
final searchUsersFieldProvider = Provider<TextEditingController>((ref) => TextEditingController());

class Users extends ConsumerWidget with UsersMixins, TextFields {
  const Users({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Users', buttons: [
            Visibility(
              visible: !Responsive.isMobile(context),
              child: SerachUsersTextField(ref: ref),
            ),
            const SizedBox(width: 10),
            SortUsersButton(ref: ref),
          ]),
          buildUsers(context, ref: ref, isMobile: Responsive.isMobile(context))
        ],
      ),
    );
  }
}
