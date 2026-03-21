import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// A secondary client using the Service Role Key for Admin operations.
  /// Note: This is initialized lazily and used ONLY on the Admin Portal.
  static SupabaseClient? _adminClient;
  
  static SupabaseClient get adminClient {
    if (_adminClient == null) {
      if (AppConstants.SUPABASE_SERVICE_ROLE_KEY != 'YOUR_SERVICE_ROLE_KEY_HERE') {
        _adminClient = SupabaseClient(
          AppConstants.SUPABASE_URL,
          AppConstants.SUPABASE_SERVICE_ROLE_KEY,
        );
      } else {
        // Fallback to standard client if service key is missing
        return client;
      }
    }
    return _adminClient!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.SUPABASE_URL,
      anonKey: AppConstants.SUPABASE_ANON_KEY,
    );
  }
}
