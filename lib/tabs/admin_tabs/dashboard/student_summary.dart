import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/user_model.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/services/supabase_service.dart';
import 'package:lms_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:lms_admin/utils/toasts.dart';
import '../../../l10n/app_localizations.dart';

final studentSummaryProvider = FutureProvider<List<UserModel>>((ref) async {
  final List<UserModel> users = await FirebaseService().getLatestUsers(10);
  return users;
});

class StudentSummary extends ConsumerWidget {
  const StudentSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentSummaryProvider);

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
            AppLocalizations.of(context).dashboardStudentsSummary,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          students.when(
            data: (data) => _buildTable(context, ref, data),
            error: (e, _) => Center(child: Text(e.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
      BuildContext context, WidgetRef ref, List<UserModel> students) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('XP')),
          DataColumn(label: Text('Streak')),
          DataColumn(label: Text('Joined')),
        ],
        rows: students.map((student) {
          return DataRow(cells: [
            DataCell(Row(
              children: [
                UserMixin.getUserImageByUrl(imageUrl: student.imageUrl, radius: 15),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(student.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            )),
            DataCell(IconButton(
              tooltip: 'Generate AI Weekly Plan',
              icon: const Icon(Icons.psychology, color: Colors.indigo),
              onPressed: () async {
                final settingsValue = ref.read(appSettingsProvider).value;
                if (settingsValue != null &&
                    settingsValue.openaiKey != null &&
                    settingsValue.weeklyPlanPrompt != null) {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    await SupabaseService().generateWeeklyPlan(
                      firebaseUid: student.id,
                      openaiKey: settingsValue.openaiKey!,
                      systemPrompt: settingsValue.weeklyPlanPrompt!,
                    );
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading dialog
                      openSuccessToast(
                          context, 'Weekly plan generated successfully!');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      openFailureToast(context, 'Failed to generate plan: $e');
                    }
                  }
                } else {
                  openFailureToast(context,
                      'Please configure OpenAI Key and Weekly Plan Prompt first');
                }
              },
            )),
            DataCell(Text(student.xp?.toString() ?? '0')),
            DataCell(Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.orange, size: 16),
                const SizedBox(width: 5),
                Text(student.streak?.toString() ?? '0'),
              ],
            )),
            DataCell(Text(student.createdAt != null ? '${student.createdAt!.day}/${student.createdAt!.month}/${student.createdAt!.year}' : '-')),
          ]);
        }).toList(),
      ),
    );
  }
}
