import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'pdf_viewer_screen.dart';
import 'pdf_editor_screen.dart';
import 'tools_screen.dart';
import 'llm_chat_screen.dart';
import 'document_scanner_screen.dart';
import '../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _recentFilePath;
  final AnalyticsService _analytics = AnalyticsService();

  Future<void> _pickAndOpenPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _recentFilePath = result.files.single.path!;
        });
        
        // Log analytics
        _analytics.logOpenPdf(source: 'file_picker');
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(filePath: _recentFilePath!),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
        
        // Log error
        _analytics.logError(
          errorType: 'file_picker_error',
          errorMessage: e.toString(),
          screen: 'home',
        );
      }
    }
  }

  Future<void> _createNewPDF() async {
    // Log analytics
    _analytics.logCreatePdf();
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PdfEditorScreen()),
    );
  }

  Future<void> _openToolsScreen() async {
    // Log analytics
    _analytics.logEvent(name: 'open_tools_screen');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ToolsScreen()),
    );
  }

  Future<void> _openLlmChatScreen() async {
    // Log analytics
    _analytics.logOpenAiChat();
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LlmChatScreen()),
    );
  }

  Future<void> _openScannerScreen() async {
    _analytics.logEvent(name: 'open_document_scanner');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Icon(
              Icons.picture_as_pdf,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'PDF Editor',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'View, create, and edit PDF documents',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _pickAndOpenPDF,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createNewPDF,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openScannerScreen,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Document'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openToolsScreen,
              icon: const Icon(Icons.build),
              label: const Text('PDF Tools'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openLlmChatScreen,
              icon: const Icon(Icons.smart_toy),
              label: const Text('AI Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Test crash for Crashlytics
                throw Exception('Test Crash for Crashlytics - ${DateTime.now().toIso8601String()}');
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Crash'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (_recentFilePath != null) ...[
              const SizedBox(height: 32),
              Text(
                'Recent:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _recentFilePath!.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About PDF Editor'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PDF Editor App'),
            SizedBox(height: 8),
            Text('Built with Syncfusion Flutter PDF libraries'),
            SizedBox(height: 16),
            Text(
              'Features:\n'
              '• View PDF documents\n'
              '• Create new PDFs\n'
              '• Add text and images\n'
              '• PDF tools (merge, compress, annotate)',
              style: TextStyle(fontSize: 12),
            ),
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
}
