import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a flyer image and return the download URL
  static Future<String> uploadFlyer({
    required String calendarId,
    required String eventId,
    required XFile file,
  }) async {
    final ext = file.name.split('.').last;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref =
        _storage.ref().child('flyers/$calendarId/$eventId/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload multiple flyer images
  static Future<List<String>> uploadMultipleFlyers({
    required String calendarId,
    required String eventId,
    required List<XFile> files,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadFlyer(
        calendarId: calendarId,
        eventId: eventId,
        file: file,
      );
      urls.add(url);
    }
    return urls;
  }

  /// Delete a flyer by URL
  static Future<void> deleteFlyer(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }
}
