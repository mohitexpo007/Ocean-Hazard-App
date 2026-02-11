import 'package:flutter/material.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 📸 Beach background image
          Image.asset(
            "assets/beach_bg.jpg",
            fit: BoxFit.cover,
          ),
          // 🌫️ Soft dark scrim for readability
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

          // content
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  // slightly more transparent so the beach shows through
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // segmented tabs (Login active)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/signup');
                              },
                              child: Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6A5BFF), Color(0xFF7C5CFF)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // professional icon tile (instead of "A")
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C5CFF), Color(0xFF5C8DFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5C8DFF).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_moon_rounded,
                            size: 42, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Welcome",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign in to your account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.alternate_email_outlined),
                        hintText: "you@example.com",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF7C5CFF)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: "Your password",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF7C5CFF)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // remember me
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Text("Remember me"),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Sign In (gradient)
                    SizedBox(
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A5BFF), Color(0xFF7C5CFF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await ApiService.login(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (!mounted) return;
                            if (success) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/dashboard',
                                    (route) => false,
                                arguments: {
                                  'username': _emailController.text.split('@')[0],
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Login failed")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // divider
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.black12)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Or continue with",
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.black12)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Google only (GitHub removed)
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Google sign-in not implemented."),
                            ),
                          );
                        },
                        icon: const Icon(Icons.circle, color: Colors.red),
                        label: const Text(
                          "Google",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE8ECF2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // footer links
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Password reset coming soon."),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot your password?",
                        style: TextStyle(color: Color(0xFF5C8DFF)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/signup'),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6A5BFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
