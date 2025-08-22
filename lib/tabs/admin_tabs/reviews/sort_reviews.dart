import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/models/course.dart';
import '../../../utils/reponsive.dart';
import '../../../services/firebase_service.dart';
import 'reviews.dart';

final CollectionReference colRef = FirebaseFirestore.instance.collection('reviews');

class SortReviewsButton extends StatelessWidget {
  const SortReviewsButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final String sortText = ref.watch(sortByReviewTextProvider);
    return PopupMenuButton(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.sort_down,
              color: Colors.grey[800],
            ),
            Visibility(
              visible: Responsive.isMobile(context) ? false : true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Sort By - $sortText',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(Icons.keyboard_arrow_down)
                ],
              ),
            )
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return sortByReviews.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Text(e.value),
          );
        }).toList();
      },
      onSelected: (dynamic value) {
        ref.read(sortByReviewTextProvider.notifier).update((state) => sortByReviews[value].toString());
        final notifier = ref.read(reviewsQueryprovider.notifier);

        if (value == 'all') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          notifier.update((state) => newQuery);
        }
        if (value == 'new') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          notifier.update((state) => newQuery);
        }
        if (value == 'old') {
          final newQuery = colRef.orderBy('created_at', descending: false);
          notifier.update((state) => newQuery);
        }
        if (value == 'high-rating') {
          final newQuery = colRef.orderBy('rating', descending: true);
          notifier.update((state) => newQuery);
        }
        if (value == 'low-rating') {
          final newQuery = colRef.orderBy('rating', descending: false);
          notifier.update((state) => newQuery);
        }
        if (value == 'course') {
          _openCourseDialog(context, ref);
        }
      },
    );
  }

  _openCourseDialog(BuildContext context, WidgetRef ref) async {
    await FirebaseService().getAllCourses().then((List<Course> courses) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Course'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: ListView.separated(
                  itemCount: courses.length,
                  shrinkWrap: true,
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    final Course course = courses[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: Text('${index + 1}. ${course.name}'),
                      onTap: () {
                        ref.read(sortByReviewTextProvider.notifier).update((state) => course.name);
                        final newQuery = colRef.where('course_id', isEqualTo: course.id);
                        ref.read(reviewsQueryprovider.notifier).update((state) => newQuery);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            );
          });
    });
  }
}
