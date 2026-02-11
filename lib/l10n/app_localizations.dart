import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyOceanApp'**
  String get appTitle;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'🌊 Ocean Disaster Chatbot'**
  String get chatbotTitle;

  /// No description provided for @askPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask about disasters...'**
  String get askPlaceholder;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Server error. Please try again.'**
  String get serverError;

  /// No description provided for @connectError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Could not connect to disaster server.'**
  String get connectError;

  /// No description provided for @nearbyReports.
  ///
  /// In en, this message translates to:
  /// **'Nearby Reports:'**
  String get nearbyReports;

  /// No description provided for @latestNews.
  ///
  /// In en, this message translates to:
  /// **'Latest Disaster News:'**
  String get latestNews;

  /// No description provided for @fallbackMsg.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I don’t have info on that right now. Stay safe and follow official alerts.'**
  String get fallbackMsg;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location error'**
  String get locationError;

  /// No description provided for @permDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery permission denied'**
  String get permDenied;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @syncedAndRemoved.
  ///
  /// In en, this message translates to:
  /// **'Synced and removed cached report'**
  String get syncedAndRemoved;

  /// No description provided for @syncFailedWillRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync report, will retry later'**
  String get syncFailedWillRetry;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields & get location'**
  String get fillAllFields;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline, will sync later'**
  String get savedOffline;

  /// No description provided for @cachedWillSync.
  ///
  /// In en, this message translates to:
  /// **'Report cached, will sync when online'**
  String get cachedWillSync;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get genericError;

  /// No description provided for @thankYouReport.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your report'**
  String get thankYouReport;

  /// No description provided for @reportSubmittedAppreciate.
  ///
  /// In en, this message translates to:
  /// **'Your report has been successfully submitted. We appreciate your contribution to making our community safer.'**
  String get reportSubmittedAppreciate;

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'Report Summary'**
  String get reportSummary;

  /// No description provided for @hazardType.
  ///
  /// In en, this message translates to:
  /// **'Hazard Type'**
  String get hazardType;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get lat;

  /// No description provided for @lng.
  ///
  /// In en, this message translates to:
  /// **'Lng'**
  String get lng;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnHome;

  /// No description provided for @hazardTypeEmoji.
  ///
  /// In en, this message translates to:
  /// **'🌊 Hazard Type'**
  String get hazardTypeEmoji;

  /// No description provided for @selectHazardType.
  ///
  /// In en, this message translates to:
  /// **'Select hazard type'**
  String get selectHazardType;

  /// No description provided for @severityLevelEmoji.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Severity Level'**
  String get severityLevelEmoji;

  /// No description provided for @locationEmoji.
  ///
  /// In en, this message translates to:
  /// **'📍 Location'**
  String get locationEmoji;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Current location detected...'**
  String get locationHint;

  /// No description provided for @getLocation.
  ///
  /// In en, this message translates to:
  /// **'Get location'**
  String get getLocation;

  /// No description provided for @descriptionEmoji.
  ///
  /// In en, this message translates to:
  /// **'📝 Description'**
  String get descriptionEmoji;

  /// No description provided for @describeHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you\'re observing...'**
  String get describeHint;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @addMediaEmoji.
  ///
  /// In en, this message translates to:
  /// **'📷 Add Photo/Video'**
  String get addMediaEmoji;

  /// No description provided for @tapToAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photos or videos'**
  String get tapToAddMedia;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @pendingOfflineEmoji.
  ///
  /// In en, this message translates to:
  /// **'📌 Pending Reports (Offline)'**
  String get pendingOfflineEmoji;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @keyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeatures;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'⚡ Quick Actions'**
  String get quickActions;

  /// No description provided for @reportHazard.
  ///
  /// In en, this message translates to:
  /// **'Report Hazard'**
  String get reportHazard;

  /// No description provided for @liveMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Live Monitoring'**
  String get liveMonitoring;

  /// No description provided for @hazardMapView.
  ///
  /// In en, this message translates to:
  /// **'📍 Hazard Map View'**
  String get hazardMapView;

  /// No description provided for @liveIncidents.
  ///
  /// In en, this message translates to:
  /// **'Live Incidents'**
  String get liveIncidents;

  /// No description provided for @predictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictions;

  /// No description provided for @activeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Active Alerts'**
  String get activeAlerts;

  /// No description provided for @reportsToday.
  ///
  /// In en, this message translates to:
  /// **'Reports Today'**
  String get reportsToday;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @submitHazardReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Hazard Report'**
  String get submitHazardReport;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @scrapedReports.
  ///
  /// In en, this message translates to:
  /// **'Scraped Reports'**
  String get scrapedReports;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
