import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 🔹 Firebase & Permissions
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myoceanapp/config.dart';
import 'package:permission_handler/permission_handler.dart';

// 🔹 Caching & Connectivity
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// 🔹 Import your pages
import 'login.dart';
import 'signup.dart';
import 'otp_verify.dart';
import 'dashboard.dart';
import 'profile.dart';
import 'splash_screen.dart';
import 'notification_service.dart';
import 'notifications_page.dart';

// 🔹 i18n imports
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

// 🔹 Locale helper (shared by dashboard & others)
import 'app_locale.dart';

// ──────────────────────────────────────────────────────────────
// 🔹 Background notification handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  if (notification != null) {
    await NotificationService.showNotification(
      notification.title ?? "No title",
      notification.body ?? "No body",
    );
    appNotifications.insert(0, {
      "title": notification.title ?? "No title",
      "message": notification.body ?? "No body",
      "timestamp": DateTime.now().toIso8601String(),
    });
  }
}

bool _syncInProgress = false; // 👈 to prevent duplicate syncs

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  // ✅ Hive initialization
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('offline_reports');
  await Hive.openBox('app_settings');

  // ✅ Load saved language into ValueNotifier used by MaterialApp
  await loadSavedLocale();

  // ✅ Sync cached reports when internet is back
  Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      _syncCachedReports();
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

// 🔹 Sync cached reports safely
Future<void> _syncCachedReports() async {
  if (_syncInProgress) return; // avoid parallel syncs
  _syncInProgress = true;

  final box = Hive.box('offline_reports');
  final keys = box.keys.toList();

  for (var key in keys) {
    final report = Map<String, dynamic>.from(box.get(key));

    final success = await _sendCachedToBackend(report);
    if (success) {
      await box.delete(key); // ✅ delete only after success
      debugPrint("✅ Synced and removed cached report: $report");
    } else {
      debugPrint("⚠️ Failed to sync report, will retry later");
    }
  }

  _syncInProgress = false;
}

// 🔹 Helper to send cached report to backend
Future<bool> _sendCachedToBackend(Map<String, dynamic> report) async {
  try {
    final uri = Uri.parse("$baseUrlx/citizen/reports/");
    final request = http.MultipartRequest("POST", uri);

    request.fields["user_id"] = report["user_id"];
    request.fields["text"] = report["text"];
    request.fields["lat"] = report["lat"].toString();
    request.fields["lon"] = report["lon"].toString();
    request.fields["hazard_type"] = report["hazard_type"];
    request.fields["severity"] = report["severity"];

    if (report["image"] != null) {
      request.files.add(await http.MultipartFile.fromPath(
        "image",
        report["image"],
      ));
    }

    final response = await request.send();
    return response.statusCode == 200;
  } catch (e) {
    debugPrint("Cached send failed: $e");
    return false;
  }
}

