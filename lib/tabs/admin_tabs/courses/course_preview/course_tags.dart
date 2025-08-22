import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/forms/course_form.dart';
import 'package:lms_admin/models/course.dart';

class CourseTags extends ConsumerWidget {
  const CourseTags({Key? key, required this.course}) : super(key: key);

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);
    return tags.when(
        skipError: true,
        error: (error, stackTrace) => Container(),
        loading: () => Container(),
        data: (data) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: data.where((element) => course.tagIDs!.contains(element.id)).map((e) {
                return Chip(
                  padding: const EdgeInsets.all(10),
                  elevation: 0,
                  label: Text(
                    e.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          );
        });
  }
}
