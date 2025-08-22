import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';

class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({Key? key, required this.category}) : super(key: key);

  final Category? category;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> with TextFields {
  late String _submitBtnText;
  late String _dialogText;

  var nameCtlr = TextEditingController();
  var thumbnailUrlCtlr = TextEditingController();
  final btnCtlr = RoundedLoadingButtonController();
  var formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  void _onPickImage() async {
    XFile? image = await AppService.pickImage();
    if (image != null) {
      _selectedImage = image;
      thumbnailUrlCtlr.text = image.name;
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'category_thumbnails');
      return imageUrl;
    } else {
      return thumbnailUrlCtlr.text;
    }
  }

  void handleSubmit() async {
    if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        btnCtlr.start();
        final String? imageUrl = await _getImageUrl();
        if (imageUrl != null) {
          thumbnailUrlCtlr.text = imageUrl;
          _handleUpload(imageUrl);
        } else {
          _selectedImage = null;
          thumbnailUrlCtlr.clear();
          setState(() {});
          btnCtlr.reset();
        }
      }
    } else {
      openTestingToast(context);
    }
  }

  _handleUpload(String imageUrl) async {
    final navigator = Navigator.of(context);
    await FirebaseService().saveCategory(_categoryData());
    _clearTextFields();
    await ref.read(categoriesProvider.notifier).getCategories();
    btnCtlr.success();
    navigator.pop();
    if (!mounted) return;
    openSuccessToast(context, _dialogText);
  }

  Category _categoryData() {
    final String id = widget.category?.id ?? FirebaseService.getUID('categories');
    final createdAt = widget.category?.createdAt ?? DateTime.now().toUtc();
    final int orderIndex = widget.category?.orderIndex ?? 0;

    final Category category = Category(
      id: id,
      name: nameCtlr.text,
      thumbnailUrl: thumbnailUrlCtlr.text,
      createdAt: createdAt,
      orderIndex: orderIndex
    );
    return category;
  }

  @override
  void initState() {
    _submitBtnText = widget.category == null ? 'Upload Category' : 'Update Category';
    _dialogText = widget.category == null ? 'Uploaded Successfully!' : 'Updated Successfully!';
    if (widget.category != null) {
      nameCtlr.text = widget.category!.name;
      thumbnailUrlCtlr.text = widget.category!.thumbnailUrl;
    }
    super.initState();
  }

  _clearTextFields() {
    if (widget.category == null) {
      nameCtlr.clear();
      thumbnailUrlCtlr.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          width: 300,
          buttonController: btnCtlr,
          text: _submitBtnText,
          onPressed: handleSubmit,
        ),
      ),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(context, controller: nameCtlr, hint: 'Category Name', title: 'Category Name *', hasImageUpload: false),
              const SizedBox(
                height: 30,
              ),
              buildTextField(context,
                  controller: thumbnailUrlCtlr,
                  hint: 'Enter image URL or select image',
                  title: 'Thumbnail Image *',
                  hasImageUpload: true,
                  onPickImage: _onPickImage),
            ],
          ),
        ),
      ),
    );
  }
}
