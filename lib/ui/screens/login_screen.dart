import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  late final Animation<Offset> _slideAnim =
      Tween(begin: const Offset(0, .25), end: Offset.zero).animate(
    CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // LOGIN HANDLER
  // -------------------------------------------------------------
  void _login() async {
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email & password.")),
      );
      return;
    }

    setState(() => _loading = true);

    final user = await _auth.login(email, pass);

    setState(() => _loading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid login credentials or network error.")),
      );
      return;
    }

    // SUCCESS → Save logged-in user globally
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(user);

    // Navigate into the app
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/home");
  }

  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _softBlobs(),
          _animatedLoginCard(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FLOATING BACKGROUND BLOBS
  // -------------------------------------------------------------
  Widget _softBlobs() {
    return Stack(
      children: [
        Positioned(
          top: 120,
          left: -40,
          child: _blob(150, AppColors.brandIndigo.withOpacity(.18)),
        ),
        Positioned(
          bottom: 160,
          right: -50,
          child: _blob(190, AppColors.brandCyan.withOpacity(.15)),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        return Transform.scale(
          scale: 0.95 + (_animCtrl.value * 0.05),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.5),
                  blurRadius: 80,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // CORE LOGIN CARD
  // -------------------------------------------------------------
  Widget _animatedLoginCard() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _loginCard(),
          ),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.45),
                  Colors.white.withOpacity(.25)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(.3)),
            ),
            child: Column(
              children: [
                _logo(),
                const SizedBox(height: 18),
                _title(),
                const SizedBox(height: 28),
                _emailField(),
                const SizedBox(height: 18),
                _passwordField(),
                const SizedBox(height: 24),
                _loginButton(),
                const SizedBox(height: 22),
                _socialRow(),
                const SizedBox(height: 12),
                _forgotAndCreateRow(), // <- updated area
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlue.withOpacity(.3),
            AppColors.brandIndigo.withOpacity(.25)
          ],
        ),
      ),
      child: const Icon(Icons.lock_outline, size: 60, color: AppColors.primary),
    );
  }

  Widget _title() {
    return const Text(
      "Welcome Back!",
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _emailField() {
    return _inputField(
      controller: _emailCtl,
      label: "Email",
      icon: Icons.email_outlined,
    );
  }

  Widget _passwordField() {
    return _inputField(
      controller: _passCtl,
      label: "Password",
      icon: Icons.lock_outline,
      obscure: true,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white.withOpacity(.95),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text("Login"),
            ),
    );
  }

  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialIcon(Icons.g_mobiledata, Colors.red),
        const SizedBox(width: 16),
        _socialIcon(Icons.facebook, Colors.blue),
        const SizedBox(width: 16),
        _socialIcon(Icons.apple, Colors.black),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(.9),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }

  // -------------------------------------------------------------
  // FORGOT + CREATE ACCOUNT ROW
  // -------------------------------------------------------------
  Widget _forgotAndCreateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            // TODO: implement forgot password flow
          },
          child: const Text(
            "Forgot Password?",
            style: TextStyle(color: AppColors.primary),
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to register screen
            Navigator.pushNamed(context, '/register');
          },
          child: const Text(
            "Create account",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
