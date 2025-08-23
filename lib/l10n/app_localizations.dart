import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get appTitle;

  /// No description provided for @loginSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In to the Admin Panel'**
  String get loginSignInTitle;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get commonLogin;

  /// No description provided for @loginHintEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginHintEmailAddress;

  /// No description provided for @loginHintPassword.
  ///
  /// In en, this message translates to:
  /// **'Your Password'**
  String get loginHintPassword;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email/Password is invalid'**
  String get authInvalidCredentials;

  /// No description provided for @authAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get authAccessDenied;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Purchase'**
  String get verifyTitle;

  /// No description provided for @verifyWhereCode.
  ///
  /// In en, this message translates to:
  /// **'Where is Your Purchase Code?'**
  String get verifyWhereCode;

  /// No description provided for @verifyCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get verifyCheck;

  /// No description provided for @verifyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Code'**
  String get verifyFieldLabel;

  /// No description provided for @verifyHint.
  ///
  /// In en, this message translates to:
  /// **'Your Purchase Code'**
  String get verifyHint;

  /// No description provided for @verifyRequired.
  ///
  /// In en, this message translates to:
  /// **'Purchase code is required'**
  String get verifyRequired;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @notificationsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preview'**
  String get notificationsPreviewTitle;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get commonOk;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @dialogYesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get dialogYesDelete;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created: {date}'**
  String accountCreated(String date);

  /// No description provided for @subscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription: '**
  String get subscriptionLabel;

  /// No description provided for @enrolledCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Courses ({count})'**
  String enrolledCoursesTitle(int count);

  /// No description provided for @noCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCoursesFound;

  /// No description provided for @wishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Wishlist ({count})'**
  String wishlistTitle(int count);

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String byAuthor(String author);

  /// No description provided for @percentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String percentCompleted(int percent);

  /// No description provided for @questionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions *'**
  String get questionsTitle;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestion;

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get noQuestionsFound;

  /// No description provided for @questionIndexTitle.
  ///
  /// In en, this message translates to:
  /// **'Q{number}. {title}'**
  String questionIndexTitle(int number, String title);

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer: {answer}'**
  String correctAnswer(String answer);

  /// No description provided for @quizAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get quizAddQuestion;

  /// No description provided for @quizUpdateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Update Question'**
  String get quizUpdateQuestion;

  /// No description provided for @quizEnterQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Question Title'**
  String get quizEnterQuestionTitle;

  /// No description provided for @quizQuestionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Question Title *'**
  String get quizQuestionTitleLabel;

  /// No description provided for @quizOptionsType.
  ///
  /// In en, this message translates to:
  /// **'Options Type'**
  String get quizOptionsType;

  /// No description provided for @quizOptionTypeFour.
  ///
  /// In en, this message translates to:
  /// **'Four Options'**
  String get quizOptionTypeFour;

  /// No description provided for @quizOptionTypeTwo.
  ///
  /// In en, this message translates to:
  /// **'Two Options'**
  String get quizOptionTypeTwo;

  /// No description provided for @quizOptionA.
  ///
  /// In en, this message translates to:
  /// **'Option A'**
  String get quizOptionA;

  /// No description provided for @quizOptionB.
  ///
  /// In en, this message translates to:
  /// **'Option B'**
  String get quizOptionB;

  /// No description provided for @quizOptionC.
  ///
  /// In en, this message translates to:
  /// **'Option C'**
  String get quizOptionC;

  /// No description provided for @quizOptionD.
  ///
  /// In en, this message translates to:
  /// **'Option D'**
  String get quizOptionD;

  /// No description provided for @quizSelectCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Select Correct Answer'**
  String get quizSelectCorrectAnswer;

  /// No description provided for @quizValueIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Value is required'**
  String get quizValueIsRequired;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @editorYoutubeUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Youtube Video Url'**
  String get editorYoutubeUrlTitle;

  /// No description provided for @editorImageUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get editorImageUrlTitle;

  /// No description provided for @editorNetworkVideoUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Video Url'**
  String get editorNetworkVideoUrlTitle;

  /// No description provided for @editorUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get editorUrlLabel;

  /// No description provided for @editorEnterYoutubeUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Youtube video Url'**
  String get editorEnterYoutubeUrlHint;

  /// No description provided for @editorEnterImageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Image Url'**
  String get editorEnterImageUrlHint;

  /// No description provided for @editorEnterVideoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Video URL'**
  String get editorEnterVideoUrlHint;

  /// No description provided for @validationValueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Value is empty'**
  String get validationValueEmpty;

  /// No description provided for @validationInvalidVideoId.
  ///
  /// In en, this message translates to:
  /// **'Invalid video ID'**
  String get validationInvalidVideoId;

  /// No description provided for @validationInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get validationInvalidUrl;

  /// No description provided for @editorInsertUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert URL'**
  String get editorInsertUrlTitle;

  /// No description provided for @editorInsertImageUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert Image URL'**
  String get editorInsertImageUrlTitle;

  /// No description provided for @editorInsertVideoUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert Video URL'**
  String get editorInsertVideoUrlTitle;

  /// No description provided for @editorDisplayTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Text'**
  String get editorDisplayTextLabel;

  /// No description provided for @editorTextToDisplayHint.
  ///
  /// In en, this message translates to:
  /// **'Text to Display'**
  String get editorTextToDisplayHint;

  /// No description provided for @editorEnterUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter URL'**
  String get editorEnterUrlHint;

  /// No description provided for @editorEnterDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter Description'**
  String get editorEnterDescriptionPlaceholder;

  /// No description provided for @tooltipInsertLink.
  ///
  /// In en, this message translates to:
  /// **'Insert Link'**
  String get tooltipInsertLink;

  /// No description provided for @tooltipInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get tooltipInsertImage;

  /// No description provided for @tooltipInsertVideo.
  ///
  /// In en, this message translates to:
  /// **'Insert Video Link'**
  String get tooltipInsertVideo;

  /// No description provided for @tooltipClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get tooltipClearAll;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get commonViewAll;

  /// No description provided for @dashboardLatestReviews.
  ///
  /// In en, this message translates to:
  /// **'Latest Reviews'**
  String get dashboardLatestReviews;

  /// No description provided for @dashboardNewUsers.
  ///
  /// In en, this message translates to:
  /// **'New Users'**
  String get dashboardNewUsers;

  /// No description provided for @dashboardLatestPurchases.
  ///
  /// In en, this message translates to:
  /// **'Latest Purchases'**
  String get dashboardLatestPurchases;

  /// No description provided for @dashboardTopCourses.
  ///
  /// In en, this message translates to:
  /// **'Top Courses'**
  String get dashboardTopCourses;

  /// No description provided for @dashboardEnrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Courses: {count}'**
  String dashboardEnrolledCourses(int count);

  /// No description provided for @dashboardStudentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String dashboardStudentsCount(int count);

  /// No description provided for @chartLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get chartLast7Days;

  /// No description provided for @chartLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get chartLast30Days;

  /// No description provided for @chartSubscriptionPurchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Purchases'**
  String get chartSubscriptionPurchasesTitle;

  /// No description provided for @chartPurchasesTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} Purchases'**
  String chartPurchasesTooltip(int count);

  /// No description provided for @chartNewUserRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'News User Registration'**
  String get chartNewUserRegistrationTitle;

  /// No description provided for @chartUsersTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} Users'**
  String chartUsersTooltip(int count);

  /// No description provided for @authorTotalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get authorTotalStudents;

  /// No description provided for @authorTotalCourses.
  ///
  /// In en, this message translates to:
  /// **'Total Courses'**
  String get authorTotalCourses;

  /// No description provided for @authorTotalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get authorTotalReviews;

  /// No description provided for @priceStatusFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get priceStatusFree;

  /// No description provided for @priceStatusPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get priceStatusPremium;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
