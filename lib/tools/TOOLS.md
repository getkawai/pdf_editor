# PDF Editor Tools System

The PDF Editor app includes a modular tools system similar to `tools/builtin` in the main repository. Each tool is a self-contained class that implements the `PdfTool` interface.

## Directory Structure

```
lib/tools/
├── tools.dart                 # Main export file
├── pdf_tool.dart              # Base interface and types
├── tools_registry.dart        # Tools registry singleton
├── tools_manager.dart         # Tools manager for initialization
├── text_to_pdf_tool.dart      # Convert text to PDF
├── image_to_pdf_tool.dart     # Convert images to PDF
├── merge_pdfs_tool.dart       # Merge multiple PDFs
├── compress_pdf_tool.dart     # Compress PDF files
└── annotate_pdf_tool.dart     # Add annotations to PDFs
```

## Creating a New Tool

To create a new tool, implement the `PdfTool` interface:

```dart
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class MyCustomTool implements PdfTool {
  @override
  String get id => 'my_custom_tool';

  @override
  String get name => 'My Custom Tool';

  @override
  String get description => 'Description of what the tool does';

  @override
  String get iconName => 'Icons.custom_icon';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      // Your tool logic here
      final PdfDocument document = PdfDocument();
      // ... do something ...
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'custom': 'data'},
      );
    } catch (e) {
      return PdfToolResult.failure('Error: $e');
    }
  }
}
```

## Registering a Tool

Add your tool to the `ToolsManager`:

```dart
// In lib/tools/tools_manager.dart
void _initializeTools() {
  _registry.registerTool(TextToPdfTool());
  _registry.registerTool(ImageToPdfTool());
  _registry.registerTool(MyCustomTool()); // Add your tool here
}
```

## Using Tools

### Via ToolsManager

```dart
import 'package:pdf_editor/tools/tools.dart';

// Execute a tool
final result = await ToolsManager().executeTool('text_to_pdf', {
  'text': 'Hello World',
  'title': 'My Document',
});

if (result.success) {
  // Access the PDF data
  final Uint8List pdfData = result.pdfData!;
}
```

### Via ToolsRegistry

```dart
import 'package:pdf_editor/tools/tools.dart';

// Get a specific tool
final tool = ToolsRegistry().getTool('merge_pdfs');
if (tool != null) {
  final result = await tool.execute({'pdfDataList': [...]});
}
```

## Available Tools

### TextToPdfTool (`text_to_pdf`)
Convert text content to PDF document.

**Parameters:**
- `text` (String): The text content
- `title` (String, optional): Document title
- `fontFamily` (String, optional): 'helvetica', 'times', 'courier'
- `fontSize` (double, optional): Font size (default: 12.0)

### ImageToPdfTool (`image_to_pdf`)
Convert images to PDF document.

**Parameters:**
- `imageData` (Uint8List): Image file bytes
- `title` (String, optional): Document title
- `fitMode` (String, optional): 'fit', 'fill', 'stretch'

### MergePdfsTool (`merge_pdfs`)
Merge multiple PDF documents into one.

**Parameters:**
- `pdfDataList` (List<Uint8List>): List of PDF file bytes

### CompressPdfTool (`compress_pdf`)
Reduce PDF file size.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes

### AnnotatePdfTool (`annotate_pdf`)
Add annotations to PDF.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `annotations` (List<Map>): List of annotation objects
- `pageNumber` (int): Page number to annotate

**Annotation Types:**
- `text`: Add text annotation
- `highlight`: Add highlight rectangle
- `rectangle`: Add rectangle shape
- `circle`: Add circle/ellipse shape (as rectangle)

## Result Format

All tools return a `PdfToolResult`:

```dart
class PdfToolResult {
  final bool success;
  final Uint8List? pdfData;      // Generated PDF bytes
  final String? outputPath;      // Optional file path
  final String? errorMessage;    // Error message if failed
  final Map<String, dynamic>? metadata; // Additional metadata
}
```

## Best Practices

1. **Validate Input**: Always check required parameters before processing
2. **Error Handling**: Return `PdfToolResult.failure()` with descriptive error messages
3. **Resource Management**: Call `document.dispose()` after saving
4. **Async Operations**: Use async/await for file I/O and PDF operations
5. **Metadata**: Include useful metadata in results (page count, file size, etc.)

## Testing Tools

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_editor/tools/tools.dart';

void main() {
  test('TextToPdfTool creates PDF successfully', () async {
    final tool = TextToPdfTool();
    final result = await tool.execute({
      'text': 'Test content',
      'title': 'Test Document',
    });
    
    expect(result.success, isTrue);
    expect(result.pdfData, isNotNull);
    expect(result.pdfData!.isNotEmpty, isTrue);
  });
}
```
