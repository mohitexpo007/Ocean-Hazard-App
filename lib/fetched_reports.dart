import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvestigationAnalysisPage extends StatefulWidget {
  const InvestigationAnalysisPage({super.key});

  @override
  State<InvestigationAnalysisPage> createState() =>
      _InvestigationAnalysisPageState();
}

class _InvestigationAnalysisPageState extends State<InvestigationAnalysisPage>
    with TickerProviderStateMixin {
  List redditReports = [];

  // Animation controllers
  late AnimationController _liveController;
  late AnimationController _wifiPulseController;
  final Map<String, PageController> _pageControllers = {};
  Timer? _timer;

  // Dummy API reports
  final Map<String, List<String>> apiReports = {
    "Twitter/X API": [
      "High volume of eyewitness reports and images of a potential oil slick are trending under #MumbaiOilSpill.",
      "Users sharing oil slick images near Arabian Sea.",
      "Hashtag storm: 1200+ mentions in 1 hour."
    ],
    "Meta API": [
      "Local fishing community groups on Facebook are posting actively, expressing concern over livelihood impact.",
      "Livelihood fears spreading in coastal forums.",
      "Community calls for immediate government response."
    ],
    "Reddit API": [
      "Discussions on r/mumbai and r/india point to vessel V-788.",
      "r/mumbai & r/india threads crossing 300 comments.",
      "Tracking data screenshots shared actively."
    ],
    "News APIs": [
      "Major outlets have picked up the story, citing coast guard sources confirming response team mobilization.",
      "Major outlets headline the oil spill.",
      "Analysts warn of tourism & fishing disruption."
    ],
    "INCOIS API": [
      "Hazard alert confirms a potential chemical spill and issues a warning for the affected coastal coordinates.",
      "Warning issued for Arabian Sea coordinates.",
      "Spill may affect 50km coastal stretch."
    ],
  };

  // ✅ Correct logo mapping
  final Map<String, String> apiLogos = {
    "Twitter/X API": "assets/twitter.png",
    "Meta API": "assets/meta.png",
    "Reddit API": "assets/reddit.png",
    "News APIs": "assets/news.png",
    "INCOIS API": "assets/incois.png",
  };

  // 🔹 Stats counters
  int mentions = 1247;
  int posts = 892;
  int discussions = 334;
  int articles = 56;
  int alerts = 2;

  @override
  void initState() {
    super.initState();
    fetchReports();

    // 🔹 Animation controllers
    _liveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);

    _wifiPulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    // 🔹 Page controllers
    for (var api in apiReports.keys) {
      _pageControllers[api] = PageController();
    }

    // 🔹 Auto-switch every 2s
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        // Update stats randomly for demo
        mentions += 5;
        posts += 3;
        discussions += 2;
        articles += 1;

        // Auto switch pageviews
        for (var entry in _pageControllers.entries) {
          final controller = entry.value;
          if (controller.hasClients) {
            int nextPage = (controller.page?.round() ?? 0) + 1;
            if (nextPage >= 3) nextPage = 0;
            controller.animateToPage(nextPage,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _liveController.dispose();
    _wifiPulseController.dispose();
    for (var c in _pageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> fetchReports() async {
    final res = await http.get(Uri.parse(
        "https://paronymic-noncontumaciously-clarence.ngrok-free.dev/scraped/reports"));
    if (res.statusCode == 200) {
      setState(() {
        redditReports = json.decode(res.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Investigation Analysis"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "CRITICAL",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("# MCR-2025-0927",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.blue)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text("📍 Arabian Sea, 18.9°N, 72.8°E",
                                style: TextStyle(color: Colors.blue)),
                            SizedBox(height: 4),
                            Text("⏰ 14:32 IST",
                                style: TextStyle(color: Colors.blue)),
                          ],
                        )
                      ],
                    ),
                  ),

                  const Divider(height: 20),

                  // 🔹 Live feed section
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _wifiPulseController,
                          builder: (context, child) {
                            return Icon(Icons.wifi,
                                size: 20,
                                color: Color.lerp(
                                    Colors.red.withOpacity(0.4),
                                    Colors.red,
                                    _wifiPulseController.value));
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text("Live Social Media Intelligence Feed",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        ScaleTransition(
                          scale: Tween(begin: 0.9, end: 1.15)
                              .animate(_liveController),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text("LIVE",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔹 API Intelligence Summary with logo
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Image.asset("assets/summary.png",
                            width: 20, height: 20), // ✅ add custom logo
                        const SizedBox(width: 6),
                        const Text("API Intelligence Summary",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  ...apiReports.entries.map((entry) {
                    final reports = entry.value;
                    final controller = _pageControllers[entry.key]!;
                    return _buildApiCard(
                        entry.key,
                        reports,
                        controller,
                        entry.key == "Twitter/X API"
                            ? mentions
                            : entry.key == "Meta API"
                                ? posts
                                : entry.key == "Reddit API"
                                    ? (redditReports.isEmpty
                                        ? discussions
                                        : redditReports.length)
                                    : entry.key == "News APIs"
                                        ? articles
                                        : alerts,
                        entry.key == "Twitter/X API"
                            ? "Mentions"
                            : entry.key == "Meta API"
                                ? "Posts"
                                : entry.key == "Reddit API"
                                    ? "Discussions"
                                    : entry.key == "News APIs"
                                        ? "Articles"
                                        : "Alerts",
                        apiLogos[entry.key]!);
                  }).toList(),

                  const Divider(height: 30),

                  // 🔹 Sentiment Trend
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("Sentiment Trend",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CircularProgressIndicator(
                              value: 0.8,
                              strokeWidth: 12,
                              color: Colors.red,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const Text("80%\nCritical",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.circle, color: Colors.red, size: 12),
                              SizedBox(width: 4),
                              Text("Critical (80%)"),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.circle,
                                  color: Colors.orange, size: 12),
                              SizedBox(width: 4),
                              Text("Moderate (15%)"),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 12),
                              SizedBox(width: 4),
                              Text("Positive (5%)"),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 🔹 Bottom Stats Row FIXED with SafeArea
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)
                  .copyWith(bottom: 20), // ✅ extra bottom padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomStat("$mentions", "Mentions", Colors.purple),
                  _buildBottomStat("$posts", "Posts", Colors.blue),
                  _buildBottomStat(
                      redditReports.isEmpty
                          ? "$discussions"
                          : redditReports.length.toString(),
                      "Discussions",
                      Colors.orange),
                  _buildBottomStat("$articles", "Articles", Colors.green),
                  _buildBottomStat("$alerts", "Alerts", Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiCard(String title, List<String> reports,
      PageController controller, int value, String label, String iconPath) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                  child: Image.asset(iconPath, width: 28, height: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(
              height: 60,
              child: PageView.builder(
                controller: controller,
                itemCount: reports.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Text(reports[i],
                        style: const TextStyle(color: Colors.black54)),
                  );
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$value",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }
}
