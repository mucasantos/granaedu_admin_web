import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/side_menu.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/purchase_history.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/l10n/app_localizations.dart';

import '../../../pages/home.dart';

final dashboardPurchasesProvider = FutureProvider<List<PurchaseHistory>>((ref) async {
  final List<PurchaseHistory> purchases = await FirebaseService().getLatestPurchases(5);
  return purchases;
});

class DashboardPurchases extends ConsumerWidget {
  const DashboardPurchases({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(dashboardPurchasesProvider);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.shade300,
        )
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).dashboardLatestPurchases,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                  onPressed: () {
                    ref.read(menuIndexProvider.notifier).update((state) => 8);
                    ref.read(pageControllerProvider.notifier).state.jumpToPage(8);
                  },
                  child: Text(AppLocalizations.of(context).commonViewAll))
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: purchases.when(
              skipError: true,
              data: (data) {
                return Column(
                  children: data.map((purchase) {
                    return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        title: Text(purchase.plan),
                        trailing: Text(purchase.price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),),
                        subtitle: Row(
                          children: [
                            UserMixin.getUserImageByUrl(imageUrl: purchase.userImageUrl, radius: 17, iconSize: 13),
                            const SizedBox(width: 10,),
                            Text(purchase.userName),
                            const SizedBox(width: 10,),
                            Text('(${purchase.platform})', style: const TextStyle(color: Colors.blueAccent),)
                          ],
                        ),);
                  }).toList(),
                );
              },
              error: (a, b) => Container(),
              loading: () => Container(),
            ),
          )
        ],
      ),
    );
  }
}
