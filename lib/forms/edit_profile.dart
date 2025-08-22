import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/author_info.dart';
import 'package:lms_admin/models/user_model.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../components/custom_buttons.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({Key? key, required this.user}) : super(key: key);

  final UserModel user;

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> with TextFields, UserMixin {
  final formKey = GlobalKey<FormState>();
  final btnController = RoundedLoadingButtonController();
  final nameCtlr = TextEditingController();

  var fbCtlr = TextEditingController();
  var twitterCtlr = TextEditingController();
  var jobTitleCtlr = TextEditingController();
  var websiteCtlr = TextEditingController();
  var bioCtlr = TextEditingController();

  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    nameCtlr.text = widget.user.name;
    fbCtlr.text = widget.user.authorInfo?.fb ?? '';
    twitterCtlr.text = widget.user.authorInfo?.twitter ?? '';
    websiteCtlr.text = widget.user.authorInfo?.website ?? '';
    bioCtlr.text = widget.user.authorInfo?.bio ?? '';
    jobTitleCtlr.text = widget.user.authorInfo?.jobTitle ?? '';
  }

  _pickImage() async {
    XFile? image = await AppService.pickImage(maxHeight: 300, maxWidth: 300);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'user_images');
      return imageUrl;
    } else {
      return widget.user.imageUrl;
    }
  }

  _handleSubmit() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.validate();
      btnController.start();
      final String? imageUrl = await _getImageUrl();
      await _updateDatabase(imageUrl);
      ref.invalidate(userDataProvider);

      await ref.read(userDataProvider.notifier).getData();
      btnController.reset();
      if (!mounted) return;
      CustomDialogs.openInfoDialog(context, 'Updated Successfully', '');
    }
  }

  Future _updateDatabase(String? imageUrl) async {
    await FirebaseService().updateUserProfile(widget.user, _prepareData(imageUrl));
  }

  Map<String, dynamic> _prepareData(String? imageUrl) {
    final AuthorInfo authorInfo = AuthorInfo(
      website: websiteCtlr.text.isEmpty ? null : websiteCtlr.text,
      bio: bioCtlr.text.isEmpty ? null : bioCtlr.text,
      fb: fbCtlr.text.isEmpty ? null : fbCtlr.text,
      twitter: twitterCtlr.text.isEmpty ? null : twitterCtlr.text,
      jobTitle: jobTitleCtlr.text.isEmpty ? null : jobTitleCtlr.text,
    );
    final authorData = AuthorInfo.getMap(authorInfo);
    final data = {'name': nameCtlr.text, 'image_url': imageUrl, 'author_info': authorData};
    return data;
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
          buttonController: btnController,
          text: 'Update',
          onPressed: _handleSubmit,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 30,
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
        ),
        elevation: 0.1,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20, top: 5),
              child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black,
                  ))),
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
              _profileImage(),
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(
                  context,
                  controller: nameCtlr,
                  hint: 'Enter Name',
                  title: 'Your Name *',
                  hasImageUpload: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(context,
                    controller: jobTitleCtlr, hint: 'Enter your job title', title: 'Work Title', hasImageUpload: false, validationRequired: false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(context,
                    controller: bioCtlr,
                    hint: 'Enter bio',
                    title: 'Bio',
                    hasImageUpload: false,
                    minLines: 2,
                    maxLines: null,
                    validationRequired: false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(context,
                    controller: websiteCtlr, hint: 'Your Website Url', title: 'Website', hasImageUpload: false, validationRequired: false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(context,
                    controller: fbCtlr, hint: 'Facebook account Url', title: 'Facebook', hasImageUpload: false, validationRequired: false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(context,
                    controller: twitterCtlr, hint: 'X account Url', title: 'X(Formly twitter)', hasImageUpload: false, validationRequired: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileImage() {
    return Center(
      child: InkWell(
        onTap: () => _pickImage(),
        child: getUserImage(
          user: widget.user,
          radius: 100,
          iconSize: 30,
          imagePath: _selectedImage?.path,
        ),
      ),
    );
  }
}
