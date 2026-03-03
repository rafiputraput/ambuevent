// lib/screens/auth_screens.dart

import 'package:flutter/material.dart';
import '../widgets/painters.dart';
import '../service/auth_service.dart';
import '../models/user_models.dart';


// =======================
// WELCOME SCREEN
// =======================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const TopWavePainter(),
          const BottomCityPainter(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(220),
                const SizedBox(height: 30),
                const Text(
                  "AMBUEVENT",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "DINKES KABUPATEN MADIUN",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// =======================
// LOGIN SCREEN
// =======================

class LoginScreen extends StatefulWidget {
  final Function(String role, {UserModel? user}) onLogin;
  final VoidCallback onToSignup;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onToSignup,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const TopWavePainter(),
          const BottomCityPainter(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [

                  const SizedBox(height: 40),

                  _buildLogo(130),

                  const SizedBox(height: 16),

                  const Text(
                    "AMBUEVENT",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Sign In",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  _buildInput(
                    hint: "Email",
                    icon: Icons.person,
                    controller: _emailController,
                  ),

                  const SizedBox(height: 16),

                  _buildInput(
                    hint: "Password",
                    icon: Icons.lock,
                    controller: _passwordController,
                    isObscure: true,
                  ),

                  const SizedBox(height: 25),

                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.red)
                      : Column(
                          children: [

                            // LOGIN BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleEmailLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FF00),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "— ATAU —",
                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 18),

                            // GOOGLE BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _handleGoogleSignIn,
                                icon: const Icon(Icons.g_mobiledata,
                                    size: 26, color: Colors.red),
                                label: const Text(
                                  "Login dengan Google",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(
                                      color: Colors.grey, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Belum punya akun? ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                GestureDetector(
                                  onTap: widget.onToSignup,
                                  child: const Text(
                                    "Daftar",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ======================
  // FUNCTIONS
  // ======================

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack("Email dan Password harus diisi!");
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      widget.onLogin(user.role, user: user);
    } else {
      _showSnack("Email atau password salah!");
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final user = await _authService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (user != null) {
      widget.onLogin(user.role, user: user);
    } else {
      _showSnack("Login Google dibatalkan.");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}


// =======================
// SIGNUP SCREEN
// =======================

class SignupScreen extends StatefulWidget {
  final VoidCallback onToLogin;
  const SignupScreen({super.key, required this.onToLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const TopWavePainter(),
          const BottomCityPainter(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 40),

                  _buildLogo(130),

                  const SizedBox(height: 16),

                  const Text(
                    "AMBUEVENT",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Buat Akun Baru",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildInput(
                    hint: "Nama Lengkap",
                    icon: Icons.person,
                    controller: _nameController,
                  ),

                  const SizedBox(height: 16),

                  _buildInput(
                    hint: "Email",
                    icon: Icons.email,
                    controller: _emailController,
                  ),

                  const SizedBox(height: 16),

                  _buildInput(
                    hint: "Password",
                    icon: Icons.lock,
                    controller: _passwordController,
                    isObscure: true,
                  ),

                  const SizedBox(height: 30),

                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.red)
                      : Column(
                          children: [

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FF00),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "DAFTAR",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Sudah punya akun? ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                GestureDetector(
                                  onTap: widget.onToLogin,
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack("Semua field harus diisi!");
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.registerWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      _showSnack("Registrasi berhasil! Silakan login.");
      widget.onToLogin();
    } else {
      _showSnack("Registrasi gagal!");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// =======================
// SHARED WIDGETS
// =======================

Widget _buildLogo(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 15,
          spreadRadius: 3,
        ),
      ],
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/images/logo_ambuevent.png',
        fit: BoxFit.cover,
      ),
    ),
  );
}

Widget _buildInput({
  required String hint,
  required IconData icon,
  bool isObscure = false,
  TextEditingController? controller,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFA6969),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        suffixIcon: Icon(icon, color: Colors.black54),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
  );
}