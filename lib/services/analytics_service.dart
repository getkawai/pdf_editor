import 'package:flutter/foundation.dart';

/// No-op analytics service (Firebase removed).
///
/// This preserves the existing API surface so the rest of the app compiles,
/// but it does not send any events externally.
class AnalyticsService {
  AnalyticsService._privateConstructor();

  static final AnalyticsService _instance = AnalyticsService._privateConstructor();

  factory AnalyticsService() {
    return _instance;
  }

  bool get isAvailable => false;

  // ============================================================================
  // GENERAL EVENTS
  // ============================================================================

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('📊 Analytics (noop): $name, params: $parameters');
    }
  }

  // ============================================================================
  // SCREEN TRACKING
  // ============================================================================

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) {
      debugPrint('📱 Screen View (noop): $screenName');
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
  }) async {
    await logEvent(
      name: 'error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screen != null) 'screen': screen,
      },
    );
    if (kDebugMode) {
      debugPrint('❌ Error (noop): $errorType $errorMessage');
    }
  }

  // ============================================================================
  // ANALYTICS SETTINGS
  // ============================================================================

  Future<void> setUserId(String? userId) async {
    if (kDebugMode) {
      debugPrint('👤 setUserId (noop): $userId');
    }
  }

  Future<void> setUserProperty({
    required String name,
    String? value,
  }) async {
    if (kDebugMode) {
      debugPrint('🏷️ setUserProperty (noop): $name=$value');
    }
  }

  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (kDebugMode) {
      debugPrint('⚙️ setAnalyticsCollectionEnabled (noop): $enabled');
    }
  }
}
