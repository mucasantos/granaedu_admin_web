import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../../../mixins/user_mixin.dart';
import '../../../models/category.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../utils/reponsive.dart';

final filteredCategoriesProvider = StateProvider.autoDispose<List<Category>>((ref) => []);

class SetCategoryOrder extends ConsumerStatefulWidget {
  const SetCategoryOrder({Key? key}) : super(key: key);

  @override
  ConsumerState<SetCategoryOrder> createState() => _SetCategoryOrderState();
}

class _SetCategoryOrderState extends ConsumerState<SetCategoryOrder> {
  final btnController = RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final categories = ref.read(categoriesProvider);
      ref.read(filteredCategoriesProvider.notifier).update((state) => [...categories]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(filteredCategoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          buttonController: btnController,
          text: 'Update Order',
          width: 300,
          onPressed: () => _handleUpdate(context, ref, btnController),
        ),
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, categories, ref),
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final Category category = categories[index];
          return ReorderableDragStartListener(
            index: index,
            key: Key(index.toString()),
            child: ListTile(
              horizontalTitleGap: 20,
              key: Key(index.toString()),
              leading: CircleAvatar(
                radius: 20,
                child: Text('${index + 1}'),
              ),
              title: Text(category.name),
            ),
          );
        },
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex, List<Category> categories, WidgetRef ref) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Category category = categories.removeAt(oldIndex);
    categories.insert(newIndex, category);
    ref.read(filteredCategoriesProvider.notifier).update((state) => [...categories]);
  }

  Future _handleUpdate(BuildContext context, WidgetRef ref, RoundedLoadingButtonController btnController) async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      btnController.start();
      final categories = ref.read(filteredCategoriesProvider);
      final navigator = Navigator.of(context);
      await FirebaseService().updateCategoriesOrder(categories);
      await ref.read(categoriesProvider.notifier).getCategories();
      btnController.success();
      navigator.pop();
      if (!context.mounted) return;
      openSuccessToast(context, 'Updated succesfully');
    } else {
      openTestingToast(context);
    }
  }
}
