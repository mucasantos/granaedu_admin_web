import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static bool _isInitialized = false;

  static Future<void> init(
      {required String? url, required String? anonKey}) async {
    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      debugPrint('Supabase credentials missing. Skipping initialization.');
      return;
    }

    try {
      if (!_isInitialized) {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
          debug: kDebugMode,
        );
        _isInitialized = true;
        debugPrint('Supabase initialized successfully.');
      } else {
        // Handle potential updates if needed, though Supabase SDK usually requires restart
        // for changing URL/Key. We can at least log it.
        debugPrint('Supabase is already initialized.');
      }
    } catch (e) {
      debugPrint('Supabase Initialization Error: $e');
    }
  }

  /// Invokes a Supabase Edge Function
  Future<FunctionResponse> invokeFunction(String functionName,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await client.functions.invoke(
        functionName,
        body: body,
      );
      return response;
    } catch (e) {
      debugPrint('Supabase Function Error ($functionName): $e');
      rethrow;
    }
  }

  /// Triggers the AI Orchestrator to generate a weekly plan
  Future<void> generateWeeklyPlan({
    required String firebaseUid,
    required String openaiKey,
    required String systemPrompt,
  }) async {
    await invokeFunction(
      'ai-orchestrator',
      body: {
        'firebase_uid': firebaseUid,
        'action': 'generate_weekly_plan',
        'openai_key': openaiKey,
        'system_prompt': systemPrompt,
      },
    );
  }

  /// Syncs Firebase User data with Supabase users_profile table
  Future<void> syncUserProfile({
    required String firebaseUid,
    String? email,
    String? name,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'firebase_uid': firebaseUid,
        'email': email,
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Perform an upsert: update if firebase_uid exists, insert otherwise
      // Using firebase_uid as the onConflict target (it's marked as UNIQUE in SQL)
      await client.from('users_profile').upsert(
            data,
            onConflict: 'firebase_uid',
          );

      debugPrint('User profile synced with Supabase: $firebaseUid');
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    }
  }
}
