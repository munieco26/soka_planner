import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pages/flyer_fullscreen_page.dart';

class FlyerGalleryWidget extends StatelessWidget {
  final List<String> flyerUrls;

  const FlyerGalleryWidget({super.key, required this.flyerUrls});

  @override
  Widget build(BuildContext context) {
    if (flyerUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imágenes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: flyerUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FlyerFullscreenPage(imageUrl: flyerUrls[index]),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: flyerUrls[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
