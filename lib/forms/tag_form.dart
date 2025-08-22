import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/forms/course_form.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/tag.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';

class TagForm extends ConsumerStatefulWidget {
  const TagForm({Key? key, this.tag, this.shouldRefresh}) : super(key: key);

  final Tag? tag;

  // required for creating tags inside course form
  final bool? shouldRefresh;

  @override
  ConsumerState<TagForm> createState() => _TagFormState();
}

class _TagFormState extends ConsumerState<TagForm> with TextFields {
  late String _submitBtnText;
  late String _dialogText;

  var nameCtlr = TextEditingController();
  final btnCtlr = RoundedLoadingButtonController();
  var formKey = GlobalKey<FormState>();

  void handleSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        btnCtlr.start();
        _handleUpload();
      }
    } else {
      openTestingToast(context);
    }
  }
  

  _refreshTags (){
    if(widget.shouldRefresh == true){
      ref.invalidate(tagsProvider);
    }
  }

  _handleUpload() async {
    final navigator = Navigator.of(context);
    await FirebaseService().saveTag(_tagData());
    _refreshTags();
    _clearTextFields();
    btnCtlr.success();
    navigator.pop();
    if (!mounted) return;
    openSuccessToast(context, _dialogText);
  }

  Tag _tagData() {
    final String id = widget.tag?.id ?? FirebaseService.getUID('tags');
    final createdAt = DateTime.now();
    final tag = Tag(id: id, name: nameCtlr.text, createdAt: createdAt);
    return tag;
  }

  @override
  void initState() {
    _submitBtnText = widget.tag == null ? 'Create Tag' : 'Update Tag';
    _dialogText = widget.tag == null ? 'Created Successfully!' : 'Updated Successfully!';
    if (widget.tag != null) {
      nameCtlr.text = widget.tag!.name;
    }
    super.initState();
  }

  _clearTextFields() {
    if (widget.tag == null) {
      nameCtlr.clear();
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
              buildTextField(context, controller: nameCtlr, hint: 'Enter Tag Name', title: 'Tag Name *', hasImageUpload: false),
            ],
          ),
        ),
      ),
    );
  }
}
