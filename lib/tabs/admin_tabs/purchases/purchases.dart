import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../configs/constants.dart';
import '../../../mixins/appbar_mixin.dart';
import '../../../mixins/purchase_mixin.dart';
import '../../../utils/reponsive.dart';
import 'sort_purchases.dart';

final purchasesQueryProvider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('purchases').orderBy('purchase_at', descending: true);
  return query;
});

final sortByPurchasesTextProvider = StateProvider<String>((ref) =>   sortByPurchases.entries.first.value);


class Purchases extends ConsumerWidget with PurchasesMixin{
  const Purchases({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Purchase History', buttons: [
            SortPurchasesButton(ref: ref),
          ]),

        buildPurchases(context, ref: ref, isMobile: Responsive.isMobile(context)),
          
        ],
      ),
    );
  }
}
