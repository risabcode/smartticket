import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, .25), end: Offset.zero).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _gradientBackground(),
          _floatingBlobs(),
          _animatedBody(),
          _madeBySkynet(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BEAUTIFUL SOFT GRADIENT BACKGROUND
  // ---------------------------------------------------------------------------
  Widget _gradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlue.withOpacity(.22),
            AppColors.brandIndigo.withOpacity(.22),
            AppColors.brandCyan.withOpacity(.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING BLOB ANIMATIONS
  // ---------------------------------------------------------------------------
  Widget _floatingBlobs() {
    return Stack(
      children: [
        Positioned(top: -30, left: -20, child: _blob(180, AppColors.brandBlue)),
        Positioned(bottom: -40, right: -30, child: _blob(220, AppColors.brandCyan)),
        Positioned(top: 300, right: 40, child: _blob(120, AppColors.brandIndigo)),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 0.9 + (_ctrl.value * 0.1);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(.18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.45),
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

  // ---------------------------------------------------------------------------
  // MAIN CONTENT WITH ANIMATIONS
  // ---------------------------------------------------------------------------
  Widget _animatedBody() {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _glassPanel(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GLASS PANEL WITH CONTENT
  // ---------------------------------------------------------------------------
  Widget _glassPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.45),
                Colors.white.withOpacity(.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --------------------------------------------------------------
              // H E R O   I C O N   (Animated Glow)
              // --------------------------------------------------------------
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final glow = (0.7 + _ctrl.value * 0.3);
                  return Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(.12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.25),
                          blurRadius: 20 * glow,
                          spreadRadius: 4 * glow,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 90,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------------------
              // APP NAME
              // --------------------------------------------------------------
              Text(
                Constants.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------------------
              // TAGLINE
              // --------------------------------------------------------------
              Text(
                "AI-powered insights for your social media\nperformance across all platforms.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black.withOpacity(.65),
                ),
              ),

              const SizedBox(height: 40),

              // --------------------------------------------------------------
              // BUTTON
              // --------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER (MADE BY SKYNET)
  // ---------------------------------------------------------------------------
  Widget _madeBySkynet() {
    return Positioned(
      bottom: 18,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fade,
        child: const Text(
          "Made by Skynet E-Solution ",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
