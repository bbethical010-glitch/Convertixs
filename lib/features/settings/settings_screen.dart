import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/history_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _isBackendHealthy = false;
  bool _isCheckingBackend = true;
  Map<String, String> _sourcePreferences = {};
  bool _isLoadingPreferences = true;

  static const Map<String, String> _toolTitles = {
    'image_converter': 'Image Converter',
    'video_to_audio': 'Video to Audio',
    'audio_converter': 'Audio Converter',
    'video_converter': 'Video Converter',
    'video_compression': 'Video Compression',
    'image_to_pdf': 'Image to PDF',
    'document_convert': 'Document Converter',
    'greyscale_pdf': 'Greyscale PDF',
    'merge_pdf': 'Merge PDF',
    'split_pdf': 'Split PDF',
  };

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _checkBackendHealth();
    _loadFileSourcePreferences();
  }

  Future<void> _loadFileSourcePreferences() async {
    final prefs = await FilePickerService.getPreferences();
    if (mounted) {
      setState(() {
        _sourcePreferences = prefs;
        _isLoadingPreferences = false;
      });
    }
  }

  String _formatToolName(String raw) {
    return _toolTitles[raw] ??
        raw
            .split('_')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
            .join(' ');
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Version ${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _checkBackendHealth() async {
    setState(() => _isCheckingBackend = true);
    final isHealthy = await backendService.checkHealth();
    if (mounted) {
      setState(() {
        _isBackendHealthy = isHealthy;
        _isCheckingBackend = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all conversion history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(historyServiceProvider).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(LucideIcons.crown, color: Colors.amber),
            title: const Text('Convertix Pro & Store', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Upgrade to Pro, remove ads & unlock all packs'),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            onTap: () => context.push('/store'),
          ),
          SwitchListTile(
            secondary: const Icon(LucideIcons.moon),
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (val) {
              ref.read(themeProvider.notifier).toggle();
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.settings),
            title: const Text('Tool Settings'),
            subtitle: const Text('Configure default format, quality, and folder per tool'),
            onTap: () => context.push('/tool-settings'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: Colors.red),
            title: const Text('Clear History', style: TextStyle(color: Colors.red)),
            onTap: _clearHistory,
          ),
          const Divider(),
          _buildSectionHeader('Backend Status'),
          ListTile(
            leading: const Icon(LucideIcons.server),
            title: const Text('Document Tools Server'),
            subtitle: Text(_isCheckingBackend
                ? 'Checking...'
                : (_isBackendHealthy ? 'Online' : 'Offline')),
            trailing: _isCheckingBackend
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _isBackendHealthy ? LucideIcons.checkCircle : LucideIcons.xCircle,
                    color: _isBackendHealthy ? Colors.green : Colors.red,
                  ),
            onTap: _checkBackendHealth,
          ),
          const Divider(),
          _buildSectionHeader('File Source Preferences'),
          if (_isLoadingPreferences)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_sourcePreferences.isEmpty)
            ListTile(
              leading: const Icon(LucideIcons.folderInput),
              title: const Text('Default File Chooser'),
              subtitle: Text(
                'Convertix will show the Android system chooser. No default apps are currently remembered.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          else ...[
            for (final entry in _sourcePreferences.entries)
              ListTile(
                leading: const Icon(LucideIcons.folderCheck),
                title: Text(_formatToolName(entry.key)),
                subtitle: Text(
                  'Default: ${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                ),
                trailing: TextButton.icon(
                  icon: const Icon(LucideIcons.rotateCcw, size: 14),
                  label: const Text('Reset'),
                  onPressed: () async {
                    await FilePickerService.resetPreference(entry.key);
                    await _loadFileSourcePreferences();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reset ${_formatToolName(entry.key)} to system chooser'),
                        ),
                      );
                    }
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('Reset All Sources to Default'),
                onPressed: () async {
                  await FilePickerService.resetAllPreferences();
                  await _loadFileSourcePreferences();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All file source preferences reset')),
                    );
                  }
                },
              ),
            ),
          ],
          const Divider(),
          _buildSectionHeader('Permissions'),
          ListTile(
            leading: const Icon(LucideIcons.shieldCheck),
            title: const Text('Manage App Permissions'),
            subtitle: Text(
              'Allow notifications or media management',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            onTap: () async {
              await openAppSettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(LucideIcons.scale),
            title: const Text('Open Source Licenses'),
            onTap: () => context.push('/licenses'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.fileText),
            title: const Text('Privacy Policy'),
            onTap: () => _launchUrl('https://example.com/privacy'), // Placeholder
          ),
          ListTile(
            leading: const Icon(LucideIcons.star),
            title: const Text('Rate App'),
            onTap: () => _launchUrl('market://details?id=com.allformat.converter'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: const Text('Convertix'),
            subtitle: Text(
              _version.isEmpty ? 'Loading...' : _version,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
