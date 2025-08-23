import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/models/chart_model.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/tabs/admin_tabs/dashboard/empty_bar_chart.dart';
import 'package:lms_admin/l10n/app_localizations.dart';

final userStatsProvider = FutureProvider<List<ChartModel>>((ref) async {
  final int days = ref.read(usersStateDaysCount);
  final List<ChartModel> stats = await FirebaseService().getUserStats(days);
  return stats;
});

final usersStateDaysCount = StateProvider<int>((ref) => 7);

class UserBarChart extends ConsumerWidget {
  const UserBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStateRef = ref.watch(userStatsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.shade300,
        )
      ]),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LineIcons.userPlus),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  AppLocalizations.of(context).chartNewUserRegistrationTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DefaultTabController(
              initialIndex: ref.watch(usersStateDaysCount) == 7 ? 0 : 1,
              length: 2,
              child: TabBar(
                onTap: (int index) {
                  if (index == 0) {
                    ref.read(usersStateDaysCount.notifier).update((state) => 7);
                    ref.invalidate(userStatsProvider);
                  } else {
                    ref.read(usersStateDaysCount.notifier).update((state) => 30);
                    ref.invalidate(userStatsProvider);
                  }
                },
                indicator: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                automaticIndicatorColorAdjustment: true,
                splashBorderRadius: BorderRadius.circular(20),
                unselectedLabelColor: Colors.grey,
                indicatorPadding: const EdgeInsets.all(8),
                tabAlignment: TabAlignment.center,
                labelPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 30),
                tabs: [
                  Tab(child: Text(AppLocalizations.of(context).chartLast7Days)),
                  Tab(child: Text(AppLocalizations.of(context).chartLast30Days)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: usersStateRef.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, x) => const EmptyBarChart(),
                  skipError: true,
                  data: (usersStat) {
                    final double maxYvalue = _calculateMaxYValue(usersStat);
                    return BarChart(
                      BarChartData(
                        maxY: maxYvalue,
                        barTouchData: BarTouchData(
                          touchTooltipData: _getTouchData(context, usersStat),
                        ),
                        barGroups: generateBarGroups(context, usersStat),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.blueGrey.shade100)),
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => _bottomTitles(value, ref),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }

  _bottomTitles(double value, ref) {
    String title = '';
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (ref.watch(usersStateDaysCount) == 7) {
      title = DateFormat('E').format(date);
    } else {
      title = DateFormat('d').format(date);
    }
    return Text(title);
  }

  BarTouchTooltipData _getTouchData(BuildContext context, List<ChartModel> usersStat) {
    return BarTouchTooltipData(
      getTooltipColor: (group) => Theme.of(context).primaryColor,
      getTooltipItem: (groupData, groupIndex, rod, rodIndex) {
        // Get Date
        final ChartModel model = usersStat[groupIndex];
        final String formattedDate = DateFormat('dd/MM/yyyy').format(model.timestamp);

        return BarTooltipItem(AppLocalizations.of(context).chartUsersTooltip(rod.toY.toInt()), const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16), children: [
          const TextSpan(text: '\n'),
          TextSpan(text: formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ]);
      },
    );
  }

  List<BarChartGroupData> generateBarGroups(BuildContext context, userStats) {
    // Group user registrations by day
    Map<DateTime, dynamic> groupedData = {};
    userStats.forEach((registration) {
      DateTime day = DateTime(registration.timestamp.year, registration.timestamp.month, registration.timestamp.day);

      if (groupedData.containsKey(day)) {
        groupedData[day] = groupedData[day]! + registration.count;
      } else {
        groupedData[day] = registration.count;
      }
    });

    // Sort the days in ascending order
    List<DateTime> sortedDays = groupedData.keys.toList()..sort();

    // Generate BarChartGroupData for each day
    List<BarChartGroupData> barGroups = [];
    for (DateTime day in sortedDays) {
      int registrationsCount = groupedData[day] ?? 0;

      // Create a BarChartRodData for the day
      BarChartRodData rodData = BarChartRodData(
        toY: registrationsCount.toDouble(),
        color: Theme.of(context).primaryColor, // Customize the color as needed
      );

      // Create a BarChartGroupData for the day
      BarChartGroupData groupData = BarChartGroupData(
        x: day.millisecondsSinceEpoch,
        // barsSpace: 4,
        barRods: [rodData],
      );

      // Add the group data to the list
      barGroups.add(groupData);
    }

    return barGroups;
  }

  double _calculateMaxYValue(List<ChartModel> usersStat) {
    // Find the maximum Y value in the data
    double maxYValue = 0;
    for (ChartModel model in usersStat) {
      if (model.count > maxYValue) {
        maxYValue = model.count.toDouble();
      }
    }
    // Optionally, add some padding to the maxY value for better visualization
    maxYValue += 5;
    return maxYValue;
  }
}
