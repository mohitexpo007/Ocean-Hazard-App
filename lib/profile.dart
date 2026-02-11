import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _gender = "male";
  String _phone = "";
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gender = prefs.getString("gender") ?? "male";
      _phone = prefs.getString("phone") ?? "";
      _phoneController.text = _phone;
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("gender", _gender);
    await prefs.setString("phone", _phoneController.text.trim());
    setState(() {
      _phone = _phoneController.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // ✅ ensures gradient fills full screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF003973), Color(0xFF04619F)], // dark to light blue
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Profile Avatar with border + edit badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        _gender == "female"
                            ? "assets/female_bitmoji.png"
                            : "assets/bitmoji.png",
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  )
                ],
              ),

              const SizedBox(height: 15),

              // Username + handle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Colors.white, size: 20),
                ],
              ),
              Text(
                "@${widget.username.toLowerCase()}",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),

              const SizedBox(height: 30),

              // Gender Selection Pill
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gender",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _gender = "male"),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _gender == "male"
                                      ? Colors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text("Male",
                                    style: TextStyle(
                                        color: _gender == "male"
                                            ? Colors.white
                                            : Colors.black87)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _gender = "female"),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _gender == "female"
                                      ? Colors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text("Female",
                                    style: TextStyle(
                                        color: _gender == "female"
                                            ? Colors.white
                                            : Colors.black87)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Email Field
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.email, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "user@gmail.com",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // Phone Field
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: "Phone number",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _saveProfileData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Save",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
