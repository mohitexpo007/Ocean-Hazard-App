import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hive/hive.dart';

import 'config.dart';
import 'my_reports_page.dart';

class ReportFormWidget extends StatefulWidget {
  final String userId;
  const ReportFormWidget({super.key, required this.userId});

  @override
  _ReportFormWidgetState createState() => _ReportFormWidgetState();
}

class _ReportFormWidgetState extends State<ReportFormWidget> {
  final _formKey = GlobalKey<FormState>();
  String? _hazardType;
  String? _severity;
  String _description = "";
  Position? _location;

  // Media (photo or video)
  File? _pickedMedia;
  bool _pickedIsVideo = false;

  WebSocketChannel? _channel;
  bool _loading = false;

  // AI state
  bool _aiBusy = false;
  String? _aiDetected; // e.g., "Cyclone"

  List<Map<String, dynamic>> _pendingReports = [];

  // Updated options
  final List<String> hazardTypes = [
    "Flood",
    "Tsunami",
    "Cyclone",
    "Storm Surge",
    "Coastal Erosion",
  ];
  final List<String> severityLevels = ["low", "medium", "high", "critical"];

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse(getWsUrl("/citizen/ws/reports")),
    );
    _loadPendingReports();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _location = pos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();
    if (cameraStatus.isDenied || photosStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera or gallery permission denied")),
      );
      return false;
    }
    return true;
  }

  // Pick media (two-step: 1) Camera/Gallery, 2) Photo/Video)
  Future<void> _pickMedia() async {
    if (!await _requestPermissions()) return;

    // Step 1: Choose source (ONLY Camera / Gallery)
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Step 2: Choose media type (Photo / Video)
    final kind = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose Type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Photo"),
              onTap: () => Navigator.of(ctx).pop("photo"),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Video"),
              onTap: () => Navigator.of(ctx).pop("video"),
            ),
          ],
        ),
      ),
    );
    if (kind == null) return;

    // Perform actual pick based on selections
    if (kind == "photo") {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        setState(() {
          _pickedMedia = File(picked.path);
          _pickedIsVideo = false;
        });
      }
    } else {
      final picked = await ImagePicker().pickVideo(source: source);
      if (picked != null) {
        setState(() {
          _pickedMedia = File(picked.path);
          _pickedIsVideo = true;
        });
      }
    }
  }

  Future<void> _loadPendingReports() async {
    final box = Hive.box('offline_reports');
    setState(() {
      _pendingReports = box.values.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> _syncPendingReports() async {
    final box = Hive.box('offline_reports');
    final keys = box.keys.toList();

    for (var key in keys) {
      final report = Map<String, dynamic>.from(box.get(key));
      bool success = await _sendToBackend(report);
      if (success) {
        await box.delete(key);
        debugPrint("✅ Synced and removed cached report: $report");
      } else {
        debugPrint("⚠ Failed to sync cached report, keeping it");
      }
    }
    await _loadPendingReports();
  }

  // ---- AI Hazard Recognition (mock) ----
  // Shows 1s loading, then selects "Cyclone" and prints "Detected: Cyclone" below the button.
  Future<void> _runAiRecognition() async {
    setState(() {
      _aiBusy = true;
      _aiDetected = null; // clear previous
    });

    await Future.delayed(const Duration(seconds: 1)); // loading effect

    setState(() {
      _hazardType = "Cyclone"; // select in dropdown (label)
      _aiDetected = "Cyclone"; // show below the button
      _aiBusy = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("AI detected: Cyclone")),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _location == null || _hazardType == null || _severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select hazard, severity & fetch location")),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _loading = true);

    final reportData = {
      "user_id": widget.userId,
      "text": _description,
      "lat": _location!.latitude,
      "lon": _location!.longitude,
      "hazard_type": _hazardType,
      "severity": _severity,
      "image": _pickedMedia?.path,
      "media_type": _pickedIsVideo ? "video" : "image",
    };

    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity != ConnectivityResult.none) {
        bool success = await _sendToBackend(reportData);
        if (success) {
          _showSuccessPopup(reportData);
        } else {
          Hive.box('offline_reports').add(reportData);
          await _loadPendingReports();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠ Saved offline, will sync later")),
          );
        }
      } else {
        Hive.box('offline_reports').add(reportData);
        await _loadPendingReports();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📌 Report cached, will sync when online")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  Future<bool> _sendToBackend(Map<String, dynamic> report) async {
    try {
      var uri = Uri.parse("$baseUrlx/citizen/reports/");
      var request = http.MultipartRequest("POST", uri);

      request.fields["user_id"] = report["user_id"];
      request.fields["text"] = report["text"] ?? "";
      request.fields["lat"] = report["lat"].toString();
      request.fields["lon"] = report["lon"].toString();

      // Normalize hazard label → backend-friendly snake_case
      final normalizedHazard =
      ((report["hazard_type"] ?? "") as String).toLowerCase().replaceAll(' ', '_');
      request.fields["hazard_type"] = normalizedHazard;

      request.fields["severity"] = report["severity"];
      request.fields["media_type"] = report["media_type"] ?? "image";

      if (report["image"] != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "image",
          report["image"],
        ));
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Send failed: $e");
      return false;
    }
  }

  void _showSuccessPopup(Map<String, dynamic> reportData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("✅ Thank you for your report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your report has been successfully submitted. We appreciate your contribution to making our community safer.",
            ),
            const SizedBox(height: 16),
            const Text("Report Summary", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _summaryRow(Icons.warning, "Hazard Type", reportData["hazard_type"]),
            _summaryRow(Icons.location_on, "Location",
                "Lat: ${reportData["lat"]}, Lng: ${reportData["lon"]}"),
            _summaryRow(Icons.security, "Severity", reportData["severity"]),
            _summaryRow(Icons.description, "Description",
                (reportData["text"] ?? "").isEmpty ? "—" : reportData["text"]),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyReportsPage(userId: widget.userId)),
              );
            },
            child: const Text("View Report"),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Return to Home"),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text("$label: ${value ?? "-"}", style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Hazard Type
          const Text("🌊 Hazard Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _hazardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            items: hazardTypes
                .map((label) => DropdownMenuItem(
              value: label,
              child: Text(label),
            ))
                .toList(),
            onChanged: (val) => setState(() => _hazardType = val),
            validator: (val) => val == null ? "Select hazard type" : null,
          ),
          const SizedBox(height: 16),

          // 2) Add Photo/Video + AI Recognition
          const Text("📷 Add Photo/Video", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickMedia,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Center(
                child: _pickedMedia == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.perm_media, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Tap to add photo or video"),
                  ],
                )
                    : (_pickedIsVideo
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_filled, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedMedia!.path.split(Platform.pathSeparator).last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_pickedMedia!, fit: BoxFit.cover, width: double.infinity),
                )),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2a) AI Button (centered text) + Detected below
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _aiBusy ? null : _runAiRecognition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C35FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _aiBusy
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text("Detecting..."),
                  ],
                )
                    : const Text("✨ Use AI Hazard Recognition", textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _aiDetected == null
                    ? const SizedBox.shrink()
                    : Row(
                  key: const ValueKey('detectedRow'),
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      "Detected: ${_aiDetected!}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3) Location
          const Text("📍 Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Current location detected...",
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _getLocation,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            controller: TextEditingController(
              text: _location == null ? "" : "Lat: ${_location!.latitude}, Lng: ${_location!.longitude}",
            ),
          ),
          const SizedBox(height: 16),

          // 4) Severity
          const Text("⚠ Severity Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: ["Low", "Medium", "High", "Critical"].map((level) {
              bool selected = _severity?.toLowerCase() == level.toLowerCase();
              return ChoiceChip(
                label: Text(level),
                selected: selected,
                onSelected: (_) => setState(() => _severity = level.toLowerCase()),
                selectedColor: level == "High"
                    ? Colors.red
                    : (level == "Critical" ? Colors.black : Colors.blueAccent),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 5) Description (optional)
          const Text("📝 Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          TextFormField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe what you're observing... (optional)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSaved: (val) => _description = val ?? "",
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFFE94057),
                foregroundColor: Colors.white,
              ),
              onPressed: _submitForm,
              icon: const Icon(Icons.send),
              label: const Text("Submit Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 20),

          // Pending Reports (Offline Sync Section)
          if (_pendingReports.isNotEmpty) ...[
            const Divider(),
            const Text("📌 Pending Reports (Offline)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _pendingReports.length,
                itemBuilder: (ctx, i) {
                  final r = _pendingReports[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.orange),
                      title: Text((r["hazard_type"] ?? "Unknown").toString()),
                      subtitle: Text("Severity: ${r["severity"]}\n${(r["text"] ?? "").toString()}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text("Sync Now"),
              onPressed: _syncPendingReports,
            ),
          ],
        ],
      ),
    );
  }
}
