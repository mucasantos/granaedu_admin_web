import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../../../../models/course.dart';

class Requirements extends StatelessWidget {
  const Requirements({
    super.key,
    required this.course,
  });

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: course.courseMeta.requirements!.isNotEmpty,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requirements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(
              height: 5,
            ),
            Column(
              children: course.courseMeta.requirements!.map((e) => ListTile(
                contentPadding: const EdgeInsets.all(0),
                horizontalTitleGap: 0,
                title: Text(e),
                leading: const Icon(LineIcons.dotCircle),
              )).toList(),
            )
          ],
        ),
      ),
    );
  }
}