import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/models/purchase_history.dart';
import 'package:lms_admin/tabs/admin_tabs/purchases/purchases_data_source.dart';

import '../tabs/admin_tabs/purchases/purchases.dart';
import '../utils/empty_with_image.dart';

final List<String> _columns = [
  'User',
  'Subscription Plan',
  'Price',
  'Platform',
  'Purchased At',
  // 'Expire At',
];

const int _itemsPerPage = 10;

mixin PurchasesMixin {
  Widget buildPurchases(
    BuildContext context, {
    required WidgetRef ref,
    required isMobile,
  }) {
    return FirestoreQueryBuilder(
      pageSize: _itemsPerPage,
      query: ref.watch(purchasesQueryProvider),
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) return const CircularProgressIndicator();
        if (snapshot.docs.isEmpty) return const EmptyPageWithImage(title: 'No history found');
        
        List<PurchaseHistory> purchases = [];
        purchases = snapshot.docs.map((e) => PurchaseHistory.fromFirestore(e)).toList();
        DataTableSource source = PurchasesDataSource(context, purchases);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PaginatedDataTable2(
              rowsPerPage: _itemsPerPage - 1,
              source: source,
              empty: const Center(child: Text('No History Found')),
              minWidth: 1200,
              wrapInCard: false,
              horizontalMargin: 20,
              columnSpacing: 20,
              fit: FlexFit.tight,
              lmRatio: 2,
              dataRowHeight: isMobile ? 90 : 70,
              onPageChanged: (_) => snapshot.fetchMore(),
              columns: _columns.map((e) => DataColumn(label: Text(e))).toList(),
            ),
          ),
        );
      },
    );
  }

  bool isExpiredFromPurchaseHistory(PurchaseHistory purchase) {
    final DateTime expireDate = purchase.expireAt;
    final DateTime now = DateTime.now();
    final difference = expireDate.difference(now).inDays;
    if (difference >= 0) {
      return false;
    } else {
      return true;
    }
  }
}
