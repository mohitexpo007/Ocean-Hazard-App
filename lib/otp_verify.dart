import 'package:flutter/material.dart';
import 'api_service.dart';

class OtpVerifyPage extends StatefulWidget {
  final String email;
  final String username;

  const OtpVerifyPage({
    super.key,
    required this.email,
    required this.username,
  });

  @override
  _OtpVerifyPageState createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Verification",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027), // dark blue top
              Color(0xFF203A43),
              Color(0xFF2C5364), // greenish bottom
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 120),
            const Text(
              "Enter Verification Code",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We've sent a 6-digit code to your email",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // OTP Input (rounded box style like in your image)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: "",
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Verify Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => Colors.transparent,
                    ),
                  ),
                  onPressed: () async {
                    final success = await ApiService.verifyOtp(
                      widget.email,
                      _otpController.text,
                    );
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("OTP verified, signup complete!"),
                        ),
                      );
                      Navigator.pushReplacementNamed(
                        context,
                        '/dashboard',
                        arguments: {'username': widget.username},
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid OTP")),
                      );
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text(
                        "Verify",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
