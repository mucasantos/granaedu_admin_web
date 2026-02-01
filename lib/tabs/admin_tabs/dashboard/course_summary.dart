import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/models/course.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/utils/custom_cache_image.dart';
import '../../../l10n/app_localizations.dart';

final courseSummaryProvider = FutureProvider<List<Course>>((ref) async {
  final List<Course> courses = await FirebaseService().getAllCourses();
  // Sort by students count descending and take top 10 for summary
  courses.sort((a, b) => b.studentsCount.compareTo(a.studentsCount));
  return courses.take(10).toList();
});

class CourseSummary extends ConsumerWidget {
  const CourseSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(courseSummaryProvider);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).dashboardCoursesSummary,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          courses.when(
            data: (data) => _buildTable(context, data),
            error: (e, _) => Center(child: Text(e.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Course> courses) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Course')),
          DataColumn(label: Text('Students')),
          DataColumn(label: Text('Rating')),
          DataColumn(label: Text('Status')),
        ],
        rows: courses.map((course) {
          return DataRow(cells: [
            DataCell(Row(
              children: [
                SizedBox(
                  height: 30,
                  width: 30,
                  child: CustomCacheImage(
                      imageUrl: course.thumbnailUrl, radius: 5),
                ),
                const SizedBox(width: 10),
                Text(course.name, overflow: TextOverflow.ellipsis),
              ],
            )),
            DataCell(Text(course.studentsCount.toString())),
            DataCell(Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 5),
                Text(course.rating.toStringAsFixed(1)),
              ],
            )),
            DataCell(_getStatusChip(course.status)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status) {
      case 'live':
        color = Colors.green;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      case 'pending':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
