import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Mercury Legal';
  static const String logoAsset = 'assets/app_logo.png';

  // Supabase Configuration (PLACEHOLDERS)
  // Replace these with actual values from Supabase project settings
  static const String SUPABASE_URL = 'https://pqjflmqhcowtxhgulavk.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxamZsbXFoY293dHhoZ3VsYXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNzY2NjYsImV4cCI6MjA4OTY1MjY2Nn0.iXflzQifr9qC7KMDKhRBaauyhe8UIpfxhAeYtKgR5R4';
  
  // WARNING: This key is for internal admin use only.
  // Obtain this from Supabase Dashboard -> Settings -> API -> service_role (secret)
  static const String SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxamZsbXFoY293dHhoZ3VsYXZrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDA3NjY2NiwiZXhwIjoyMDg5NjUyNjY2fQ.MAtEdYi4_-WDKG9JdfGQ3bs9hKs_DCj9hHW_3T-Sxr4';

  // New Premium Midnight & Gold Theme
  static const Color backgroundColor = Color(0xFF0F172A); // Deep Midnight Navy
  static const Color primaryColor = Color(0xFF1E293B);    // Navy Slate
  static const Color secondaryColor = Color(0xFFC5A059);  // Antique Metallic Gold
  static const Color accentColor = Color(0xFFC5A059);     // Premium Gold
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color textColor = Color(0xFFF8FAFC);
  static const Color textSecondaryColor = Color(0xFF94A3B8);
  
  static const Color errorColor = Color(0xFFEF4444); // Modern Red
  static const Color successColor = Color(0xFF10B981); // Emerald Green

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: accentColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );
}
