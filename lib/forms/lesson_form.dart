import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/components/questions.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/forms/quiz_form.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/radio_options.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/lesson.dart';
import 'package:lms_admin/models/question.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../components/text_editors/html_editor.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';

class LessonForm extends ConsumerStatefulWidget {
  const LessonForm({Key? key, required this.courseDocId, required this.sectionDocId, required this.lesson}) : super(key: key);

  final String courseDocId;
  final String sectionDocId;
  final Lesson? lesson;

  @override
  ConsumerState<LessonForm> createState() => _LessonFormState();
}

class _LessonFormState extends ConsumerState<LessonForm> with TextFields {
  var nameCtlr = TextEditingController();
  var videoCtlr = TextEditingController();
  final descriptionCtlr = HtmlEditorController();

  final btnCtlr = RoundedLoadingButtonController();
  var formKey = GlobalKey<FormState>();

  String _contentType = lessonTypes.keys.elementAt(0);

  @override
  void initState() {
    if (widget.lesson != null) {
      _contentType = widget.lesson!.contentType;
      nameCtlr.text = widget.lesson!.name;
      videoCtlr.text = widget.lesson?.videoUrl ?? '';

      //updating questions from database
      Future.microtask(() {
        List<Question> questions = ref.read(questionListProvider);
        questions = widget.lesson?.questions ?? [];
        ref.read(questionListProvider.notifier).update((state) => [...questions]);
      });
    }
    super.initState();
  }

  void handleSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        final navigator = Navigator.of(context);

        //quiz and article validation
        bool isValidated = await _contentTypeValidation();
        if (isValidated) {
          btnCtlr.start();
          await _handleUpload();
          btnCtlr.success();
          navigator.pop();
        } else {
          debugPrint('Content validation faild');
        }
      }
    } else {
      openTestingToast(context);
    }
  }

  Future<bool> _contentTypeValidation() async {
    bool validated = false;
    if (_contentType == lessonTypes.keys.elementAt(1)) {
      final String description = await descriptionCtlr.getText();
      if (description.isEmpty) {
        validated = false;
        if (mounted) {
          openFailureToast(context, 'Article is empty');
        }
      } else {
        validated = true;
      }
    } else if (_contentType == lessonTypes.keys.elementAt(2)) {
      final questions = ref.read(questionListProvider);
      if (questions.isEmpty) {
        openFailureToast(context, 'No questions found');
        validated = false;
      } else {
        validated = true;
      }
    } else {
      validated = true;
    }

    return validated;
  }

  Lesson _lessonData(String? description) {
    final String id = widget.lesson?.id ?? FirebaseService.getUID('lessons');
    final questions = ref.read(questionListProvider);
    Lesson lesson = Lesson(
      id: id,
      name: nameCtlr.text,
      order: 0,
      contentType: _contentType,
      videoUrl: videoCtlr.text,
      description: description,
      questions: questions.isEmpty ? null : questions,
    );

    return lesson;
  }

  Future _handleUpload() async {
    final String? description = _contentType == lessonTypes.keys.elementAt(1) ? await descriptionCtlr.getText() : null;
    final Lesson lesson = _lessonData(description);
    await FirebaseService().saveLesson(widget.courseDocId, widget.sectionDocId, lesson);
    if (widget.lesson == null) {
      await FirebaseService().updateLessonCountInCourse(widget.courseDocId, count: 1);
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
          text: widget.lesson == null ? 'Create Lesson' : 'Update Lesson',
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
              buildTextField(context, controller: nameCtlr, hint: 'Enter Lesson Title', title: 'Lesson Title *', hasImageUpload: false),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: RadioOptions(
                  contentType: _contentType,
                  options: lessonTypes,
                  icon: LineIcons.list,
                  title: 'Lesson Type',
                  onChanged: (value) {
                    setState(() {
                      _contentType = value;
                    });
                  },
                ),
              ),
              Visibility(
                visible: _contentType == lessonTypes.keys.elementAt(0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: buildTextField(
                    context,
                    controller: videoCtlr,
                    hint: 'Enter Video Url',
                    title: 'Video *',
                    hasImageUpload: false,
                    urlValidationRequired: true,
                  ),
                ),
              ),
              Visibility(
                visible: _contentType == lessonTypes.keys.elementAt(1),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: CustomHtmlEditor(
                      controller: descriptionCtlr,
                      initialText: widget.lesson?.description ?? '',
                      height: 400,
                      hint: 'Enter article details',
                      title: 'Article *',
                    )),
              ),
              Visibility(
                visible: _contentType == lessonTypes.keys.elementAt(2),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Questions()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
