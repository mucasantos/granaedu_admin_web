import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/forms/tag_form.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/mixins/tags_mixin.dart';

final tagQueryprovider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('tags').orderBy('created_at', descending: true);
  return query;
});

class Tags extends ConsumerWidget with TagsMixin {
  const Tags({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Tags', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Create Tag',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const TagForm(tag: null));
              },
            ),
          ]),
          buildTags(context, ref: ref)
        ],
      ),
    );
  }
}
