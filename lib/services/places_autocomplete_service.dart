import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Sugerencia de Places API (New), vía Cloud Functions (evita CORS en web).
class PlaceSuggestion {
  final String placeId;
  final String primaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
  });
}

/// Llama a `placesAutocomplete` y `placesGetDetails` desplegadas en `us-central1`.
class PlacesAutocompleteService {
  PlacesAutocompleteService._();

  static final FirebaseFunctions _fn = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  static bool get _canUse =>
      FirebaseAuth.instance.currentUser != null;

  static Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    if (!_canUse || input.trim().length < 2) return [];

    final callable = _fn.httpsCallable('placesAutocomplete');
    final result = await callable.call({
      'input': input.trim(),
      'sessionToken': sessionToken,
    });

    final data = result.data;
    if (data is! Map) return [];
    final raw = data['suggestions'];
    if (raw is! List) return [];

    final out = <PlaceSuggestion>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = map['placeId'] as String?;
      final text = map['primaryText'] as String?;
      if (id != null && text != null) {
        out.add(PlaceSuggestion(placeId: id, primaryText: text));
      }
    }
    return out;
  }

  static Future<String?> formattedAddressForPlace({
    required String placeId,
    required String sessionToken,
  }) async {
    if (!_canUse) return null;

    final callable = _fn.httpsCallable('placesGetDetails');
    final result = await callable.call({
      'placeId': placeId,
      'sessionToken': sessionToken,
    });

    final payload = result.data;
    if (payload is! Map) return null;
    final addr = payload['formattedAddress'];
    if (addr is String && addr.isNotEmpty) return addr;
    return null;
  }
}
