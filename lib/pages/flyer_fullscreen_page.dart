import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FlyerFullscreenPage extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const FlyerFullscreenPage({
    super.key,
    required this.imageUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: title != null ? Text(title!) : null,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.error, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
