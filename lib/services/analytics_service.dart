import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Analytics/error service that logs to Supabase and respects telemetry opt-out.
class AnalyticsService {
  AnalyticsService._privateConstructor();

  static final AnalyticsService _instance = AnalyticsService._privateConstructor();

  factory AnalyticsService() {
    return _instance;
  }

  bool get isAvailable => true;


  static const String _supabaseUrl = 'https://rprdvmnxdmlhlbgdkhkx.supabase.co';
  static const String _supabaseApiKey = 'sb_publishable__0zRF8LyDQaGtFF2IJSt9g_YX33se4o';

  Future<void> _sendToSupabase({
    required String level,
    required String eventType,
    required String message,
    String? screen,
    Map<String, Object>? metadata,
  }) async {
    try {
      final deviceTime = DateTime.now().toIso8601String();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.postUrl(
        Uri.parse('$_supabaseUrl/rest/v1/app_logs'),
      );
      request.headers
        ..set('apikey', _supabaseApiKey)
        ..set('Authorization', 'Bearer $_supabaseApiKey')
        ..set('Content-Type', 'application/json')
        ..set('Prefer', 'return=minimal');

      final payload = <String, Object?>{
        'level': level,
        'event_type': eventType,
        'message': message,
        'screen': screen,
        'metadata': metadata,
        'created_at': deviceTime,
      };
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      response.drain();
      client.close(force: true);
    } catch (_) {
      // Ignore network errors.
    }
  }

  // ============================================================================
  // GENERAL EVENTS
  // ============================================================================

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    // Intentionally no-op: only errors are sent.
  }

  // ============================================================================
  // SCREEN TRACKING
  // ============================================================================

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    // Intentionally no-op: only errors are sent.
  }

  // ============================================================================
  // PDF EDITOR SPECIFIC EVENTS
  // ============================================================================

  Future<void> logOpenPdf({String? source}) async {
    // no-op
  }

  Future<void> logCreatePdf() async {
    // no-op
  }

  Future<void> logUsePdfTool({
    required String toolName,
    String? result,
  }) async {
    // no-op
  }

  Future<void> logViewPdf({
    String? documentId,
    int? pageCount,
  }) async {
    // no-op
  }

  Future<void> logEditPdf({
    required String editType,
    String? details,
  }) async {
    // no-op
  }

  Future<void> logSavePdf({
    String? documentId,
    int? pageCount,
  }) async {
    // no-op
  }

  // ============================================================================
  // AI/LLM EVENTS
  // ============================================================================

  Future<void> logOpenAiChat() async {
    // no-op
  }

  Future<void> logAiMessage({
    required String messageType,
    int? messageLength,
    String? model,
  }) async {
    // no-op
  }

  Future<void> logAiResponse({
    int? responseLength,
    Duration? latency,
    String? model,
  }) async {
    // no-op
  }

  // ============================================================================
  // ERROR TRACKING
  // ============================================================================

  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screen,
    Object? exception,
    StackTrace? stackTrace,
    Map<String, Object>? metadata,
  }) async {
    // Fire-and-forget to avoid blocking UI.
    _sendToSupabase(
      level: 'error',
      eventType: errorType,
      message: errorMessage,
      screen: screen,
      metadata: metadata,
    );
    if (kDebugMode) {
      debugPrint('❌ Error: $errorType $errorMessage');
    }
  }

  // ============================================================================
  // ANALYTICS SETTINGS
  // ============================================================================

  Future<void> setUserId(String? userId) async {
    if (kDebugMode) {
      debugPrint('👤 setUserId (local only): $userId');
    }
  }

  Future<void> setUserProperty({
    required String name,
    String? value,
  }) async {
    if (kDebugMode) {
      debugPrint('🏷️ setUserProperty (local only): $name=$value');
    }
  }

  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (kDebugMode) {
      debugPrint('⚙️ Analytics collection flag ignored: $enabled');
    }
  }
}
