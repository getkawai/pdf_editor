import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics service for Firebase Analytics event tracking.
/// 
/// Provides a simple interface for logging events throughout the app.
/// All events are automatically sent to Firebase Console for observation.
class AnalyticsService {
  AnalyticsService._privateConstructor();

  static final AnalyticsService _instance = AnalyticsService._privateConstructor();

  factory AnalyticsService() {
    return _instance;
  }

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the underlying FirebaseAnalytics instance for advanced usage.
  FirebaseAnalytics get analytics => _analytics;

  // ============================================================================
  // GENERAL EVENTS
  // ============================================================================

  /// Log a custom event with optional parameters.
  /// 
  /// Example:
  /// ```dart
  /// AnalyticsService().logEvent(
  ///   name: 'button_click',
  ///   parameters: {'button_name': 'submit', 'screen': 'checkout'},
  /// );
  /// ```
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        debugPrint('📊 Analytics Event: $name, params: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics error: $e');
      }
    }
  }

  // ============================================================================
  // SCREEN TRACKING
  // ============================================================================

  /// Log a screen view event (automatically handled by FirebaseAnalyticsObserver,
  /// but can be used for manual tracking).
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'screen_view',
        parameters: {
          'firebase_screen': screenName,
          'firebase_screen_class': screenClass ?? screenName,
        },
      );
      if (kDebugMode) {
        debugPrint('📱 Screen View: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics error: $e');
      }
    }
  }

  // ============================================================================
  // PDF EDITOR SPECIFIC EVENTS
  // ============================================================================

  /// Log when user opens a PDF file.
  Future<void> logOpenPdf({String? source}) async {
    await logEvent(
      name: 'open_pdf',
      parameters: source != null ? {'source': source} : null,
    );
  }

  /// Log when user creates a new PDF.
  Future<void> logCreatePdf() async {
    await logEvent(name: 'create_pdf');
  }

  /// Log when user uses a PDF tool (merge, compress, etc.).
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

  /// Log when user views a PDF.
  Future<void> logViewPdf({
    String? documentId,
    int? pageCount,
  }) async {
    await logEvent(
      name: 'view_pdf',
      parameters: {
        if (documentId != null) 'document_id': documentId,
        if (pageCount != null) 'page_count': pageCount,
      },
    );
  }

  /// Log when user edits a PDF (adds text, image, etc.).
  Future<void> logEditPdf({
    required String editType,
    String? details,
  }) async {
    await logEvent(
      name: 'edit_pdf',
      parameters: {
        'edit_type': editType,
        if (details != null) 'details': details,
      },
    );
  }

  /// Log when user saves a PDF.
  Future<void> logSavePdf({
    String? documentId,
    int? pageCount,
  }) async {
    await logEvent(
      name: 'save_pdf',
      parameters: {
        if (documentId != null) 'document_id': documentId,
        if (pageCount != null) 'page_count': pageCount,
      },
    );
  }

  // ============================================================================
  // AI/LLM EVENTS
  // ============================================================================

  /// Log when user opens AI chat.
  Future<void> logOpenAiChat() async {
    await logEvent(name: 'open_ai_chat');
  }

  /// Log when user sends a message to AI.
  Future<void> logAiMessage({
    required String messageType,
    int? messageLength,
    String? model,
  }) async {
    await logEvent(
      name: 'ai_message',
      parameters: {
        'message_type': messageType,
        if (messageLength != null) 'message_length': messageLength,
        if (model != null) 'model': model,
      },
    );
  }

  /// Log when AI generates a response.
  Future<void> logAiResponse({
    int? responseLength,
    Duration? latency,
    String? model,
  }) async {
    await logEvent(
      name: 'ai_response',
      parameters: {
        if (responseLength != null) 'response_length': responseLength,
        if (latency != null) 'latency_ms': latency.inMilliseconds,
        if (model != null) 'model': model,
      },
    );
  }

  // ============================================================================
  // USER ENGAGEMENT EVENTS
  // ============================================================================

  /// Log user sign up (if you have authentication).
  Future<void> logSignUp({required String signUpMethod}) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
  }

  /// Log user login (if you have authentication).
  Future<void> logLogin({required String loginMethod}) async {
    await _analytics.logLogin(loginMethod: loginMethod);
  }

  /// Log when user shares content.
  Future<void> logShare({
    String? contentType,
    String? itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }

  // ============================================================================
  // ERROR TRACKING
  // ============================================================================

  /// Log an error event for observation.
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screen,
  }) async {
    await logEvent(
      name: 'error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screen != null) 'screen': screen,
      },
    );
  }

  // ============================================================================
  // ANALYTICS SETTINGS
  // ============================================================================

  /// Set user ID for cross-device tracking.
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(userId);
  }

  /// Set a user property for segmentation.
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Set whether analytics collection is enabled.
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  /// Get the current session ID.
  Future<int?> getSessionId() async {
    return await _analytics.sessionId;
  }
}
