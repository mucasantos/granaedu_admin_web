import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/lessons_mixin.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/section.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../forms/lesson_form.dart';
import '../forms/section_form.dart';
import '../providers/user_data_provider.dart';
import 'appbar_mixin.dart';
import '../components/custom_buttons.dart';
import '../components/dialogs.dart';

final isSectionExpnadedProvider = StateProvider.autoDispose.family<bool, String>((ref, sectionId) => false);

mixin SectionsMixin {
  Widget buildSection(
    BuildContext context, {
    required String? courseId,
    required bool isMobile,
    required WidgetRef ref,
  }) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Build Course', buttons: [
            CustomButtons.customOutlineButton(context, icon: Icons.add, text: 'Create Section', onPressed: () {
              if (courseId != null) {
                CustomDialogs.openResponsiveDialog(
                  context,
                  widget: SectionForm(courseId: courseId, section: null),
                );
              } else {
                openFailureToast(context, 'Save the course to drafts before creating sections');
              }
            }),
          ]),
          const SizedBox(
            height: 10,
          ),
          buildSectionList(courseDocId: courseId, isMobile: isMobile, ref: ref),
        ],
      ),
    );
  }

  Widget buildSectionList({
    required String? courseDocId,
    required bool isMobile,
    required WidgetRef ref,
    bool isPreview = false,
  }) {
    if (courseDocId == null) return const Center(child: Text('No sections found'));
    return FirestoreQueryBuilder(
      query: FirebaseService.sectionsQuery(courseDocId),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const Center(child: Text('No sections found'));
        }
        return _sectionList(context, snapshot: snapshot, courseDocId: courseDocId, isMobile: isMobile, ref: ref, isPreview: isPreview);
      },
    );
  }

  Widget _sectionList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required String courseDocId,
    required bool isMobile,
    required WidgetRef ref,
    required bool isPreview,
  }) {
    return ReorderableListView.builder(
      physics: isPreview ? const NeverScrollableScrollPhysics() : null,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) => _onReorder(context, oldIndex, newIndex, snapshot, courseDocId, ref),
      padding: EdgeInsets.all(isPreview ? 0 : 20),
      itemCount: snapshot.docs.length,
      shrinkWrap: true,
      itemBuilder: (BuildContext listContext, int index) {
        if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
          snapshot.fetchMore();
        }
        final List<Section> sections = snapshot.docs.map((e) => Section.fromFiresore(e)).toList();
        final Section section = sections[index];
        return _buildListItem(context, section, courseDocId, isMobile, index, ref, isPreview);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Section section,
    String courseDocId,
    bool isMobile,
    int index,
    WidgetRef ref,
    bool isPreview,
  ) {
    final bool isExpanded = ref.watch(isSectionExpnadedProvider(section.id));
    return ReorderableDragStartListener(
      enabled: !isPreview,
      index: index,
      key: Key(index.toString()),
      child: ExpansionTile(
        childrenPadding: const EdgeInsets.symmetric(vertical: 30),
        tilePadding: const EdgeInsets.all(15),
        leading: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isExpanded == false
                  ? const RotationTransition(turns: AlwaysStoppedAnimation(0.25), child: Icon(Icons.add))
                  : const RotationTransition(turns: AlwaysStoppedAnimation(0), child: Icon(Icons.remove)),
            ),
            const SizedBox(
              width: 20,
            ),
            Visibility(visible: !isPreview, child: const Icon(Icons.drag_handle)),
          ],
        ),
        trailing: Visibility(
          visible: !isPreview,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CustomButtons.customOutlineButton(
                context,
                icon: Icons.add,
                text: 'Add Lesson',
                onPressed: () => CustomDialogs.openResponsiveDialog(
                  context,
                  verticalPaddingPercentage: 0.02,
                  widget: LessonForm(
                    courseDocId: courseDocId,
                    sectionDocId: section.id,
                    lesson: null,
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              CustomButtons.circleButton(
                context,
                icon: Icons.edit,
                tooltip: 'edit section',
                onPressed: () => _onEdit(context, courseDocId, section),
              ),
              const SizedBox(width: 8),
              CustomButtons.circleButton(
                context,
                icon: Icons.delete,
                tooltip: 'edit section',
                onPressed: () => _onDeleteSection(context, courseDocId, section.id, ref),
              ),
            ],
          ),
        ),
        onExpansionChanged: (bool value) => ref.read(isSectionExpnadedProvider(section.id).notifier).update((state) => value),
        title: Text('Section ${index + 1} - ${section.name}'),
        children: [LessonsMixin().buildLessons(courseDocId: courseDocId, sectionId: section.id, isMobile: isMobile, ref: ref, isPreview: isPreview)],
      ),
    );
  }

  void _onEdit(context, String courseId, Section section) {
    CustomDialogs.openResponsiveDialog(context, widget: SectionForm(courseId: courseId, section: section));
  }

  void _onDeleteSection(context, String courseDocId, String sectionId, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      CustomDialogs.openActionDialog(
        context,
        actionBtnController: deleteBtnController,
        title: 'Delete this section?',
        message: 'Warning: All of the lessons releated to this section will be deleted and this can not be undone!',
        onAction: () async {
          deleteBtnController.start();

          // decrease lessons count related to section
          final int lessonsCount = await FirebaseService().getLessonsCountInSection(courseDocId, sectionId);
          debugPrint('lessons found: $lessonsCount');
          if (lessonsCount != 0) {
            await FirebaseService().updateLessonCountInCourse(courseDocId, count: (-lessonsCount));
          }

          // Delete Section
          await FirebaseService().deleteSection(courseDocId, sectionId);

          deleteBtnController.success();
          if (!context.mounted) return;
          Navigator.pop(context);
        },
      );
    } else {
      openTestingToast(context);
    }
  }

  void _onReorder(
    context,
    int oldIndex,
    int newIndex,
    FirestoreQueryBuilderSnapshot snapshot,
    String courseDocId,
    WidgetRef ref,
  ) async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      final List<Section> sections = snapshot.docs.map((e) => Section.fromFiresore(e)).toList();
      sections.sort((a, b) => a.order.compareTo(b.order));
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Section section = sections.removeAt(oldIndex);
      sections.insert(newIndex, section);
      await FirebaseService().updateSectionsOrder(sections, courseDocId);
    } else {
      openTestingToast(context);
    }
  }
}
