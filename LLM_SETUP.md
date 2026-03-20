# LLM Setup Guide for PDF Editor

This guide explains how to set up and use the LLM (Large Language Model) features in the PDF Editor app using [cactus](https://pub.dev/packages/cactus).

## What is Cactus?

Cactus is a cross-platform Flutter/Dart framework for running GGUF LLMs locally in apps, with optional streaming and embeddings support.

**Features:**
- ✅ Cross-platform: Android, iOS, macOS, Linux, Windows, Web
- ✅ Local GGUF inference
- ✅ Streaming API: Token-by-token generation
- ✅ Embeddings (optional)

## Installation

The cactus package is already included in `pubspec.yaml`:

```yaml
dependencies:
  cactus: ^1.3.0
```

Run:
```bash
flutter pub get
```

Cactus can load models from a local path or a remote URL. If you use a URL, the model is downloaded and cached automatically.

## Quick Start

### 1. Select a Model

The app fetches the supported model list from Cactus and lets you pick a model by slug (for example: `qwen3-0.6`, `gemma3-270m`).

### 2. Download & Load in App

1. Open the app
2. Navigate to **AI Chat** screen
3. Select a model from the dropdown
4. Tap **Download & Load**
5. Start chatting!

## Usage Examples

### Basic Text Generation

```dart
import 'package:pdf_editor/llm/llm.dart';

final llmService = LlmService();
await llmService.initialize();

// Load model (by slug from Cactus)
final models = await llmService.getModels();
final model = models.firstWhere((m) => m.slug == 'qwen3-0.6');
await llmService.loadModel(model);

// Generate text
final response = await llmService.generate(LlmGenerationRequest(
  prompt: 'What is the capital of France?',
  temperature: 0.7,
  maxTokens: 256,
));

print(response.content);
```

### Streaming Generation (Recommended for UI)

```dart
llmService.generateStream(LlmGenerationRequest(
  prompt: 'Write a story about',
)).listen((chunk) {
  setState(() {
    _generatedText += chunk.content;
  });
});
```

## Tool Calling Notes

Cactus supports tool calling on models that advertise `supportsToolCalling`. Use `getModels()` and prefer those models when enabling tool calling.

## AI PDF Tools

The app includes AI-powered PDF tools:

### 1. AI PDF Assistant
Generate PDF content using AI prompts.

**Usage:**
1. Go to **PDF Tools** → **AI PDF Assistant**
2. Enter your prompt (e.g., "Write an article about climate change")
3. Optionally set a title
4. Tap **Generate**
5. PDF will be created with AI-generated content

### 2. Summarize PDF
Generate AI summaries of PDF documents.

**Usage:**
1. Go to **PDF Tools** → **Summarize PDF**
2. Select a PDF file
3. Choose summary type (brief, detailed, bullet points)
4. Tap **Summarize**
5. Summary PDF will be generated

## Platform-Specific Notes

Refer to the Cactus docs for platform requirements, supported backends, and any required runtime dependencies.

## Performance Tips

1. **Use quantized models** (Q4_K_M or Q5_K_M) for best speed/quality balance
2. **Reduce context size** for faster inference (2048 vs 4096)
3. **Enable GPU layers** if available (device-dependent)
4. **Close other apps** to free up RAM
5. **Use smaller models** (1-3B) for quick tasks

## Troubleshooting

### "Model not downloaded"
- Ensure the model was downloaded successfully
- Try re-downloading from the AI Chat screen

### "Failed to load library"
- Run `flutter clean && flutter pub get`
- Verify platform is supported

### Slow performance
- Use a smaller model
- Reduce context size in config

### Out of memory
- Close other applications
- Use smaller model
- Reduce context size
- Use quantized models

## Model Configuration Options

```dart
await llmService.loadModel(
  model,
  contextSize: 4096, // Context window size
);
```

## Resources

- **Cactus Docs:** https://pub.dev/documentation/cactus/latest/
- **Cactus GitHub:** https://github.com/cactus-compute/cactus
- **GGUF Models:** https://huggingface.co/models?search=gguf
- **TheBloke's Quantized Models:** https://huggingface.co/TheBloke

## License

Cactus is licensed under MIT. GGUF models may have different licenses - check the model card on HuggingFace.
