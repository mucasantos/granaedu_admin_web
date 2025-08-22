// Sub-model of AppSettingsModel

class AdsModel {
  final bool? isAdsEnabled, bannerEnbaled, interstitialEnabled;

  AdsModel({
    this.isAdsEnabled,
    this.bannerEnbaled,
    this.interstitialEnabled,
  });

  factory AdsModel.fromMap(Map<String, dynamic> d) {
    return AdsModel(
      isAdsEnabled: d['enabled'] ?? false,
      bannerEnbaled: d['banner'] ?? false,
      interstitialEnabled: d['interstitial'] ?? false,
    );
  }

  static Map<String, dynamic> getMap(AdsModel d) {
    return {
      'enabled': d.isAdsEnabled,
      'banner': d.bannerEnbaled,
      'interstitial': d.interstitialEnabled,
    };
  }
}
