/// LLM model configuration and types
import 'package:llamadart/llamadart.dart';

/// Configuration for LLM model
class LlmModelConfig {
  final String modelPath;
  final String modelName;
  final int contextSize;
  final int gpuLayers;
  final int threads;
  final double temperature;
  final int maxTokens;

  const LlmModelConfig({
    required this.modelPath,
    required this.modelName,
    this.contextSize = 4096,
    this.gpuLayers = 0,
    this.threads = 4,
    this.temperature = 0.7,
    this.maxTokens = 1024,
  });

  /// Default config for TinyLlama (1.1B) - fast, good for testing
  static const tinyLlama = LlmModelConfig(
    modelPath: 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    modelName: 'TinyLlama 1.1B',
    contextSize: 2048,
    gpuLayers: 0,
    threads: 4,
    temperature: 0.7,
    maxTokens: 512,
  );

  /// Default config for Llama 2 (7B) - more powerful
  static const llama2_7b = LlmModelConfig(
    modelPath: 'llama-2-7b-chat.Q4_K_M.gguf',
    modelName: 'Llama 2 7B',
    contextSize: 4096,
    gpuLayers: 0,
    threads: 4,
    temperature: 0.7,
    maxTokens: 1024,
  );

  /// Default config for Mistral (7B) - great performance
  static const mistral_7b = LlmModelConfig(
    modelPath: 'mistral-7b-instruct-v0.2.Q4_K_M.gguf',
    modelName: 'Mistral 7B',
    contextSize: 4096,
    gpuLayers: 0,
    threads: 4,
    temperature: 0.7,
    maxTokens: 1024,
  );

  /// Default config for Phi 2 (2.7B) - Microsoft's efficient model
  static const phi2 = LlmModelConfig(
    modelPath: 'phi-2.Q4_K_M.gguf',
    modelName: 'Phi 2',
    contextSize: 2048,
    gpuLayers: 0,
    threads: 4,
    temperature: 0.7,
    maxTokens: 512,
  );

  /// Default config for FunctionGemma (270M) - function calling focused
  /// Note: Uses full-precision BF16 GGUF as recommended by Unsloth.
  static const functionGemma_270m = LlmModelConfig(
    modelPath: 'functiongemma-270m-it-BF16.gguf',
    modelName: 'FunctionGemma 270M (BF16)',
    contextSize: 32768,
    gpuLayers: 0,
    threads: 4,
    temperature: 1.0,
    maxTokens: 1024,
  );
}

/// LLM message role
enum LlmMessageRole {
  system,
  user,
  assistant,
}

/// LLM message for chat
class LlmMessage {
  final LlmMessageRole role;
  final String content;

  const LlmMessage({
    required this.role,
    required this.content,
  });

  /// Convert to LlamaTextContent
  LlamaTextContent toLlamaText() {
    return LlamaTextContent(content);
  }
}

/// LLM generation request
class LlmGenerationRequest {
  final String prompt;
  final String? systemPrompt;
  final double temperature;
  final int maxTokens;
  final int topP;
  final bool enableFunctionCalling;
  final List<LlmFunctionTool> tools;

  const LlmGenerationRequest({
    required this.prompt,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 512,
    this.topP = 95,
    this.enableFunctionCalling = false,
    this.tools = const [],
  });
}

/// LLM generation response
class LlmGenerationResponse {
  final String content;
  final int tokensGenerated;
  final Duration duration;
  final bool isComplete;
  final String? errorMessage;

  const LlmGenerationResponse({
    required this.content,
    required this.tokensGenerated,
    required this.duration,
    this.isComplete = true,
    this.errorMessage,
  });

  factory LlmGenerationResponse.error(String message) {
    return LlmGenerationResponse(
      content: '',
      tokensGenerated: 0,
      duration: Duration.zero,
      isComplete: false,
      errorMessage: message,
    );
  }
}

/// LLM streaming chunk
class LlmChunk {
  final String content;
  final bool isComplete;

  const LlmChunk({
    required this.content,
    this.isComplete = false,
  });
}

/// LLM model info
class LlmModelInfo {
  final String name;
  final String path;
  final bool isLoaded;
  final int? contextSize;
  final DateTime? loadedAt;

  const LlmModelInfo({
    required this.name,
    required this.path,
    this.isLoaded = false,
    this.contextSize,
    this.loadedAt,
  });
}

/// Function-calling tool definition for FunctionGemma
class LlmFunctionTool {
  final String name;
  final String description;
  final Map<String, String> parameters;

  const LlmFunctionTool({
    required this.name,
    required this.description,
    this.parameters = const {},
  });
}

/// Parsed function call from model output
class LlmFunctionCall {
  final String name;
  final Map<String, String> arguments;
  final String rawBlock;

  const LlmFunctionCall({
    required this.name,
    required this.arguments,
    required this.rawBlock,
  });
}
