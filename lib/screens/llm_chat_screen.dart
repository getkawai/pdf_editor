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
  static const String _targetModelSlug = 'LiquidAI/LFM2.5-1.2B-Thinking';

  final LlmService _llmService = LlmService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isLoadingModels = false;
  String? _loadedModelSlug;
  LocalLlmProvider? _provider;
  String? _modelError;

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
      setState(() => _isLoadingModels = false);
    }

    final target = _selectTargetModel(models);
    if (target == null) {
      if (!mounted) return;
      setState(() {
        _modelError =
            'Model $_targetModelSlug not found. Please check available models.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_modelError!)),
      );
      return;
    }

    await _loadModel(target);
  }

  CactusModel? _selectTargetModel(List<CactusModel> models) {
    final direct =
        models.where((m) => m.slug == _targetModelSlug).toList(growable: false);
    if (direct.isNotEmpty) return direct.first;

    final normalized = _targetModelSlug.toLowerCase();
    final fuzzy = models.where((m) {
      final slug = m.slug.toLowerCase();
      final name = m.name.toLowerCase();
      return slug.contains(normalized) || name.contains(normalized);
    }).toList(growable: false);

    return fuzzy.isNotEmpty ? fuzzy.first : null;
  }

  Future<void> _loadModel(CactusModel model) async {
    setState(() {
      _isLoading = true;
      _modelError = null;
    });

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
        } else {
          _modelError = _llmService.lastError ?? 'Failed to load model';
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
      ),
      body: Column(
        children: [
          _buildModelBanner(),
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
            _modelError != null ? 'Failed to load model' : 'Preparing model…',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _modelError ??
                'Downloading and initializing $_targetModelSlug. This may take a moment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _modelError = null);
                    await _initializeService();
                  },
            icon: const Icon(Icons.refresh),
            label: Text(_modelError != null ? 'Retry' : 'Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildModelBanner() {
    if (_modelError != null && _modelError!.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(_modelError!)),
          ],
        ),
      );
    }

    final statusText = _isModelLoaded
        ? 'Model ready: ${_loadedModelSlug ?? _targetModelSlug}'
        : _isLoadingModels || _isLoading
            ? 'Preparing model $_targetModelSlug…'
            : 'Model not loaded';
    final statusColor = _isModelLoaded
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
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
            _isModelLoaded ? Icons.check_circle : Icons.hourglass_top,
            color: _isModelLoaded
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
