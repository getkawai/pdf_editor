import 'package:cactus/cactus.dart';
import 'package:flutter/material.dart';
import '../llm/llm.dart';
import '../services/analytics_service.dart';
import '../tools/tools_manager.dart';

/// Screen for interacting with LLM chat
class LlmChatScreen extends StatefulWidget {
  const LlmChatScreen({super.key});

  @override
  State<LlmChatScreen> createState() => _LlmChatScreenState();
}

class _LlmChatScreenState extends State<LlmChatScreen> {
  final LlmService _llmService = LlmService();
  final TextEditingController _promptController = TextEditingController();
  final AnalyticsService _analytics = AnalyticsService();

  final List<Map<String, String>> _messages = [];
  final List<LlmFunctionTool> _defaultTools = const [
    LlmFunctionTool(
      name: 'get_today_date',
      description: 'Gets today\'s date. Use this when the user needs the current date or calendar info.',
      parameters: {},
    ),
  ];

  List<LlmFunctionTool> _getAllTools() {
    final pdfTools = ToolsManager().getAllTools().map((t) => LlmFunctionTool(
      name: t.id.replaceAll('-', '_'), 
      description: t.description,
      parameters: t.parametersSchema,
    )).toList();
    
    return [
      ..._defaultTools,
      ...pdfTools,
    ];
  }
  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isLoadingModels = false;
  List<CactusModel> _availableModels = [];
  String? _selectedModelSlug;
  bool _enableTools = true;
  DateTime? _requestStartTime;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final initialized = await _llmService.initialize();
    if (!initialized) {
      _analytics.logError(
        errorType: 'llm_init_failed',
        errorMessage: _llmService.lastError ?? 'LLM init failed',
        screen: 'llm_chat',
        metadata: {'stage': 'initialize'},
      );
    }
    if (mounted) {
      setState(() => _isLoadingModels = true);
    }

    List<CactusModel> models = [];
    try {
      models = await _llmService.getModels();
    } catch (e, st) {
      _analytics.logError(
        errorType: 'llm_get_models_failed',
        errorMessage: e.toString(),
        screen: 'llm_chat',
        exception: e,
        stackTrace: st,
        metadata: {'stage': 'get_models'},
      );
    }

