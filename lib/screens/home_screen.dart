import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_viewer_screen.dart';
import 'pdf_editor_screen.dart';
import '../services/analytics_service.dart';
import '../tools/tools_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToTab, this.drawer});

  final ValueChanged<int>? onNavigateToTab;
  final Widget? drawer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _recentFilePath;
  final AnalyticsService _analytics = AnalyticsService();
  final int _toolsCount = ToolsManager().getAllTools().length;
  bool _animateIn = false;
  static const String _recentKey = 'recent_pdf_path';

  @override
  void initState() {
    super.initState();
    _loadRecentFile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _animateIn = true;
      });
    });
  }

  Future<void> _loadRecentFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_recentKey);
      if (!mounted) return;
      setState(() {
        _recentFilePath = path;
      });
    } catch (_) {}
  }

  Future<void> _saveRecentFile(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentKey, path);
    } catch (_) {}
  }

  Future<void> _clearRecentFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {}
  }

  Future<void> _pickAndOpenPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        await _saveRecentFile(result.files.single.path!);
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

  Future<void> _openRecentPdf() async {
    if (_recentFilePath == null) return;
    final file = File(_recentFilePath!);
    if (!await file.exists()) {
      if (!mounted) return;
      await _clearRecentFile();
      setState(() {
        _recentFilePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recent file not found.')),
      );
      return;
    }
    _analytics.logOpenPdf(source: 'recent');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(filePath: _recentFilePath!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canNavigateTabs = widget.onNavigateToTab != null;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('PDF Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                opacity: _animateIn ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  offset: _animateIn ? Offset.zero : const Offset(0, 0.02),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeroCard(
                        context,
                        isTablet: isTablet,
                        canNavigateTabs: canNavigateTabs,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        title: 'Quick Actions',
                        subtitle: 'Jump back in or start fresh.',
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
                                isPrimary: true,
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
                                  onTap: () => widget.onNavigateToTab!(2),
                                ),
                              if (canNavigateTabs)
                                _buildQuickAction(
                                  context,
                                  width: cardWidth,
                                  icon: Icons.document_scanner,
                                  title: 'Scan Doc',
                                  subtitle: 'Capture with camera',
                                  onTap: () => widget.onNavigateToTab!(3),
                                ),
                              if (canNavigateTabs)
                                _buildQuickAction(
                                  context,
                                  width: cardWidth,
                                  icon: Icons.smart_toy,
                                  title: 'AI Chat',
                                  subtitle: 'Ask about your PDF',
                                  onTap: () => widget.onNavigateToTab!(0),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        title: 'Workspace',
                        subtitle: 'Your recent activity and tools.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildStatChip(
                            context,
                            label: 'Tools Available',
                            value: _toolsCount.toString(),
                            icon: Icons.build,
                          ),
                          if (_recentFilePath != null)
                            _buildStatChip(
                              context,
                              label: 'Last Opened',
                              value: _recentFilePath!.split('/').last,
                              icon: Icons.history,
                            ),
                        ],
                      ),
                      if (_recentFilePath != null) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _openRecentPdf,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Continue Editing'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No recent file yet. Open a PDF to get started.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required bool isTablet,
    required bool canNavigateTabs,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: isTablet ? 48 : 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make PDFs feel effortless',
                      style: isTablet
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open, edit, or scan files with a fast local toolkit.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _pickAndOpenPDF,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _createNewPDF,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create New'),
              ),
              if (canNavigateTabs)
                OutlinedButton.icon(
                  onPressed: () => widget.onNavigateToTab!(1),
                  icon: const Icon(Icons.build),
                  label: const Text('Explore Tools'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
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
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        color: isPrimary
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
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

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
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
