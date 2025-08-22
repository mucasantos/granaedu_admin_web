import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/app_config.dart';
import 'package:lms_admin/forms/tag_form.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/tag.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/tags.dart';
import '../utils/empty_with_image.dart';
import '../components/custom_buttons.dart';
import '../components/dialogs.dart';

mixin TagsMixin {
  Widget buildTags(
    BuildContext context, {
    required WidgetRef ref,
  }) {
    return FirestoreQueryBuilder(
      query: ref.watch(tagQueryprovider),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const EmptyPageWithImage(title: 'No tags found');
        }
        return _tagList(context, snapshot: snapshot, ref: ref);
      },
    );
  }

  Widget _tagList(BuildContext context, {required FirestoreQueryBuilderSnapshot snapshot, required WidgetRef ref}) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: snapshot.docs.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
            snapshot.fetchMore();
          }
          final List<Tag> tags = snapshot.docs.map((e) => Tag.fromFirestore(e)).toList();
          final Tag tag = tags[index];
          return _buildListItem(context, tag, index, ref);
        },
      ),
    );
  }

  ListTile _buildListItem(BuildContext context, Tag tag, int index, WidgetRef ref) {
    return ListTile(
      minVerticalPadding: 10,
      horizontalTitleGap: 20,
      leading: CircleAvatar(
        backgroundColor: AppConfig.titleBarColor,
        radius: 18,
        child: Text('${index + 1}'),
      ),
      title: Text(tag.name),
      trailing: Wrap(
        children: [
          CustomButtons.circleButton(context, icon: Icons.edit, tooltip: 'Edit', onPressed: () => _onEdit(context, tag)),
          const SizedBox(
            width: 8,
          ),
          CustomButtons.circleButton(context, icon: Icons.delete, tooltip: 'Delete', onPressed: () => _onDelete(context, tag, ref)),
        ],
      ),
    );
  }

  void _onDelete(context, Tag tag, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this tag?',
      message: 'Warning: This can not be undone.',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          deleteBtnController.start();
          await FirebaseService().deleteContent('tags', tag.id);
          deleteBtnController.success();
          Navigator.pop(context);
          openSuccessToast(context, "Deleted successfully!");
        }else{
          openTestingToast(context);
        }
      },
    );
  }

  void _onEdit(BuildContext context, Tag tag) {
    CustomDialogs.openResponsiveDialog(context, widget: TagForm(tag: tag));
  }
}
