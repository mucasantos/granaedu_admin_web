import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../../../models/app_settings_model.dart';
import '../../../services/firebase_service.dart';
import '../ads_settings.dart';

final saveSettingsBtnProvider = Provider<RoundedLoadingButtonController>((ref) => RoundedLoadingButtonController());

final isFreeCoursesEnabledProvider = StateProvider<bool>((ref) => true);
final isTopAuthorsEnabledProvider = StateProvider<bool>((ref) => true);
final isFeaturedEnabledProvider = StateProvider<bool>((ref) => true);
final isCategoriesEnabledProvider = StateProvider<bool>((ref) => true);
final isLatestCoursesProvider = StateProvider((ref) => true);

final selectedHomeCategoryId1Provider = StateProvider<String?>((ref) => null);
final selectedHomeCategoryId2Provider = StateProvider<String?>((ref) => null);
final selectedHomeCategoryId3Provider = StateProvider<String?>((ref) => null);

final isTagsEnabledProvider = StateProvider<bool>((ref) => true);

final websiteTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());
final supportEmailTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());
final privacyUrlTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());
final isSkipLoginEnabledProvider = StateProvider<bool>((ref) => false);
final isOnboardingEnabledProvider = StateProvider<bool>((ref) => true);
final isContentSecurityEnabledProvider = StateProvider<bool>((ref) => false);


final fbProvider = Provider<TextEditingController>((ref) => TextEditingController());
final youtubeProvider = Provider<TextEditingController>((ref) => TextEditingController());
final twitterProvider = Provider<TextEditingController>((ref) => TextEditingController());
final instaProvider = Provider<TextEditingController>((ref) => TextEditingController());

final appSettingsProvider = FutureProvider<AppSettingsModel?>((ref) async {
  final AppSettingsModel? settings = await FirebaseService().getAppSettings();

  // Update the other providers based on the ads data
  if (settings != null) {
    ref.read(isFreeCoursesEnabledProvider.notifier).state = settings.freeCourses!;
    ref.read(isTopAuthorsEnabledProvider.notifier).state = settings.topAuthors!;
    ref.read(isFeaturedEnabledProvider.notifier).state = settings.featured!;
    ref.read(isCategoriesEnabledProvider.notifier).state = settings.categories!;
    ref.read(isSkipLoginEnabledProvider.notifier).state = settings.skipLogin!;
    ref.read(isLatestCoursesProvider.notifier).state = settings.latestCourses!;
    ref.read(isTagsEnabledProvider.notifier).state = settings.tags!;
    ref.read(isSkipLoginEnabledProvider.notifier).state = settings.skipLogin!;
    ref.read(isOnboardingEnabledProvider.notifier).state = settings.onBoarding!;
    ref.read(isContentSecurityEnabledProvider.notifier).state = settings.contentSecurity!;

    ref.read(selectedHomeCategoryId1Provider.notifier).state = settings.homeCategory1?.id;
    ref.read(selectedHomeCategoryId2Provider.notifier).state = settings.homeCategory2?.id;
    ref.read(selectedHomeCategoryId3Provider.notifier).state = settings.homeCategory3?.id;

    ref.read(fbProvider).text = settings.social?.fb ?? '';
    ref.read(instaProvider).text = settings.social?.instagram ?? '';
    ref.read(youtubeProvider).text = settings.social?.youtube ?? '';
    ref.read(twitterProvider).text = settings.social?.twitter ?? '';
    ref.read(websiteTextfieldProvider).text = settings.website ?? '';
    ref.read(supportEmailTextfieldProvider).text = settings.supportEmail ?? '';
    ref.read(privacyUrlTextfieldProvider).text = settings.privacyUrl ?? '';

    ref.read(adsEnbaledProvider.notifier).state = settings.ads?.isAdsEnabled ?? false;
    ref.read(bannerAdProvider.notifier).state = settings.ads?.bannerEnbaled ?? false;
    ref.read(interstitialAdProvider.notifier).state = settings.ads?.interstitialEnabled ?? false;
  }

  return settings;
});
