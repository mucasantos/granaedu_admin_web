// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Admin Panel';

  @override
  String get loginSignInTitle => 'Sign In to the Admin Panel';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonLogin => 'Login';

  @override
  String get loginHintEmailAddress => 'Email Address';

  @override
  String get loginHintPassword => 'Your Password';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get authInvalidCredentials => 'Email/Password is invalid';

  @override
  String get authAccessDenied => 'Access Denied';

  @override
  String get verifyTitle => 'Verify Your Purchase';

  @override
  String get verifyWhereCode => 'Where is Your Purchase Code?';

  @override
  String get verifyCheck => 'Check';

  @override
  String get verifyFieldLabel => 'Purchase Code';

  @override
  String get verifyHint => 'Your Purchase Code';

  @override
  String get verifyRequired => 'Purchase code is required';

  @override
  String get verifyButton => 'Verify';

  @override
  String get notificationsPreviewTitle => 'Notification Preview';

  @override
  String get commonOk => 'Okay';

  @override
  String get commonNo => 'No';

  @override
  String get dialogYesDelete => 'Yes, Delete';

  @override
  String accountCreated(String date) {
    return 'Account Created: $date';
  }

  @override
  String get subscriptionLabel => 'Subscription: ';

  @override
  String enrolledCoursesTitle(int count) {
    return 'Enrolled Courses ($count)';
  }

  @override
  String get noCoursesFound => 'No courses found';

  @override
  String wishlistTitle(int count) {
    return 'Wishlist ($count)';
  }

  @override
  String byAuthor(String author) {
    return 'By $author';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% completed';
  }

  @override
  String get questionsTitle => 'Questions *';

  @override
  String get addQuestion => 'Add Question';

  @override
  String get noQuestionsFound => 'No questions found';

  @override
  String questionIndexTitle(int number, String title) {
    return 'Q$number. $title';
  }

  @override
  String correctAnswer(String answer) {
    return 'Correct Answer: $answer';
  }

  @override
  String get quizAddQuestion => 'Add Question';

  @override
  String get quizUpdateQuestion => 'Update Question';

  @override
  String get quizEnterQuestionTitle => 'Enter Question Title';

  @override
  String get quizQuestionTitleLabel => 'Question Title *';

  @override
  String get quizOptionsType => 'Options Type';

  @override
  String get quizOptionTypeFour => 'Four Options';

  @override
  String get quizOptionTypeTwo => 'Two Options';

  @override
  String get quizOptionA => 'Option A';

  @override
  String get quizOptionB => 'Option B';

  @override
  String get quizOptionC => 'Option C';

  @override
  String get quizOptionD => 'Option D';

  @override
  String get quizSelectCorrectAnswer => 'Select Correct Answer';

  @override
  String get quizValueIsRequired => 'Value is required';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get editorYoutubeUrlTitle => 'Youtube Video Url';

  @override
  String get editorImageUrlTitle => 'Image URL';

  @override
  String get editorNetworkVideoUrlTitle => 'Network Video Url';

  @override
  String get editorUrlLabel => 'URL';

  @override
  String get editorEnterYoutubeUrlHint => 'Enter Youtube video Url';

  @override
  String get editorEnterImageUrlHint => 'Enter Image Url';

  @override
  String get editorEnterVideoUrlHint => 'Enter Video URL';

  @override
  String get validationValueEmpty => 'Value is empty';

  @override
  String get validationInvalidVideoId => 'Invalid video ID';

  @override
  String get validationInvalidUrl => 'Invalid URL';

  @override
  String get editorInsertUrlTitle => 'Insert URL';

  @override
  String get editorInsertImageUrlTitle => 'Insert Image URL';

  @override
  String get editorInsertVideoUrlTitle => 'Insert Video URL';

  @override
  String get editorDisplayTextLabel => 'Display Text';

  @override
  String get editorTextToDisplayHint => 'Text to Display';

  @override
  String get editorEnterUrlHint => 'Enter URL';

  @override
  String get editorEnterDescriptionPlaceholder => 'Enter Description';

  @override
  String get tooltipInsertLink => 'Insert Link';

  @override
  String get tooltipInsertImage => 'Image';

  @override
  String get tooltipInsertVideo => 'Insert Video Link';

  @override
  String get tooltipClearAll => 'Clear All';

  @override
  String get commonViewAll => 'View All';

  @override
  String get dashboardLatestReviews => 'Latest Reviews';

  @override
  String get dashboardNewUsers => 'New Users';

  @override
  String get dashboardLatestPurchases => 'Latest Purchases';

  @override
  String get dashboardTopCourses => 'Top Courses';

  @override
  String dashboardEnrolledCourses(int count) {
    return 'Enrolled Courses: $count';
  }

  @override
  String dashboardStudentsCount(int count) {
    return '$count students';
  }

  @override
  String get chartLast7Days => 'Last 7 Days';

  @override
  String get chartLast30Days => 'Last 30 Days';

  @override
  String get chartSubscriptionPurchasesTitle => 'Subscription Purchases';

  @override
  String chartPurchasesTooltip(int count) {
    return '$count Purchases';
  }

  @override
  String get chartNewUserRegistrationTitle => 'News User Registration';

  @override
  String chartUsersTooltip(int count) {
    return '$count Users';
  }

  @override
  String get authorTotalStudents => 'Total Students';

  @override
  String get authorTotalCourses => 'Total Courses';

  @override
  String get authorTotalReviews => 'Total Reviews';

  @override
  String get priceStatusFree => 'Free';

  @override
  String get priceStatusPremium => 'Premium';
}
