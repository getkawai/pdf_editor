import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'pdf_viewer_screen.dart';
import 'pdf_editor_screen.dart';
import '../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

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

  @override
  Widget build(BuildContext context) {
    final canNavigateTabs = widget.onNavigateToTab != null;

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
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'PDF Editor',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'View, create, and edit PDF documents',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final columns = maxWidth >= 900
                        ? 4
                        : maxWidth >= 600
                            ? 3
                            : maxWidth >= 420
                                ? 2
                                : 1;
                    const spacing = 16.0;
                    final cardWidth = columns == 1
                        ? maxWidth
                        : (maxWidth - spacing * (columns - 1)) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _buildQuickAction(
                          context,
                          width: cardWidth,
                          icon: Icons.folder_open,
                          title: 'Open PDF',
                          subtitle: 'Pick a PDF file',
                          onTap: _pickAndOpenPDF,
                        ),
                        _buildQuickAction(
                          context,
                          width: cardWidth,
                          icon: Icons.add_circle_outline,
                          title: 'Create New',
                          subtitle: 'Start from scratch',
                          onTap: _createNewPDF,
                        ),
                        if (canNavigateTabs)
                          _buildQuickAction(
                            context,
                            width: cardWidth,
                            icon: Icons.build,
                            title: 'PDF Tools',
                            subtitle: 'Merge, compress, annotate',
                            onTap: () => widget.onNavigateToTab!(1),
                          ),
                        if (canNavigateTabs)
                          _buildQuickAction(
                            context,
                            width: cardWidth,
                            icon: Icons.document_scanner,
                            title: 'Scan Doc',
                            subtitle: 'Capture with camera',
                            onTap: () => widget.onNavigateToTab!(2),
                          ),
                        if (canNavigateTabs)
                          _buildQuickAction(
                            context,
                            width: cardWidth,
                            icon: Icons.smart_toy,
                            title: 'AI Chat',
                            subtitle: 'Ask about your PDF',
                            onTap: () => widget.onNavigateToTab!(3),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Diagnostics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
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
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
                if (_recentFilePath != null) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _recentFilePath!.split('/').last,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
