import 'package:flutter/material.dart';

import '../../shared/constants/format_constants.dart';
import '../services/file_picker_service.dart';

/// File input button for all 10 tools.
class FilePickerButton extends StatefulWidget {
  final String toolName;
  final String label;
  final IconData? icon;
  final bool allowMultiple;
  final Function(String path)? onFilePicked;
  final Function(List<String> paths)? onFilesPicked;

  const FilePickerButton({
    super.key,
    required this.toolName,
    required this.label,
    this.icon,
    this.allowMultiple = false,
    this.onFilePicked,
    this.onFilesPicked,
  });

  @override
  State<FilePickerButton> createState() => _FilePickerButtonState();
}

class _FilePickerButtonState extends State<FilePickerButton> {
  List<String>? _selectedFileNames;
  bool _busy = false;

  Future<void> _pickFile() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final allowedExtensions = toolAllowedExtensions[widget.toolName] ?? [];
      final mimeType = toolMimeTypes[widget.toolName] ?? '*/*';

      final picked = await FilePickerService.pickFiles(
        toolName: widget.toolName,
        mimeType: mimeType,
        allowMultiple: widget.allowMultiple,
      );

      // Null means the user cancelled inside the picker — not an error, no message.
      if (picked == null) return;
      if (picked.isEmpty) return;

      for (final file in picked) {
        final path = file['path']!;
        final fileName = file['name'] ?? path.split(RegExp(r'[/\\]')).last;
        final ext = fileName.contains('.')
            ? fileName.split('.').last.toLowerCase()
            : '';
        if (!isFileCompatible(fileName, widget.toolName)) {
          final selected = ext.isEmpty ? 'unknown' : ext;
          _showMessage(
            'This tool only accepts ${allowedExtensions.join(', ')} files. You selected a $selected file.',
          );
          return;
        }
      }

      final paths = picked.map((file) => file['path']!).toList(growable: false);
      setState(() {
        _selectedFileNames = picked
            .map(
              (file) =>
                  file['name'] ?? file['path']!.split(RegExp(r'[/\\]')).last,
            )
            .toList();
      });

      if (widget.allowMultiple) {
        widget.onFilesPicked?.call(paths);
      } else {
        widget.onFilePicked?.call(paths.first);
      }
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickFile,
          icon: Icon(widget.icon ?? Icons.upload_file),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_selectedFileNames != null && !widget.allowMultiple) ...[
          const SizedBox(height: 8),
          Text(
            _selectedFileNames!.first,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
