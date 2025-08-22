import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/mixins/categories_mixin.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/tabs/admin_tabs/categories/set_order_category.dart';
import '../../../forms/category_form.dart';

class Categories extends ConsumerWidget with CategoriesMixin {
  const Categories({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Categories', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: LineIcons.sortAmountDown,
              text: 'Set Order',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const SetCategoryOrder());
              },
            ),
            const SizedBox(width: 10),
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Add Category',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const CategoryForm(category: null));
              },
            ),
          ]),
          buildCategories(context, ref: ref)
        ],
      ),
    );
  }
}