// 🔹 Global store for notifications
List<Map<String, dynamic>> appNotifications = [];

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ------------------ UI Code ------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild app when locale changes
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (_, locale, __) {
        return MaterialApp(
          title: 'My Ocean App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          navigatorKey: navigatorKey,
          initialRoute: '/',
          locale: locale, // 👈 runtime locale
          // i18n wiring
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'), // Hindi
          ],
          routes: {
            '/': (context) => const SplashWrapper(),
            '/home': (context) => const HomePage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignupPage(),
            '/notifications': (context) => NotificationsPage(
              notifications: appNotifications,
              onClear: () {
                appNotifications.clear();
                (context as Element).markNeedsBuild();
              },
            ),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/otp') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => OtpVerifyPage(
                  email: args['email'],
                  username: args['username'],
                ),
              );
            } else if (settings.name == '/dashboard') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) =>
                    DashboardPage(username: args['username']),
              );
            } else if (settings.name == '/profile') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => ProfilePage(username: args['username']),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();

    // 🔐 Print JWT right at startup (no Firebase Auth involved)
    _printJwtOnStartup();

    _setupNotifications();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  // 🔐 NEW: fetch & print JWT like your FCM print style
  Future<void> _printJwtOnStartup() async {
    final uri = Uri.parse("$baseUrlx/auth/anon-jwt");
    print("🔐 Calling $uri for JWT...");
    try {
      final resp = await http
          .post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": null}),
      )
          .timeout(const Duration(seconds: 8));

      print("🔐 JWT status: ${resp.statusCode}");
      print("🔐 JWT body  : ${resp.body}");

      if (resp.statusCode == 200) {
        final token = (jsonDecode(resp.body)["jwt"] as String?) ?? "";
        if (token.isEmpty) {
          print("⚠️ JWT empty in response");
        } else {
          final preview =
          token.length > 28 ? "${token.substring(0, 28)}..." : token;
          print("🔐 App JWT (preview): $preview");
        }
      } else {
        print("⚠️ JWT request failed: ${resp.statusCode} ${resp.reasonPhrase}");
      }
    } on TimeoutException {
      print("⏳ JWT request timed out (8s). Is your tunnel/host awake?");
    } catch (e) {
      print("❌ JWT request error: $e");
    }
  }

  Future<void> _setupNotifications() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      print("📲 Device FCM Token: $token");
      if (token != null) {
        await http.post(
          Uri.parse("$baseUrlx/register-token"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"token": token}),
        );
      }
    } else {
      print("❌ Notifications denied");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        final data = {
          "title": notification.title ?? "No title",
          "message": notification.body ?? "No body",
          "timestamp": DateTime.now().toIso8601String(),
        };
        appNotifications.insert(0, data);
        NotificationService.showNotification(
            data["title"]!, data["message"]!);
        _showAlert(data["title"]!, data["message"]!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushNamed("/notifications");
    });
  }

  void _showAlert(String title, String body) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style:
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(body, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dismiss"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/notifications");
            },
            child: const Text("View"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplashScreen();
  }
}

// ──────────────────────────────────────────────────────────────
// HomePage redesigned: beach background, new title & colored icons
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _chooseLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Language / भाषा',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English'),
              onTap: () {
                saveLocale(const Locale('en'));
                Navigator.pop(context);
              },
              trailing: (appLocale.value?.languageCode ?? 'en') == 'en'
                  ? const Icon(Icons.check, color: Colors.teal)
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('हिन्दी'),
              onTap: () {
                saveLocale(const Locale('hi'));
                Navigator.pop(context);
              },
              trailing: (appLocale.value?.languageCode ?? 'en') == 'hi'
                  ? const Icon(Icons.check, color: Colors.teal)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _chooseLanguage(context),
        icon: const Icon(Icons.language),
        label: const Text('Language'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 📸 Beach background + subtle gradient scrim for text contrast
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/beach_bg.jpg",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // top rounded icon tile
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 44),
                    ),

                    const SizedBox(height: 20),

                    // 🆕 Title changed
                    const Text(
                      "Samudra Rakshak",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "AI-Powered Disaster Management &\nEmergency Response System",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Feature cards with themed colors
                    Row(
                      children: const [
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.warning_amber_rounded,
                            title: "Smart Alerts",
                            subtitle: "Real-time disaster\n detection with AI",
                            iconBg: Color(0xFFFFE08A),   // amber bg
                            iconColor: Color(0xFF9C6F00),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.verified_rounded,
                            title: "Report Verification",
                            subtitle: "Crowd-sourced\n validation system",
                            iconBg: Color(0xFFB8F5C2),   // green bg
                            iconColor: Color(0xFF1E7A3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.auto_awesome,
                            title: "AI Insights",
                            subtitle: "Clustered & AI-\n powered insights",
                            iconBg: Color(0xFFB9E8FF),   // cyan/blue bg
                            iconColor: Color(0xFF0E74A8),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.sos_rounded,
                            title: "Help & SOS",
                            subtitle: "Direct connection to\n emergency services",
                            iconBg: Color(0xFFFFC2C2),   // red bg
                            iconColor: Color(0xFFB00020), // deep red icon
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // Get Started — gradient pill
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF31D8A4), Color(0xFF1EC6E2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF14C7C3).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Get Started",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Sign In — glass outline button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.28)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.08),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Glassy feature card used on the home page
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBg = const Color(0x33FFFFFF),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
