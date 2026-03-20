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

### 1. Download a GGUF Model

Recommended models (quantized Q4_K_M for best speed/quality balance):

| Model | Size | Download |
|-------|------|----------|
| **TinyLlama 1.1B** | ~638MB | [Download](https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf) |
| **Phi 2** | ~1.7GB | [Download](https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf) |
| **Mistral 7B** | ~4.1GB | [Download](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf) |
| **Llama 2 7B** | ~4.1GB | [Download](https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf) |
| **FunctionGemma 270M (BF16)** | Small | [Download](https://huggingface.co/unsloth/functiongemma-270m-it-GGUF/resolve/main/functiongemma-270m-it-BF16.gguf) |

### 2. Store Model on Device

**Android:** `/sdcard/Download/` or app-specific directory  
**iOS:** Files app → On My iPhone → PDF Editor  
**Desktop:** Any accessible location (e.g., `~/models/`)

### 3. Load Model in App

1. Open the app
2. Navigate to **AI Chat** screen
3. Enter the full path to your `.gguf` model file
4. Tap **Load Model**
5. Start chatting!

## Usage Examples

### Basic Text Generation

```dart
import 'package:pdf_editor/llm/llm.dart';

final llmService = LlmService();
await llmService.initialize();

// Load model
await llmService.loadModel(LlmModelConfig(
  modelPath: '/path/to/model.gguf',
  modelName: 'My Model',
));

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

## FunctionGemma Notes

FunctionGemma uses a specific tool-calling chat template and prefers a system/developer prompt that declares available functions. If you use it for function calling, format prompts accordingly. Recommended inference settings:

- `top_k = 64`
- `top_p = 0.95`
- `temperature = 1.0`
- maximum context length = `32768`

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

### "Model file not found"
- Verify the file path is correct
- Ensure the file has `.gguf` extension
- Check file permissions

### "Failed to load library"
- Run `flutter clean && flutter pub get`
- Verify platform is supported

### Slow performance
- Use a smaller model (TinyLlama, Phi 2)
- Reduce context size in config
- Enable GPU acceleration if available
- Use lower quantization (Q4_K_M)

### Out of memory
- Close other applications
- Use smaller model
- Reduce context size
- Use quantized models

## Model Configuration Options

```dart
LlmModelConfig(
  modelPath: 'path/to/model.gguf',
  modelName: 'Custom Model',
  contextSize: 4096,      // Context window size
  gpuLayers: 0,           // GPU layers (0 = CPU only)
  threads: 4,             // CPU threads
  temperature: 0.7,       // Creativity (0.0-1.0)
  maxTokens: 1024,        // Max generation length
);
```

## Resources

- **Cactus Docs:** https://pub.dev/documentation/cactus/latest/
- **Cactus GitHub:** https://github.com/cactus-compute/cactus
- **GGUF Models:** https://huggingface.co/models?search=gguf
- **TheBloke's Quantized Models:** https://huggingface.co/TheBloke

## License

Cactus is licensed under MIT. GGUF models may have different licenses - check the model card on HuggingFace.
