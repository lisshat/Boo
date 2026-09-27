import 'dart:async';
import 'dart:convert';

import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_provider/recommended_provider_card.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:geolocator/geolocator.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

enum _LocationAcquisitionState {
  loading,
  available,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  unavailable,
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  static const orange = Color(0xFFF68B1F);

  late Future<Map<String, dynamic>> _meFuture;
  final _searchCtrl = TextEditingController();

  ProviderType? _selectedCategory;
  String _sortBy = 'recommended';
  int? _radius = 25; // null = any distance

  Position? _position;
  bool _locationLoading = true;

  List<ProviderModel> _allProviders = [];
  bool _providersLoading = false;
  String? _providersError;
  bool _meRetrying = false;
  bool _locationPermissionRequested = false;
  bool _usingProviderFallback = false;
  _LocationAcquisitionState _locationState = _LocationAcquisitionState.loading;
  Future<void>? _locationAttempt;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
    _searchCtrl.addListener(() => setState(() {}));
    // Requesting Android location permission before the first frame can leave
    // the platform dialog suppressed on a cold start. Start it once the Home
    // shell is mounted and visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initLocation();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    if (UserCache.instance.data != null) return UserCache.instance.data!;
    final stopwatch = Stopwatch()..start();
    try {
      final res = await ApiService.instance
          .get('/auth/me')
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) {
        debugPrint('[auth timing] auth_me ${stopwatch.elapsedMilliseconds}ms');
      }
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        UserCache.instance.set(data);
        return data;
      }
      throw Exception('Failed to load user');
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
            '[auth timing] auth_me_failed ${stopwatch.elapsedMilliseconds}ms');
      }
      rethrow;
    }
  }

  Future<void> _retryMe() async {
    if (_meRetrying || !mounted) return;
    setState(() => _meRetrying = true);
    try {
      final future = _fetchMe();
      if (mounted) setState(() => _meFuture = future);
      await future;
    } catch (_) {
      // FutureBuilder displays the safe retry state.
    } finally {
      if (mounted) setState(() => _meRetrying = false);
    }
  }

  Future<void> _signOutFromHome() async {
    if (_meRetrying) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<void> _initLocation() {
    final activeAttempt = _locationAttempt;
    if (activeAttempt != null) return activeAttempt;

    final attempt = _runLocationAttempt();
    _locationAttempt = attempt;
    return attempt.whenComplete(() {
      if (identical(_locationAttempt, attempt)) _locationAttempt = null;
    });
  }

  Future<void> _runLocationAttempt() async {
    if (!mounted) return;
    setState(() {
      _locationLoading = true;
      _locationState = _LocationAcquisitionState.loading;
      _providersError = null;
      // Never keep using an old position while a new attempt is resolving.
      _position = null;
    });

    var terminalState = _LocationAcquisitionState.unavailable;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      if (!serviceEnabled) {
        terminalState = _LocationAcquisitionState.serviceDisabled;
      } else {
        var permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 3));
        if (permission == LocationPermission.denied &&
            !_locationPermissionRequested) {
          _locationPermissionRequested = true;
          permission = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 10));
        }

        if (permission == LocationPermission.deniedForever) {
          terminalState = _LocationAcquisitionState.permissionDeniedForever;
        } else if (permission == LocationPermission.denied) {
          terminalState = _LocationAcquisitionState.permissionDenied;
        } else if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          terminalState = _LocationAcquisitionState.unavailable;
        } else {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 15),
            ),
          ).timeout(const Duration(seconds: 16));
          if (!position.latitude.isFinite ||
              !position.longitude.isFinite ||
              position.latitude < -90 ||
              position.latitude > 90 ||
              position.longitude < -180 ||
              position.longitude > 180) {
            terminalState = _LocationAcquisitionState.unavailable;
          } else {
            terminalState = _LocationAcquisitionState.available;
            if (mounted) {
              setState(() => _position = position);
            }
          }
        }
      }
    } on TimeoutException {
      terminalState = _LocationAcquisitionState.timedOut;
    } catch (_) {
      terminalState = _LocationAcquisitionState.unavailable;
    } finally {
      if (!mounted) return;
      setState(() {
        _locationState = terminalState;
        _locationLoading = false;
        if (terminalState != _LocationAcquisitionState.available) {
          _position = null;
          // Location is optional; browse the unscoped discoverable list.
          _radius = null;
        }
      });
      await _fetchProviders();
    }
  }

  Future<void> _fetchProviders() async {
    if (!mounted) return;
    setState(() {
      _providersLoading = true;
      _providersError = null;
    });

    // A missing position must never prevent browsing. If a distance filter is
    // still selected, fall back to the unscoped discoverable-provider query.
    if (_position == null && _radius != null) _radius = null;
    _usingProviderFallback = _position == null;

    String path = '/providers';
    if (_position != null && _radius != null) {
      path +=
          '?lat=${_position!.latitude}&lng=${_position!.longitude}&radius=$_radius';
    }

    try {
      final res = await ApiService.instance.get(path);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List<dynamic>)
            .map((j) => ProviderModel.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() {
          _allProviders = list;
          _providersLoading = false;
        });
      } else {
        setState(() {
          _providersError = 'Could not load providers (${res.statusCode})';
          _providersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _providersError = 'Could not connect to server';
          _providersLoading = false;
        });
      }
    }
  }

  List<ProviderModel> get _filteredProviders {
    var list = _allProviders;

    if (_selectedCategory != null) {
      final category = switch (_selectedCategory!) {
        ProviderType.boarding => 'boarding',
        ProviderType.sitter => 'sitting',
        ProviderType.groomer => 'grooming',
        ProviderType.vet => 'veterinary',
      };
      list = list
          .where((p) => p.services.any(
                (service) => service.enabled && service.category == category,
              ))
          .toList();
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final haystack = [
          p.name,
          p.about,
          p.locationName,
          p.addressLine,
          ...p.services.map((s) => '${s.title} ${s.category} ${s.subtitle}'),
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }
    if (_sortBy == 'recommended') {
      list = List.from(list)
        ..sort((a, b) {
          final scoreDiff = b.recommendedScore.compareTo(a.recommendedScore);
          if (scoreDiff != 0) return scoreDiff;
          final ratingDiff = b.rating.compareTo(a.rating);
          if (ratingDiff != 0) return ratingDiff;
          if (_radius != null) {
            final dA = _distKm(a);
            final dB = _distKm(b);
            if (dA != null && dB != null) return dA.compareTo(dB);
          }
          return 0;
        });
    } else if (_sortBy == 'reviews') {
      list = List.from(list)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return list;
  }

  double? _distKm(ProviderModel p) {
    return p.distanceKm;
  }

  String get _locationUnavailableLabel => switch (_locationState) {
        _LocationAcquisitionState.serviceDisabled => 'Location is off',
        _LocationAcquisitionState.permissionDenied =>
          'Location permission denied',
        _LocationAcquisitionState.permissionDeniedForever =>
          'Location permission needs Settings',
        _LocationAcquisitionState.timedOut => 'Location timed out',
        _LocationAcquisitionState.unavailable => 'Location unavailable',
        _ => 'Location unavailable',
      };

  Future<void> _recoverLocation() async {
    if (_locationState == _LocationAcquisitionState.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else if (_locationState ==
        _LocationAcquisitionState.permissionDeniedForever) {
      await Geolocator.openAppSettings();
    }
    if (mounted) _initLocation();
  }

  bool get _filtersActive =>
      _sortBy != 'recommended' ||
      (_radius != 25 && _position != null) ||
      _searchCtrl.text.trim().isNotEmpty;

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        sortBy: _sortBy,
        radius: _radius,
        hasLocation: _position != null,
        locationHint: _locationUnavailableLabel,
        onRecoverLocation: _recoverLocation,
        onSortChanged: (val) => setState(() => _sortBy = val),
        onRadiusChanged: (val) {
          setState(() => _radius = val);
          _fetchProviders();
        },
      ),
    );
  }

  String _categoryLabel(ProviderType type) {
    switch (type) {
      case ProviderType.vet:
        return 'Vet';
      case ProviderType.groomer:
        return 'Grooming';
      case ProviderType.boarding:
        return 'Boarding';
      case ProviderType.sitter:
        return 'Sitting';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _meFuture,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return _HomeAccountLoadingShell();
          }
          if (asyncSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not connect to server.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _meRetrying ? null : _retryMe,
                        child: _meRetrying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Try again',
                                style: TextStyle(color: Color(0xFFF68B1F))),
                      ),
                      TextButton(
                        onPressed: _meRetrying ? null : _signOutFromHome,
                        child: const Text('Sign out',
                            style: TextStyle(color: Color(0xFF6B7280))),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final userData = UserCache.instance.data ?? asyncSnapshot.data!;
          final providers = _filteredProviders;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${userData["fullName"] ?? "there"} 👋',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (_locationLoading) ...[
                              const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Color(0xFF9CA3AF))),
                              const SizedBox(width: 6),
                              Text('Finding your location…',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ] else if (_position != null) ...[
                              const Icon(Icons.location_on_rounded,
                                  size: 14, color: Color(0xFFF68B1F)),
                              const SizedBox(width: 4),
                              Text(
                                _radius != null && _position != null
                                    ? 'Within $_radius km'
                                    : 'All providers',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ] else ...[
                              const Icon(Icons.location_off_rounded,
                                  size: 14, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(_locationUnavailableLabel,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: _recoverLocation,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: const Size(48, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Enable',
                                    style:
                                        TextStyle(color: orange, fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                ],
              ),

              const SizedBox(height: 14),

              // Search bar + filter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEAECEF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Find vet, groomer, etc.',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        onPressed: _searchCtrl.clear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: const Color(0xFF9CA3AF),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _filtersActive
                              ? orange
                              : orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: _filtersActive ? Colors.white : orange,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Services row
              const Text('Services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ServiceChip(
                      icon: Icons.medical_services_outlined,
                      label: 'Vet',
                      isSelected: _selectedCategory == ProviderType.vet,
                      onTap: () => setState(() {
                        _selectedCategory =
                            _selectedCategory == ProviderType.vet
                                ? null
                                : ProviderType.vet;
                      }),
                    ),
                    _ServiceChip(
                      icon: Icons.content_cut,
                      label: 'Groom',
                      isSelected: _selectedCategory == ProviderType.groomer,
                      onTap: () => setState(() {
                        _selectedCategory =
                            _selectedCategory == ProviderType.groomer
                                ? null
                                : ProviderType.groomer;
                      }),
                    ),
                    _ServiceChip(
                      icon: Icons.home_outlined,
                      label: 'Board',
                      isSelected: _selectedCategory == ProviderType.boarding,
                      onTap: () => setState(() {
                        _selectedCategory =
                            _selectedCategory == ProviderType.boarding
                                ? null
                                : ProviderType.boarding;
                      }),
                    ),
                    _ServiceChip(
                      icon: Icons.chair_outlined,
                      label: 'Sit',
                      isSelected: _selectedCategory == ProviderType.sitter,
                      onTap: () => setState(() {
                        _selectedCategory =
                            _selectedCategory == ProviderType.sitter
                                ? null
                                : ProviderType.sitter;
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Recommended header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory != null
                          ? '${_categoryLabel(_selectedCategory!)} Providers'
                          : 'Recommended Near You',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  _selectedCategory != null
                      ? TextButton(
                          onPressed: () =>
                              setState(() => _selectedCategory = null),
                          child: const Text('Clear',
                              style: TextStyle(color: orange)),
                        )
                      : TextButton(
                          onPressed: _locationLoading || _providersLoading
                              ? null
                              : _initLocation,
                          child: const Text('Refresh',
                              style: TextStyle(color: orange)),
                        ),
                ],
              ),

              // Provider list area
              if (_providersLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_providersError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_providersError!,
                            style: const TextStyle(color: Color(0xFF6B7280))),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _initLocation,
                          child: const Text('Retry',
                              style: TextStyle(color: orange)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (providers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          _allProviders.isEmpty
                              ? 'No eligible providers are available yet.'
                              : 'No providers match your search or category.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        if (_allProviders.isEmpty &&
                            _usingProviderFallback) ...[
                          const SizedBox(height: 6),
                          Text(
                            'You can browse all providers without location. Try again later for new providers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _locationLoading || _providersLoading
                              ? null
                              : _initLocation,
                          child: const Text('Try again',
                              style: TextStyle(color: orange)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => RecommendedProviderCard(
                    provider: providers[index],
                    onReturn: _fetchProviders,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeAccountLoadingShell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 170,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFF2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 125,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF68B1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAECEF)),
          ),
        ),
        const SizedBox(height: 28),
        const Center(
          child: Text(
            'Loading your Boo home…',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final String sortBy;
  final int? radius;
  final bool hasLocation;
  final String locationHint;
  final VoidCallback onRecoverLocation;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<int?> onRadiusChanged;

  const _FilterSheet({
    required this.sortBy,
    required this.radius,
    required this.hasLocation,
    required this.locationHint,
    required this.onRecoverLocation,
    required this.onSortChanged,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort by',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _SortOption(
            label: 'Recommended',
            value: 'recommended',
            groupValue: sortBy,
            onTap: () {
              onSortChanged('recommended');
              Navigator.pop(context);
            },
          ),
          _SortOption(
            label: 'Most Reviewed',
            value: 'reviews',
            groupValue: sortBy,
            onTap: () {
              onSortChanged('reviews');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Distance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (!hasLocation) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text('($locationHint)',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                ),
                TextButton(
                  onPressed: onRecoverLocation,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(48, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Retry',
                      style: TextStyle(color: Color(0xFFF68B1F))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _RadiusChip(
                label: 'Any',
                value: null,
                selected: radius == null,
                enabled: true,
                onTap: () {
                  onRadiusChanged(null);
                  Navigator.pop(context);
                },
              ),
              _RadiusChip(
                label: '5 km',
                value: 5,
                selected: radius == 5,
                enabled: hasLocation,
                onTap: hasLocation
                    ? () {
                        onRadiusChanged(5);
                        Navigator.pop(context);
                      }
                    : null,
              ),
              _RadiusChip(
                label: '10 km',
                value: 10,
                selected: radius == 10,
                enabled: hasLocation,
                onTap: hasLocation
                    ? () {
                        onRadiusChanged(10);
                        Navigator.pop(context);
                      }
                    : null,
              ),
              _RadiusChip(
                label: '25 km',
                value: 25,
                selected: radius == 25,
                enabled: hasLocation,
                onTap: hasLocation
                    ? () {
                        onRadiusChanged(25);
                        Navigator.pop(context);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      trailing:
          selected ? const Icon(Icons.check_rounded, color: orange) : null,
      onTap: onTap,
    );
  }
}

class _RadiusChip extends StatelessWidget {
  final String label;
  final int? value;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _RadiusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? orange
              : enabled
                  ? Colors.white
                  : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? orange
                : enabled
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : enabled
                    ? Colors.black87
                    : const Color(0xFFBDBDBD),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Service chip ──────────────────────────────────────────────────────────────

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? orange : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSelected ? orange : const Color(0xFFEAECEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: isSelected ? Colors.white : orange, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
