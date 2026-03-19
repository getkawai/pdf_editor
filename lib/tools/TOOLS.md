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
├── annotate_pdf_tool.dart     # Add annotations to PDFs
├── ai_pdf_tools.dart          # AI-assisted PDF generation
├── table_to_pdf_tool.dart     # Generate PDF tables with styles
├── list_to_pdf_tool.dart      # Create PDF with lists and paragraphs
├── bookmark_pdf_tool.dart     # Add bookmarks to PDFs
├── hyperlink_pdf_tool.dart    # Add clickable hyperlinks
├── signature_pdf_tool.dart    # Digital signatures
├── encrypt_pdf_tool.dart      # Password protection and encryption
└── pdf_a_conformance_tool.dart # PDF/A archive format
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

### BulletsAndListsTool (`bullets_lists`)
Create ordered or unordered lists in a PDF.

**Parameters:**
- `items` (String or List<String>): List items (one per line for String)
- `ordered` (bool, optional): Whether list is ordered (default: true)

### TablePdfTool (`table_pdf`)
Generate a table from CSV-like input.

**Parameters:**
- `tableData` (String): CSV rows (comma-separated)
- `hasHeader` (bool, optional): Whether the first row is header (default: true)

### HeaderFooterTool (`header_footer`)
Add headers and footers to a PDF.

**Parameters:**
- `headerText` (String, optional)
- `footerText` (String, optional)
- `bodyText` (String, optional)
- `pageCount` (int, optional, default: 1)

### ShapesPdfTool (`shapes_pdf`)
Draw shapes on a PDF page.

**Parameters:**
- `shapeType` (String, optional): `all`, `rectangle`, `ellipse`, `line`, `polygon`

### RtlTextTool (`rtl_text`)
Render Unicode text with optional RTL layout.

**Parameters:**
- `text` (String): Text content
- `title` (String, optional)
- `isRtl` (bool, optional, default: true)
- `fontData` (Uint8List, optional): TTF/OTF font bytes

### HyperlinkPdfTool (`hyperlink_pdf`)
Insert a hyperlink in a PDF.

**Parameters:**
- `url` (String): URL
- `text` (String, optional): Link text

### BookmarkPdfTool (`bookmark_pdf`)
Add a bookmark to an existing PDF.

**Parameters:**
- `pdfData` (Uint8List): PDF bytes
- `title` (String): Bookmark title
- `pageNumber` (int): 1-based page index

### AttachmentPdfTool (`attachment_pdf`)
Add file attachments to a PDF.

**Parameters:**
- `pdfData` (Uint8List, optional): PDF bytes
- `attachmentData` (Uint8List): Attachment bytes
- `fileName` (String, optional)
- `description` (String, optional)
- `mimeType` (String, optional)

### EncryptPdfTool (`encrypt_pdf`)
Encrypt a PDF with a password.

**Parameters:**
- `pdfData` (Uint8List): PDF bytes
- `userPassword` (String)
- `ownerPassword` (String)
- `algorithm` (String, optional): `aes256`, `aes256_rev6`, `aes128`, `rc4_128`, `rc4_40`

### DecryptPdfTool (`decrypt_pdf`)
Remove password protection by re-saving pages into a new document.

**Parameters:**
- `pdfData` (Uint8List): Encrypted PDF bytes
- `password` (String): Password

### ConformancePdfTool (`conformance_pdf`)
Create PDF/A conformance documents.

**Parameters:**
- `conformanceLevel` (String): `a1b`, `a2b`, `a3b`
- `text` (String, optional)
- `fontData` (Uint8List, optional)

### DigitalSignatureTool (`digital_signature`)
Digitally sign PDFs using a PFX certificate.

**Parameters:**
- `pdfData` (Uint8List, optional)
- `pfxData` (Uint8List): Certificate bytes
- `password` (String): Certificate password
- `reason` (String, optional)

### TableToPdfTool (`table_to_pdf`)
Generate PDF tables with different styles and formats.

**Parameters:**
- `data` (List<List<dynamic>>): Table data rows
- `headers` (List<String>, optional): Column headers
- `title` (String, optional): Document title
- `style` (String, optional): Table style (see available styles below)
- `fontFamily` (String, optional): Font family

**Available Styles:**
- `grid`, `grid1`-`grid7` - Grid styles
- `list`, `list1`-`list7` - List styles
- `light`, `light1`-`light7` - Light styles
- `listTable1`-`listTable6` - Table styles
- `listTable1Accent1`-`listTable6Accent6` - Accented table styles

### ListToPdfTool (`list_to_pdf`)
Create PDF documents with ordered and unordered lists.

**Parameters:**
- `items` (List<Map>): List items with `text` and optional `subItems`
- `title` (String, optional): Document title
- `listType` (String): 'ordered' or 'unordered'
- `fontFamily` (String, optional): Font family
- `fontSize` (double, optional): Font size (default: 12.0)

