import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/components/text_editors/html_editor.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/components/category_dropdown.dart';
import 'package:lms_admin/mixins/course_mixin.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/components/radio_options.dart';
import 'package:lms_admin/models/app_settings_model.dart';
import 'package:lms_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/sections_mixin.dart';
import 'package:lms_admin/components/tags_dropdown.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/author.dart';
import 'package:lms_admin/models/course.dart';
import 'package:lms_admin/models/course_meta.dart';
import 'package:lms_admin/models/tag.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/course_preview.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/dashboard/dashboard_providers.dart';

final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  List<Tag> tags = await FirebaseService().getTags();
  return tags;
});

class CourseForm extends ConsumerStatefulWidget {
  const CourseForm({Key? key, required this.course, this.isAuthorTab}) : super(key: key);

  final Course? course;
  final bool? isAuthorTab;

  @override
  ConsumerState<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends ConsumerState<CourseForm> with TextFields, SectionsMixin, CourseMixin {
  var nameCtlr = TextEditingController();
  var thumbnailUrlCtlr = TextEditingController();
  var videoUrlCtlr = TextEditingController();
  var durationCtlr = TextEditingController();
  var summaryCtlr = TextEditingController();
  var learningsCtlr = TextEditingController();
  var requirementsCtlr = TextEditingController();
  var languageCtlr = TextEditingController();

  final HtmlEditorController descriptionCtlr = HtmlEditorController();

  List _learnings = [];
  List _requirements = [];
  String _pricingStatus = priceStatus.entries.first.key;

  final _publishBtnCtlr = RoundedLoadingButtonController();
  final _draftBtnCtlr = RoundedLoadingButtonController();

  var formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  String? _selectedCategoryId;
  List _selectedTagIDs = [];

  late Course? _course;

  void _onPickImage() async {
    XFile? image = await AppService.pickImage();
    if (image != null) {
      _selectedImage = image;
      thumbnailUrlCtlr.text = image.name;
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'course_thumbnails');
      return imageUrl;
    } else {
      return thumbnailUrlCtlr.text;
    }
  }

