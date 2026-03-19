import 'package:flutter/material.dart';
import '../../tools/tools.dart';
import '../../services/analytics_service.dart';

/// Widget for visual shapes drawing UI
class ShapesEditorWidget extends StatefulWidget {
  final PdfTool tool;
  final AnalyticsService analytics;
  final Function(Map<String, dynamic>) onExecute;

  const ShapesEditorWidget({
    super.key,
    required this.tool,
    required this.analytics,
    required this.onExecute,
  });

  @override
  State<ShapesEditorWidget> createState() => _ShapesEditorWidgetState();
}

class _ShapesEditorWidgetState extends State<ShapesEditorWidget> {
  final List<Map<String, dynamic>> _shapes = [];
  String _selectedShapeType = 'rectangle';
  Color _selectedColor = Colors.blue;
  double _strokeWidth = 2.0;
  final TextEditingController _titleController = TextEditingController();

  final List<Color> _presetColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.black,
  ];

  void _addShape() {
    setState(() {
      _shapes.add({
        'type': _selectedShapeType,
        'color': _selectedColor.toARGB32(),
        'strokeWidth': _strokeWidth,
        'x': 50.0 + (_shapes.length * 20),
        'y': 50.0 + (_shapes.length * 20),
        'width': 100.0,
        'height': _selectedShapeType == 'line' ? 2.0 : 100.0,
      });
    });
  }

  void _removeShape(int index) {
    setState(() {
      _shapes.removeAt(index);
    });
  }

  void _updateShape(int index, Map<String, dynamic> updates) {
    setState(() {
      _shapes[index].addAll(updates);
    });
  }

  Future<void> _createPdf() async {
    widget.onExecute({
      'title': _titleController.text,
      'shapes': _shapes,
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Document Title (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // Shape type selector
          DropdownButtonFormField<String>(
            initialValue: _selectedShapeType,
            decoration: const InputDecoration(
              labelText: 'Shape Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'rectangle', child: Text('Rectangle')),
              DropdownMenuItem(value: 'ellipse', child: Text('Ellipse/Circle')),
              DropdownMenuItem(value: 'line', child: Text('Line')),
              DropdownMenuItem(value: 'triangle', child: Text('Triangle')),
            ],
            onChanged: (value) => setState(() => _selectedShapeType = value ?? 'rectangle'),
          ),
          const SizedBox(height: 16),

          // Color selector
          const Text('Color:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _presetColors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.grey,
                      width: _selectedColor == color ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Stroke width
          ListTile(
            title: const Text('Stroke Width'),
            subtitle: Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              divisions: 9,
              label: _strokeWidth.toString(),
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
          ),
          const SizedBox(height: 16),

          // Add shape button
          ElevatedButton.icon(
            onPressed: _addShape,
            icon: const Icon(Icons.add_box),
            label: const Text('Add Shape'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Shapes list
          if (_shapes.isNotEmpty) ...[
            const Text(
              'Shapes List:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shapes.length,
              itemBuilder: (context, index) {
                final shape = _shapes[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(shape['color'] as int),
                        shape: shape['type'] == 'ellipse' ? BoxShape.circle : BoxShape.rectangle,
                      ),
                    ),
                    title: Text('${shape['type'].toString().toUpperCase()} ${index + 1}'),
                    subtitle: Text(
                      'Position: (${shape['x'].toStringAsFixed(0)}, ${shape['y'].toStringAsFixed(0)})',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeShape(index),
                    ),
                    onTap: () => _showEditShapeDialog(index),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Preview area
          if (_shapes.isNotEmpty) ...[
            const Text(
              'Preview:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _ShapesPreviewPainter(_shapes),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Create button
          ElevatedButton.icon(
            onPressed: _shapes.isNotEmpty ? _createPdf : null,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Create PDF with Shapes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditShapeDialog(int index) {
    final shape = _shapes[index];
    final xController = TextEditingController(text: shape['x'].toString());
    final yController = TextEditingController(text: shape['y'].toString());
    final widthController = TextEditingController(text: shape['width'].toString());
    final heightController = TextEditingController(text: shape['height'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Shape ${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: xController,
                decoration: const InputDecoration(
                  labelText: 'X Position',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yController,
                decoration: const InputDecoration(
                  labelText: 'Y Position',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widthController,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(
                  labelText: 'Height',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateShape(index, {
                'x': double.tryParse(xController.text) ?? shape['x'],
                'y': double.tryParse(yController.text) ?? shape['y'],
                'width': double.tryParse(widthController.text) ?? shape['width'],
                'height': double.tryParse(heightController.text) ?? shape['height'],
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ShapesPreviewPainter extends CustomPainter {
  final List<Map<String, dynamic>> shapes;

  _ShapesPreviewPainter(this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      final paint = Paint()
        ..color = Color(shape['color'] as int)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (shape['strokeWidth'] as double).clamp(1, 3);

      final type = shape['type'] as String;
      final x = (shape['x'] as double) / 3;
      final y = (shape['y'] as double) / 3;
      final width = (shape['width'] as double) / 3;
      final height = (shape['height'] as double) / 3;

      switch (type) {
        case 'rectangle':
          canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
          break;
        case 'ellipse':
          canvas.drawOval(Rect.fromLTWH(x, y, width, height), paint);
          break;
        case 'line':
          canvas.drawLine(Offset(x, y), Offset(x + width, y + height), paint);
          break;
        case 'triangle':
          final path = Path()
            ..moveTo(x + width / 2, y)
            ..lineTo(x + width, y + height)
            ..lineTo(x, y + height)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
