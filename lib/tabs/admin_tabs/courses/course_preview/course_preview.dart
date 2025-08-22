import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/sections_mixin.dart';
import 'package:lms_admin/models/course.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/course_description.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/course_info.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/course_tags.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/learnings.dart';
import 'package:lms_admin/tabs/admin_tabs/courses/course_preview/requirements.dart';
import 'package:lms_admin/services/app_service.dart';

import '../../../../components/rating_view.dart';
import '../../../../utils/custom_cache_image.dart';

class CoursePreview extends ConsumerWidget with SectionsMixin {
  const CoursePreview({Key? key, required this.course}) : super(key: key);
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text('Course Preview'),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                InkWell(
                  onTap: () {
                    if (course.videoUrl != null && course.videoUrl!.isNotEmpty) {
                      AppService().openLink(context, course.videoUrl!);
                    }
                  },
                  child: SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: ClipRRect(
                      child: CustomCacheImage(imageUrl: course.thumbnailUrl, radius: 5),
                    ),
                  ),
                ),
                Visibility(
                  visible: course.videoUrl != null && course.videoUrl!.isNotEmpty,
                  child: const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      LineIcons.play,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(
                  height: 10,
                ),
                Text(course.courseMeta.summary.toString()),
                const SizedBox(
                  height: 10,
                ),
                RatingView(rating: course.rating),
                const SizedBox(
                  height: 8,
                ),
                Text('${course.studentsCount} students'),
                CourseInfo(course: course),
                Learnings(course: course),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curricullam',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      buildSectionList(courseDocId: course.id, isMobile: Responsive.isMobile(context), ref: ref, isPreview: true),
                    ],
                  ),
                ),
                Requirements(course: course),
                CourseDescription(course: course),
                CourseTags(course: course),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
