import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../services/analytics_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 0;
  final AnalyticsService _analytics = AnalyticsService();
  bool _hasLoggedView = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'first_page',
                child: Row(
                  children: [
                    Icon(Icons.first_page),
                    SizedBox(width: 8),
                    Text('First Page'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'last_page',
                child: Row(
                  children: [
                    Icon(Icons.last_page),
                    SizedBox(width: 8),
                    Text('Last Page'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SfPdfViewer.file(
              File(widget.filePath),
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPages = _pdfViewerController.pageCount;
                });
                
                // Log PDF view event
                if (!_hasLoggedView) {
                  _analytics.logViewPdf(
                    documentId: widget.filePath.split('/').last,
                    pageCount: _totalPages,
                  );
                  _hasLoggedView = true;
                }
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
              enableTextSelection: true,
              canShowHyperlinkDialog: true,
            ),
          ),
          _buildPageNavigation(),
        ],
      ),
    );
  }

  Widget _buildPageNavigation() {
    if (_totalPages == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                tooltip: 'Previous Page',
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showPageJumpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                tooltip: 'Next Page',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Slider(
            min: 1,
            max: _totalPages.toDouble(),
            divisions: _totalPages > 1 ? _totalPages - 1 : null,
            value: _currentPage.clamp(1, _totalPages).toDouble(),
            onChanged: (value) {
              setState(() {
                _currentPage = value.round();
              });
            },
            onChangeEnd: (value) => _goToPage(value.round()),
          ),
        ],
      ),
    );
  }

  void _goToPage(int pageNumber) {
    _pdfViewerController.jumpToPage(pageNumber);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'first_page':
        _pdfViewerController.firstPage();
        break;
      case 'last_page':
        _pdfViewerController.lastPage();
        break;
    }
  }

  void _showPageJumpDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page (1-$_totalPages)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _goToPage(page);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid page number')),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
