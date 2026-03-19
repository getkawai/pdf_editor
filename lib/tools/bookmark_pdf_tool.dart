import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for adding bookmarks to PDF documents
class BookmarkPdfTool implements PdfTool {
  @override
  String get id => 'bookmark_pdf';

  @override
  String get name => 'Bookmark PDF';

  @override
  String get description => 'Add navigation bookmarks to PDF documents';

  @override
  String get iconName => 'Icons.bookmark_add';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List pdfData = parameters['pdfData'] as Uint8List? ?? Uint8List(0);
      final List<Map<String, dynamic>>? bookmarks = parameters['bookmarks'] as List<Map<String, dynamic>>?;

      if (pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }

      if (bookmarks == null || bookmarks.isEmpty) {
        return PdfToolResult.failure('At least one bookmark is required');
      }

      // Load or create the PDF document
      PdfDocument document;
      if (pdfData.isNotEmpty) {
        document = PdfDocument(inputBytes: pdfData);
      } else {
        document = PdfDocument();
        document.pages.add();
      }

      // Add bookmarks
      int bookmarksAdded = 0;
      for (final bookmarkData in bookmarks) {
        final String title = bookmarkData['title'] as String;
        final int pageNumber = bookmarkData['pageNumber'] as int? ?? 1;
        final double x = (bookmarkData['x'] as num?)?.toDouble() ?? 0.0;
        final double y = (bookmarkData['y'] as num?)?.toDouble() ?? 0.0;
        final String? colorHex = bookmarkData['color'] as String?;

        // Validate page number
        if (pageNumber < 1 || pageNumber > document.pages.count) {
          continue;
        }

        // Create bookmark
        final PdfBookmark bookmark = document.bookmarks.add(title);
        bookmark.destination = PdfDestination(
          document.pages[pageNumber - 1],
          ui.Offset(x, y),
        );

        // Set bookmark color if provided
        if (colorHex != null && colorHex.isNotEmpty) {
          bookmark.color = _hexToColor(colorHex);
        }

        bookmarksAdded++;
      }

      // Save the document
      final List<int> bytes = await document.save();
      final int pageCount = document.pages.count;
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': pageCount,
          'bookmarksAdded': bookmarksAdded,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error adding bookmarks: $e');
    }
  }

  PdfColor _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    final int value = int.parse(hex, radix: 16);
    return PdfColor(
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }
}

/// Tool for creating a PDF with bookmarks from scratch
class CreateBookmarkedPdfTool implements PdfTool {
  @override
  String get id => 'create_bookmarked_pdf';

  @override
  String get name => 'Create Bookmarked PDF';

  @override
  String get description => 'Create a new PDF with bookmarks and sections';

  @override
  String get iconName => 'Icons.book';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final List<Map<String, dynamic>> sections = parameters['sections'] as List<Map<String, dynamic>>? ?? [];
      final String title = parameters['title'] as String? ?? '';

      if (sections.isEmpty) {
        return PdfToolResult.failure('At least one section is required');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      // Add pages and create bookmarks
      for (final section in sections) {
        final String sectionTitle = section['title'] as String;
        final String content = section['content'] as String? ?? '';
        final String? fontFamily = section['fontFamily'] as String?;
        final double fontSize = (section['fontSize'] as num?)?.toDouble() ?? 12.0;

        // Add a new page for this section
        final PdfPage page = document.pages.add();
        final PdfGraphics graphics = page.graphics;

        // Create bookmark for this section
        final PdfBookmark bookmark = document.bookmarks.add(sectionTitle);
        bookmark.destination = PdfDestination(page, ui.Offset(0, 50));

        double yOffset = 50;

        // Add section title
        final PdfFont titleFont = PdfStandardFont(
          _getFontFamily(fontFamily),
          18,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          sectionTitle,
          titleFont,
          bounds: ui.Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 40),
        );
        yOffset += 50;

        // Add content
        if (content.isNotEmpty) {
          final PdfFont textFont = PdfStandardFont(
            _getFontFamily(fontFamily),
            fontSize,
          );
          PdfTextElement(
            text: content,
            font: textFont,
          ).draw(
            page: page,
            bounds: ui.Rect.fromLTWH(
              50,
              yOffset,
              page.getClientSize().width - 100,
              page.getClientSize().height - yOffset - 50,
            ),
            format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
          );
        }
      }

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': document.pages.count,
          'sectionsCount': sections.length,
          'title': title,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating bookmarked PDF: $e');
    }
  }

  PdfFontFamily _getFontFamily(String? fontFamily) {
    switch (fontFamily?.toLowerCase()) {
      case 'times':
        return PdfFontFamily.timesRoman;
      case 'courier':
        return PdfFontFamily.courier;
      case 'helvetica':
      default:
        return PdfFontFamily.helvetica;
    }
  }
}
