import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../tools/tools.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late List<PdfTool> _tools;
  bool _isLoading = true;

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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
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
      }
    }
  }
}
