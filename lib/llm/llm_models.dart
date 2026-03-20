/// LLM model configuration and types
import 'package:cactus/cactus.dart';

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

  /// Convert to Cactus ChatMessage
  ChatMessage toChatMessage() {
    return ChatMessage(role: role.name, content: content);
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
  final Future<Map<String, String>?> Function(String toolName, Map<String, String> args)? onExecuteTool;

  const LlmGenerationRequest({
    required this.prompt,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 512,
    this.topP = 95,
    this.enableFunctionCalling = false,
    this.tools = const [],
    this.onExecuteTool,
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
  final String slug;
  final bool isLoaded;
  final int? contextSize;
  final DateTime? loadedAt;

  const LlmModelInfo({
    required this.name,
    required this.slug,
    this.isLoaded = false,
    this.contextSize,
    this.loadedAt,
  });
}

/// Function-calling tool definition
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