    if (mounted) {
      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
        if (_selectedModelSlug == null && models.isNotEmpty) {
          _selectedModelSlug = models.first.slug;
        }
      });
    }
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    final selected = _availableModels
        .where((m) => m.slug == _selectedModelSlug)
        .toList();
    final model = selected.isNotEmpty ? selected.first : null;
    if (model == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a model')),
        );
      }
      return;
    }

    final success = await _llmService.loadModel(
      model,
      onProgress: (progress, status, isError) {
        if (!mounted) return;
        setState(() {
          _isLoading = true;
        });
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isModelLoaded = success;
        if (success) {
          _selectedModelSlug = model.slug;
          model.isDownloaded = true;
        }
      });

      if (!success) {
        _analytics.logError(
          errorType: 'llm_load_model_failed',
          errorMessage: _llmService.lastError ?? 'Failed to load model',
          screen: 'llm_chat',
          metadata: {'model': model.slug},
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Model loaded successfully!' : 'Failed to load model',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_promptController.text.isEmpty) return;
    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load a model first')),
      );
      return;
    }

    final userMessage = _promptController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });

    _promptController.clear();

    // Log user message
    _analytics.logAiMessage(
      messageType: 'user',
      messageLength: userMessage.length,
      model: _selectedModelSlug,
    );

    try {
      _requestStartTime = DateTime.now();
      
      final request = LlmGenerationRequest(
        prompt: userMessage,
        systemPrompt: 'You are a friendly and helpful AI assistant. You can chat naturally with the user and answer general questions. If the user says hi or greets you, greet them back gracefully. If the user asks about your capabilities or tools, politely explain that you can help them with calendar matters and perform various PDF processing tasks like summarizing, generating, or encrypting PDFs using the provided tools. Do NOT refuse to answer simple conversational questions.',
        temperature: 0.7,
        maxTokens: 512,
        enableFunctionCalling: _llmService.supportsToolCalling && _enableTools,
        tools: (_llmService.supportsToolCalling && _enableTools)
            ? _getAllTools()
            : const [],
        onExecuteTool: (name, args) async {
          var tool = ToolsManager().getTool(name);
          tool ??= ToolsManager().getTool(name.replaceAll('_', '-'));
          if (tool != null) {
            final result = await tool.execute(args);
            return {
              'success': result.success.toString(),
              if (result.errorMessage != null) 'error': result.errorMessage!,
              if (result.metadata != null) 'metadata': result.metadata.toString(),
            };
          }
          return null;
        },
      );

      final response = await _llmService.generate(request);

      // Log AI response
      final latency = _requestStartTime != null
          ? DateTime.now().difference(_requestStartTime!)
          : Duration.zero;
      
      _analytics.logAiResponse(
        responseLength: response.content.length,
        latency: latency,
        model: _selectedModelSlug,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.isComplete && response.errorMessage == null) {
            _messages.add({'role': 'assistant', 'content': response.content});
          } else {
            _messages.add({
              'role': 'assistant',
              'content': 'Error: ${response.errorMessage ?? 'Unknown error'}',
            });
            // Log error
            _analytics.logError(
              errorType: 'llm_generation_error',
              errorMessage: response.errorMessage ?? 'Unknown error',
              screen: 'llm_chat',
              exception: response.errorMessage ?? 'Unknown error',
              metadata: {
                'model': _selectedModelSlug ?? 'unknown',
                'is_complete': response.isComplete,
              },
            );
          }
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        // Log error
        _analytics.logError(
          errorType: 'llm_exception',
          errorMessage: e.toString(),
          screen: 'llm_chat',
          exception: e,
          stackTrace: st,
          metadata: {'model': _selectedModelSlug ?? 'unknown'},
        );
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _llmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              _isModelLoaded ? Icons.check_circle : Icons.error,
              color: _isModelLoaded ? Colors.green : Colors.red,
            ),
            tooltip: _isModelLoaded ? 'Model loaded' : 'No model loaded',
            onPressed: () => _showModelInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModelLoader(),
          const Divider(height: 1),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet\nLoad a model and start chatting!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return _buildMessageBubble(
                        message['content'] ?? '',
                        isUser: isUser,
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildModelLoader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Model',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_isLoadingModels)
          const Text('Loading supported models...')
          else if (_availableModels.isEmpty)
            const Text('No models available. Try again later.')
          else
            DropdownButtonFormField<String>(
              value: _selectedModelSlug,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select model',
              ),
              items: _availableModels.map((model) {
                final supportsTools = model.supportsToolCalling ? ' • tools' : '';
                final downloaded = model.isDownloaded ? ' • downloaded' : '';
                final suffix = '$supportsTools$downloaded';
                return DropdownMenuItem<String>(
                  value: model.slug,
                  child: Text('${model.name} (${model.slug})$suffix'),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedModelSlug = value;
                        final selected = _availableModels
                            .where((m) => m.slug == value)
                            .toList();
                        final model = selected.isNotEmpty ? selected.first : null;
                        if (model != null && !model.supportsToolCalling) {
                          _enableTools = false;
                        }
                      });
                    },
            ),
          const SizedBox(height: 8),
          if (_selectedModelSlug != null)
            Builder(
              builder: (context) {
                final selected = _availableModels
                    .where((m) => m.slug == _selectedModelSlug)
                    .toList();
                final model = selected.isNotEmpty ? selected.first : null;
                final supportsTools = model?.supportsToolCalling == true;
                if (!supportsTools) return const SizedBox.shrink();
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable tools (function calling)'),
                  value: _enableTools,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _enableTools = value),
                );
              },
            ),
          if (_selectedModelSlug != null) const SizedBox(height: 8),
          ElevatedButton(
            onPressed: (_isLoading || _isLoadingModels) ? null : _loadModel,
            child: const Text('Download & Load'),
          ),
          if (_selectedModelSlug != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Loaded: $_selectedModelSlug',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(content),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: _isModelLoaded && !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: (_isModelLoaded && !_isLoading) ? _sendMessage : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showModelInfo() {
    final info = _llmService.getModelInfo();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', info.name),
            _buildInfoRow('Loaded', info.isLoaded ? 'Yes' : 'No'),
            if (info.contextSize != null)
              _buildInfoRow('Context Size', '${info.contextSize}'),
            _buildInfoRow('Slug', info.slug),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
