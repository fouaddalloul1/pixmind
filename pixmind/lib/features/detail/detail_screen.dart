import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/media_item.dart';

class DetailScreen extends StatefulWidget {
  final String assetId;
  final List<MediaItem> allItems;

  const DetailScreen({
    super.key,
    required this.assetId,
    required this.allItems,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;
  bool _uiVisible = true;
  final Map<int, _VideoState> _videoStates = {};

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.allItems
        .indexWhere((item) => item.id == widget.assetId);

    if (_currentIndex < 0) _currentIndex = 0;

    _pageCtrl = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareVideoAt(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    // نتخلص من كل الـ video controllers
    for (final vs in _videoStates.values) {
      vs.chewie?.dispose();
      vs.player.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
  Future<void> _prepareVideoAt(int index) async {
    final item = widget.allItems[index];
    if (!item.isVideo) return;
    if (_videoStates.containsKey(index)) return;

    final file = await item.asset.originFile;
    if (file == null || !mounted) return;

    final player = VideoPlayerController.file(file);
    await player.initialize();

    final chewie = ChewieController(
      videoPlayerController: player,
      autoPlay: false,
      looping: false,
      aspectRatio: item.asset.width / item.asset.height,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.mintAccent,
        handleColor: AppColors.mintAccent,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
    );

    if (mounted) {
      setState(() {
        _videoStates[index] = _VideoState(player: player, chewie: chewie);
      });
    }
  }
 void _onPageChanged(int newIndex) {
    final oldVs = _videoStates[_currentIndex];
    oldVs?.player.pause();

    setState(() => _currentIndex = newIndex);

    _prepareVideoAt(newIndex);

    if (newIndex + 1 < widget.allItems.length) {
      _prepareVideoAt(newIndex + 1);
    }
    if (newIndex - 1 >= 0) {
      _prepareVideoAt(newIndex - 1);
    }
  }

  void _toggleUI() {
    setState(() => _uiVisible = !_uiVisible);
    if (_uiVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  MediaItem get _current => widget.allItems[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _uiVisible
          ? AppBar(
        backgroundColor: Colors.black.withOpacity(0.55),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _current.asset.title ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_currentIndex + 1} / ${widget.allItems.length}',
              style: const TextStyle(
                  fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptions,
          ),
        ],
      )
          : null,
      body: PageView.builder(
        controller: _pageCtrl,
        onPageChanged: _onPageChanged,
        itemCount: widget.allItems.length,
        itemBuilder: (context, index) {
          final item = widget.allItems[index];
          return item.isVideo
              ? _VideoPage(
            item: item,
            videoState: _videoStates[index],
            isActive: index == _currentIndex,
            onTap: _toggleUI,
          )
              : _ImagePage(item: item, onTap: _toggleUI);
        },
      ),
      bottomNavigationBar: _uiVisible
          ? _BottomToolbar(item: _current)
          : null,
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2B3A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _OptionsSheet(item: _current),
    );
  }
}

class _ImagePage extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  const _ImagePage({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          // حتى لو مكبرة يقدر يحركها
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Image(
            image: AssetEntityImageProvider(
              item.asset,
              isOriginal: true,
            ),
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Image(
                    image: AssetEntityImageProvider(
                      item.asset,
                      isOriginal: false,
                      thumbnailSize: const ThumbnailSize.square(600),
                    ),
                    fit: BoxFit.contain,
                  ),
                  CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null,
                    color: AppColors.mintAccent,
                    strokeWidth: 2,
                  ),
                ],
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPage extends StatelessWidget {
  final MediaItem item;
  final _VideoState? videoState;
  final bool isActive;
  final VoidCallback onTap;

  const _VideoPage({
    required this.item,
    required this.videoState,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (videoState == null) {
      return GestureDetector(
        onTap: onTap,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.mintAccent),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AspectRatio(
          aspectRatio: item.asset.width / item.asset.height,
          child: Chewie(controller: videoState!.chewie!),
        ),
      ),
    );
  }
}

class _VideoState {
  final VideoPlayerController player;
  final ChewieController? chewie;
  _VideoState({required this.player, this.chewie});
}
class _BottomToolbar extends StatelessWidget {
  final MediaItem item;
  const _BottomToolbar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Btn(icon: Icons.edit_outlined,       label: 'Edit',   onTap: () {}),
          _Btn(icon: Icons.share_outlined,       label: 'Share',  onTap: () {}),
          _Btn(icon: Icons.lock_outline,         label: 'Secure', onTap: () {}),
          _Btn(icon: Icons.delete_outline,       label: 'Delete',
              onTap: () {}, color: AppColors.errorRed),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label;
  final VoidCallback onTap; final Color color;
  const _Btn({required this.icon, required this.label,
    required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]));
}

// ─────────────────────────────────────────
// Options Sheet
// ─────────────────────────────────────────
class _OptionsSheet extends StatelessWidget {
  final MediaItem item;
  const _OptionsSheet({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSizes.lg),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4,
          decoration: BoxDecoration(color: Colors.white24,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      _Opt(icon: Icons.info_outline,    label: 'File Info',         onTap: () {}),
      _Opt(icon: Icons.text_fields,     label: 'Extract Text (OCR)',onTap: () {}),
      _Opt(icon: Icons.drive_file_move_outline, label: 'Move to Album', onTap: () {}),
    ]),
  );
}

class _Opt extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _Opt({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Colors.white70),
    title: Text(label, style: const TextStyle(color: Colors.white)),
    onTap: () { Navigator.pop(context); onTap(); },
  );
}
