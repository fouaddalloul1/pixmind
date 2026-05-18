import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/media_repository.dart';
import 'widgets/media_grid_item.dart';
import 'widgets/folder_albums_tab.dart';
enum MediaFilter {
  all,
  images,
  videos,
  folders,
}
class HomeState {
  final List<MediaItem> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
 final PermissionState? permissionStatus;

  final MediaFilter filter;
  final int currentPage;
  final int totalCount;

  const HomeState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
    this.permissionStatus,
    this.filter = MediaFilter.all,
    this.currentPage = 0,
    this.totalCount = 0,
  });

  bool get hasPermission =>
      permissionStatus == PermissionState.authorized ||
          permissionStatus == PermissionState.limited;

  HomeState copyWith({
    List<MediaItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    PermissionState? permissionStatus,
    MediaFilter? filter,
    int? currentPage,
    int? totalCount,
  }) =>
      HomeState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        permissionStatus: permissionStatus ?? this.permissionStatus,
        filter: filter ?? this.filter,
        currentPage: currentPage ?? this.currentPage,
        totalCount: totalCount ?? this.totalCount,
      );
}
class HomeController extends StateNotifier<HomeState> {
  final MediaRepository _repo;
  static const _pageSize = 120;

  HomeController(this._repo) : super(const HomeState()) {
    loadFirstPage();
  }

  RequestType get _requestType {
    switch (state.filter) {
      case MediaFilter.images:
        return RequestType.image;
      case MediaFilter.videos:
        return RequestType.video;
      case MediaFilter.all:
      case MediaFilter.folders:
        return RequestType.common;
    }
  }
  Future<void> loadFirstPage() async {
    if (state.filter == MediaFilter.folders) return;

    state = state.copyWith(
      loading: true,
      items: [],
      currentPage: 0,
      hasMore: true,
      error: null,
    );

    final permission = await _repo.requestPermission();

    state = state.copyWith(permissionStatus: permission);

    if (!state.hasPermission) {
      state = state.copyWith(
        loading: false,
        error: AppStrings.errorPermission,
      );
      return;
    }

    try {
      final total = await _repo.getTotalCount(_requestType);
      final items = await _repo.loadPage(
        type: _requestType,
        page: 0,
        pageSize: _pageSize,
      );

      state = state.copyWith(
        items: items,
        loading: false,
        currentPage: 0,
        totalCount: total,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'حدث خطأ: $e',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.loadingMore || !state.hasMore || state.loading) return;
    final permission = await _repo.checkPermission();
    if (permission != PermissionState.authorized &&
        permission != PermissionState.limited) {
      state = state.copyWith(
        permissionStatus: permission,
        error: AppStrings.errorPermission,
      );
      return;
    }

    state = state.copyWith(loadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final newItems = await _repo.loadPage(
        type: _requestType,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (newItems.isEmpty) {
        state = state.copyWith(loadingMore: false, hasMore: false);
        return;
      }

      state = state.copyWith(
        items: [...state.items, ...newItems],
        loadingMore: false,
        currentPage: nextPage,
        hasMore: newItems.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<void> setFilter(MediaFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    if (filter != MediaFilter.folders) {
      await loadFirstPage();
    }
  }

  Future<void> onAppResumed() async {
    final permission = await _repo.checkPermission();
    if (permission != state.permissionStatus) {
      state = state.copyWith(permissionStatus: permission);
      if (state.hasPermission) {
        await loadFirstPage();
      } else {
        state = state.copyWith(
          items: [],
          error: AppStrings.errorPermission,
        );
      }
    }
  }
}

final homeControllerProvider =
StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(ref.read(mediaRepositoryProvider));
});
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      ref.read(homeControllerProvider.notifier).onAppResumed();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 800) {
      ref.read(homeControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final ctrl = ref.read(homeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PixMind',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            if (state.totalCount > 0 && state.filter != MediaFilter.folders)
              Text(
                '${state.items.length} / ${state.totalCount}',
                style:
                const TextStyle(color: Colors.white60, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.go(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.white),
            onPressed: () => context.push(AppRoutes.secure),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterTabs(current: state.filter, onChanged: ctrl.setFilter),
          Expanded(child: _buildBody(context, state, ctrl)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state, HomeController ctrl) {
    if (state.filter == MediaFilter.folders) {
      return const FolderAlbumsTab();
    }

    if (!state.hasPermission && state.permissionStatus != null) {
      return _PermissionDeniedView(onRetry: ctrl.loadFirstPage);
    }

    if (state.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.navyDeep),
            SizedBox(height: 16),
            Text(AppStrings.loadingPhotos,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: ctrl.loadFirstPage,
                  child: const Text(AppStrings.errorGeneric)),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Text(AppStrings.noPhotos,
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: ctrl.loadFirstPage,
      color: AppColors.navyDeep,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => MediaGridItem(
                item: state.items[index],
                onTap: () => context.push(
                    AppRoutes.detail,  extra: {
                  'id': state.items[index].id,
                  'items': state.items,
                },),
              ),
              childCount: state.items.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppSizes.gridCrossAxisCount,
              mainAxisSpacing: AppSizes.gridSpacing,
              crossAxisSpacing: AppSizes.gridSpacing,
            ),
          ),
          if (state.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.navyDeep, strokeWidth: 2)),
              ),
            ),
          if (!state.hasMore && state.items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '$AppStrings.loadAllPhotos (${state.totalCount})',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_photography_outlined,
                  color: AppColors.errorRed, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(AppStrings.errorPermission,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            const Text(
            AppStrings.permDeniedBody,
              textAlign: TextAlign.center,
              style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await PhotoManager.openSetting();
                },
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                label: const Text(AppStrings.openSettings,
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDeep),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(AppStrings.checkAgain,
                  style: TextStyle(color: AppColors.skyBlue)),
            ),
          ],
        ),
      ),
    );
  }
}
class _FilterTabs extends StatelessWidget {
  final MediaFilter current;
  final ValueChanged<MediaFilter> onChanged;
  const _FilterTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyDeep,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Tab(label:AppStrings.all,       active: current == MediaFilter.all,     onTap: () => onChanged(MediaFilter.all)),
            _Tab(label: AppStrings.photos,        active: current == MediaFilter.images,  onTap: () => onChanged(MediaFilter.images)),
            _Tab(label: AppStrings.videos,   active: current == MediaFilter.videos,  onTap: () => onChanged(MediaFilter.videos)),
            _Tab(label: AppStrings.folders,  active: current == MediaFilter.folders, onTap: () => onChanged(MediaFilter.folders)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg, vertical: AppSizes.sm + 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.mintAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
