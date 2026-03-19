import 'dart:async';
import 'dart:io';
import 'package:llamadart/llamadart.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'llm_models.dart';

/// Service for managing LLM inference using LlamaDart
class LlmService {
  static final LlmService _instance = LlmService._internal();
  
  LlamaBackend? _backend;
  LlamaEngine? _engine;
  LlmModelConfig? _currentModel;
  bool _isInitialized = false;
  String? _error;

  factory LlmService() {
    return _instance;
  }

  LlmService._internal();

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if a model is currently loaded
  bool get isModelLoaded => _currentModel != null && _engine != null;

  /// Get the current model config
  LlmModelConfig? get currentModel => _currentModel;

  /// Get the last error message
  String? get lastError => _error;

  /// Initialize the LLM backend
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _backend = LlamaBackend();
      _engine = LlamaEngine(_backend!);
      _isInitialized = true;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to initialize LLM backend: $e';
      return false;
    }
  }

  /// Load a model from file path
  Future<bool> loadModel(LlmModelConfig config) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final file = File(config.modelPath);
      if (!await file.exists()) {
        _error = 'Model file not found: ${config.modelPath}';
        return false;
      }

      await _engine!.loadModel(config.modelPath);

      _currentModel = config;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to load model: $e';
      return false;
    }
  }

  /// Generate text from a prompt (non-streaming)
  Future<LlmGenerationResponse> generate(LlmGenerationRequest request) async {
    if (_engine == null || _currentModel == null) {
      return LlmGenerationResponse.error('No model loaded');
    }

    try {
      final useFunctionGemma = _shouldUseFunctionGemma(request);

      final primaryPrompt = useFunctionGemma
          ? _buildFunctionGemmaPrompt(
              userMessage: request.prompt,
              systemPrompt: request.systemPrompt,
              tools: request.tools,
              addModelTurn: true,
            )
          : request.prompt;

      final primary = await _generateInternal(primaryPrompt);

      if (useFunctionGemma) {
        final call = _parseFunctionCall(primary.content);
        if (call != null && _isToolDeclared(call.name, request.tools)) {
          final toolResponse = await _executeFunctionTool(call.name, call.arguments);
          if (toolResponse != null) {
            final responseBlock = _buildFunctionResponseBlock(
              toolName: call.name,
              response: toolResponse,
            );
            final followupPrompt = _buildFunctionGemmaPrompt(
              userMessage: request.prompt,
              systemPrompt: request.systemPrompt,
              tools: request.tools,
              modelFunctionCallBlock: call.rawBlock,
              functionResponseBlock: responseBlock,
              addModelTurn: true,
            );

            final followup = await _generateInternal(followupPrompt);
            return LlmGenerationResponse(
              content: followup.content,
              tokensGenerated: primary.tokensGenerated + followup.tokensGenerated,
              duration: primary.duration + followup.duration,
              isComplete: true,
            );
          }
        }
      }

      return primary;
    } catch (e) {
      return LlmGenerationResponse.error('Generation failed: $e');
    }
  }

  /// Generate text with streaming (recommended for UI)
  Stream<LlmChunk> generateStream(LlmGenerationRequest request) async* {
    if (_engine == null || _currentModel == null) {
      yield const LlmChunk(content: 'Error: No model loaded', isComplete: true);
      return;
    }

    try {
      final prompt = _shouldUseFunctionGemma(request)
          ? _buildFunctionGemmaPrompt(
              userMessage: request.prompt,
              systemPrompt: request.systemPrompt,
              tools: request.tools,
              addModelTurn: true,
            )
          : request.prompt;

      await for (final token in _engine!.generate(prompt)) {
        yield LlmChunk(content: token);
      }
      yield const LlmChunk(content: '', isComplete: true);
    } catch (e) {
      yield LlmChunk(content: 'Error: $e', isComplete: true);
    }
  }

  /// Get model info
  LlmModelInfo getModelInfo() {
    if (_currentModel == null) {
      return LlmModelInfo(
        name: 'No model loaded',
        path: '',
        isLoaded: false,
      );
    }

    return LlmModelInfo(
      name: _currentModel!.modelName,
      path: _currentModel!.modelPath,
      isLoaded: true,
      contextSize: _currentModel!.contextSize,
    );
  }

  /// Unload the current model
  Future<void> unloadModel() async {
    if (_engine != null) {
      await _engine!.dispose();
      _engine = null;
      _currentModel = null;
    }
  }

  /// Dispose the service and release all resources
  Future<void> dispose() async {
    await unloadModel();
    if (_backend != null) {
      await _backend!.dispose();
      _backend = null;
    }
    _isInitialized = false;
  }

  /// Check if a model file exists at the given path
  Future<bool> modelExists(String modelPath) async {
    return await File(modelPath).exists();
  }

  /// Get recommended model download URLs
  static const Map<String, String> recommendedModels = {
    'FunctionGemma 270M (BF16)': 'https://huggingface.co/unsloth/functiongemma-270m-it-GGUF/resolve/main/functiongemma-270m-it-BF16.gguf',
  };

  static const String _functionGemmaFileName = 'functiongemma-270m-it-BF16.gguf';
  static const String _functionGemmaUrl =
      'https://huggingface.co/unsloth/functiongemma-270m-it-GGUF/resolve/main/functiongemma-270m-it-BF16.gguf';

  Future<bool> ensureFunctionGemmaModelLoaded() async {
    if (kIsWeb) {
      _error = 'FunctionGemma download is not supported on web.';
      return false;
    }

    if (!_isInitialized) {
      await initialize();
    }

    if (_currentModel != null &&
        _engine != null &&
        _currentModel!.modelPath.toLowerCase().contains('functiongemma')) {
      return true;
    }

    try {
      final modelPath = await getFunctionGemmaModelPath();
      final file = File(modelPath);
      if (!await file.exists()) {
        await _downloadFunctionGemma(file);
      }

      final config = LlmModelConfig(
        modelPath: modelPath,
        modelName: LlmModelConfig.functionGemma_270m.modelName,
        contextSize: LlmModelConfig.functionGemma_270m.contextSize,
        gpuLayers: LlmModelConfig.functionGemma_270m.gpuLayers,
        threads: LlmModelConfig.functionGemma_270m.threads,
        temperature: LlmModelConfig.functionGemma_270m.temperature,
        maxTokens: LlmModelConfig.functionGemma_270m.maxTokens,
      );

      return await loadModel(config);
    } catch (e) {
      _error = 'Failed to prepare FunctionGemma: $e';
      return false;
    }
  }

  Future<String> getFunctionGemmaModelPath() async {
    final directory = await getApplicationSupportDirectory();
    final modelsDir = Directory('${directory.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return '${modelsDir.path}/$_functionGemmaFileName';
  }

  Future<void> _downloadFunctionGemma(File target) async {
    final temp = File('${target.path}.download');
    if (await temp.exists()) {
      await temp.delete();
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_functionGemmaUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Download failed with status ${response.statusCode}');
      }

      final sink = temp.openWrite();
      await response.pipe(sink);
      await sink.flush();
      await sink.close();

      if (await target.exists()) {
        await target.delete();
      }

      try {
        await temp.rename(target.path);
      } catch (_) {
        await temp.copy(target.path);
        await temp.delete();
      }
    } finally {
      client.close();
    }
  }

  Future<LlmGenerationResponse> _generateInternal(String prompt) async {
    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();
    int tokenCount = 0;

    await for (final token in _engine!.generate(prompt)) {
      buffer.write(token);
      tokenCount++;
    }

    stopwatch.stop();

    return LlmGenerationResponse(
      content: buffer.toString(),
      tokensGenerated: tokenCount,
      duration: stopwatch.elapsed,
      isComplete: true,
    );
  }

  bool _shouldUseFunctionGemma(LlmGenerationRequest request) {
    if (!request.enableFunctionCalling) return false;
    if (request.tools.isEmpty) return false;
    if (_currentModel == null) return false;
    final modelPath = _currentModel!.modelPath.toLowerCase();
    final modelName = _currentModel!.modelName.toLowerCase();
    return modelPath.contains('functiongemma') || modelName.contains('functiongemma');
  }

  bool _isToolDeclared(String name, List<LlmFunctionTool> tools) {
    return tools.any((tool) => tool.name == name);
  }

  String _buildFunctionGemmaPrompt({
    required String userMessage,
    required List<LlmFunctionTool> tools,
    String? systemPrompt,
    String? modelFunctionCallBlock,
    String? functionResponseBlock,
    bool addModelTurn = false,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<start_of_turn>developer');
    buffer.writeln('You can do function calling with the following functions:');
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      buffer.writeln(systemPrompt.trim());
    }
    for (final tool in tools) {
      buffer.writeln('<start_function_declaration>declaration:${tool.name}{');
      buffer.writeln('description: "${tool.description}",');
      buffer.writeln('parameters: { ${_formatToolParameters(tool.parameters)} }');
      buffer.writeln('}');
      buffer.writeln('<end_function_declaration>');
    }
    buffer.writeln('<end_of_turn>');
    buffer.writeln('<start_of_turn>user');
    buffer.writeln(userMessage);
    buffer.writeln('<end_of_turn>');
    if (modelFunctionCallBlock != null) {
      buffer.writeln('<start_of_turn>model');
      buffer.writeln(modelFunctionCallBlock.trim());
      buffer.writeln('<end_of_turn>');
    }
    if (functionResponseBlock != null) {
      buffer.writeln(functionResponseBlock.trim());
    }
    if (addModelTurn) {
      buffer.writeln('<start_of_turn>model');
    }
    return buffer.toString();
  }

  String _formatToolParameters(Map<String, String> parameters) {
    if (parameters.isEmpty) return '';
    return parameters.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  LlmFunctionCall? _parseFunctionCall(String text) {
    const startTag = '<start_function_call>';
    const endTag = '<end_function_call>';
    final start = text.indexOf(startTag);
    if (start == -1) return null;
    final end = text.indexOf(endTag, start);
    if (end == -1) return null;

    final rawBlock = text.substring(start, end + endTag.length);
    final inner = text.substring(start + startTag.length, end).trim();
    if (!inner.startsWith('call:')) return null;

    final callBody = inner.substring('call:'.length).trim();
    final nameEnd = callBody.indexOf('{');
    if (nameEnd == -1) return null;
    final name = callBody.substring(0, nameEnd).trim();

    final argsBody = callBody.substring(nameEnd + 1);
    final argsEnd = argsBody.lastIndexOf('}');
    final argsText = argsEnd >= 0 ? argsBody.substring(0, argsEnd) : argsBody;
    final args = _parseArguments(argsText);

    return LlmFunctionCall(
      name: name,
      arguments: args,
      rawBlock: rawBlock,
    );
  }

  Map<String, String> _parseArguments(String argsText) {
    final Map<String, String> args = {};
    final lines = argsText.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.endsWith(',')) {
        line = line.substring(0, line.length - 1);
      }
      final separator = line.indexOf(':');
      if (separator == -1) continue;
      final key = line.substring(0, separator).trim();
      var value = line.substring(separator + 1).trim();
      if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
        value = value.substring(1, value.length - 1);
      }
      args[key] = value;
    }
    return args;
  }

  Future<Map<String, String>?> _executeFunctionTool(
    String name,
    Map<String, String> arguments,
  ) async {
    switch (name) {
      case 'get_today_date':
        final today = DateTime.now();
        return {
          'today_date': _formatDate(today),
        };
      default:
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

  String _buildFunctionResponseBlock({
    required String toolName,
    required Map<String, String> response,
  }) {
    final payload = response.entries
        .map((entry) => '${entry.key}: "${entry.value}"')
        .join(', ');
    return '<start_function_response>response:$toolName{$payload}\n<end_function_response>';
  }
}
