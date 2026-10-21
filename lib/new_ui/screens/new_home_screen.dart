import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/brutalist_filter_chips.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_live_task_bar.dart';

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String category;
  final List<String> keywords;

  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.category,
    required this.keywords,
  });
}

class NewHomeScreen extends ConsumerStatefulWidget {
  const NewHomeScreen({super.key});

  @override
  ConsumerState<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends ConsumerState<NewHomeScreen> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  static const List<_ToolItem> _allTools = [
    _ToolItem(
      title: 'Compress Video',
      subtitle: 'Reduce file size while keeping high quality',
      icon: LucideIcons.minimize2,
      route: '/video-compression',
      category: 'video',
      keywords: ['compress', 'video', 'reduce', 'size', 'shrink', 'mb', 'gb'],
    ),
    _ToolItem(
      title: 'Convert Video',
      subtitle: 'Change format to MP4, MOV, MKV & more',
      icon: LucideIcons.video,
      route: '/video-converter',
      category: 'video',
      keywords: ['convert', 'video', 'mp4', 'mov', 'mkv', 'webm', 'format'],
    ),
    _ToolItem(
      title: 'Extract Audio',
      subtitle: 'Save sound or music from video as MP3',
      icon: LucideIcons.music,
      route: '/video-to-audio',
      category: 'audio',
      keywords: ['extract', 'audio', 'sound', 'music', 'mp3', 'video to audio', 'wav'],
    ),
    _ToolItem(
      title: 'Convert Audio',
      subtitle: 'Convert between MP3, AAC, WAV & more',
      icon: LucideIcons.audioLines,
      route: '/audio-converter',
      category: 'audio',
      keywords: ['audio', 'music', 'sound', 'mp3', 'aac', 'wav', 'flac', 'm4a'],
    ),
    _ToolItem(
      title: 'Convert Photos',
      subtitle: 'Convert JPG, PNG, WEBP & BMP formats',
      icon: LucideIcons.image,
      route: '/image-converter',
      category: 'image',
      keywords: ['image', 'photo', 'picture', 'jpg', 'jpeg', 'png', 'webp', 'bmp'],
    ),
    _ToolItem(
      title: 'Photos to PDF',
      subtitle: 'Turn multiple pictures into a PDF document',
      icon: LucideIcons.fileImage,
      route: '/image-to-pdf',
      category: 'document',
      keywords: ['photo to pdf', 'image to pdf', 'picture to pdf', 'pdf', 'scan'],
    ),
    _ToolItem(
      title: 'Office to PDF',
      subtitle: 'Convert Word, Excel & PowerPoint to PDF',
      icon: LucideIcons.fileSpreadsheet,
      route: '/document-convert',
      category: 'document',
      keywords: ['doc', 'docx', 'word', 'excel', 'xlsx', 'powerpoint', 'pptx', 'pdf', 'office'],
    ),
    _ToolItem(
      title: 'Merge PDFs',
      subtitle: 'Combine multiple PDF files into one file',
      icon: LucideIcons.layers,
      route: '/merge-pdf',
      category: 'document',
      keywords: ['merge', 'combine', 'join', 'pdf', 'multi pdf'],
    ),
    _ToolItem(
      title: 'Split PDF',
      subtitle: 'Separate or extract pages from a PDF',
      icon: LucideIcons.scissors,
      route: '/split-pdf',
      category: 'document',
      keywords: ['split', 'cut', 'pages', 'extract', 'pdf', 'separate'],
    ),
    _ToolItem(
      title: 'Black & White PDF',
      subtitle: 'Turn color PDF grey to save printer ink',
      icon: LucideIcons.palette,
      route: '/greyscale-pdf',
      category: 'document',
      keywords: ['greyscale', 'grayscale', 'black and white', 'bw', 'ink', 'toner', 'pdf'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ToolItem> get _filteredTools {
    final query = _searchController.text.trim().toLowerCase();

    return _allTools.where((tool) {
      // Category filter
      if (_selectedCategory != 'all' && tool.category != _selectedCategory) {
        return false;
      }

      // Search query filter
      if (query.isNotEmpty) {
        final inTitle = tool.title.toLowerCase().contains(query);
        final inSubtitle = tool.subtitle.toLowerCase().contains(query);
        final inKeywords = tool.keywords.any((k) => k.contains(query));
        return inTitle || inSubtitle || inKeywords;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tools = _filteredTools;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: const BrutalistHeader(
        title: 'Convertix',
        subtitle: 'File Converter',
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: BrutalTheme.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BrutalColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search tools (e.g. compress, pdf, mp3)...',
                        hintStyle: BrutalTheme.body(
                          fontSize: 13,
                          color: BrutalColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: BrutalColors.black,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16, color: BrutalColors.black),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Category Filter Chips
              SliverToBoxAdapter(
                child: BrutalistFilterChips(
                  selectedCategory: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Empty Search Result
              if (tools.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: BrutalColors.surfaceContainerLow,
                              border: BrutalTheme.brutalBorder,
                            ),
                            child: const Icon(LucideIcons.searchX, size: 26, color: BrutalColors.black),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No tools found',
                            style: BrutalTheme.headline(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for "video", "pdf", or "audio"',
                            style: BrutalTheme.body(
                              fontSize: 12,
                              color: BrutalColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _selectedCategory = 'all');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: const BoxDecoration(
                                color: BrutalColors.black,
                                border: BrutalTheme.brutalBorder,
                              ),
                              child: Text(
                                'Show All Tools',
                                style: BrutalTheme.headline(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: BrutalColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Featured "Compress Video" Card if present in filtered results and not actively searching
                if (!isSearching && _selectedCategory == 'all') ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFeaturedCard(context, _allTools.first),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                // Grid of Tools
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Skip the featured first tool if we showed it above and we are in "all" view
                        final toolList = (!isSearching && _selectedCategory == 'all')
                            ? tools.skip(1).toList()
                            : tools;

                        if (index >= toolList.length) return null;
                        return _buildToolCard(context, toolList[index]);
                      },
                      childCount: (!isSearching && _selectedCategory == 'all')
                          ? tools.length - 1
                          : tools.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),

          // Floating mini live task bar (only visible when a conversion is active)
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: BrutalistLiveTaskBar(
              onTap: () => context.push('/history'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, _ToolItem tool) {
    return BrutalistCard(
      onTap: () => context.push(tool.route),
      padding: const EdgeInsets.all(14),
      backgroundColor: BrutalColors.white,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: BrutalColors.black,
              border: BrutalTheme.brutalBorder,
            ),
            child: Icon(tool.icon, size: 22, color: BrutalColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      tool.title,
                      style: BrutalTheme.headline(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BrutalColors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      color: BrutalColors.black,
                      child: Text(
                        'POPULAR',
                        style: BrutalTheme.label(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: BrutalColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tool.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrutalTheme.body(
                    fontSize: 11,
                    color: BrutalColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.arrowRight, size: 18, color: BrutalColors.black),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool) {
    return BrutalistCard(
      onTap: () => context.push(tool.route),
      padding: const EdgeInsets.all(12),
      backgroundColor: BrutalColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: BrutalColors.surfaceContainerLow,
              border: BrutalTheme.brutalBorder,
            ),
            child: Icon(tool.icon, size: 20, color: BrutalColors.black),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrutalTheme.headline(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BrutalColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tool.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BrutalTheme.body(
                  fontSize: 10.5,
                  color: BrutalColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
