import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/switch_option.dart';
import 'package:lms_admin/models/ads_model.dart';
import 'package:lms_admin/models/app_settings_model.dart';
import 'package:lms_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../../mixins/appbar_mixin.dart';
import '../../components/custom_buttons.dart';
import '../../mixins/user_mixin.dart';
import '../../providers/user_data_provider.dart';
import '../../services/firebase_service.dart';

final adsEnbaledProvider = StateProvider<bool>((ref) => false);
final bannerAdProvider = StateProvider<bool>((ref) => false);
final interstitialAdProvider = StateProvider<bool>((ref) => false);

final saveAdSettingsCtlr = Provider<RoundedLoadingButtonController>((ref) => RoundedLoadingButtonController());

class AdsSettings extends ConsumerWidget {
  const AdsSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final ads = ref.watch(adsEnbaledProvider);
    final banner = ref.watch(bannerAdProvider);
    final interstitial = ref.watch(interstitialAdProvider);
    final saveBtnCtlr = ref.watch(saveAdSettingsCtlr);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Ads Settings', buttons: [
            CustomButtons.submitButton(
              context,
              buttonController: saveBtnCtlr,
              text: 'Save Changes',
              width: 170,
              borderRadius: 25,
              onPressed: () async {
                final AdsModel adsModel = AdsModel(
                  isAdsEnabled: ads,
                  bannerEnbaled: banner,
                  interstitialEnabled: interstitial,
                );
                final appSettingsModel = AppSettingsModel(ads: adsModel);
                final data = AppSettingsModel.getMapAdsSettings(appSettingsModel);

                if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
                  saveBtnCtlr.start();
                  await FirebaseService().updateAppSettings(data);
                  saveBtnCtlr.reset();
                  if (!context.mounted) return;
                  openSuccessToast(context, 'Saved successfully!');
                } else {
                  openTestingToast(context);
                }
              },
            ),
            const SizedBox(width: 10),
            CustomButtons.circleButton(
              context,
              icon: Icons.refresh,
              bgColor: Theme.of(context).primaryColor,
              iconColor: Colors.white,
              radius: 22,
              onPressed: () async {
                ref.invalidate(appSettingsProvider);
                openSuccessToast(context, 'Refreshed!');
              },
            ),
          ]),
          settings.isRefreshing
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          SwitchOption(
                            deafultValue: ads,
                            title: 'Ads Enabled',
                            onChanged: (value) {
                              ref.read(adsEnbaledProvider.notifier).state = value;
                            },
                          ),
                          Visibility(
                            visible: ads == true,
                            child: Column(
                              children: [
                                const Divider(),
                                SwitchOption(
                                  deafultValue: banner,
                                  title: 'Banner Ads',
                                  onChanged: (value) {
                                    ref.read(bannerAdProvider.notifier).state = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ads == true,
                            child: Column(
                              children: [
                                const Divider(),
                                SwitchOption(
                                  deafultValue: interstitial,
                                  title: 'Interstitial Ads',
                                  onChanged: (value) {
                                    ref.read(interstitialAdProvider.notifier).state = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
        ],
      ),
    );
  }
}