**Item Format:**
```dart
{
  'text': 'Main item',
  'subItems': ['Sub item 1', 'Sub item 2']
}
```

### ParagraphToPdfTool (`paragraph_to_pdf`)
Create PDF documents with formatted paragraphs.

**Parameters:**
- `paragraphs` (List<Map>): Paragraphs with text and formatting
- `title` (String, optional): Document title
- `fontFamily` (String, optional): Font family
- `fontSize` (double, optional): Font size
- `lineSpacing` (double, optional): Line spacing (default: 1.5)

**Paragraph Format:**
```dart
{
  'text': 'Paragraph content',
  'isHeading': false,
  'alignment': 'left' // 'left', 'center', 'right', 'justify'
}
```

### BookmarkPdfTool (`bookmark_pdf`)
Add navigation bookmarks to existing PDF documents.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `bookmarks` (List<Map>): List of bookmark objects

**Bookmark Format:**
```dart
{
  'title': 'Bookmark Title',
  'pageNumber': 1,
  'x': 0.0,
  'y': 0.0,
  'color': '#FF0000' // Optional hex color
}
```

### CreateBookmarkedPdfTool (`create_bookmarked_pdf`)
Create a new PDF with bookmarks and sections.

**Parameters:**
- `sections` (List<Map>): Sections with title and content
- `title` (String, optional): Document title

**Section Format:**
```dart
{
  'title': 'Section Title',
  'content': 'Section content',
  'fontFamily': 'helvetica',
  'fontSize': 12.0
}
```

### HyperlinkPdfTool (`hyperlink_pdf`)
Add clickable hyperlinks to existing PDF documents.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `hyperlinks` (List<Map>): List of hyperlink objects

**Hyperlink Format:**
```dart
{
  'url': 'https://example.com',
  'pageNumber': 1,
  'x': 50.0,
  'y': 100.0,
  'width': 150.0,
  'height': 20.0,
  'linkText': 'Click here'
}
```

### CreateHyperlinkedPdfTool (`create_hyperlinked_pdf`)
Create a new PDF with clickable links.

**Parameters:**
- `title` (String, optional): Document title
- `content` (List<Map>): Content items with text and optional URLs
- `links` (List<Map>, optional): Additional links

**Content Format:**
```dart
{
  'text': 'Link text',
  'url': 'https://example.com', // Optional
  'isHeading': false
}
```

### EncryptPdfTool (`encrypt_pdf`)
Add password protection and encryption to PDF files.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `userPassword` (String): User password (required)
- `ownerPassword` (String, optional): Owner password
- `algorithm` (String): 'aes256', 'aes128', 'rc4_128', 'rc4_40'
- `allowPrint` (bool, optional): Allow printing
- `allowCopy` (bool, optional): Allow copying
- `allowModify` (bool, optional): Allow modifications
- `allowAnnotations` (bool, optional): Allow annotations

### DecryptPdfTool (`decrypt_pdf`)
Remove password protection from PDF files.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `password` (String): Password to decrypt

### SignaturePdfTool (`signature_pdf`)
Add digital signatures to existing PDF documents.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `certificateData` (Uint8List): Certificate (.pfx) file bytes
- `certificatePassword` (String): Certificate password
- `pageNumber` (int): Page number for signature
- `x`, `y`, `width`, `height`: Signature position and size
- `reason` (String, optional): Signing reason
- `contactInfo` (String, optional): Contact information
- `location` (String, optional): Signing location

### CreateSignedPdfTool (`create_signed_pdf`)
Create a new PDF document with digital signature.

**Parameters:**
- `text` (String): Document content
- `title` (String, optional): Document title
- `certificateData` (Uint8List): Certificate (.pfx) file bytes
- `certificatePassword` (String): Certificate password
- `reason` (String, optional): Signing reason
- `contactInfo` (String, optional): Contact information
- `location` (String, optional): Signing location

### VerifySignaturePdfTool (`verify_signature_pdf`)
Verify digital signatures in PDF documents.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes

### PdfAConformanceTool (`pdf_a_conformance`)
Create PDF/A conformant documents for long-term archiving.

**Parameters:**
- `text` (String): Document content
- `title` (String, optional): Document title
- `conformanceLevel` (String): 'a1b', 'a1a', 'a2b', 'a2a', 'a2u', 'a3b', 'a3a', 'a3u'
- `fontPath` (String, optional): Path to TrueType font file

### ConvertToPdfATool (`convert_to_pdf_a`)
Convert existing PDF to PDF/A archive format.

**Parameters:**
- `pdfData` (Uint8List): PDF file bytes
- `conformanceLevel` (String): 'a1b', 'a2b', 'a3b', etc.

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
