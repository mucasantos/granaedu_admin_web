import 'package:flutter/material.dart';
import 'package:lms_admin/components/html_body.dart';

import '../../../../models/course.dart';

class CourseDescription extends StatelessWidget {
  const CourseDescription({Key? key, required this.course}) : super(key: key);

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(
            height: 5,
          ),
          HtmlBody(
            content: course.courseMeta.description ?? '',
            isVideoEnabled: true,
            isimageEnabled: true,
            isIframeVideoEnabled: true,
          ),
        ],
      ),
    );
  }
}
