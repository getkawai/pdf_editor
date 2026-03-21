import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pdf_viewer_screen.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key, this.drawer});

  final Widget? drawer;

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  bool _isScanning = false;
  DocumentScanningResultPdf? _lastPdf;
  List<String>? _lastImages;
  String? _errorMessage;

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Camera permission is required to scan documents.';
      });
      return;
    }

    final options = DocumentScannerOptions(
      documentFormats: {DocumentFormat.pdf},
      pageLimit: 20,
      mode: ScannerMode.full,
      isGalleryImport: true,
    );
    final scanner = DocumentScanner(options: options);

    try {
      final result = await scanner.scanDocument();
      setState(() {
        _lastPdf = result.pdf;
        _lastImages = result.images;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Scanning failed: $e';
      });
    } finally {
      await scanner.close();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  String? _pdfFilePath() {
    final pdf = _lastPdf;
    if (pdf == null) return null;
    final uri = Uri.parse(pdf.uri);
    if (uri.scheme == 'file') return uri.toFilePath();
    if (uri.scheme.isEmpty) return pdf.uri;
    return null;
  }

  void _openPdfViewer(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewerScreen(filePath: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSupported = Platform.isAndroid;
    final pdfPath = _pdfFilePath();

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('Document Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.document_scanner,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan a document into a PDF',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: (!_isScanning && isSupported) ? _startScan : null,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isScanning ? 'Scanning…' : 'Start Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            if (!isSupported) ...[
              const SizedBox(height: 12),
              Text(
                'Document scanning is only supported on Android devices.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            if (_lastPdf != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Last Scan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Pages: ${_lastPdf!.pageCount}'),
                      const SizedBox(height: 8),
                      Text(
                        'PDF: ${_lastPdf!.uri}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      if (pdfPath != null)
                        OutlinedButton.icon(
                          onPressed: () => _openPdfViewer(pdfPath),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Open PDF'),
                        )
                      else
                        Text(
                          'Cannot open this PDF URI in the viewer.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            if (_lastImages != null && _lastImages!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Scanned Images (${_lastImages!.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _lastImages!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final imagePath = _lastImages![index];
                    return ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(
                        imagePath.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        imagePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
