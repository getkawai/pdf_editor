import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../providers/interface/llm_provider.dart';
import '../../providers/interface/attachments.dart';
import '../../providers/interface/chat_message.dart';
import '../../../../llm/llm_service.dart';
import '../../../../llm/llm_models.dart';
import '../../../../services/analytics_service.dart';
import '../../../../tools/tools_manager.dart';

/// An implementation of [LlmProvider] that uses [LlmService] for local LLM inference.
class LocalLlmProvider extends ChangeNotifier implements LlmProvider {
  LocalLlmProvider({required this.llmService, String? systemPrompt})
    : _systemPrompt = systemPrompt;

  final LlmService llmService;
  final String? _systemPrompt;
  final List<ChatMessage> _history = [];
  bool _isProcessing = false;
  Iterable<Attachment> _lastUserAttachments = const [];

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
      final augmentedPrompt = await _augmentPromptWithPdfText(
        prompt,
        attachments,
      );
      final request = LlmGenerationRequest(
        prompt: augmentedPrompt,
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
      _lastUserAttachments = attachments;
      // Add user message to history
      final userMessage = ChatMessage.user(prompt, attachments);
      _history.add(userMessage);
      notifyListeners();

      // Add placeholder for LLM response
      final llmMessage = ChatMessage.llm();
      _history.add(llmMessage);
      notifyListeners();

      final augmentedPrompt = await _augmentPromptWithPdfText(
        prompt,
        attachments,
      );

      final request = LlmGenerationRequest(
        prompt: augmentedPrompt,
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
    final toolManager = ToolsManager();
    final pdfTools = toolManager.getAllTools();

    final llmTools = pdfTools
        .map(
          (tool) => LlmFunctionTool(
            name: tool.id,
            description: tool.description,
            parameters: tool.parametersSchema,
          ),
        )
        .toList();

    return llmTools;
  }

  Future<Map<String, String>?> _onExecuteTool(
    String name,
    Map<String, String> arguments,
  ) async {
    switch (name) {
      default:
        final manager = ToolsManager();
        final params = Map<String, dynamic>.from(arguments);
        _injectPdfAttachment(params);
        final tool =
            manager.getTool(name) ?? manager.getTool(name.replaceAll('_', '-'));
        if (tool == null) {
          return {
            'success': 'false',
            'error': 'Tool not found: $name',
          };
        }
        final result = await manager.executeTool(tool.id, params);
        if (result.success) {
          final response = <String, String>{'success': 'true'};
          if (result.pdfData != null && result.pdfData!.isNotEmpty) {
            response['pdfDataBase64'] = base64Encode(result.pdfData!);
          }
          if (result.metadata != null) {
            response['metadata'] = result.metadata.toString();
          }
          return response;
        }
        return {
          'success': 'false',
          'error': result.errorMessage ?? 'Tool execution failed',
        };
    }
  }

  void _injectPdfAttachment(Map<String, dynamic> params) {
    if (params.containsKey('pdfData')) return;
    final pdfAttachment = _lastUserAttachments.firstWhere(
      (attachment) =>
          attachment is FileAttachment &&
          ((attachment.mimeType).toLowerCase() == 'application/pdf' ||
              attachment.name.toLowerCase().endsWith('.pdf')),
      orElse: () => LinkAttachment(name: '', url: Uri()),
    );
    if (pdfAttachment is FileAttachment) {
      params['pdfData'] = pdfAttachment.bytes;
    }
  }

  String _extractTextFromPdf(Uint8List pdfData) {
    try {
      final document = PdfDocument(inputBytes: pdfData);
      final extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }

  Future<String> _augmentPromptWithPdfText(
    String prompt,
    Iterable<Attachment> attachments,
  ) async {
    final pdfAttachments = attachments.where(
      (attachment) =>
          attachment is FileAttachment &&
          ((attachment.mimeType).toLowerCase() == 'application/pdf' ||
              attachment.name.toLowerCase().endsWith('.pdf')),
    );

    if (pdfAttachments.isEmpty) return prompt;

    final buffer = StringBuffer(prompt);
    for (final attachment in pdfAttachments) {
      final file = attachment as FileAttachment;
      final text = _extractTextFromPdf(file.bytes).trim();
      if (text.isEmpty) {
        buffer.write(
          '\n\n[Attached PDF: ${file.name}]'
          '\n(No extractable text found in this PDF.)',
        );
        continue;
      }
      final truncated = text.length > 8000 ? text.substring(0, 8000) : text;
      buffer.write(
        '\n\n[Attached PDF: ${file.name}]'
        '\n$truncated',
      );
      if (text.length > 8000) {
        buffer.write('\n[Text truncated]');
      }
    }

    return buffer.toString();
  }

  /// Clears the chat history.
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
