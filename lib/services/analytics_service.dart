import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only analytics/error service.
/// Writes events to a local log file and respects telemetry opt-out.
class AnalyticsService {
  AnalyticsService._privateConstructor();

  static final AnalyticsService _instance = AnalyticsService._privateConstructor();

  factory AnalyticsService() {
    return _instance;
  }

  bool get isAvailable => true;

  static const String _telemetryEnabledKey = 'telemetry_enabled';
  bool? _telemetryEnabledCache;
  File? _localLogFile;

  Future<bool> _isTelemetryEnabled() async {
    if (_telemetryEnabledCache != null) {
      return _telemetryEnabledCache!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _telemetryEnabledCache = prefs.getBool(_telemetryEnabledKey) ?? true;
    } catch (_) {
      _telemetryEnabledCache = true;
    }
    return _telemetryEnabledCache!;
  }

  Future<File> _getLocalLogFile() async {
    if (_localLogFile != null) return _localLogFile!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/telemetry.log');
    _localLogFile = file;
    return file;
  }

  Future<void> _appendLocalLog(String line) async {
    try {
      final file = await _getLocalLogFile();
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Ignore local logging failures.
    }
  }

  Future<String> getLocalLogPath() async {
    final file = await _getLocalLogFile();
    return file.path;
  }

  Future<String> readLocalLog({int maxBytes = 20000}) async {
    try {
      final file = await _getLocalLogFile();
      if (!await file.exists()) return '';
      final length = await file.length();
      if (length <= maxBytes) {
        return await file.readAsString();
      }
      final raf = await file.open();
      final start = length - maxBytes;
      await raf.setPosition(start);
      final bytes = await raf.read(maxBytes);
      await raf.close();
      return String.fromCharCodes(bytes);
    } catch (_) {
      return '';
    }
  }

  // ============================================================================
  // GENERAL EVENTS
  // ============================================================================

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _appendLocalLog('[EVENT] $name ${parameters ?? const {}}');
    if (!await _isTelemetryEnabled()) {
      if (kDebugMode) {
        debugPrint('📊 Event dropped (telemetry disabled): $name');
      }
      return;
    }
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
    await _appendLocalLog('[SCREEN] $screenName ${screenClass ?? screenName}');
    if (!await _isTelemetryEnabled()) {
      if (kDebugMode) {
        debugPrint('📱 Screen View dropped (telemetry disabled): $screenName');
      }
      return;
    }
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
  }) async {
    await _appendLocalLog('[ERROR] $errorType $errorMessage ${screen ?? ''}');
    if (!await _isTelemetryEnabled()) {
      if (kDebugMode) {
        debugPrint('❌ Error dropped (telemetry disabled): $errorType');
      }
      return;
    }
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
    _telemetryEnabledCache = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_telemetryEnabledKey, enabled);
    } catch (_) {
      // Ignore persistence failures; cache still applies for this session.
    }
    if (kDebugMode) {
      debugPrint('⚙️ Analytics collection set to: $enabled');
    }
  }
}
