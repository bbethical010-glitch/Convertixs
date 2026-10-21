import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/backend_service.dart';
import '../../core/services/file_picker_service.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_tag.dart';

class NewSettingsScreen extends ConsumerStatefulWidget {
  const NewSettingsScreen({super.key});

  @override
  ConsumerState<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends ConsumerState<NewSettingsScreen> {
  String _version = '1.0.13';
  String _buildNumber = '21';
  bool _isBackendHealthy = false;
  bool _isCheckingBackend = true;
  String _cacheSizeStr = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _checkBackend();
    _calculateCache();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkBackend() async {
    final healthy = await backendService.checkHealth();
    if (mounted) {
      setState(() {
        _isBackendHealthy = healthy;
        _isCheckingBackend = false;
      });
    }
  }

  Future<void> _calculateCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalBytes = 0;
      if (tempDir.existsSync()) {
        final files = tempDir.listSync(recursive: true, followLinks: false);
        for (final file in files) {
          if (file is File) totalBytes += file.lengthSync();
        }
      }
      if (mounted) {
        setState(() {
          if (totalBytes < 1024 * 1024) {
            _cacheSizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
          } else {
            _cacheSizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cacheSizeStr = '0 MB');
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final files = tempDir.listSync(recursive: true, followLinks: false);
        for (final file in files) {
          try {
            if (file is File) file.deleteSync();
          } catch (_) {}
        }
      }
      _calculateCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temporary cache cleared.'),
            backgroundColor: BrutalColors.black,
          ),
        );
      }
    } catch (_) {}
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'App Settings',
        subtitle: 'System & Engine Options',
        showBackButton: false,
        showUpgrade: false,
        showProfile: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Pro Status Card
          GestureDetector(
            onTap: () => context.push('/store'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: BrutalColors.black,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                    ),
                    child: const Icon(LucideIcons.crown, size: 24, color: BrutalColors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONVERTIX PRO STATUS',
                          style: BrutalTheme.headline(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view Pro plans, ad-free passes & packs',
                          style: BrutalTheme.body(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.arrowRight, size: 18, color: BrutalColors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          _buildSectionHeader('Engine & Cloud Sync'),
          const SizedBox(height: 8),

          BrutalistCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: BrutalColors.surfaceContainerLow,
                        border: BrutalTheme.brutalBorder,
                      ),
                      child: const Icon(LucideIcons.server, size: 18, color: BrutalColors.black),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CLOUD WORKER ENGINE', style: BrutalTheme.headline(fontSize: 12)),
                        Text(
                          _isCheckingBackend
                              ? 'Checking status...'
                              : (_isBackendHealthy ? 'Online & Healthy' : 'Degraded'),
                          style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                BrutalistTag(
                  label: _isBackendHealthy ? 'ACTIVE' : 'OFFLINE',
                  inverted: _isBackendHealthy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          BrutalistCard(
            onTap: () => context.push('/tool-settings'),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: BrutalColors.surfaceContainerLow,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: const Icon(LucideIcons.slidersHorizontal, size: 18, color: BrutalColors.black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOOL DEFAULT FORMATS', style: BrutalTheme.headline(fontSize: 12)),
                      Text('Configure default output extension per tool',
                          style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: BrutalColors.black),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _buildSectionHeader('Storage & Data'),
          const SizedBox(height: 8),

          BrutalistCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: BrutalColors.surfaceContainerLow,
                        border: BrutalTheme.brutalBorder,
                      ),
                      child: const Icon(LucideIcons.hardDrive, size: 18, color: BrutalColors.black),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TEMP ENCODING CACHE', style: BrutalTheme.headline(fontSize: 12)),
                        Text('Cached video chunks: $_cacheSizeStr',
                            style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted)),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _clearCache,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: BrutalColors.black,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: Text(
                      'CLEAR',
                      style: BrutalTheme.label(fontSize: 10, color: BrutalColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          BrutalistCard(
            onTap: () async {
              await FilePickerService.resetAllPreferences();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Source app preferences reset.'),
                    backgroundColor: BrutalColors.black,
                  ),
                );
              }
            },
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: BrutalColors.surfaceContainerLow,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: const Icon(LucideIcons.folderSync, size: 18, color: BrutalColors.black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESET FILE PICKER MEMORY', style: BrutalTheme.headline(fontSize: 12)),
                      Text('Clears remembered source apps for all 10 tools',
                          style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.refreshCw, size: 16, color: BrutalColors.black),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _buildSectionHeader('About & Legal'),
          const SizedBox(height: 8),

          BrutalistCard(
            onTap: () => context.push('/licenses'),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: BrutalColors.surfaceContainerLow,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: const Icon(LucideIcons.scrollText, size: 18, color: BrutalColors.black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OPEN SOURCE LICENSES', style: BrutalTheme.headline(fontSize: 12)),
                      Text('FFmpeg, Flutter & Open Source modules',
                          style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: BrutalColors.black),
              ],
            ),
          ),
          const SizedBox(height: 8),

          BrutalistCard(
            onTap: () => _launchUrl('https://convertix.app/privacy'),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: BrutalColors.surfaceContainerLow,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: const Icon(LucideIcons.shieldCheck, size: 18, color: BrutalColors.black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRIVACY POLICY', style: BrutalTheme.headline(fontSize: 12)),
                      Text('On-device safety and zero data collection policy',
                          style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.externalLink, size: 16, color: BrutalColors.black),
              ],
            ),
          ),
          const SizedBox(height: 8),

          BrutalistCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: BrutalColors.surfaceContainerLow,
                        border: BrutalTheme.brutalBorder,
                      ),
                      child: const Icon(LucideIcons.info, size: 18, color: BrutalColors.black),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONVERTIX CORE', style: BrutalTheme.headline(fontSize: 12)),
                        Text('Version $_version (Build $_buildNumber)',
                            style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted)),
                      ],
                    ),
                  ],
                ),
                const BrutalistTag(label: 'V3.4 STITCH'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrutalColors.black, width: 2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: BrutalTheme.label(fontSize: 11, letterSpacing: 0.8),
      ),
    );
  }
}
