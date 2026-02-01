import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/models/app_settings_model.dart';
import 'package:lms_admin/services/app_service.dart';
import 'package:lms_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/pages/home.dart';
import 'package:lms_admin/services/api_service.dart';
import 'package:lms_admin/utils/next_screen.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:svg_flutter/svg.dart';
import '../configs/assets_config.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';

class VerifyInfo extends ConsumerStatefulWidget {
  const VerifyInfo({Key? key}) : super(key: key);

  @override
  ConsumerState<VerifyInfo> createState() => _VerifyInfoState();
}

class _VerifyInfoState extends ConsumerState<VerifyInfo> {
  var textFieldCtlr = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final RoundedLoadingButtonController _btnCtlr = RoundedLoadingButtonController();

  void _handleVerification() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _checkVerification();
    }
  }

  _checkVerification() async {
    _btnCtlr.start();
    final LicenseType licenseType = await APIService().verifyPurchaseCode(textFieldCtlr.text);
    final bool isVerified = licenseType != LicenseType.none;

    if (isVerified) {
      final AppSettingsModel settingsModel = AppSettingsModel(license: licenseType);
      final Map<String, dynamic> data = AppSettingsModel.getMapLicense(settingsModel);

      await FirebaseService().updateAppSettings(data);
      ref.invalidate(appSettingsProvider);
      await ref.read(userDataProvider.notifier).getData();

      _btnCtlr.success();
      await Future.delayed(const Duration(milliseconds: 500)).then((value) => NextScreen.replaceAnimation(context, const Home()));
    } else {
      _btnCtlr.reset();
      if (!mounted) return;
      openFailureToast(context, 'Invalid Purchase Code. Try again!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.indigo.withOpacity(0.1),
        child: Row(
          children: [
            Visibility(
              visible: Responsive.isDesktop(context) || Responsive.isDesktopLarge(context),
              child: Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: SvgPicture.asset(
                  AssetsConfig.verifyImageString,
                  alignment: Alignment.center,
                  height: 400,
                  width: 400,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Form(
                key: formKey,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.09),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Verify Your Purchase',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Where is Your Purchase Code?', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey)),
                          const SizedBox(
                            width: 10,
                          ),
                          InkWell(
                            onTap: () => AppService()
                                .openLink(context, 'https://help.market.envato.com/hc/en-us/articles/202822600-Where-Is-My-Purchase-Code-'),
                            child: const Text(
                              'Check',
                              style: TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 80,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Code',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            color: Colors.grey.shade100,
                            child: TextFormField(
                              controller: textFieldCtlr,
                              validator: (value) {
                                if (value!.isEmpty) return 'Purchase code is required';
                                return null;
                              },
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () => textFieldCtlr.clear(),
                                  icon: const Icon(Icons.clear),
                                ),
                                hintText: 'Your Purchase Code',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(15),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 80,
                          ),
                          RoundedLoadingButton(
                            onPressed: _handleVerification,
                            controller: _btnCtlr,
                            color: Theme.of(context).primaryColor,
                            width: MediaQuery.of(context).size.width,
                            borderRadius: 0,
                            height: 55,
                            animateOnTap: false,
                            elevation: 0,
                            child: Text(
                              'Verify',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
