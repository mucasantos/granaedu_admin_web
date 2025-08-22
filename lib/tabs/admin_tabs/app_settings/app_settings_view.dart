import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/mixins/appbar_mixin.dart';
import 'package:lms_admin/components/category_dropdown.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/switch_option.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/utils/toasts.dart';
import '../../../models/app_settings_model.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../services/firebase_service.dart';
import 'app_setting_providers.dart';

class AppSettings extends ConsumerWidget with TextFields {
  const AppSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isFreeCoursesEnbled = ref.watch(isFreeCoursesEnabledProvider);
    final isFeaturedEnbled = ref.watch(isFeaturedEnabledProvider);
    final isCategoriesEnbaled = ref.watch(isCategoriesEnabledProvider);
    final isTopAuthorsEnabled = ref.watch(isTopAuthorsEnabledProvider);
    final isLatestCoursesEnabled = ref.watch(isLatestCoursesProvider);
    final isTagsEnabled = ref.watch(isTagsEnabledProvider);
    final isSkipLoginEnabled = ref.watch(isSkipLoginEnabledProvider);
    final onBoardingEnabled = ref.watch(isOnboardingEnabledProvider);
    final contentSecurityEnabled = ref.watch(isContentSecurityEnabledProvider);

    final websiteCtlr = ref.watch(websiteTextfieldProvider);
    final supportEmailCtlr = ref.watch(supportEmailTextfieldProvider);
    final privacyCtlr = ref.watch(privacyUrlTextfieldProvider);

    final selectedCategoryId1 = ref.watch(selectedHomeCategoryId1Provider);
    final selectedCategoryId2 = ref.watch(selectedHomeCategoryId2Provider);
    final selectedCategoryId3 = ref.watch(selectedHomeCategoryId3Provider);

    final fbCtlr = ref.watch(fbProvider);
    final youtubeCtlr = ref.watch(youtubeProvider);
    final twitterCtrl = ref.watch(twitterProvider);
    final instaCtlr = ref.watch(instaProvider);

