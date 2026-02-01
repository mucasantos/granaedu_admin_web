import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/app_settings_model.dart';
import 'package:lms_admin/pages/splash.dart';
import 'package:lms_admin/providers/user_data_provider.dart';
import 'package:lms_admin/services/firebase_service.dart';
import 'package:lms_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:lms_admin/utils/next_screen.dart';
import 'package:lms_admin/utils/toasts.dart';

class LicenseTab extends ConsumerWidget {
  const LicenseTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final LicenseType license = settings.value?.license ?? LicenseType.none;

    final String licenseString = license == LicenseType.extended
        ? 'Extended License'
        : license == LicenseType.regular
            ? 'Regular License'
            : 'Unknown';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(100),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Icon(
                LineIcons.checkCircle,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 30),
              Text(
                'Your license key is valid and activated',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    text: 'License Type:  ',
                    children: [TextSpan(text: licenseString, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))]),
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(style: Theme.of(context).textTheme.bodyMedium, text: 'Want to deactivate this license?  ', children: [
            TextSpan(
                style: const TextStyle(color: Colors.blueAccent),
                text: 'Click here',
                recognizer: TapGestureRecognizer()..onTap = () => _handleDeactivateLicense(context, ref))
          ]),
        )
      ],
    );
  }

  _handleDeactivateLicense(BuildContext context, WidgetRef ref) async {
    if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      final AppSettingsModel appSettingsModel = AppSettingsModel(license: LicenseType.none);
      final Map<String, dynamic> data = AppSettingsModel.getMapLicense(appSettingsModel);
      await FirebaseService().updateAppSettings(data);
      ref.invalidate(appSettingsProvider);
      if (!context.mounted) return;
      NextScreen.replaceAnimation(context, const SplashScreen());
    } else {
      openTestingToast(context);
    }
  }
}
