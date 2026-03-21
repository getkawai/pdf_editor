import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../tools/tools.dart';
import '../services/analytics_service.dart';
import 'pdf_viewer_screen.dart';
import 'widgets/table_editor_widget.dart';
import 'widgets/shapes_editor_widget.dart';
import 'widgets/annotations_editor_widget.dart';
import 'widgets/lists_editor_widget.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, this.drawer});

  final Widget? drawer;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late List<PdfTool> _tools;
  bool _isLoading = true;
  final AnalyticsService _analytics = AnalyticsService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadTools();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTools() async {
    final toolsManager = ToolsManager();
    setState(() {
      _tools = toolsManager.getAllTools();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTools = _filteredTools();
    final groupedTools = _groupTools(filteredTools);

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('PDF Tools'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchBar(context),
                const SizedBox(height: 16),
                if (filteredTools.isEmpty)
                  _buildEmptyState(context)
                else
                  ...groupedTools.entries.map(
                    (entry) => _buildToolSection(
                      context,
                      title: entry.key,
                      tools: entry.value,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search tools',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
      ),
    );
  }

  Widget _buildToolSection(
    BuildContext context, {
    required String title,
    required List<PdfTool> tools,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...tools.map(_buildToolCard),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.search_off,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No tools match your search.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different keyword or clear the search.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(PdfTool tool) {
    IconData iconData;

    // Map icon name string to actual IconData
    switch (tool.iconName) {
      case 'Icons.text_fields':
        iconData = Icons.text_fields;
        break;
      case 'Icons.image':
        iconData = Icons.image;
        break;
      case 'Icons.merge':
        iconData = Icons.merge;
        break;
      case 'Icons.compress':
        iconData = Icons.compress;
        break;
      case 'Icons.edit_note':
        iconData = Icons.edit_note;
        break;
      case 'Icons.smart_toy':
        iconData = Icons.smart_toy;
        break;
      case 'Icons.auto_awesome':
        iconData = Icons.auto_awesome;
        break;
      case 'Icons.format_list_bulleted':
        iconData = Icons.format_list_bulleted;
        break;
      case 'Icons.table_chart':
        iconData = Icons.table_chart;
        break;
      case 'Icons.view_headline':
        iconData = Icons.view_headline;
        break;
      case 'Icons.crop_square':
        iconData = Icons.crop_square;
        break;
      case 'Icons.format_textdirection_r_to_l':
        iconData = Icons.format_textdirection_r_to_l;
        break;
      case 'Icons.link':
        iconData = Icons.link;
        break;
      case 'Icons.bookmark':
        iconData = Icons.bookmark;
        break;
      case 'Icons.attach_file':
        iconData = Icons.attach_file;
        break;
      case 'Icons.lock':
        iconData = Icons.lock;
        break;
      case 'Icons.lock_open':
        iconData = Icons.lock_open;
        break;
      case 'Icons.verified':
        iconData = Icons.verified;
        break;
      case 'Icons.draw':
        iconData = Icons.draw;
        break;
      default:
        iconData = Icons.build;
    }

    final category = _categoryFor(tool);
    final isAi = tool.id.contains('ai') || tool.id.contains('summarize');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openTool(tool),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconData,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(category),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                        ),
                        if (isAi)
                          Chip(
                            label: const Text('AI'),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.15),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<T?> _showToolSheet<T>({
    required String title,
    String? subtitle,
    required Widget content,
    required List<Widget> actions,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 16),
            Row(
              children: actions
                  .map(
                    (action) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: action,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim();
    });
  }

  List<PdfTool> _filteredTools() {
    if (_query.isEmpty) return _tools;
    final q = _query.toLowerCase();
    return _tools.where((tool) {
      return tool.name.toLowerCase().contains(q) ||
          tool.description.toLowerCase().contains(q) ||
          tool.id.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<PdfTool>> _groupTools(List<PdfTool> tools) {
    final Map<String, List<PdfTool>> grouped = {
      'Create & Convert': [],
      'Edit & Layout': [],
      'Organize': [],
      'Enhance': [],
      'Security': [],
      'AI': [],
      'Other': [],
    };

    for (final tool in tools) {
      final category = _categoryFor(tool);
      grouped.putIfAbsent(category, () => []).add(tool);
    }

    grouped.removeWhere((_, value) => value.isEmpty);
    return grouped;
  }

  String _categoryFor(PdfTool tool) {
    switch (tool.id) {
      case 'text_to_pdf':
      case 'image_to_pdf':
      case 'table_to_pdf':
      case 'list_to_pdf':
      case 'paragraph_to_pdf':
      case 'table_pdf':
      case 'bullets_lists':
      case 'header_footer':
        return 'Create & Convert';
      case 'annotate_pdf':
      case 'shapes_pdf':
      case 'rtl_text':
      case 'hyperlink_pdf':
      case 'bookmark_pdf':
      case 'attachment_pdf':
        return 'Edit & Layout';
      case 'merge_pdfs':
      case 'compress_pdf':
        return 'Organize';
      case 'ocr_pdf':
      case 'pdf_a_conformance':
      case 'convert_to_pdf_a':
      case 'conformance_pdf':
        return 'Enhance';
      case 'encrypt_pdf':
      case 'decrypt_pdf':
      case 'signature_pdf':
      case 'create_signed_pdf':
      case 'verify_signature_pdf':
      case 'digital_signature':
        return 'Security';
      case 'ai_pdf_assistant':
      case 'summarize_pdf':
        return 'AI';
      default:
        return 'Other';
    }
  }

  Future<void> _openTool(PdfTool tool) async {
    // Log tool selection
    _analytics.logUsePdfTool(toolName: tool.id);
    
    switch (tool.id) {
      case 'text_to_pdf':
        await _openTextToPdfTool(tool);
        break;
      case 'image_to_pdf':
        await _openImageToPdfTool(tool);
        break;
      case 'merge_pdfs':
        await _openMergePdfsTool(tool);
        break;
      case 'compress_pdf':
        await _openCompressPdfTool(tool);
        break;
      case 'annotate_pdf':
        await _openAnnotatePdfTool(tool);
        break;
      case 'ai_pdf_assistant':
        await _openAiPdfAssistantTool(tool);
        break;
      case 'summarize_pdf':
        await _openSummarizePdfTool(tool);
        break;
      case 'bullets_lists':
        await _openBulletsListTool(tool);
        break;
      case 'table_pdf':
        await _openTablePdfTool(tool);
        break;
      case 'header_footer':
        await _openHeaderFooterTool(tool);
        break;
      case 'shapes_pdf':
        await _openShapesTool(tool);
        break;
      case 'rtl_text':
        await _openRtlTextTool(tool);
        break;
      case 'hyperlink_pdf':
        await _openHyperlinkTool(tool);
        break;
      case 'bookmark_pdf':
        await _openBookmarkTool(tool);
        break;
      case 'attachment_pdf':
        await _openAttachmentTool(tool);
        break;
      case 'encrypt_pdf':
        await _openEncryptTool(tool);
        break;
      case 'decrypt_pdf':
        await _openDecryptTool(tool);
        break;
      case 'conformance_pdf':
        await _openConformanceTool(tool);
        break;
      case 'digital_signature':
        await _openDigitalSignatureTool(tool);
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tool.name} is not yet implemented')),
          );
        }
    }
  }

  Future<void> _openTextToPdfTool(PdfTool tool) async {
    final TextEditingController textController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    if (!mounted) return;

    final result = await _showToolSheet<Map<String, dynamic>>(
      title: 'Create PDF from Text',
      subtitle: 'Write content and export it as a PDF document.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title (Optional)',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Content',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.subject),
            ),
            maxLines: 8,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': titleController.text,
              'text': textController.text,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openImageToPdfTool(PdfTool tool) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && mounted) {
        final File imageFile = File(result.files.single.path!);
        final Uint8List imageData = await imageFile.readAsBytes();

        final titleController = TextEditingController();

        final dialogResult = await _showToolSheet<Map<String, dynamic>>(
          title: 'Create PDF from Image',
          subtitle: 'Preview your image before exporting.',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': titleController.text,
                  'imageData': imageData,
                });
              },
              child: const Text('Create'),
            ),
          ],
        );

        if (dialogResult != null && mounted) {
          await _executeToolAndShowResult(tool, dialogResult);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openMergePdfsTool(PdfTool tool) async {
    try {
      if (!mounted) return;
      List<PlatformFile> selectedFiles = [];

      final picked = await showModalBottomSheet<List<PlatformFile>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Merge PDFs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select at least 2 files to combine.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        allowMultiple: true,
                      );
                      if (result != null) {
                        setState(() {
                          selectedFiles = result.files;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      selectedFiles.isEmpty
                          ? 'Select PDF files'
                          : 'Selected ${selectedFiles.length} files',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedFiles.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: selectedFiles
                            .map((file) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: selectedFiles.length < 2
                              ? null
                              : () => Navigator.pop(context, selectedFiles),
                          child: const Text('Merge'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (picked != null && picked.isNotEmpty) {
        final pdfDataList = <Uint8List>[];
        for (final file in picked) {
          if (file.path != null) {
            pdfDataList.add(await File(file.path!).readAsBytes());
          }
        }
        if (pdfDataList.isNotEmpty) {
          await _executeToolAndShowResult(tool, {'pdfDataList': pdfDataList});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openCompressPdfTool(PdfTool tool) async {
    try {
      if (!mounted) return;
      PlatformFile? selectedFile;
      String level = 'medium';

      final picked = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Compress PDF',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a compression level before exporting.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null) {
                        setState(() {
                          selectedFile = result.files.single;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      selectedFile == null
                          ? 'Select PDF file'
                          : selectedFile!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: const InputDecoration(
                      labelText: 'Compression level',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low (Best quality)')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium (Balanced)')),
                      DropdownMenuItem(value: 'high', child: Text('High (Smallest size)')),
                    ],
                    onChanged: (value) => setState(() => level = value ?? 'medium'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: selectedFile == null
                              ? null
                              : () => Navigator.pop(context, {
                                    'file': selectedFile,
                                    'level': level,
                                  }),
                          child: const Text('Compress'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (picked != null && picked['file'] != null && mounted) {
        final PlatformFile fileRef = picked['file'] as PlatformFile;
        final file = File(fileRef.path!);
        final pdfData = await file.readAsBytes();
        await _executeToolAndShowResult(tool, {
          'pdfData': pdfData,
          'compressionLevel': picked['level'] as String,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openAnnotatePdfTool(PdfTool tool) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Annotate PDF'),
          ),
          body: AnnotationsEditorWidget(
            tool: tool,
            analytics: _analytics,
            onExecute: (params) async {
              Navigator.pop(context);
              await _executeToolAndShowResult(tool, params);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openBulletsListTool(PdfTool tool) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Create Bullets & Lists'),
          ),
          body: ListsEditorWidget(
            tool: tool,
            analytics: _analytics,
            onExecute: (params) async {
              Navigator.pop(context);
              await _executeToolAndShowResult(tool, params);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openTablePdfTool(PdfTool tool) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Create Table PDF'),
          ),
          body: TableEditorWidget(
            tool: tool,
            analytics: _analytics,
            onExecute: (params) async {
              Navigator.pop(context);
              await _executeToolAndShowResult(tool, params);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openHeaderFooterTool(PdfTool tool) async {
    final TextEditingController headerController = TextEditingController();
    final TextEditingController footerController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    final TextEditingController pageCountController = TextEditingController(text: '1');

    if (!mounted) return;

    final result = await _showToolSheet<Map<String, dynamic>>(
      title: 'Header & Footer',
      subtitle: 'Add consistent headers and footers to a new PDF.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: headerController,
            decoration: const InputDecoration(
              labelText: 'Header text',
              prefixIcon: Icon(Icons.horizontal_rule),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: footerController,
            decoration: const InputDecoration(
              labelText: 'Footer text',
              prefixIcon: Icon(Icons.horizontal_rule),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyController,
            decoration: const InputDecoration(
              labelText: 'Body text (optional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pageCountController,
            decoration: const InputDecoration(
              labelText: 'Page count',
              prefixIcon: Icon(Icons.layers),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final int pageCount = int.tryParse(pageCountController.text) ?? 1;
            Navigator.pop(context, {
              'headerText': headerController.text,
              'footerText': footerController.text,
              'bodyText': bodyController.text,
              'pageCount': pageCount,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openShapesTool(PdfTool tool) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Draw Shapes'),
          ),
          body: ShapesEditorWidget(
            tool: tool,
            analytics: _analytics,
            onExecute: (params) async {
              Navigator.pop(context);
              await _executeToolAndShowResult(tool, params);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openRtlTextTool(PdfTool tool) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController textController = TextEditingController();
    bool isRtl = true;
    Uint8List? fontData;
    String fontName = 'No font selected';

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'RTL / Unicode Text',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Support right-to-left languages with optional custom font.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Right-to-left'),
                value: isRtl,
                onChanged: (value) => setState(() => isRtl = value),
                contentPadding: EdgeInsets.zero,
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.subject),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fontName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      FilePickerResult? pick = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['ttf', 'otf'],
                      );
                      if (pick != null && pick.files.single.path != null) {
                        final file = File(pick.files.single.path!);
                        final data = await file.readAsBytes();
                        setState(() {
                          fontData = data;
                          fontName = pick.files.single.name;
                        });
                      }
                    },
                    child: const Text('Pick font'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'title': titleController.text,
                          'text': textController.text,
                          'isRtl': isRtl,
                          'fontData': fontData,
                        });
                      },
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openHyperlinkTool(PdfTool tool) async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController textController = TextEditingController();

    if (!mounted) return;

    final result = await _showToolSheet<Map<String, dynamic>>(
      title: 'Create Hyperlink',
      subtitle: 'Add a tappable link inside the PDF.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Link text (optional)',
              prefixIcon: Icon(Icons.text_fields),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'url': urlController.text,
              'text': textController.text,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openBookmarkTool(PdfTool tool) async {
    try {
      FilePickerResult? pick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pick == null || !mounted) return;
      final file = File(pick.files.single.path!);
      final Uint8List pdfData = await file.readAsBytes();

      final TextEditingController titleController = TextEditingController();
      final TextEditingController pageController = TextEditingController(text: '1');

      final result = await _showToolSheet<Map<String, dynamic>>(
        title: 'Add Bookmark',
        subtitle: 'Create a bookmark for quick navigation.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Bookmark title',
                prefixIcon: Icon(Icons.bookmark),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pageController,
              decoration: const InputDecoration(
                labelText: 'Page number',
                prefixIcon: Icon(Icons.filter_1),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final int pageNumber = int.tryParse(pageController.text) ?? 1;
              Navigator.pop(context, {
                'pdfData': pdfData,
                'title': titleController.text,
                'pageNumber': pageNumber,
              });
            },
            child: const Text('Apply'),
          ),
        ],
      );

      if (result != null && mounted) {
        await _executeToolAndShowResult(tool, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openAttachmentTool(PdfTool tool) async {
    try {
      FilePickerResult? pdfPick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pdfPick == null || !mounted) return;
      final Uint8List pdfData = await File(pdfPick.files.single.path!).readAsBytes();

      FilePickerResult? attachmentPick = await FilePicker.platform.pickFiles();
      if (attachmentPick == null || !mounted) return;

      final attachedFile = File(attachmentPick.files.single.path!);
      final Uint8List attachmentData = await attachedFile.readAsBytes();

      final TextEditingController descController = TextEditingController();

      final result = await _showToolSheet<Map<String, dynamic>>(
        title: 'Add Attachment',
        subtitle: 'Embed an extra file inside the PDF.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${attachmentPick.files.single.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'pdfData': pdfData,
                'attachmentData': attachmentData,
                'fileName': attachmentPick.files.single.name,
                'description': descController.text,
              });
            },
            child: const Text('Attach'),
          ),
        ],
      );

      if (result != null && mounted) {
        await _executeToolAndShowResult(tool, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openEncryptTool(PdfTool tool) async {
    try {
      FilePickerResult? pick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pick == null || !mounted) return;
      final Uint8List pdfData = await File(pick.files.single.path!).readAsBytes();

      final TextEditingController userController = TextEditingController();
      final TextEditingController ownerController = TextEditingController();
      String algorithm = 'aes256';

      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Encrypt PDF',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Protect the document with user and owner passwords.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'User password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Owner password',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: algorithm,
                  items: const [
                    DropdownMenuItem(value: 'aes256', child: Text('AES-256')),
                    DropdownMenuItem(value: 'aes256_rev6', child: Text('AES-256 Rev6')),
                    DropdownMenuItem(value: 'aes128', child: Text('AES-128')),
                    DropdownMenuItem(value: 'rc4_128', child: Text('RC4-128')),
                    DropdownMenuItem(value: 'rc4_40', child: Text('RC4-40')),
                  ],
                  onChanged: (value) => setState(() => algorithm = value ?? 'aes256'),
                  decoration: const InputDecoration(
                    labelText: 'Algorithm',
                    prefixIcon: Icon(Icons.security),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'pdfData': pdfData,
                            'userPassword': userController.text,
                            'ownerPassword': ownerController.text,
                            'algorithm': algorithm,
                          });
                        },
                        child: const Text('Encrypt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (result != null && mounted) {
        await _executeToolAndShowResult(tool, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openDecryptTool(PdfTool tool) async {
    try {
      FilePickerResult? pick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pick == null || !mounted) return;
      final Uint8List pdfData = await File(pick.files.single.path!).readAsBytes();

      final TextEditingController passwordController = TextEditingController();

      final result = await _showToolSheet<Map<String, dynamic>>(
        title: 'Decrypt PDF',
        subtitle: 'Enter the password to unlock the file.',
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_open),
          ),
          obscureText: true,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'pdfData': pdfData,
                'password': passwordController.text,
              });
            },
            child: const Text('Decrypt'),
          ),
        ],
      );

      if (result != null && mounted) {
        await _executeToolAndShowResult(tool, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openConformanceTool(PdfTool tool) async {
    final TextEditingController textController = TextEditingController();
    String level = 'a1b';
    Uint8List? fontData;
    String fontName = 'No font selected';

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PDF/A Conformance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Generate a PDF/A compliant document.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: level,
                items: const [
                  DropdownMenuItem(value: 'a1b', child: Text('PDF/A-1B')),
                  DropdownMenuItem(value: 'a2b', child: Text('PDF/A-2B')),
                  DropdownMenuItem(value: 'a3b', child: Text('PDF/A-3B')),
                ],
                onChanged: (value) => setState(() => level = value ?? 'a1b'),
                decoration: const InputDecoration(
                  labelText: 'Conformance level',
                  prefixIcon: Icon(Icons.verified),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  prefixIcon: Icon(Icons.text_snippet),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fontName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      FilePickerResult? pick = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['ttf', 'otf'],
                      );
                      if (pick != null && pick.files.single.path != null) {
                        final data = await File(pick.files.single.path!).readAsBytes();
                        setState(() {
                          fontData = data;
                          fontName = pick.files.single.name;
                        });
                      }
                    },
                    child: const Text('Pick font'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'conformanceLevel': level,
                          'text': textController.text,
                          'fontData': fontData,
                        });
                      },
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openDigitalSignatureTool(PdfTool tool) async {
    if (!mounted) return;

    final bool? useExisting = await _showToolSheet<bool>(
      title: 'Sign PDF',
      subtitle: 'Choose whether to sign an existing file or create a new one.',
      content: const SizedBox.shrink(),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Create New'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Use Existing'),
        ),
      ],
    );

    if (useExisting == null || !mounted) return;

    Uint8List? pdfData;
    if (useExisting) {
      FilePickerResult? pdfPick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (pdfPick == null || !mounted) return;
      pdfData = await File(pdfPick.files.single.path!).readAsBytes();
    }

    FilePickerResult? pfxPick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pfx'],
    );

    if (pfxPick == null || !mounted) return;
    final Uint8List pfxData = await File(pfxPick.files.single.path!).readAsBytes();

    final TextEditingController passwordController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    final result = await _showToolSheet<Map<String, dynamic>>(
      title: 'Certificate Details',
      subtitle: pfxPick.files.single.name,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Certificate password',
              prefixIcon: Icon(Icons.password),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'pdfData': pdfData,
              'pfxData': pfxData,
              'password': passwordController.text,
              'reason': reasonController.text,
            });
          },
          child: const Text('Sign'),
        ),
      ],
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _executeToolAndShowResult(
    PdfTool tool,
    Map<String, dynamic> parameters,
  ) async {
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await ToolsManager().executeTool(tool.id, parameters);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result.success) {
          final previewPath = await _materializeResultPath(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tool.name} completed successfully!'),
              backgroundColor: Colors.green,
              action: previewPath == null
                  ? null
                  : SnackBarAction(
                      label: 'Preview',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PdfViewerScreen(filePath: previewPath),
                          ),
                        );
                      },
                    ),
            ),
          );
          
          // Log success
          _analytics.logUsePdfTool(
            toolName: tool.id,
            result: 'success',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
          
          // Log error
          _analytics.logError(
            errorType: 'tool_execution_error',
            errorMessage: result.errorMessage ?? 'Unknown error',
            screen: 'tools',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Log error
        _analytics.logError(
          errorType: 'tool_exception',
          errorMessage: e.toString(),
          screen: 'tools',
        );
      }
    }
  }

  Future<String?> _materializeResultPath(PdfToolResult result) async {
    try {
      final outputPath = result.outputPath;
      if (outputPath != null && outputPath.isNotEmpty) {
        return outputPath;
      }
      final pdfData = result.pdfData;
      if (pdfData == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/tool_result_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(pdfData, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAiPdfAssistantTool(PdfTool tool) async {
    final TextEditingController promptController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    if (!mounted) return;

    final result = await _showToolSheet<Map<String, dynamic>>(
      title: 'AI PDF Assistant',
      subtitle: 'Generate content from a prompt, ready for export.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title (Optional)',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: promptController,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              hintText: 'e.g., Write an article about climate change',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.auto_awesome),
            ),
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': titleController.text,
              'prompt': promptController.text,
            });
          },
          child: const Text('Generate'),
        ),
      ],
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openSummarizePdfTool(PdfTool tool) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && mounted) {
        final file = File(result.files.single.path!);
        final pdfData = await file.readAsBytes();

        final summaryType = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Summary Type',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Brief'),
                  onTap: () => Navigator.pop(context, 'brief'),
                ),
                ListTile(
                  title: const Text('Detailed'),
                  onTap: () => Navigator.pop(context, 'detailed'),
                ),
                ListTile(
                  title: const Text('Bullet Points'),
                  onTap: () => Navigator.pop(context, 'bullet points'),
                ),
              ],
            ),
          ),
        );

        if (summaryType != null) {
          await _executeToolAndShowResult(tool, {
            'pdfData': pdfData,
            'summaryType': summaryType,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
