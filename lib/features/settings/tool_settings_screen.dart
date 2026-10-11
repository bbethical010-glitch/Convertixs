import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/output_location_service.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../shared/constants/format_constants.dart';

class ToolSettingsScreen extends ConsumerWidget {
  const ToolSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tool Settings')),
      body: ListView.builder(
        itemCount: ConvertixTool.values.length,
        itemBuilder: (context, index) {
          final tool = ConvertixTool.values[index];
          final folder = prefs.getString('output_folder_${tool.name}') ?? 'Default (${tool.collection.wireName})';

          return ListTile(
            title: Text(_toolDisplayName(tool)),
            subtitle: Text('Folder: $folder'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showToolSettingsDialog(context, tool, prefs),
          );
        },
      ),
    );
  }

  String _toolDisplayName(ConvertixTool tool) {
    switch (tool) {
      case ConvertixTool.imageConverter:
        return 'Image Converter';
      case ConvertixTool.videoConverter:
        return 'Video Converter';
      case ConvertixTool.videoCompression:
        return 'Video Compression';
      case ConvertixTool.audioConverter:
        return 'Audio Converter';
      case ConvertixTool.videoToAudio:
        return 'Video to Audio';
      case ConvertixTool.imageToPdf:
        return 'Image to PDF';
      case ConvertixTool.documentConverter:
        return 'Document Converter';
      case ConvertixTool.greyscalePdf:
        return 'Greyscale PDF';
      case ConvertixTool.mergePdf:
        return 'Merge PDF';
      case ConvertixTool.splitPdf:
        return 'Split PDF';
    }
  }

  void _showToolSettingsDialog(BuildContext context, ConvertixTool tool, SharedPreferences prefs) {
    showDialog(
      context: context,
      builder: (context) => _ToolSettingsDialog(tool: tool, prefs: prefs),
    );
  }
}

class _ToolSettingsDialog extends StatefulWidget {
  final ConvertixTool tool;
  final SharedPreferences prefs;

  const _ToolSettingsDialog({required this.tool, required this.prefs});

  @override
  State<_ToolSettingsDialog> createState() => _ToolSettingsDialogState();
}

class _ToolSettingsDialogState extends State<_ToolSettingsDialog> {
  late String _format;
  late int _quality;

  @override
  void initState() {
    super.initState();
    final defaultFormat = _getDefaultFormatForTool(widget.tool);
    _format = widget.prefs.getString('default_format_${widget.tool.name}') ?? defaultFormat;
    _quality = widget.prefs.getInt('quality_preset_${widget.tool.name}') ?? 90;
  }

  String _getDefaultFormatForTool(ConvertixTool tool) {
    switch (tool) {
      case ConvertixTool.imageConverter:
        return imageOutputFormats.first;
      case ConvertixTool.videoConverter:
        return videoOutputFormats.first;
      case ConvertixTool.audioConverter:
      case ConvertixTool.videoToAudio:
        return audioOutputFormats.first;
      case ConvertixTool.documentConverter:
        return documentOutputFormats.first;
      default:
        return 'pdf';
    }
  }
  
  List<String> _getFormatsForTool(ConvertixTool tool) {
    switch (tool) {
      case ConvertixTool.imageConverter:
        return imageOutputFormats;
      case ConvertixTool.videoConverter:
        return videoOutputFormats;
      case ConvertixTool.audioConverter:
      case ConvertixTool.videoToAudio:
        return audioOutputFormats;
      case ConvertixTool.documentConverter:
        return documentOutputFormats;
      default:
        return ['pdf'];
    }
  }

  bool _hasFormatPicker(ConvertixTool tool) {
    return _getFormatsForTool(tool).length > 1;
  }

  bool _hasQualityPicker(ConvertixTool tool) {
    return tool == ConvertixTool.imageConverter || tool == ConvertixTool.imageToPdf;
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.prefs.getString('output_folder_${widget.tool.name}') ?? 'Default';

    return AlertDialog(
      title: const Text('Tool Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasFormatPicker(widget.tool)) ...[
              const Text('Default Output Format'),
              DropdownButton<String>(
                value: _format,
                isExpanded: true,
                items: _getFormatsForTool(widget.tool)
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _format = val);
                    widget.prefs.setString('default_format_${widget.tool.name}', val);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_hasQualityPicker(widget.tool)) ...[
              Text('Default Quality: $_quality%'),
              Slider(
                value: _quality.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: _quality.toString(),
                onChanged: (val) {
                  setState(() => _quality = val.toInt());
                  widget.prefs.setInt('quality_preset_${widget.tool.name}', _quality);
                },
              ),
              const SizedBox(height: 16),
            ],
            const Text('Output Folder'),
            const SizedBox(height: 8),
            Text(folder, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final uri = await outputLocationService.pickFolder();
                    if (uri != null) {
                      await widget.prefs.setString('output_folder_${widget.tool.name}', uri);
                      setState(() {});
                    }
                  },
                  child: const Text('Change'),
                ),
                if (widget.prefs.containsKey('output_folder_${widget.tool.name}')) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      widget.prefs.remove('output_folder_${widget.tool.name}');
                      setState(() {});
                    },
                    child: const Text('Reset'),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
