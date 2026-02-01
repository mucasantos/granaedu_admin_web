import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lms_admin/models/app_settings_model.dart';

class APIService {
  final int itemId = 50417076;

  Future<LicenseType> verifyPurchaseCode(String purchaseCode) async {
    LicenseType license = LicenseType.none;

    final String url = 'https://mrb-lab.com/wp-json/envato/v1/verify-purchase/$purchaseCode';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);

        if (decodedData['validated'] == true && decodedData['purchase'] != null) {
          final int verifiedItemId = decodedData['purchase']['item']['id'];
          if (verifiedItemId == itemId) {
            return license = _getLicenseTypeFromJson(decodedData);
          }
        }
      }
    } catch (error) {
      debugPrint('error on validating purchase code: $error');
      return license;
    }

    return license;
  }

  static LicenseType _getLicenseTypeFromJson(json) {
    if (json['purchase']['license'] == 'Regular License') {
      return LicenseType.regular;
    } else if (json['purchase']['license'] == 'Extended License') {
      return LicenseType.extended;
    } else {
      return LicenseType.none;
    }
  }
}
