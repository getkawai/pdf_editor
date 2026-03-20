import 'dart:async';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'llm_models.dart';

/// Service for managing LLM inference using Cactus
class LlmService {
  static final LlmService _instance = LlmService._internal();

  CactusLM? _model;
  CactusModel? _currentModel;
  int? _currentContextSize;
  bool _isInitialized = false;
  String? _error;

  factory LlmService() {
    return _instance;
  }

  LlmService._internal();

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if a model is currently loaded
  bool get isModelLoaded => _currentModel != null && _model != null;

  /// Get the current model
  CactusModel? get currentModel => _currentModel;

  /// Check if current model supports tool calling
  bool get supportsToolCalling => _currentModel?.supportsToolCalling == true;

  /// Get the last error message
  String? get lastError => _error;

  /// Initialize the LLM backend
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _model = CactusLM();
      _isInitialized = true;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to initialize LLM backend: $e';
      return false;
    }
  }

  /// Fetch supported models from Cactus
  Future<List<CactusModel>> getModels() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      return await _model!.getModels();
    } catch (e) {
      _error = 'Failed to fetch models: $e';
      return [];
    }
  }

  /// Download and initialize a model by slug
  Future<bool> loadModel(
    CactusModel model, {
    int? contextSize,
    CactusProgressCallback? onProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _model ??= CactusLM();
      await _model!.downloadModel(
        model: model.slug,
        downloadProcessCallback: onProgress,
      );
      await _model!.initializeModel(
        params: CactusInitParams(
          model: model.slug,
          contextSize: contextSize ?? 2048,
        ),
      );

      _currentModel = model;
      _currentContextSize = contextSize ?? 2048;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to load model: $e';
      return false;
    }
  }

  /// Generate text from a prompt (non-streaming)
  Future<LlmGenerationResponse> generate(LlmGenerationRequest request) async {
    if (_model == null || _currentModel == null) {
      return LlmGenerationResponse.error('No model loaded');
    }

    try {
      final messages = _buildMessages(
        prompt: request.prompt,
        systemPrompt: request.systemPrompt,
      );

      final primary = await _generateInternal(
        messages: messages,
        request: request,
      );

      if (request.enableFunctionCalling &&
          request.onExecuteTool != null &&
          primary.toolCalls.isNotEmpty) {
        final toolMessages = <ChatMessage>[];
        for (final call in primary.toolCalls) {
          if (!_isToolDeclared(call.name, request.tools)) continue;
          final toolResponse = await _executeFunctionTool(call.name, call.arguments, request);
          if (toolResponse != null) {
            toolMessages.add(
              ChatMessage(
                role: 'tool',
                content: _formatToolResponse(call.name, toolResponse),
              ),
            );
          }
        }

        if (toolMessages.isNotEmpty) {
          final followup = await _generateInternal(
            messages: [...messages, ...toolMessages],
            request: request,
            includeTools: false,
          );
          return LlmGenerationResponse(
            content: followup.response,
            tokensGenerated: primary.tokensGenerated + followup.tokensGenerated,
            duration: primary.duration + followup.duration,
            isComplete: true,
          );
        }
      }

      return LlmGenerationResponse(
        content: primary.response,
        tokensGenerated: primary.tokensGenerated,
        duration: primary.duration,
        isComplete: true,
      );
    } catch (e) {
      return LlmGenerationResponse.error('Generation failed: $e');
    }
  }

  /// Generate text with streaming (recommended for UI)
  Stream<LlmChunk> generateStream(LlmGenerationRequest request) async* {
    if (_model == null || _currentModel == null) {
      yield const LlmChunk(content: 'Error: No model loaded', isComplete: true);
      return;
    }

    try {
      final messages = _buildMessages(
        prompt: request.prompt,
        systemPrompt: request.systemPrompt,
      );

      final controller = StreamController<LlmChunk>();
      Future<void> run() async {
        try {
          final streamed = await _model!.generateCompletionStream(
            messages: messages,
            params: _buildCompletionParams(request),
          );
          streamed.stream.listen(
            (token) => controller.add(LlmChunk(content: token)),
            onError: (e) => controller.add(LlmChunk(content: 'Error: $e', isComplete: true)),
            onDone: () async {
              await streamed.result;
              controller.add(const LlmChunk(content: '', isComplete: true));
              await controller.close();
            },
          );
        } catch (e) {
          controller.add(LlmChunk(content: 'Error: $e', isComplete: true));
          await controller.close();
        }
      }

      run();
      yield* controller.stream;
    } catch (e) {
      yield LlmChunk(content: 'Error: $e', isComplete: true);
    }
  }

  /// Get model info
  LlmModelInfo getModelInfo() {
    if (_currentModel == null) {
      return const LlmModelInfo(
        name: 'No model loaded',
        slug: '',
        isLoaded: false,
      );
    }

    return LlmModelInfo(
      name: _currentModel!.name,
      slug: _currentModel!.slug,
      isLoaded: true,
      contextSize: _currentContextSize,
    );
  }

  /// Unload the current model
  Future<void> unloadModel() async {
    if (_model != null) {
      _model!.unload();
      _currentModel = null;
      _currentContextSize = null;
    }
  }

  /// Dispose the service and release all resources
  Future<void> dispose() async {
    await unloadModel();
    _model = null;
    _isInitialized = false;
  }

  Future<_InternalGeneration> _generateInternal({
    required List<ChatMessage> messages,
    required LlmGenerationRequest request,
    bool includeTools = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final params = _buildCompletionParams(request, includeTools: includeTools);
    try {
      if (kDebugMode) {
        debugPrint(
          'LLM generateCompletion: model=${_currentModel?.slug} '
          'context=${_currentContextSize ?? 'n/a'} '
          'tools=${params.tools?.length ?? 0} '
          'maxTokens=${params.maxTokens} '
          'topP=${params.topP} '
          'temp=${params.temperature}',
        );
      }
      final result = await _model!.generateCompletion(
        messages: messages,
        params: params,
      );

      stopwatch.stop();

      return _InternalGeneration(
        response: result.response,
        toolCalls: result.toolCalls,
        tokensGenerated: result.totalTokens,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  List<ChatMessage> _buildMessages({
    required String prompt,
    String? systemPrompt,
  }) {
    final messages = <ChatMessage>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add(ChatMessage(role: 'system', content: systemPrompt.trim()));
    }
    messages.add(ChatMessage(role: 'user', content: prompt));
    return messages;
  }

  bool _isToolDeclared(String name, List<LlmFunctionTool> tools) {
    return tools.any((tool) => tool.name == name);
  }

  Future<Map<String, String>?> _executeFunctionTool(
    String name,
    Map<String, String> arguments,
    LlmGenerationRequest request,
  ) async {
    switch (name) {
      case 'get_today_date':
        final today = DateTime.now();
        return {
          'today_date': _formatDate(today),
        };
      default:
        if (request.onExecuteTool != null) {
          return await request.onExecuteTool!(name, arguments);
        }
        return null;
    }
  }

  String _formatDate(DateTime date) {
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
    final monthName = months[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  CactusCompletionParams _buildCompletionParams(
    LlmGenerationRequest request, {
    bool includeTools = true,
  }) {
    final canUseTools = supportsToolCalling;
    return CactusCompletionParams(
      model: _currentModel?.slug,
      temperature: request.temperature,
      topP: request.topP / 100.0,
      maxTokens: request.maxTokens,
      tools: includeTools &&
              canUseTools &&
              request.enableFunctionCalling &&
              request.tools.isNotEmpty
          ? _mapTools(request.tools)
          : null,
    );
  }

  List<CactusTool> _mapTools(List<LlmFunctionTool> tools) {
    return tools.map((tool) {
      final params = tool.parameters.map(
        (key, desc) => MapEntry(
          key,
          ToolParameter(type: 'string', description: desc, required: true),
        ),
      );
      return CactusTool(
        name: tool.name,
        description: tool.description,
        parameters: ToolParametersSchema(properties: params),
      );
    }).toList();
  }

  String _formatToolResponse(String toolName, Map<String, String> response) {
    final payload = response.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return 'Tool $toolName result: {$payload}';
  }
}

class _InternalGeneration {
  final String response;
  final List<ToolCall> toolCalls;
  final int tokensGenerated;
  final Duration duration;

  _InternalGeneration({
    required this.response,
    required this.toolCalls,
    required this.tokensGenerated,
    required this.duration,
  });
}