    final saveBtnCtlr = ref.watch(saveSettingsBtnProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBarMixin.buildTitleBar(context, title: 'App Settings', buttons: [
            CustomButtons.submitButton(
              context,
              buttonController: saveBtnCtlr,
              text: 'Save Changes',
              width: 170,
              borderRadius: 25,
              onPressed: () async {
                final categories = ref.read(categoriesProvider);
                final HomeCategory? category1 = selectedCategoryId1 == null
                    ? null
                    : HomeCategory(id: selectedCategoryId1, name: categories.where((element) => element.id == selectedCategoryId1).first.name);

                final HomeCategory? category2 = selectedCategoryId2 == null
                    ? null
                    : HomeCategory(id: selectedCategoryId2, name: categories.where((element) => element.id == selectedCategoryId2).first.name);

                final HomeCategory? category3 = selectedCategoryId3 == null
                    ? null
                    : HomeCategory(id: selectedCategoryId3, name: categories.where((element) => element.id == selectedCategoryId3).first.name);

                final AppSettingsSocialInfo social =
                    AppSettingsSocialInfo(fb: fbCtlr.text, youtube: youtubeCtlr.text, twitter: twitterCtrl.text, instagram: instaCtlr.text);

                final AppSettingsModel appSettingsModel = AppSettingsModel(
                  featured: isFeaturedEnbled,
                  categories: isCategoriesEnbaled,
                  freeCourses: isFreeCoursesEnbled,
                  topAuthors: isTopAuthorsEnabled,
                  tags: isTagsEnabled,
                  onBoarding: onBoardingEnabled,
                  skipLogin: isSkipLoginEnabled,
                  contentSecurity: contentSecurityEnabled,
                  privacyUrl: privacyCtlr.text,
                  supportEmail: supportEmailCtlr.text,
                  website: websiteCtlr.text,
                  homeCategory1: category1,
                  homeCategory2: category2,
                  homeCategory3: category3,
                  social: social,
                  latestCourses: isLatestCoursesEnabled,
                );

                final data = AppSettingsModel.getMap(appSettingsModel);
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
            const SizedBox(
              width: 10,
            ),
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
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Home Tab',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              SwitchOption(
                                  deafultValue: isFeaturedEnbled,
                                  title: 'Featured Section',
                                  onChanged: (value) {
                                    ref.read(isFeaturedEnabledProvider.notifier).update((state) => value);
                                  }),
                              SwitchOption(
                                  deafultValue: isCategoriesEnbaled,
                                  title: 'Categories Section',
                                  onChanged: (value) {
                                    ref.read(isCategoriesEnabledProvider.notifier).update((state) => value);
                                  }),
                              SwitchOption(
                                  deafultValue: isFreeCoursesEnbled,
                                  title: 'Free Couses Section',
                                  onChanged: (value) {
                                    ref.read(isFreeCoursesEnabledProvider.notifier).update((state) => value);
                                  }),
                              SwitchOption(
                                  deafultValue: isTopAuthorsEnabled,
                                  title: 'Top Authors Sections',
                                  onChanged: (value) {
                                    ref.read(isTopAuthorsEnabledProvider.notifier).update((state) => value);
                                  }),
                              SwitchOption(
                                  deafultValue: isLatestCoursesEnabled,
                                  title: 'Latest Courses Section',
                                  onChanged: (value) {
                                    ref.read(isLatestCoursesProvider.notifier).update((state) => value);
                                  }),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: CategoryDropdown(
                                  title: 'Home Category 1',
                                  selectedCategoryId: selectedCategoryId1,
                                  onChanged: (value) => ref.read(selectedHomeCategoryId1Provider.notifier).update((state) => value),
                                  hasClearButton: true,
                                  onClearSelection: () => ref.read(selectedHomeCategoryId1Provider.notifier).update((state) => null),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: CategoryDropdown(
                                  title: 'Home Category 2',
                                  selectedCategoryId: selectedCategoryId2,
                                  onChanged: (value) => ref.read(selectedHomeCategoryId2Provider.notifier).update((state) => value),
                                  hasClearButton: true,
                                  onClearSelection: () => ref.read(selectedHomeCategoryId2Provider.notifier).update((state) => null),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 50),
                                child: CategoryDropdown(
                                  title: 'Home Category 3',
                                  selectedCategoryId: selectedCategoryId3,
                                  onChanged: (value) => ref.read(selectedHomeCategoryId3Provider.notifier).update((state) => value),
                                  hasClearButton: true,
                                  onClearSelection: () => ref.read(selectedHomeCategoryId3Provider.notifier).update((state) => null),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(30),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search Tab',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              SwitchOption(
                                  deafultValue: isTagsEnabled,
                                  title: 'Show Tags',
                                  onChanged: (value) {
                                    ref.read(isTagsEnabledProvider.notifier).update((state) => value);
                                  }),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(30),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Others',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              SwitchOption(
                                  deafultValue: onBoardingEnabled,
                                  title: 'On Boarding',
                                  onChanged: (value) {
                                    ref.read(isOnboardingEnabledProvider.notifier).update((state) => value);
                                  }),
                              SwitchOption(
                                  deafultValue: isSkipLoginEnabled,
                                  title: 'Skip Login',
                                  onChanged: (value) {
                                    ref.read(isSkipLoginEnabledProvider.notifier).update((state) => value);
                                  }),
                              SwitchOption(
                                deafultValue: contentSecurityEnabled,
                                title: 'Content Security (Disable screenshots and screen recording)',
                                onChanged: (value) {
                                  ref.read(isContentSecurityEnabledProvider.notifier).update((state) => value);
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(30),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Informations',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: supportEmailCtlr,
                                    hint: 'Email',
                                    title: 'Support Email',
                                    hasImageUpload: false,
                                    validationRequired: false),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: websiteCtlr,
                                    hint: 'Your website url',
                                    title: 'Website URL',
                                    hasImageUpload: false,
                                    validationRequired: false),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: privacyCtlr,
                                    hint: 'Privacy url',
                                    title: 'Privacy Policy',
                                    hasImageUpload: false,
                                    validationRequired: false),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(30),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Social Informations',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: fbCtlr, hint: 'Facebook Page', title: 'Facebook', hasImageUpload: false, validationRequired: false),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: youtubeCtlr,
                                    hint: 'Youtube channel url',
                                    title: 'Youtube',
                                    hasImageUpload: false,
                                    validationRequired: false),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: twitterCtrl,
                                    hint: 'X acount url',
                                    title: 'X (Formly Twitter)',
                                    hasImageUpload: false,
                                    validationRequired: false),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: buildTextField(context,
                                    controller: instaCtlr,
                                    hint: 'Instagram url',
                                    title: 'Instagram',
                                    hasImageUpload: false,
                                    validationRequired: false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
