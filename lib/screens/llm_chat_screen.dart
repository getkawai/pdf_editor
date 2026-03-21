import 'package:cactus/cactus.dart';
import 'package:flutter/material.dart';
import '../flutter_ai_toolkit/src/providers/implementations/local_llm_provider.dart';
import '../flutter_ai_toolkit/src/views/llm_chat_view/llm_chat_view.dart';
import '../llm/llm.dart';
import '../services/analytics_service.dart';

/// Screen for interacting with LLM chat using flutter_ai_toolkit's LlmChatView
class LlmChatScreen extends StatefulWidget {
  const LlmChatScreen({super.key, this.drawer});

  final Widget? drawer;

  @override
  State<LlmChatScreen> createState() => _LlmChatScreenState();
}

class _LlmChatScreenState extends State<LlmChatScreen> {
  final LlmService _llmService = LlmService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isLoadingModels = false;
  List<CactusModel> _availableModels = [];
  String? _selectedModelSlug;
  String? _loadedModelSlug;
  bool _enableTools = true;
  LocalLlmProvider? _provider;
  bool _showModelSheet = false;

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
    final selected = _availableModels.where((m) => m.slug == _selectedModelSlug).toList();
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
          _loadedModelSlug = model.slug;
          model.isDownloaded = true;
          // Create provider with loaded model
          _provider = LocalLlmProvider(
            llmService: _llmService,
            systemPrompt:
                'You are a friendly and helpful AI assistant. You can chat naturally with the user and answer general questions. If the user says hi or greets you, greet them back gracefully. If the user asks about your capabilities or tools, politely explain that you can help them with calendar matters and perform various PDF processing tasks like summarizing, generating, or encrypting PDFs using the provided tools.',
          );
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

  @override
  void dispose() {
    _llmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          IconButton(
            icon: Icon(
              _isModelLoaded ? Icons.check_circle : Icons.error,
              color: _isModelLoaded ? Colors.green : Colors.red,
            ),
            tooltip: _isModelLoaded ? 'Model loaded' : 'No model loaded',
            onPressed: () => _showModelInfo(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Model settings',
            onPressed: _openModelSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModelStatusBar(),
          const Divider(height: 1),
          Expanded(
            child: _isModelLoaded && _provider != null
                ? LlmChatView(
                    provider: _provider!,
                    enableAttachments: false,
                    enableVoiceNotes: false,
                    welcomeMessage:
                        'Hello! I\'m your AI assistant. I can help you with PDF-related tasks. How can I assist you today?',
                    suggestions: const [
                      'What can you help me with?',
                      'How do I merge PDFs?',
                      'Can you summarize a PDF?',
                    ],
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Load a model to start chatting',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a model from the settings to begin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openModelSheet,
            icon: const Icon(Icons.download),
            label: const Text('Load Model'),
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusBar() {
    final statusText = _isModelLoaded
        ? 'Model loaded: ${_loadedModelSlug ?? 'unknown'}'
        : 'No model loaded';
    final statusColor = _isModelLoaded
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.12);

    return InkWell(
      onTap: _openModelSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: statusColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isModelLoaded ? Icons.check_circle : Icons.error,
              color: _isModelLoaded ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: _openModelSheet,
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _openModelSheet() {
    if (_showModelSheet) return;
    _showModelSheet = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ModelSelectorSheet(
        availableModels: _availableModels,
        selectedModelSlug: _selectedModelSlug,
        loadedModelSlug: _loadedModelSlug,
        isModelLoaded: _isModelLoaded,
        isLoading: _isLoading,
        isLoadingModels: _isLoadingModels,
        enableTools: _enableTools,
        onModelSelected: (slug) {
          setState(() {
            _selectedModelSlug = slug;
            final selected = _availableModels.where((m) => m.slug == slug).toList();
            final model = selected.isNotEmpty ? selected.first : null;
            if (model != null && !model.supportsToolCalling) {
              _enableTools = false;
            }
          });
        },
        onToolsEnabledChanged: (enabled) {
          setState(() => _enableTools = enabled);
        },
        onLoadModel: _loadModel,
      ),
    ).whenComplete(() {
      _showModelSheet = false;
    });
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

class ModelSelectorSheet extends StatefulWidget {
  final List<CactusModel> availableModels;
  final String? selectedModelSlug;
  final String? loadedModelSlug;
  final bool isModelLoaded;
  final bool isLoading;
  final bool isLoadingModels;
  final bool enableTools;
  final ValueChanged<String> onModelSelected;
  final ValueChanged<bool> onToolsEnabledChanged;
  final VoidCallback onLoadModel;

  const ModelSelectorSheet({
    super.key,
    required this.availableModels,
    required this.selectedModelSlug,
    required this.loadedModelSlug,
    required this.isModelLoaded,
    required this.isLoading,
    required this.isLoadingModels,
    required this.enableTools,
    required this.onModelSelected,
    required this.onToolsEnabledChanged,
    required this.onLoadModel,
  });

  @override
  State<ModelSelectorSheet> createState() => _ModelSelectorSheetState();
}

class _ModelSelectorSheetState extends State<ModelSelectorSheet> {
  String? _localSelectedSlug;

  @override
  void initState() {
    super.initState();
    _localSelectedSlug = widget.selectedModelSlug;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Model', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (widget.isLoadingModels)
            const Text('Loading supported models...')
          else if (widget.availableModels.isEmpty)
            const Text('No models available. Try again later.')
          else
            DropdownButtonFormField<String>(
              initialValue: _localSelectedSlug,
              decoration: const InputDecoration(labelText: 'Select model'),
              items: widget.availableModels.map((model) {
                final supportsTools =
                    model.supportsToolCalling ? ' • tools' : '';
                final downloaded = model.isDownloaded ? ' • downloaded' : '';
                final suffix = '$supportsTools$downloaded';
                return DropdownMenuItem<String>(
                  value: model.slug,
                  child: Text('${model.name} (${model.slug})$suffix'),
                );
              }).toList(),
              onChanged: widget.isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _localSelectedSlug = value;
                      });
                      if (value != null) {
                        widget.onModelSelected(value);
                      }
                    },
            ),
          const SizedBox(height: 8),
          if (_localSelectedSlug != null)
            Builder(
              builder: (context) {
                final selected = widget.availableModels
                    .where((m) => m.slug == _localSelectedSlug)
                    .toList();
                final model = selected.isNotEmpty ? selected.first : null;
                final supportsTools = model?.supportsToolCalling == true;
                if (!supportsTools) return const SizedBox.shrink();
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable tools (function calling)'),
                  value: widget.enableTools,
                  onChanged: widget.isLoading
                      ? null
                      : (value) => widget.onToolsEnabledChanged(value),
                );
              },
            ),
          if (_localSelectedSlug != null) const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                (widget.isLoading || widget.isLoadingModels)
                    ? null
                    : widget.onLoadModel,
            child: const Text('Download & Load'),
          ),
          if (widget.loadedModelSlug != null && widget.isModelLoaded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Loaded: ${widget.loadedModelSlug}',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
