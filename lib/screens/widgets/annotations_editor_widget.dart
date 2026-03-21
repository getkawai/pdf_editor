import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import '../../tools/tools.dart';
import '../../services/analytics_service.dart';

/// Widget for PDF annotations UI
class AnnotationsEditorWidget extends StatefulWidget {
  final PdfTool tool;
  final AnalyticsService analytics;
  final Function(Map<String, dynamic>) onExecute;

  const AnnotationsEditorWidget({
    super.key,
    required this.tool,
    required this.analytics,
    required this.onExecute,
  });

  @override
  State<AnnotationsEditorWidget> createState() =>
      _AnnotationsEditorWidgetState();
}

class _AnnotationsEditorWidgetState extends State<AnnotationsEditorWidget> {
  Uint8List? _selectedPdf;
  String? _pdfPath;
  final List<Map<String, dynamic>> _annotations = [];
  String _selectedAnnotationType = 'text';
  Color _selectedColor = Colors.yellow;
  double _fontSize = 12.0;
  final TextEditingController _textController = TextEditingController();
  int _pageNumber = 1;

  final List<Color> _highlightColors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.orange,
  ];

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pdfPath = result.files.single.path!;
          _selectedPdf = null; // Will be loaded when needed
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking PDF: $e')));
      }
    }
  }

  void _addAnnotation() {
    if (_textController.text.isEmpty && _selectedAnnotationType == 'text') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter annotation text')),
      );
      return;
    }

    setState(() {
      _annotations.add({
        'type': _selectedAnnotationType,
        'text': _textController.text,
        'color': _selectedColor.toARGB32(),
        'fontSize': _fontSize,
        'x': 50.0 + (_annotations.length * 30),
        'y': 100.0 + (_annotations.length * 30),
        'width': _selectedAnnotationType == 'highlight' ? 150.0 : 200.0,
        'height': _selectedAnnotationType == 'highlight' ? 20.0 : 30.0,
        'pageNumber': _pageNumber,
      });
      _textController.clear();
    });
  }

  void _removeAnnotation(int index) {
    setState(() {
      _annotations.removeAt(index);
    });
  }

  Future<void> _applyAnnotations() async {
    if (_selectedPdf == null && _pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    if (_annotations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one annotation')),
      );
      return;
    }

    Uint8List pdfData;
    if (_selectedPdf != null) {
      pdfData = _selectedPdf!;
    } else {
      pdfData = await File(_pdfPath!).readAsBytes();
    }

    widget.onExecute({
      'pdfData': pdfData,
      'annotations': _annotations,
      'pageNumber': _pageNumber,
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          // PDF Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select PDF',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  if (_pdfPath != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pdfPath!.split('/').last,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _pdfPath = null;
                              _selectedPdf = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Select PDF File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Page Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.looks_one),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _pageNumber = int.tryParse(value) ?? 1;
                    },
                    controller: TextEditingController(
                      text: _pageNumber.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Annotation Type Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedAnnotationType,
            decoration: const InputDecoration(
              labelText: 'Annotation Type',
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Text Annotation')),
              DropdownMenuItem(value: 'highlight', child: Text('Highlight')),
              DropdownMenuItem(value: 'rectangle', child: Text('Rectangle')),
              DropdownMenuItem(value: 'circle', child: Text('Circle')),
            ],
            onChanged: (value) =>
                setState(() => _selectedAnnotationType = value ?? 'text'),
          ),
          const SizedBox(height: 16),

          // Text input for annotations
          if (_selectedAnnotationType == 'text') ...[
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Annotation Text',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
          ],

          // Color selector
          const Text(
            'Color:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                (_selectedAnnotationType == 'highlight'
                        ? _highlightColors
                        : [
                            Colors.red,
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.black,
                          ])
                    .map((color) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color
                                  ? Colors.black
                                  : Colors.grey,
                              width: _selectedColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
          ),
          const SizedBox(height: 16),

          // Font size (for text annotations)
          if (_selectedAnnotationType == 'text') ...[
            ListTile(
              title: const Text('Font Size'),
              subtitle: Slider(
                value: _fontSize,
                min: 8,
                max: 24,
                divisions: 16,
                label: _fontSize.toString(),
                onChanged: (value) => setState(() => _fontSize = value),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Add annotation button
          ElevatedButton.icon(
            onPressed: _pdfPath != null ? _addAnnotation : null,
            icon: const Icon(Icons.add_comment),
            label: const Text('Add Annotation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Annotations list
          if (_annotations.isNotEmpty) ...[
            Text(
              'Annotations (${_annotations.length}):',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _annotations.length,
              itemBuilder: (context, index) {
                final annotation = _annotations[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(annotation['color'] as int),
                        shape: annotation['type'] == 'circle'
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                      ),
                    ),
                    title: Text(annotation['type'].toString().toUpperCase()),
                    subtitle: Text(
                      annotation['text']?.isNotEmpty == true
                          ? annotation['text']
                          : 'Page ${annotation['pageNumber']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeAnnotation(index),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Apply button
          ElevatedButton.icon(
            onPressed: _annotations.isNotEmpty ? _applyAnnotations : null,
            icon: const Icon(Icons.save),
            label: const Text('Apply Annotations to PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_note,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annotate with precision',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a PDF and add highlights or notes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
