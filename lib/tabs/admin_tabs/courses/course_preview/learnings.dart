import 'package:flutter/material.dart';

import '../../../../models/course.dart';

class Learnings extends StatelessWidget {
  const Learnings({
    super.key,
    required this.course,
  });

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: course.courseMeta.learnings!.isNotEmpty,
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(top: 20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What You Will Learn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(
              height: 5,
            ),
            Column(
              children: course.courseMeta.learnings!.map((e) => ListTile(
                contentPadding: const EdgeInsets.all(0),
                horizontalTitleGap: 0,
                title: Text(e),
                leading: const Icon(Icons.check),
              )).toList(),
            )
          ],
        ),
      ),
    );
  }
}