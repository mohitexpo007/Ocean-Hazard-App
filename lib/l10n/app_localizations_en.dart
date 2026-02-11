// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyOceanApp';

  @override
  String get chatbotTitle => '🌊 Ocean Disaster Chatbot';

  @override
  String get askPlaceholder => 'Ask about disasters...';

  @override
  String get send => 'Send';

  @override
  String get loading => 'Loading...';

  @override
  String get serverError => '⚠️ Server error. Please try again.';

  @override
  String get connectError => '⚠️ Could not connect to disaster server.';

  @override
  String get nearbyReports => 'Nearby Reports:';

  @override
  String get latestNews => 'Latest Disaster News:';

  @override
  String get fallbackMsg =>
      'Sorry, I don’t have info on that right now. Stay safe and follow official alerts.';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get clear => 'Clear';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get locationError => 'Location error';

  @override
  String get permDenied => 'Camera or gallery permission denied';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get syncedAndRemoved => 'Synced and removed cached report';

  @override
  String get syncFailedWillRetry => 'Failed to sync report, will retry later';

  @override
  String get fillAllFields => 'Please fill all fields & get location';

  @override
  String get savedOffline => 'Saved offline, will sync later';

  @override
  String get cachedWillSync => 'Report cached, will sync when online';

  @override
  String get genericError => 'Error';

  @override
  String get thankYouReport => 'Thank you for your report';

  @override
  String get reportSubmittedAppreciate =>
      'Your report has been successfully submitted. We appreciate your contribution to making our community safer.';

  @override
  String get reportSummary => 'Report Summary';

  @override
  String get hazardType => 'Hazard Type';

  @override
  String get locationLabel => 'Location';

  @override
  String get lat => 'Lat';

  @override
  String get lng => 'Lng';

  @override
  String get severity => 'Severity';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get viewReport => 'View Report';

  @override
  String get returnHome => 'Return to Home';

  @override
  String get hazardTypeEmoji => '🌊 Hazard Type';

  @override
  String get selectHazardType => 'Select hazard type';

  @override
  String get severityLevelEmoji => '⚠️ Severity Level';

  @override
  String get locationEmoji => '📍 Location';

  @override
  String get locationHint => 'Current location detected...';

  @override
  String get getLocation => 'Get location';

  @override
  String get descriptionEmoji => '📝 Description';

  @override
  String get describeHint => 'Describe what you\'re observing...';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get addMediaEmoji => '📷 Add Photo/Video';

  @override
  String get tapToAddMedia => 'Tap to add photos or videos';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get pendingOfflineEmoji => '📌 Pending Reports (Offline)';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get keyFeatures => 'Key Features';

  @override
  String get hello => 'Hello,';

  @override
  String get quickActions => '⚡ Quick Actions';

  @override
  String get reportHazard => 'Report Hazard';

  @override
  String get liveMonitoring => 'Live Monitoring';

  @override
  String get hazardMapView => '📍 Hazard Map View';

  @override
  String get liveIncidents => 'Live Incidents';

  @override
  String get predictions => 'Predictions';

  @override
  String get activeAlerts => 'Active Alerts';

  @override
  String get reportsToday => 'Reports Today';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get submitHazardReport => 'Submit Hazard Report';

  @override
  String get navigation => 'Navigation';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get analytics => 'Analytics';

  @override
  String get myReports => 'My Reports';

  @override
  String get chatbot => 'Chatbot';

  @override
  String get scrapedReports => 'Scraped Reports';
}
