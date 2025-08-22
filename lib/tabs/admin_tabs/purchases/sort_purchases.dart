import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/configs/constants.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'purchases.dart';

class SortPurchasesButton extends StatelessWidget {
  const SortPurchasesButton({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final String sortText = ref.watch(sortByPurchasesTextProvider);
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
        return sortByPurchases.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Text(e.value),
          );
        }).toList();
      },
      onSelected: (dynamic value) {
        final CollectionReference colRef = FirebaseFirestore.instance.collection('purchases');

        ref.read(sortByPurchasesTextProvider.notifier).update((state) => sortByPurchases[value].toString());
        final qureryProvider = ref.read(purchasesQueryProvider.notifier);

        if (value == 'all') {
          final newQuery = colRef.orderBy('purchase_at', descending: true);
          qureryProvider.update((state) => newQuery);
        }
        if (value == 'new') {
          final newQuery = colRef.orderBy('purchase_at', descending: true);
          qureryProvider.update((state) => newQuery);
        }
        if (value == 'old') {
          final newQuery = colRef.orderBy('purchase_at', descending: false);
          qureryProvider.update((state) => newQuery);
        }
        if (value == 'active') {
          final newQuery = colRef.where('expire_at', isGreaterThanOrEqualTo: DateTime.now());
          qureryProvider.update((state) => newQuery);
        }
        if (value == 'expired') {
          final newQuery = colRef.where('expire_at', isLessThanOrEqualTo: DateTime.now());
          qureryProvider.update((state) => newQuery);
        }
        if (value == 'android') {
          final newQuery = colRef.where('platform', isEqualTo: 'Android');
          qureryProvider.update((state) => newQuery);
        }
        if (value == 'ios') {
          final newQuery = colRef.where('platform', isEqualTo: 'iOS');
          qureryProvider.update((state) => newQuery);
        }
      },
    );
  }
}
