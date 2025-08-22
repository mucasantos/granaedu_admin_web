import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../models/course.dart';

class CourseInfo extends StatelessWidget {
  const CourseInfo({Key? key, required this.course}) : super(key: key);
  final Course course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
                text: 'Created By ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: course.author?.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600, color: Colors.blue),
                  )
                ]),
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              const Icon(
                CupertinoIcons.globe,
                size: 20,
              ),
              const SizedBox(
                width: 3,
              ),
              Text('Language: ${course.courseMeta.language}'),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              const Icon(
                CupertinoIcons.timer,
                size: 20,
              ),
              const SizedBox(
                width: 3,
              ),
              Text('Duration: ${course.courseMeta.duration}'),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              const Icon(
                CupertinoIcons.book,
                size: 20,
              ),
              const SizedBox(
                width: 3,
              ),
              Text('${course.lessonsCount} Lessons'),
            ],
          ),
        ],
      ),
    );
  }
}