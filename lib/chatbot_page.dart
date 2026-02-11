import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

final String backendUrl = "$baseUrlx/citizen/chatbot";

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isLoading = false;

  // Suggestions (English only)
  final List<String> _suggestions = const [
    "🌀 Cyclone safety",
    "🌊 Tsunami evacuation",
    "🌧️ Flood tips",
    "📍 Nearby risks",
    "📰 Latest alerts",
  ];

  @override
  void initState() {
    super.initState();

    // English-only welcome (hello with 2 emojis)
    const welcome = """
Hello! 👋🙂

**What my app does:**
• Real-time alerts & nearby risks  
• Cyclone / Tsunami / Flood guidance  
• Evacuation tips, emergency kit & helplines

What would you like to know?
""";
    _messages.add({"role": "bot", "text": welcome});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text.trim()});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": "u123",
          "message": text.trim(),
          "lat": 20.9392,
          "lon": 79.0100
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({"role": "bot", "text": "${data["reply"]}"});
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": "⚠️ Server error. Please try again."
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "⚠️ Could not connect to the server. Please check your network."
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8A56F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(Icons.smart_toy, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "OceanIQ", // renamed title
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.lightGreenAccent, size: 8),
                    SizedBox(width: 6),
                    Text("Online",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          // settings icon placeholder
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";
    final text = msg["text"] ?? "";

    if (isUser) {
      // User bubble – purple gradient (right)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8A56F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    } else {
      // Bot bubble – card style with avatar (left)
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEDEAFF),
              ),
              child: const Icon(Icons.smart_toy, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SelectableText(
                  text,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      );
    }
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(), SizedBox(width: 4),
            _Dot(), SizedBox(width: 4),
            _Dot(),
          ],
        ),
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          return ActionChip(
            label: Text(_suggestions[i]),
            onPressed: () => _sendMessage(_suggestions[i]),
            backgroundColor: const Color(0xFFEDEAFF),
            labelStyle: const TextStyle(color: Color(0xFF5B57D1)),
            shape: StadiumBorder(
              side: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.2)),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _suggestions.length,
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: Row(
          children: [
            // attach icon (decorative)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.attach_file, color: Colors.grey),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // send button – purple circular
            InkWell(
              onTap: () => _sendMessage(_controller.text),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8A56F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _chips();
                final listIdx = index - 1;
                if (_isLoading && listIdx == _messages.length) {
                  return _typingIndicator();
                }
                if (listIdx < _messages.length) {
                  return _buildMessage(_messages[listIdx]);
                }
                return const SizedBox(height: 8);
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF6C63FF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
