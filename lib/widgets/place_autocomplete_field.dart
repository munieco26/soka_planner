import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/places_autocomplete_service.dart';
import '../utils/globals.dart';

/// Campo de ubicación con sugerencias de Google Places (New) vía Cloud Functions.
class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText = 'Ubicación (opcional)',
    this.hintText = 'Buscá una dirección…',
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  static final _uuid = Uuid();
  late String _sessionToken;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final list = await PlacesAutocompleteService.autocomplete(
        input: q,
        sessionToken: _sessionToken,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _loading = false;
      });
    }
  }

  Future<void> _select(PlaceSuggestion s) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _loading = true;
    });
    try {
      final addr = await PlacesAutocompleteService.formattedAddressForPlace(
        placeId: s.placeId,
        sessionToken: _sessionToken,
      );
      if (!mounted) return;
      widget.controller.text = (addr != null && addr.isNotEmpty)
          ? addr
          : s.primaryText;
    } catch (_) {
      if (mounted) widget.controller.text = s.primaryText;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) setState(() => _sessionToken = _uuid.v4());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _scheduleSearch,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _suggestions = []);
          },
        ),
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.black.withOpacity(0.08)),
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        s.primaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      leading: Icon(
                        Icons.place_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onTap: () => _select(s),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
