import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../tools/tools.dart';
import '../services/analytics_service.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late List<PdfTool> _tools;
  bool _isLoading = true;
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _loadTools();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Tools'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                return _buildToolCard(tool);
              },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openTool(tool),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create PDF from Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text,
                'text': textController.text,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
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

        final dialogResult = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Create PDF from Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(
                  imageFile,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'title': titleController.text,
                    'imageData': imageData,
                  });
                },
                child: const Text('Create'),
              ),
            ],
          ),
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && mounted) {
        List<Uint8List> pdfDataList = [];
        
        for (final file in result.files) {
          if (file.path != null) {
            final pdfData = await File(file.path!).readAsBytes();
            pdfDataList.add(pdfData);
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && mounted) {
        final file = File(result.files.single.path!);
        final pdfData = await file.readAsBytes();

        await _executeToolAndShowResult(tool, {
          'pdfData': pdfData,
          'compressionLevel': 'medium',
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annotation tool - Coming soon')),
      );
    }
  }

  Future<void> _openBulletsListTool(PdfTool tool) async {
    final TextEditingController itemsController = TextEditingController();
    bool ordered = true;

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Bullets & Lists'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Ordered list'),
                value: ordered,
                onChanged: (value) => setState(() => ordered = value),
              ),
              TextField(
                controller: itemsController,
                decoration: const InputDecoration(
                  labelText: 'Items (one per line)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'items': itemsController.text,
                  'ordered': ordered,
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openTablePdfTool(PdfTool tool) async {
    final TextEditingController tableController = TextEditingController();
    bool hasHeader = true;

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Table PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('First row is header'),
                value: hasHeader,
                onChanged: (value) => setState(() => hasHeader = value),
              ),
              TextField(
                controller: tableController,
                decoration: const InputDecoration(
                  labelText: 'CSV rows (comma-separated)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'tableData': tableController.text,
                  'hasHeader': hasHeader,
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openHeaderFooterTool(PdfTool tool) async {
    final TextEditingController headerController = TextEditingController();
    final TextEditingController footerController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    final TextEditingController pageCountController = TextEditingController(text: '1');

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Header & Footer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: headerController,
              decoration: const InputDecoration(
                labelText: 'Header text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: footerController,
              decoration: const InputDecoration(
                labelText: 'Footer text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Body text (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pageCountController,
              decoration: const InputDecoration(
                labelText: 'Page count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openShapesTool(PdfTool tool) async {
    String shapeType = 'all';
    const List<String> options = <String>['all', 'rectangle', 'ellipse', 'line', 'polygon'];

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Draw Shapes'),
          content: DropdownButtonFormField<String>(
            value: shapeType,
            items: options
                .map((value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) => setState(() => shapeType = value ?? 'all'),
            decoration: const InputDecoration(
              labelText: 'Shape type',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {'shapeType': shapeType});
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openRtlTextTool(PdfTool tool) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController textController = TextEditingController();
    bool isRtl = true;
    Uint8List? fontData;
    String fontName = 'No font selected';

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('RTL / Unicode Text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Right-to-left'),
                value: isRtl,
                onChanged: (value) => setState(() => isRtl = value),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
          ],
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Hyperlink'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Link text (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'url': urlController.text,
                'text': textController.text,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
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

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Bookmark'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Bookmark title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pageController,
                decoration: const InputDecoration(
                  labelText: 'Page number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Attachment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${attachmentPick.files.single.name}'),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Encrypt PDF'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'User password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Owner password',
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
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
            ],
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

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Decrypt PDF'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'pdfData': pdfData,
                  'password': passwordController.text,
                });
              },
              child: const Text('Decrypt'),
            ),
          ],
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

  Future<void> _openConformanceTool(PdfTool tool) async {
    final TextEditingController textController = TextEditingController();
    String level = 'a1b';
    Uint8List? fontData;
    String fontName = 'No font selected';

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('PDF/A Conformance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'conformanceLevel': level,
                  'text': textController.text,
                  'fontData': fontData,
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _executeToolAndShowResult(tool, result);
    }
  }

  Future<void> _openDigitalSignatureTool(PdfTool tool) async {
    if (!mounted) return;

    final bool? useExisting = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign PDF'),
        content: const Text('Do you want to sign an existing PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Create New'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use Existing'),
          ),
        ],
      ),
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Certificate: ${pfxPick.files.single.name}'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Certificate password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tool.name} completed successfully!'),
              backgroundColor: Colors.green,
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

  Future<void> _openAiPdfAssistantTool(PdfTool tool) async {
    final TextEditingController promptController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI PDF Assistant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a prompt to generate PDF content using AI.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'e.g., Write an article about climate change',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text,
                'prompt': promptController.text,
              });
            },
            child: const Text('Generate'),
          ),
        ],
      ),
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

        final summaryType = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Summary Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