  void _handleSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        _publishBtnCtlr.start();
        final String? imageUrl = await _getImageUrl();
        if (imageUrl != null) {
          thumbnailUrlCtlr.text = imageUrl;
          await _handleUpload(setCourseStatus(course: _course, isAuthorTab: widget.isAuthorTab, isDraft: false));
          ref.invalidate(coursesCountProvider);
          _publishBtnCtlr.reset();
          if (!mounted) return;
          openSuccessToast(context, 'Published successfully!');
        } else {
          _selectedImage = null;
          thumbnailUrlCtlr.clear();
          setState(() {});
          _publishBtnCtlr.reset();
        }
      }
    } else {
      openTestingToast(context);
    }
  }

  void _handleDraftSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      _draftBtnCtlr.start();
      final String? imageUrl = await _getImageUrl();
      thumbnailUrlCtlr.text = imageUrl ?? '';
      //draft
      await _handleUpload(setCourseStatus(course: _course, isAuthorTab: widget.isAuthorTab, isDraft: true));
      _draftBtnCtlr.reset();
      if (!mounted) return;
      openSuccessToast(context, 'Drafts saved!');
    } else {
      openTestingToast(context);
    }
  }

  Future _handleUpload(String courseStatus) async {
    final String description = await descriptionCtlr.getText();
    final int lessonsCount = await _getLessonCount();
    final course = _courseData(courseStatus, description, lessonsCount);
    await FirebaseService().saveCourse(course);
    setState(() {
      _course = course;
    });
  }

  Course _courseData(String courseStatus, String description, int lessonsCount) {
    final String id = _course?.id ?? FirebaseService.getUID('courses');
    final createdAt = _course?.createdAt ?? DateTime.now().toUtc();
    final updatedAt = _course == null ? null : DateTime.now().toUtc();
    final String name = nameCtlr.text.isEmpty ? 'Untitled' : nameCtlr.text;
    final String thumbnail = thumbnailUrlCtlr.text.isEmpty ? '' : thumbnailUrlCtlr.text;
    final String? video = videoUrlCtlr.text.isEmpty ? null : videoUrlCtlr.text;
    final String priceStatus = _pricingStatus;
    final double rating = _course?.rating ?? 0.0;
    final int studentsCount = _course?.studentsCount ?? 0;
    final String? duration = durationCtlr.text.isEmpty ? null : durationCtlr.text;
    final String? summary = summaryCtlr.text.isEmpty ? null : summaryCtlr.text;
    final String? categoriyId = _selectedCategoryId;
    final String? language = languageCtlr.text.isEmpty ? null : languageCtlr.text;

    //Author Data
    final Author? author = _authorData();

    //Course Meta Data
    final CourseMeta meta = CourseMeta(
      description: description,
      duration: duration,
      learnings: _learnings,
      requirements: _requirements,
      summary: summary,
      language: language,
    );

    final Course course = Course(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: name,
      categoryId: categoriyId,
      thumbnailUrl: thumbnail,
      tagIDs: _selectedTagIDs,
      videoUrl: video,
      status: courseStatus,
      author: author,
      priceStatus: priceStatus,
      rating: rating,
      studentsCount: studentsCount,
      courseMeta: meta,
      lessonsCount: lessonsCount,
    );

    return course;
  }

  Future<int> _getLessonCount() async {
    if (_course != null) {
      final int count = await FirebaseService().getLessonsCountFromCourse(_course!.id);
      return count;
    } else {
      return 0;
    }
  }

  Author? _authorData() {
    Author? author;
    final user = ref.read(userDataProvider);
    if (user != null) {
      if (_course?.author == null) {
        author = Author(id: user.id, name: user.name, imageUrl: user.imageUrl);
      } else {
        author = Author(id: _course!.author!.id, name: _course!.author!.name, imageUrl: _course!.author!.imageUrl);
      }
    }
    return author;
  }

  @override
  void initState() {
    if (widget.course != null) {
      _course = widget.course;
      nameCtlr.text = _course?.name ?? '';
      thumbnailUrlCtlr.text = _course?.thumbnailUrl ?? '';
      videoUrlCtlr.text = _course?.videoUrl ?? '';
      _selectedCategoryId = _course?.categoryId;
      _selectedTagIDs = _course?.tagIDs ?? [];
      _pricingStatus = _course?.priceStatus ?? priceStatus.entries.first.key;
      durationCtlr.text = _course?.courseMeta.duration ?? '';
      summaryCtlr.text = _course?.courseMeta.summary ?? '';
      languageCtlr.text = _course?.courseMeta.language ?? '';
      _learnings = _course?.courseMeta.learnings ?? [];
      _requirements = _course?.courseMeta.requirements ?? [];
    } else {
      _course = null;
    }
    super.initState();
  }

  void _handlePreview() async {
    final String description = await descriptionCtlr.getText();
    final int lessonsCount = await _getLessonCount();
    final course = _courseData('', description, lessonsCount);
    if (!mounted) return;
    CustomDialogs.openFormDialog(context,
        widget: PointerInterceptor(child: CoursePreview(course: course)), verticalPaddingPercentage: 0.02, horizontalPaddingPercentage: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 70,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.black,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CustomButtons.customOutlineButton(context, icon: Icons.remove_red_eye, text: 'Preview', onPressed: () => _handlePreview()),
                const SizedBox(
                  width: 10,
                ),
                Visibility(
                  visible: _course == null || _course?.status == courseStatus.keys.elementAt(0),
                  child: CustomButtons.submitButton(context,
                      buttonController: _draftBtnCtlr,
                      text: 'Save Draft',
                      onPressed: _handleDraftSubmit,
                      borderRadius: 20,
                      width: 140,
                      height: 45,
                      bgColor: Colors.blueGrey.shade300),
                ),
                const SizedBox(
                  width: 10,
                ),
                CustomButtons.submitButton(
                  context,
                  buttonController: _publishBtnCtlr,
                  text: widget.isAuthorTab != null && widget.isAuthorTab == true ? 'Submit' : 'Publish',
                  onPressed: _handleSubmit,
                  borderRadius: 20,
                  width: 120,
                  height: 45,
                )
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.isMobile(context) ? const EdgeInsets.all(20) : const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: buildTextField(context, controller: nameCtlr, hint: 'Enter Course Title', title: 'Course Title *', hasImageUpload: false),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: CategoryDropdown(
                      selectedCategoryId: _selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              buildTextField(
                context,
                controller: thumbnailUrlCtlr,
                hint: 'Enter image URL or select image',
                title: 'Preview Image *',
                hasImageUpload: true,
                onPickImage: _onPickImage,
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: videoUrlCtlr,
                hint: 'Enter video url',
                title: 'Video Preview',
                hasImageUpload: false,
                validationRequired: false,
              ),
              const SizedBox(height: 30),
              buildSection(context, courseId: _course?.id, isMobile: Responsive.isMobile(context), ref: ref),
              const SizedBox(height: 30),
              tags.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, x) => Container(),
                data: (data) => TagsDropdown(
                  selectedTagIDs: _selectedTagIDs,
                  tags: data,
                  onAdd: (value) => setState(() => _selectedTagIDs.add(value)),
                  onRemove: (value) => setState(() => _selectedTagIDs.remove(value)),
                ),
              ),
              const SizedBox(height: 30),
              actionTextField(context,
                  controller: requirementsCtlr,
                  hint: 'Enter requirements one by one',
                  title: 'Course Requirements',
                  list: _requirements, onSubmitted: (String value) {
                setState(() {
                  if (!_requirements.contains(value) && value.isNotEmpty) {
                    _requirements.add(value);
                    requirementsCtlr.clear();
                  }
                });
              }, onDelete: (value) {
                setState(() {
                  _requirements.remove(value);
                });
              }),
              const SizedBox(
                height: 30,
              ),
              actionTextField(context,
                  controller: learningsCtlr,
                  hint: 'Enter learnings one by one',
                  title: 'What User Will Learn?',
                  list: _learnings, onSubmitted: (String value) {
                setState(() {
                  if (!_learnings.contains(value) && value.isNotEmpty) {
                    _learnings.add(value);
                    learningsCtlr.clear();
                  }
                });
              }, onDelete: (value) {
                setState(() {
                  _learnings.remove(value);
                });
              }),
              const SizedBox(
                height: 30,
              ),
              Consumer(
                builder: (context, ref, child) {
                  final settings = ref.watch(appSettingsProvider);
                  final LicenseType license = settings.value?.license ?? LicenseType.none;
                  final bool isExtendedLicense = license == LicenseType.extended;

                  return RadioOptions(
                    contentType: _pricingStatus,
                    onChanged: (value) {
                      if (isExtendedLicense) {
                        setState(() => _pricingStatus = value);
                      } else {
                        openFailureToast(context, 'Extended license is required');
                      }
                    },
                    options: priceStatus,
                    title: 'Course Pricing',
                    icon: LineIcons.dollarSign,
                  );
                },
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Expanded(
                      child: buildTextField(context,
                          controller: durationCtlr, hint: 'Enter course duration', title: 'Course Duration *', hasImageUpload: false)),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                      child: buildTextField(context,
                          controller: languageCtlr, hint: 'Enter course language', title: 'Course Language *', hasImageUpload: false)),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              buildTextField(
                context,
                controller: summaryCtlr,
                hint: 'Enter Course Summary',
                title: 'Course Summary *',
                hasImageUpload: false,
                maxLines: null,
                validationRequired: true,
                minLines: 3,
              ),
              const SizedBox(
                height: 30,
              ),
              CustomHtmlEditor(
                title: 'Course Description',
                height: 450,
                controller: descriptionCtlr,
                initialText: _course?.courseMeta.description ?? '',
                hint: 'Enter description',
              ),
              const SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}
