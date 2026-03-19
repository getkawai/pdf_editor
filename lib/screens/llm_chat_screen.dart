import 'package:flutter/material.dart';
import '../llm/llm.dart';
import '../services/analytics_service.dart';

/// Screen for interacting with LLM chat
class LlmChatScreen extends StatefulWidget {
  const LlmChatScreen({super.key});

  @override
  State<LlmChatScreen> createState() => _LlmChatScreenState();
}

class _LlmChatScreenState extends State<LlmChatScreen> {
  final LlmService _llmService = LlmService();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _modelPathController = TextEditingController();
  final AnalyticsService _analytics = AnalyticsService();

  final List<Map<String, String>> _messages = [];
  final List<LlmFunctionTool> _functionGemmaTools = const [
    LlmFunctionTool(
      name: 'get_today_date',
      description: 'Gets today\'s date',
      parameters: {},
    ),
  ];
  bool _isModelLoaded = false;
  bool _isLoading = false;
  String? _selectedModel;
  DateTime? _requestStartTime;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _llmService.initialize();
    if (mounted) {
      setState(() {
        _isModelLoaded = _llmService.isModelLoaded;
      });
    }
  }

  Future<void> _loadModel() async {
    if (_modelPathController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a model path')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final config = LlmModelConfig(
      modelPath: _modelPathController.text,
      modelName: 'Custom Model',
    );

    final success = await _llmService.loadModel(config);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isModelLoaded = success;
        if (success) {
          _selectedModel = config.modelName;
        }
      });

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
      model: _selectedModel,
    );

    try {
      _requestStartTime = DateTime.now();
      
      final request = LlmGenerationRequest(
        prompt: userMessage,
        temperature: 0.7,
        maxTokens: 512,
        enableFunctionCalling: true,
        tools: _functionGemmaTools,
      );

      final response = await _llmService.generate(request);

      // Log AI response
      final latency = _requestStartTime != null
          ? DateTime.now().difference(_requestStartTime!)
          : Duration.zero;
      
      _analytics.logAiResponse(
        responseLength: response.content.length,
        latency: latency,
        model: _selectedModel,
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
            );
          }
        });
      }
    } catch (e) {
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
        );
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _modelPathController.dispose();
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
            'Load LLM Model',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelPathController,
            decoration: const InputDecoration(
              labelText: 'Model Path (.gguf file)',
              hintText: '/path/to/model.gguf',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storage),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: LlmService.recommendedModels.entries.map((entry) {
              return ActionChip(
                label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    _modelPathController.text = entry.value;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _loadModel,
            child: const Text('Load Model'),
          ),
          if (_selectedModel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Loaded: $_selectedModel',
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
            _buildInfoRow('Path', info.path),
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
