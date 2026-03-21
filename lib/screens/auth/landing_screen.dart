import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'login_screen.dart';
// import 'client_signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.primaryColor, AppConstants.backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.gavel, size: 100, color: AppConstants.accentColor),
                const SizedBox(height: 16),
                const Text(
                  'MERCURY LEGAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Justice & Excellence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.accentColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 64),
                const Text(
                  'Choose your portal:',
                  textAlign: TextAlign.center,
                  style: AppConstants.subHeadingStyle,
                ),
                const SizedBox(height: 24),
                _buildRoleCard(
                  context,
                  'Client Portal',
                  'Access your cases, messages, and legal awareness.',
                  Icons.person,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'client'))),
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context,
                  'Lawyer Portal',
                  'Manage cases, timeline, and client appointments.',
                  Icons.balance,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'lawyer'))),
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context,
                  'Admin Portal',
                  'Firm-wide management and analytics.',
                  Icons.admin_panel_settings,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'admin'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.accentColor, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
