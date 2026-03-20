# PDF Editor

A Flutter application for viewing, creating, and editing PDF documents on iOS and Android, with AI-powered features using local LLM inference.

## Package ID

- **Android**: `com.getkawai.pdf_editor`
- **iOS**: `com.getkawai.pdfEditor`

## Features

### Document Scanning
- **ML Kit Scanner**: Scan physical documents directly into PDFs (Android only)

### PDF Creation & Conversion
- **Text to PDF**: Create new PDF documents from custom text content
- **Image to PDF**: Convert photos and images to PDF documents
- **List & Table to PDF**: Generate structured PDFs with custom lists and tables
- **OCR Support**: Extract text from image-based PDFs

### PDF Security & Validation
- **Encrypt & Decrypt**: Password protect PDFs or remove existing passwords
- **Digital Signatures**: Add cryptographic and visual signatures to your PDFs
- **PDF/A Conformance**: Validate and format PDFs for long-term archiving

### PDF Editing & Manipulation
- **View PDFs**: Open and view PDF documents with page navigation
- **Merge PDFs**: Combine multiple PDF documents into a single file
- **Compress PDF**: Optimize and reduce PDF file sizes
- **Annotate & Shapes**: Add text, highlights, and various shapes to PDFs
- **Header & Footer**: Inject custom headers and footers across pages
- **Bookmarks & Hyperlinks**: Add interactive navigation elements to your PDFs
- **RTL Text Support**: Full support for Right-to-Left text rendering
- **Attachments**: Embed external files directly inside your PDF documents

### AI Features (Powered by Cactus)
- **AI Chat**: Chat with local LLM models entirely on-device (GGUF format)
- **AI PDF Assistant**: Generate PDF content using AI prompts
- **Summarize PDF**: Generate AI summaries of long PDF documents

## Dependencies

- `syncfusion_flutter_pdf` - PDF creation and manipulation
- `syncfusion_flutter_pdfviewer` - PDF viewing
- `cactus` - Local LLM inference with GGUF models
- `file_picker` - File selection for PDFs and images
- `path_provider` - Document storage location
- `permission_handler` - Permission management

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode for platform-specific development
- Java Development Kit (JDK) for Android builds

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies

### Running the App

```bash
# Run on connected device or emulator
flutter run

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android
```

### Building for Production

```bash
# Build Android APK
flutter build apk --release

# Build iOS app
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── llm/                         # LLM service and models
│   ├── llm.dart
│   ├── llm_service.dart
│   └── llm_models.dart
├── tools/                       # PDF tools system
│   ├── tools.dart
│   ├── pdf_tool.dart
│   ├── tools_manager.dart
│   ├── tools_registry.dart
│   ├── text_to_pdf_tool.dart
│   ├── image_to_pdf_tool.dart
│   ├── merge_pdfs_tool.dart
│   ├── compress_pdf_tool.dart
│   ├── annotate_pdf_tool.dart
│   └── ai_pdf_tools.dart
└── screens/
    ├── home_screen.dart         # Home screen with navigation
    ├── pdf_viewer_screen.dart   # PDF viewer screen
    ├── pdf_editor_screen.dart   # PDF creation screen
    ├── tools_screen.dart        # PDF tools browser
    ├── llm_chat_screen.dart     # AI chat screen
    └── ...
```

## Platform Configuration

### Android

Permissions added to `AndroidManifest.xml`:
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `MANAGE_EXTERNAL_STORAGE`

### iOS

Permissions added to `Info.plist`:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSDocumentsFolderUsageDescription`
- File sharing enabled

## Usage

### Viewing a PDF

1. Launch the app
2. Tap "Open PDF"
3. Select a PDF file from your device
4. Use the navigation controls to browse pages

### Creating a PDF

1. Launch the app
2. Tap "Create New PDF"
3. Choose content type:
   - **Add Text**: Enter document title and content
   - **Add Image**: Select an image from your gallery
   - **Add Signature**: Draw a signature (placeholder)
4. The PDF will be saved to your device's documents folder

### Using AI Features

1. Launch the app and tap "AI Chat"
2. Select a model from the dropdown
3. Tap "Download & Load"
4. Start chatting or use AI PDF tools from the Tools screen

## LLM Setup

For detailed instructions on setting up and using the LLM features, see [LLM_SETUP.md](LLM_SETUP.md).

**Quick Start:**
1. Open the AI Chat screen
2. Select a model (for example `qwen3-0.6`)
3. Download & load it
4. Start generating content!

## License

This project uses:
- **Syncfusion Flutter PDF** - Requires commercial or community license
- **Cactus** - MIT License

See [Syncfusion License](https://www.syncfusion.com/sales/license) and [Cactus License](https://github.com/cactus-compute/cactus/blob/main/LICENSE) for details.

## Support

For issues or feature requests, please file an issue in the repository.

## Acknowledgments

- [Cactus](https://github.com/cactus-compute/cactus) for local LLM inference
- [llama.cpp](https://github.com/ggerganov/llama.cpp) for the underlying C++ library
- [Syncfusion](https://www.syncfusion.com/) for PDF libraries
