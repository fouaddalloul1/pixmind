import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/router/app_router.dart';
import '../data/models/media_item.dart';
import '../data/repositories/media_repository.dart';
import 'detail/detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('Smart Search', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('Smart Albums', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('AI Albums — Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final AlbumInfo album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final List<MediaItem> _items = [];
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const _pageSize = 120;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.extentAfter < 600) _loadPage();
  }

  Future<void> _loadPage() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final repo = ref.read(mediaRepositoryProvider);
    final newItems = await repo.loadAlbumPage(
      albumPath: widget.album.path,
      page: _page,
      pageSize: _pageSize,
    );

    setState(() {
      _items.addAll(newItems);
      _page++;
      _hasMore = newItems.length >= _pageSize;
      _loading = false;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.album.name,
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          Text('${widget.album.count} items',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navyDeep))
          : GridView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(AppSizes.gridSpacing),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSizes.gridSpacing,
          crossAxisSpacing: AppSizes.gridSpacing,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.navyDeep, strokeWidth: 2));
          }
          final item = _items[index];
          return GestureDetector(
            onTap: () {
              context.push(
                AppRoutes.detail,
                extra: {
                  'id': item.id,
                  'items': _items,
                },
              );
            },
            child: Stack(fit: StackFit.expand, children: [
              Image(
                image: AssetEntityImageProvider(item.asset,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(200)),
                fit: BoxFit.cover,
                frameBuilder: (_, child, frame, sync) {
                  if (sync) return child;
                  return AnimatedOpacity(
                    opacity: frame != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: frame != null
                        ? child
                        : Container(color: AppColors.textHint.withOpacity(0.12)),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.textHint.withOpacity(0.12),
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textHint, size: 20),
                ),
              ),
              if (item.isVideo)
                Positioned(
                  bottom: 5, right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 13),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class EditingScreen extends StatelessWidget {
  final String assetId;
  const EditingScreen({super.key, required this.assetId});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('Edit', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}

class OcrScreen extends StatelessWidget {
  final String assetId;
  const OcrScreen({super.key, required this.assetId});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('Extract Text', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}

class SecureScreen extends StatelessWidget {
  const SecureScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('Secure Folder', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('For You', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}

class VideoScreen extends StatelessWidget {
  final String assetId;
  const VideoScreen({super.key, required this.assetId});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: AppColors.navyDeep,
          title: const Text('Video Summary', style: TextStyle(color: Colors.white))),
      body: const Center(child: Text('Coming soon',
          style: TextStyle(color: AppColors.textSecondary))));
}
