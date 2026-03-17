import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FlyerPickerWidget extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newImages;
  final ValueChanged<List<XFile>> onImagesChanged;
  final ValueChanged<String> onExistingRemoved;

  const FlyerPickerWidget({
    super.key,
    required this.existingUrls,
    required this.newImages,
    required this.onImagesChanged,
    required this.onExistingRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing images
        if (existingUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: existingUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: existingUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => onExistingRemoved(existingUrls[index]),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        if (existingUrls.isNotEmpty && newImages.isNotEmpty)
          const SizedBox(height: 8),

        // New images
        if (newImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: newImages[index].readAsBytes(),
                              builder: (_, snap) {
                                if (!snap.hasData) {
                                  return const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                return Image.memory(
                                  snap.data!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.file(
                              File(newImages[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          final updated = List<XFile>.from(newImages)
                            ..removeAt(index);
                          onImagesChanged(updated);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pickImages(context),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Agregar imagen'),
        ),
      ],
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      onImagesChanged([...newImages, ...picked]);
    }
  }
}
