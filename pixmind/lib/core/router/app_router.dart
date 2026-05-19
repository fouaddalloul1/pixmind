import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/permissions/permissions_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/detail/detail_screen.dart';
import '../../features/placeholder_screens.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/media_repository.dart';

class AppRoutes {
  static const splash       = '/';
  static const permissions  = '/permissions';
  static const home         = '/home';
  static const search       = '/search';
  static const albums       = '/albums';
  static const albumDetail  = '/album-detail';
  static const detail       = '/detail';
  static const editing      = '/editing';
  static const ocr          = '/ocr';
  static const secure       = '/secure';
  static const suggestions  = '/suggestions';
  static const video        = '/video';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (_, state) =>
            PermissionsScreen(reason: state.extra as String?),
      ),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,        builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.search,      builder: (_, __) => const SearchScreen()),
          GoRoute(path: AppRoutes.albums,      builder: (_, __) => const AlbumsScreen()),
          GoRoute(path: AppRoutes.suggestions, builder: (_, __) => const SuggestionsScreen()),
        ],
      ),

      GoRoute(
        path: AppRoutes.detail,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          final id    = extra['id'] as String;
          final items = extra['items'] as List<MediaItem>;
          return DetailScreen(assetId: id, allItems: items);
        },
      ),

      GoRoute(
        path: AppRoutes.albumDetail,
        builder: (_, state) =>
            AlbumDetailScreen(album: state.extra as AlbumInfo),
      ),
      GoRoute(
        path: AppRoutes.editing,
        builder: (_, state) =>
            EditingScreen(assetId: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.ocr,
        builder: (_, state) =>
            OcrScreen(assetId: state.extra as String? ?? ''),
      ),
      GoRoute(path: AppRoutes.secure, builder: (_, __) => const SecureScreen()),
      GoRoute(
        path: AppRoutes.video,
        builder: (_, state) =>
            VideoScreen(assetId: state.extra as String? ?? ''),
      ),
    ],
  );
});

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;
  static const _tabs = [
    AppRoutes.home, AppRoutes.search,
    AppRoutes.albums, AppRoutes.suggestions,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        indicatorColor : Colors.white,
      backgroundColor: AppColors.navyDeep.withOpacity(0.1),
        onDestinationSelected: (i) {
          setState(() => _idx = i);
          context.go(_tabs[i]);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.navyDeep),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppColors.navyDeep),
              label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.photo_album_outlined),
              selectedIcon: Icon(Icons.photo_album, color: AppColors.navyDeep),
              label: 'Albums'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome, color: AppColors.navyDeep),
              label: 'For You'),
        ],
      ),
    );
  }
}
