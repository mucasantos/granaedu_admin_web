import 'package:flutter/material.dart';
import 'package:lms_admin/mixins/purchase_mixin.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/purchase_history.dart';
import 'package:lms_admin/services/app_service.dart';

class PurchasesDataSource extends DataTableSource with PurchasesMixin {
  final List<PurchaseHistory> purchases;
  final BuildContext context;
  PurchasesDataSource(this.context, this.purchases);

  @override
  DataRow getRow(int index) {
    final PurchaseHistory purchase = purchases[index];

    return DataRow.byIndex(index: index, cells: [
      DataCell(_userInfo(purchase)),
      DataCell(_plan(purchase)),
      DataCell(_price(purchase)),
      DataCell(_platform(purchase)),
      DataCell(_purchaseDate(purchase)),
    ]);
  }

  static Text _platform(PurchaseHistory purchase) => Text(purchase.platform);

  static Text _purchaseDate(PurchaseHistory purchase) {
    final String date = AppService.getDateTime(purchase.purchaseAt);
    return Text(date);
  }

  ListTile _userInfo(PurchaseHistory purchase) {
    return ListTile(
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.all(0),
      title: Text(purchase.userName),
      leading: UserMixin.getUserImageByUrl(imageUrl: purchase.userImageUrl),
      subtitle: Text(purchase.userEmail),
    );
  }

  RichText _plan(PurchaseHistory purchase) {
    final bool isExpired = isExpiredFromPurchaseHistory(purchase);
    return RichText(
      text: TextSpan(
        text: purchase.plan,
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          isExpired
              ? const TextSpan(text: ' (Expired)', style: TextStyle(color: Colors.red))
              : const TextSpan(text: ' (Active)', style: TextStyle(color: Colors.green))
        ],
      ),
    );
  }

  static Text _price(PurchaseHistory purchase) {
    return Text(purchase.price);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => purchases.length;

  @override
  int get selectedRowCount => 0;
}
