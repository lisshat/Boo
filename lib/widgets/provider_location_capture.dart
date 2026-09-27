import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

bool validProviderCoordinates(double? latitude, double? longitude) =>
    latitude != null &&
    longitude != null &&
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

class ProviderLocationCapture extends StatefulWidget {
  final TextEditingController areaController;
  final bool hasCoordinates;
  final void Function(double? latitude, double? longitude) onChanged;
  final ValueChanged<bool> onCapturing;
  final String actionLabel;
  final bool enabled;
  final bool enableSearch;

  const ProviderLocationCapture(
      {super.key,
      required this.areaController,
      required this.hasCoordinates,
      required this.onChanged,
      required this.onCapturing,
      this.actionLabel = 'Use current location',
      this.enabled = true,
      this.enableSearch = false});

  @override
  State<ProviderLocationCapture> createState() =>
      _ProviderLocationCaptureState();
}

class _ProviderLocationCaptureState extends State<ProviderLocationCapture> {
  bool _capturing = false;
  bool _searching = false;
  bool _applyingSelection = false;
  String? _error;
  String? _searchError;
  String? _confirmedLabel;
  int _areaRevision = 0;
  late String _areaText;
  final Geocoding _geocoding = Geocoding();

  @override
  void initState() {
    super.initState();
    _areaText = widget.areaController.text;
    widget.areaController.addListener(_areaChanged);
  }

  void _areaChanged() {
    if (_areaText == widget.areaController.text) return;
    _areaText = widget.areaController.text;
    _areaRevision++;
    if (!_applyingSelection) {
      _confirmedLabel = null;
      widget.onChanged(null, null);
    }
    setState(() {
      _error = null;
      _searchError = null;
    });
  }

  @override
  void dispose() {
    widget.areaController.removeListener(_areaChanged);
    super.dispose();
  }

  Future<void> _capture() async {
    final revision = _areaRevision;
    setState(() {
      _capturing = true;
      _error = null;
      _confirmedLabel = null;
    });
    widget.onCapturing(true);
    widget.onChanged(null, null);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Turn on device location, then try again.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever)
        throw Exception(
            'Allow location access in app settings, then try again.');
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse)
        throw Exception(
            'Location permission is needed. Allow access and retry.');
      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20)));
      if (!mounted) return;
      if (revision != _areaRevision)
        throw Exception('The area changed. Capture your location again.');
      if (!validProviderCoordinates(position.latitude, position.longitude))
        throw Exception(
            'The device returned an invalid location. Please retry.');
      widget.onChanged(position.latitude, position.longitude);
    } on TimeoutException {
      if (mounted)
        setState(() => _error =
            'Location capture timed out. Move to an open area and try again.');
    } catch (error) {
      if (mounted)
        setState(() => _error = error is Exception &&
                error.toString().startsWith('Exception: ')
            ? error.toString().substring(11)
            : 'Could not get your location. Check device location and retry.');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        widget.onCapturing(false);
      }
    }
  }

  String _labelFor(Placemark place, String fallback) {
    final parts = [
      place.name,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.country
    ]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final unique = <String>[];
    for (final part in parts) {
      if (!unique.any((item) => item.toLowerCase() == part.toLowerCase()))
        unique.add(part);
    }
    return unique.isEmpty ? fallback : unique.join(', ');
  }

  Future<void> _search() async {
    final query = widget.areaController.text.trim();
    if (query.length < 3) {
      setState(() => _searchError =
          'Enter a specific area, city or country, then try again.');
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
      _confirmedLabel = null;
    });
    widget.onChanged(null, null);
    try {
      final locations = await _geocoding.locationFromAddress(query);
      final candidates = <_LocationCandidate>[];
      final seen = <String>{};
      for (final location in locations.take(5)) {
        if (!validProviderCoordinates(location.latitude, location.longitude))
          continue;
        var label = query;
        try {
          final marks = await _geocoding.placemarkFromCoordinates(
              location.latitude, location.longitude);
          if (marks.isNotEmpty) label = _labelFor(marks.first, query);
        } catch (_) {}
        final key =
            '${label.toLowerCase()}|${location.latitude.toStringAsFixed(5)}|${location.longitude.toStringAsFixed(5)}';
        if (seen.add(key))
          candidates.add(_LocationCandidate(
              label: label,
              latitude: location.latitude,
              longitude: location.longitude));
      }
      if (!mounted) return;
      if (candidates.isEmpty) {
        setState(() => _searchError =
            'No matching locations found. Add a city and country, then retry.');
        return;
      }
      final selected = await showModalBottomSheet<_LocationCandidate>(
          context: context,
          isScrollControlled: true,
          builder: (context) => SafeArea(
              child: Semantics(
                  container: true,
                  label: 'Service location search results',
                  child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final candidate = candidates[index];
                        return Semantics(
                            button: true,
                            label: 'Select ${candidate.label}',
                            child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                minVerticalPadding: 14,
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(candidate.label),
                                onTap: () =>
                                    Navigator.pop(context, candidate))));
                      }))));
      if (selected == null || !mounted) return;
      _applyingSelection = true;
      widget.areaController.text = selected.label;
      _applyingSelection = false;
      setState(() => _confirmedLabel = selected.label);
      widget.onChanged(selected.latitude, selected.longitude);
    } on UnimplementedError {
      if (mounted)
        setState(() => _searchError =
            'Location search is unavailable on this device. Use current location or retry.');
    } catch (_) {
      if (mounted)
        setState(() => _searchError =
            'Could not search locations. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _error ??
        _searchError ??
        (_confirmedLabel != null
            ? 'Location selected for nearby discovery.'
            : widget.hasCoordinates
                ? 'Location captured for nearby discovery.'
                : 'Capture or search for your service location to appear nearby.');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        Semantics(
            button: true,
            label: widget.actionLabel,
            child: TextButton.icon(
                onPressed: _capturing || _searching || !widget.enabled
                    ? null
                    : _capture,
                icon: const Icon(Icons.my_location),
                label: Text(
                    _capturing ? 'Getting locationâ€¦' : widget.actionLabel))),
        if (widget.enableSearch)
          Semantics(
              button: true,
              label: 'Search for service location',
              child: TextButton.icon(
                  onPressed: _capturing || _searching || !widget.enabled
                      ? null
                      : _search,
                  icon: const Icon(Icons.search),
                  label: Text(
                      _searching ? 'Finding locationâ€¦' : 'Find location'))),
      ]),
      if (_confirmedLabel != null)
        Row(children: [
          Expanded(
              child: Semantics(
                  liveRegion: true,
                  label: 'Selected service location: $_confirmedLabel',
                  child: Text('Selected service location: $_confirmedLabel'))),
          TextButton(
              onPressed: () {
                _applyingSelection = true;
                widget.areaController.clear();
                _applyingSelection = false;
                setState(() => _confirmedLabel = null);
                widget.onChanged(null, null);
              },
              child: const Text('Change'))
        ]),
      Semantics(
          liveRegion: true,
          label: message,
          child: Text(message,
              style: TextStyle(
                  fontSize: 13,
                  color: (_error != null || _searchError != null)
                      ? Colors.red
                      : Colors.black54))),
    ]);
  }
}

class _LocationCandidate {
  final String label;
  final double latitude;
  final double longitude;
  const _LocationCandidate(
      {required this.label, required this.latitude, required this.longitude});
}
