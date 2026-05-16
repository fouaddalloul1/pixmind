import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/media_item.dart';

class MediaGridItem extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  const MediaGridItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(fit: StackFit.expand, children: [
        Image(
          image: AssetEntityImageProvider(
            item.asset,
            isOriginal: false,
            // 200 بدل 300 — أسرع بـ 50% في التحميل على الـ grid
            thumbnailSize: const ThumbnailSize.square(200),
          ),
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
        if (item.aiCaption != null)
          Positioned(
            top: 4, left: 4,
            child: Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(
                  color: AppColors.mintAccent, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 8),
            ),
          ),
      ]),
    );
  }
}
