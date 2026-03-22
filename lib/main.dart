import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';
import 'screens/auth/role_dispatcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  await NotificationService.init();
  
  // Initialize Supabase (Catch errors for placeholder keys)
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: MercuryLegalApp(),
    ),
  );
}

class MercuryLegalApp extends StatelessWidget {
  const MercuryLegalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.secondaryColor, // Indigo instead of Navy
          brightness: Brightness.dark,
          secondary: AppConstants.secondaryColor,
          surface: AppConstants.primaryColor, // Ensure cards use the sleek elevated slate
        ),
        useMaterial3: true,
      ),
      home: const RoleBasedDispatcher(),
    );
  }
}
