import 'package:flutter/material.dart';
import 'landing_screen.dart';
import '../client/client_dashboard.dart';
import '../lawyer/lawyer_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleBasedDispatcher extends ConsumerWidget {
  const RoleBasedDispatcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const LandingScreen();
    }

    final role = user.userMetadata?['role'] as String? ?? 'client';

    switch (role) {
      case 'lawyer':
        return const LawyerDashboard();
      case 'admin':
        return const AdminDashboard();
      case 'client':
      default:
        return const ClientDashboard();
    }
  }
}
