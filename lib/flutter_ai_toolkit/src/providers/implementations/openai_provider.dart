// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart' as openai;

import '../interface/attachments.dart';
import '../interface/chat_message.dart';
import '../interface/llm_provider.dart';

/// A provider class for interacting with OpenAI-compatible APIs.
///
/// This class extends [LlmProvider] and implements the necessary methods to
/// generate text using OpenAI's chat completion API or compatible endpoints.
class OpenAiProvider extends LlmProvider with ChangeNotifier {
  /// Creates a new instance of [OpenAiProvider].
  ///
  /// [apiKey] is the API key for authenticating with the OpenAI API.
  /// [model] is the model to use for generation (e.g., 'gpt-4', 'gpt-3.5-turbo').
  /// [baseUrl] is the base URL for the API endpoint. Defaults to OpenAI's API.
  /// Can be changed for compatible APIs like Azure OpenAI, local models, etc.
  /// [history] is an optional list of previous chat messages to initialize the
  /// chat session with.
  /// [temperature] controls randomness in generation (0.0 to 2.0).
  /// [maxTokens] limits the maximum tokens in the response.
  OpenAiProvider({
    required String apiKey,
    required this.model,
    String? baseUrl,
    Iterable<ChatMessage>? history,
    this.temperature = 1.0,
    this.maxTokens,
  })  : _client = openai.OpenAIClient(
          config: openai.OpenAIConfig(
            authProvider: openai.ApiKeyProvider(apiKey),
            baseUrl: baseUrl ?? 'https://api.openai.com/v1',
          ),
        ),
        _history = history?.toList() ?? [];

  final openai.OpenAIClient _client;

  /// The model to use for generation.
  final String model;

  /// Temperature for generation (controls randomness).
  final double temperature;

  /// Maximum tokens to generate.
  final int? maxTokens;

  final List<ChatMessage> _history;

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) =>
      _sendMessageStream(
        prompt: prompt,
        attachments: attachments,
        history: const [],
      );

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final userMessage = ChatMessage.user(prompt, attachments);
    final llmMessage = ChatMessage.llm();
    _history.addAll([userMessage, llmMessage]);

    final response = _sendMessageStream(
      prompt: prompt,
      attachments: attachments,
      history: _history,
    );

    yield* response.map((chunk) {
      llmMessage.append(chunk);
      return chunk;
    });

    notifyListeners();
  }

  Stream<String> _sendMessageStream({
    required String prompt,
    required Iterable<Attachment> attachments,
    required Iterable<ChatMessage> history,
  }) async* {
    final messages = <openai.ChatMessage>[
      ...history.where((m) => m.text != null).map(_messageToOpenAiMessage),
      if (attachments.isNotEmpty)
        _buildMultiModalMessage(prompt, attachments)
      else
        openai.ChatMessage.user(prompt),
    ];

    final request = openai.ChatCompletionCreateRequest(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final stream = _client.chat.completions.createStream(request);

    await for (final chunk in stream) {
      final choices = chunk.choices;
      if (choices != null && choices.isNotEmpty) {
        final content = choices.first.delta.content;
        if (content != null) {
          yield content;
        }
      }
    }
  }

  openai.ChatMessage _buildMultiModalMessage(
    String prompt,
    Iterable<Attachment> attachments,
  ) {
    final content = <openai.ContentPart>[
      openai.ContentPart.text(prompt),
    ];

    for (final attachment in attachments) {
      if (attachment is FileAttachment) {
        if (attachment.mimeType.startsWith('image/')) {
          content.add(
            openai.ContentPart.imageBase64(
              data: base64Encode(attachment.bytes),
              mediaType: attachment.mimeType,
            ),
          );
        } else {
          content.add(
            openai.ContentPart.text(
              '[File: ${attachment.name} (${attachment.mimeType})]',
            ),
          );
        }
      } else if (attachment is LinkAttachment) {
        content.add(
          openai.ContentPart.imageUrl(attachment.url.toString()),
        );
      }
    }

    return openai.ChatMessage.user(openai.UserMessageContent.parts(content));
  }

  openai.ChatMessage _messageToOpenAiMessage(ChatMessage message) {
    if (message.attachments.isNotEmpty && message.origin.isUser) {
      final content = <openai.ContentPart>[
        openai.ContentPart.text(message.text ?? ''),
      ];
      for (final attachment in message.attachments) {
        if (attachment is FileAttachment &&
            attachment.mimeType.startsWith('image/')) {
          content.add(
            openai.ContentPart.imageBase64(
              data: base64Encode(attachment.bytes),
              mediaType: attachment.mimeType,
            ),
          );
        } else if (attachment is LinkAttachment) {
          content.add(
            openai.ContentPart.imageUrl(attachment.url.toString()),
          );
        }
      }
      return openai.ChatMessage.user(
        openai.UserMessageContent.parts(content),
      );
    }

    if (message.origin.isUser) {
      return openai.ChatMessage.user(message.text ?? '');
    } else {
      return openai.ChatMessage.assistant(content: message.text ?? '');
    }
  }

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history.clear();
    _history.addAll(history);
    notifyListeners();
  }

  /// Closes the underlying HTTP client.
  ///
  /// Call this method when the provider is no longer needed to free resources.
  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
