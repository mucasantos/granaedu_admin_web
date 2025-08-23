import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/models/chart_model.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/l10n/app_localizations.dart';
import 'empty_bar_chart.dart';

final purchaseStatsProvider = FutureProvider<List<ChartModel>>((ref) async {
  final int days = ref.read(purchaseStatsDaysCount);
  final List<ChartModel> stats = await FirebaseService().getPurchaseStats(days);
  return stats;
});

final purchaseStatsDaysCount = StateProvider<int>((ref) => 7);

class PurchaseBarChart extends ConsumerWidget {
  const PurchaseBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseStatsRef = ref.watch(purchaseStatsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.shade300,
        )
      ]),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LineIcons.areaChart),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  AppLocalizations.of(context).chartSubscriptionPurchasesTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            DefaultTabController(
              initialIndex: ref.watch(purchaseStatsDaysCount) == 7 ? 0 : 1,
              length: 2,
              child: TabBar(
                onTap: (int index) {
                  if (index == 0) {
                    ref.read(purchaseStatsDaysCount.notifier).update((state) => 7);
                    ref.invalidate(purchaseStatsProvider);
                  } else {
                    ref.read(purchaseStatsDaysCount.notifier).update((state) => 30);
                    ref.invalidate(purchaseStatsProvider);
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
                  Tab(child: Text(AppLocalizations.of(context).chartLast30Days))
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: purchaseStatsRef.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, x) => const EmptyBarChart(),
                  skipError: true,
                  data: (purchaseStats) {
                    final double maxYvalue = _calculateMaxYValue(purchaseStats);
                    return BarChart(
                      BarChartData(
                        maxY: maxYvalue,
                        barTouchData: BarTouchData(touchTooltipData: _getTouchData(context, purchaseStats)),
                        barGroups: _generateBarGroups(context, purchaseStats),
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
                            )),
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
    if (ref.watch(purchaseStatsDaysCount) == 7) {
      title = DateFormat('E').format(date);
    } else {
      title = DateFormat('d').format(date);
    }
    return Text(title);
  }

  BarTouchTooltipData _getTouchData(BuildContext context, List<ChartModel> purchaseStats) {
    return BarTouchTooltipData(
      getTooltipColor: (group) => Theme.of(context).primaryColor,
      getTooltipItem: (groupData, groupIndex, rod, rodIndex) {
        // Get Date
        final ChartModel model = purchaseStats[groupIndex];
        final String formattedDate = DateFormat('dd/MM/yyyy').format(model.timestamp);

        return BarTooltipItem(AppLocalizations.of(context).chartPurchasesTooltip(rod.toY.toInt()), const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16), children: [
          const TextSpan(text: '\n'),
          TextSpan(text: formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ]);
      },
    );
  }

  List<BarChartGroupData> _generateBarGroups(BuildContext context, purchaseStats) {
    // Group user registrations by day
    Map<DateTime, dynamic> groupedData = {};
    purchaseStats.forEach((registration) {
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

  double _calculateMaxYValue(List<ChartModel> purchaseStats) {
    // Find the maximum Y value in the data
    double maxYValue = 0;

    for (ChartModel model in purchaseStats) {
      if (model.count > maxYValue) {
        maxYValue = model.count.toDouble();
      }
    }
    maxYValue += 5;
    return maxYValue;
  }
}
