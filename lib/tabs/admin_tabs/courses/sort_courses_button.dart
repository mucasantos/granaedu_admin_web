import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/models/user_model.dart';
import '../../../models/category.dart';
import '../../../services/firebase_service.dart';
import 'courses.dart';

final CollectionReference colRef = FirebaseFirestore.instance.collection('courses');


class SortCoursesButton extends StatelessWidget {
  const SortCoursesButton({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final sortText = ref.watch(sortByCourseTextProvider);
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
        return sortByCourse.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Text(e.value),
          );
        }).toList();
      },
      onSelected: (dynamic value) {
        ref.read(sortByCourseTextProvider.notifier).update((state) => sortByCourse[value].toString());

        if (value == 'all') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (courseStatus.containsKey(value)) {
          final newQuery = colRef.where('status', isEqualTo: value);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'featured') {
          final newQuery = colRef.where('featured', isEqualTo: true);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'new') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'old') {
          final newQuery = colRef.orderBy('created_at', descending: false);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'free' || value == 'premium') {
          final newQuery = colRef.where('price_status', isEqualTo: value);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'high-rating') {
          final newQuery = colRef.orderBy('rating', descending: true);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'low-rating') {
          final newQuery = colRef.orderBy('rating', descending: false);
          ref.read(courseQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'category') {
          _openCategoryDialog(context, ref);
        }
        if (value == 'author') {
          _openAuthorDialog(context, ref);
        }
      },
    );
  }

  _openAuthorDialog(BuildContext context, WidgetRef ref) async {
    await FirebaseService().getAuthors().then((List<UserModel> authors) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Author'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: ListView.separated(
                  itemCount: authors.length,
                  shrinkWrap: true,
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: Text('${index + 1}. ${authors[index].name}'),
                      subtitle: Text(authors[index].email),
                      onTap: () {
                        ref.read(sortByCourseTextProvider.notifier).update((state) => authors[index].name);
                        final newQuery = colRef.where('author.id', isEqualTo: authors[index].id);
                        ref.read(courseQueryprovider.notifier).update((state) => newQuery);
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

  _openCategoryDialog(BuildContext context, WidgetRef ref) async {
    await FirebaseService().getCategories().then((List<Category> cList) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Category'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: ListView.separated(
                  itemCount: cList.length,
                  shrinkWrap: true,
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: Text('${index + 1}. ${cList[index].name}'),
                      onTap: () {
                        ref.read(sortByCourseTextProvider.notifier).update((state) => cList[index].name);
                        final newQuery = colRef.where('cat_id', isEqualTo: cList[index].id);
                        ref.read(courseQueryprovider.notifier).update((state) => newQuery);
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
