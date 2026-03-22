import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          // Dynamic Background with layered gradients
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          // Subtle circular glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.accentColor.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Logo Section
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.secondaryColor.withOpacity(0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: AppConstants.primaryColor.withOpacity(0.5),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              1, 0, 0, 0, 0,
                              0, 1, 0, 0, 0,
                              0, 0, 1, 0, 0,
                              1, 1, 1, 0, -1,
                            ]),
                            child: Image.asset(
                              AppConstants.logoAsset,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title with gradient and shadow
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppConstants.secondaryColor,
                          const Color(0xFFFDE68A),
                          AppConstants.secondaryColor,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'MERCURY LEGAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'JUSTICE & EXCELLENCE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondaryColor,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Text(
                      'Access Your Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: AppConstants.textColor.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRoleCard(
                      context,
                      'Client Portal',
                      'Case tracking & appointments',
                      Icons.person_outline_rounded,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'client'))),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      context,
                      'Lawyer Portal',
                      'Firm records & client management',
                      Icons.balance_rounded,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'lawyer'))),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      context,
                      'Admin Portal',
                      'System analytics & oversight',
                      Icons.admin_panel_settings_rounded,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'admin'))),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.02),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.secondaryColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppConstants.secondaryColor, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppConstants.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppConstants.secondaryColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
