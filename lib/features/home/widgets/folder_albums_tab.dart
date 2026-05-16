import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/media_repository.dart';

class FolderAlbumsState {
  final List<AlbumInfo> albums;
  final bool loading;
  final String? error;

  const FolderAlbumsState({
    this.albums = const [],
    this.loading = false,
    this.error,
  });

  FolderAlbumsState copyWith({
    List<AlbumInfo>? albums,
    bool? loading,
    String? error,
  }) =>
      FolderAlbumsState(
        albums: albums ?? this.albums,
        loading: loading ?? this.loading,
        error: error,
      );
}

class FolderAlbumsController extends StateNotifier<FolderAlbumsState> {
  final MediaRepository _repo;

  FolderAlbumsController(this._repo) : super(const FolderAlbumsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final albums = await _repo.getFolderAlbums();
      state = state.copyWith(albums: albums, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'خطأ في تحميل الألبومات');
    }
  }
}

final folderAlbumsProvider =
    StateNotifierProvider<FolderAlbumsController, FolderAlbumsState>((ref) {
  return FolderAlbumsController(ref.read(mediaRepositoryProvider));
});

class FolderAlbumsTab extends ConsumerWidget {
  const FolderAlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(folderAlbumsProvider);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyDeep),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    if (state.albums.isEmpty) {
      return const Center(
        child: Text('لا توجد ألبومات',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
        childAspectRatio: 0.85,
      ),
      itemCount: state.albums.length,
      itemBuilder: (context, index) {
        return _AlbumCard(
          album: state.albums[index],
          onTap: () => context.push(
            AppRoutes.albumDetail,
            extra: state.albums[index],
          ),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final AlbumInfo album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: album.coverAsset != null
                  ? Image(
                      image: AssetEntityImageProvider(
                        album.coverAsset!,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(400),
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          // ── عدد الصور ──
          Text(
            '${album.count} عنصر',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.textHint.withOpacity(0.15),
      child: const Center(
        child: Icon(Icons.photo_album_outlined,
            color: AppColors.textHint, size: 40),
      ),
    );
  }
}
