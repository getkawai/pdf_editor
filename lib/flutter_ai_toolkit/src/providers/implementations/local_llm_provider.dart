import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../providers/interface/llm_provider.dart';
import '../../providers/interface/attachments.dart';
import '../../providers/interface/chat_message.dart';
import '../../../../llm/llm_service.dart';
import '../../../../llm/llm_models.dart';
import '../../../../services/analytics_service.dart';

/// An implementation of [LlmProvider] that uses [LlmService] for local LLM inference.
class LocalLlmProvider extends ChangeNotifier implements LlmProvider {
  LocalLlmProvider({
    required this.llmService,
    String? systemPrompt,
  }) : _systemPrompt = systemPrompt;

  final LlmService llmService;
  final String? _systemPrompt;
  final List<ChatMessage> _history = [];
  bool _isProcessing = false;

  @override
  Iterable<ChatMessage> get history => List.unmodifiable(_history);

  @override
  set history(Iterable<ChatMessage> history) {
    _history.clear();
    _history.addAll(history);
    notifyListeners();
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    try {
      final request = LlmGenerationRequest(
        prompt: prompt,
        systemPrompt: _systemPrompt,
        temperature: 0.7,
        maxTokens: 512,
      );

      await for (final chunk in llmService.generateStream(request)) {
        if (chunk.content.isNotEmpty) {
          yield chunk.content;
        }
        if (chunk.isComplete) break;
      }
    } catch (e, st) {
      AnalyticsService().logError(
        errorType: 'llm_generate_stream_error',
        errorMessage: e.toString(),
        screen: 'local_llm_provider',
        exception: e,
        stackTrace: st,
        metadata: {'prompt_length': prompt.length},
      );
      yield 'Error: $e';
    }
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    if (_isProcessing) {
      yield 'Already processing a previous message. Please wait.';
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // Add user message to history
      final userMessage = ChatMessage.user(prompt, attachments);
      _history.add(userMessage);
      notifyListeners();

      // Add placeholder for LLM response
      final llmMessage = ChatMessage.llm();
      _history.add(llmMessage);
      notifyListeners();

      final request = LlmGenerationRequest(
        prompt: prompt,
        systemPrompt: _systemPrompt,
        temperature: 0.7,
        maxTokens: 512,
        enableFunctionCalling: llmService.supportsToolCalling,
        tools: llmService.supportsToolCalling ? _getDefaultTools() : const [],
        onExecuteTool: _onExecuteTool,
      );

      final response = StringBuffer();
      await for (final chunk in llmService.generateStream(request)) {
        if (chunk.content.isNotEmpty) {
          response.write(chunk.content);
          llmMessage.append(chunk.content);
          notifyListeners();
          yield chunk.content;
        }
        if (chunk.isComplete) break;
      }

      // Log analytics
      AnalyticsService().logAiMessage(
        messageType: 'user',
        messageLength: prompt.length,
        model: llmService.currentModel?.slug,
      );
    } catch (e, st) {
      AnalyticsService().logError(
        errorType: 'llm_send_message_error',
        errorMessage: e.toString(),
        screen: 'local_llm_provider',
        exception: e,
        stackTrace: st,
        metadata: {'prompt_length': prompt.length},
      );
      yield 'Error: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  List<LlmFunctionTool> _getDefaultTools() {
    return const [
      LlmFunctionTool(
        name: 'get_today_date',
        description:
            'Gets today\'s date. Use this when the user needs the current date or calendar info.',
        parameters: {},
      ),
    ];
  }

  Future<Map<String, String>?> _onExecuteTool(
    String name,
    Map<String, String> arguments,
  ) async {
    switch (name) {
      case 'get_today_date':
        final today = DateTime.now();
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        final monthName = months[today.month - 1];
        return {
          'today_date': '${today.day} $monthName ${today.year}',
        };
      default:
        // Try to execute from ToolsManager
        // This would require importing tools_manager
        return null;
    }
  }

  /// Clears the chat history.
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
