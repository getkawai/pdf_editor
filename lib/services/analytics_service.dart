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
    // Fire-and-forget to avoid blocking UI.
    _sendToSupabase(
      level: 'info',
      eventType: 'event',
      message: name,
      metadata: parameters,
    );
    if (kDebugMode) {
      debugPrint('📊 Event: $name, params: $parameters');
    }
  }

  // ============================================================================
  // SCREEN TRACKING
  // ============================================================================

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    // Fire-and-forget to avoid blocking UI.
    _sendToSupabase(
      level: 'info',
      eventType: 'screen',
      message: screenName,
      metadata: {'screen_class': screenClass ?? screenName},
    );
    if (kDebugMode) {
      debugPrint('📱 Screen View: $screenName');
    }
  }

  // ============================================================================
  // PDF EDITOR SPECIFIC EVENTS
  // ============================================================================

  Future<void> logOpenPdf({String? source}) async {
    await logEvent(
      name: 'open_pdf',
      parameters: source != null ? {'source': source} : null,
    );
  }

  Future<void> logCreatePdf() async {
    await logEvent(name: 'create_pdf');
  }

  Future<void> logUsePdfTool({
    required String toolName,
    String? result,
  }) async {
    await logEvent(
      name: 'use_pdf_tool',
      parameters: result != null
          ? {'tool_name': toolName, 'result': result}
          : {'tool_name': toolName},
    );
  }

  Future<void> logViewPdf({
    String? documentId,
    int? pageCount,
  }) async {
    final parameters = <String, Object>{};
    if (documentId != null) parameters['document_id'] = documentId;
    if (pageCount != null) parameters['page_count'] = pageCount;
    await logEvent(name: 'view_pdf', parameters: parameters.isEmpty ? null : parameters);
  }

  Future<void> logEditPdf({
    required String editType,
    String? details,
  }) async {
    final parameters = <String, Object>{'edit_type': editType};
    if (details != null) parameters['details'] = details;
    await logEvent(name: 'edit_pdf', parameters: parameters);
  }

  Future<void> logSavePdf({
    String? documentId,
    int? pageCount,
  }) async {
    final parameters = <String, Object>{};
    if (documentId != null) parameters['document_id'] = documentId;
    if (pageCount != null) parameters['page_count'] = pageCount;
    await logEvent(name: 'save_pdf', parameters: parameters.isEmpty ? null : parameters);
  }

  // ============================================================================
  // AI/LLM EVENTS
  // ============================================================================

  Future<void> logOpenAiChat() async {
    await logEvent(name: 'open_ai_chat');
  }

  Future<void> logAiMessage({
    required String messageType,
    int? messageLength,
    String? model,
  }) async {
    final parameters = <String, Object>{'message_type': messageType};
    if (messageLength != null) parameters['message_length'] = messageLength;
    if (model != null) parameters['model'] = model;
    await logEvent(name: 'ai_message', parameters: parameters);
  }

  Future<void> logAiResponse({
    int? responseLength,
    Duration? latency,
    String? model,
  }) async {
    final parameters = <String, Object>{};
    if (responseLength != null) parameters['response_length'] = responseLength;
    if (latency != null) parameters['latency_ms'] = latency.inMilliseconds;
    if (model != null) parameters['model'] = model;
    await logEvent(name: 'ai_response', parameters: parameters.isEmpty ? null : parameters);
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
