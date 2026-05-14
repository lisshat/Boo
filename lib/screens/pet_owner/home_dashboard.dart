import 'dart:convert';

import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_provider/recommended_provider_card.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  static const orange = Color(0xFFF68B1F);

  late Future<Map<String, dynamic>> _meFuture;
  final _searchCtrl = TextEditingController();

  ProviderType? _selectedCategory;
  String _sortBy = 'rating';
  int? _radius = 25; // null = any distance

  Position? _position;
  bool _locationLoading = true;

  List<ProviderModel> _allProviders = [];
  bool _providersLoading = false;
  String? _providersError;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
    _searchCtrl.addListener(() => setState(() {}));
    _initLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    if (UserCache.instance.data != null) return UserCache.instance.data!;
    final res = await ApiService.instance.get('/auth/me');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      UserCache.instance.set(data);
      return data;
    }
    throw Exception('Failed to load user (${res.statusCode})');
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission perm = permission;
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() => _locationLoading = false);
        _fetchProviders();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (mounted)
        setState(() {
          _position = pos;
          _locationLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    if (!mounted) return;
    setState(() {
      _providersLoading = true;
      _providersError = null;
    });

    String path = '/providers';
    if (_position != null) {
      path += '?lat=${_position!.latitude}&lng=${_position!.longitude}';
      if (_radius != null) path += '&radius=$_radius';
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
      list = list.where((p) => p.type == _selectedCategory).toList();
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
    if (_sortBy == 'reviews') {
      list = List.from(list)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return list;
  }

  bool get _filtersActive =>
      _sortBy != 'rating' ||
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
            return const Center(child: CircularProgressIndicator());
          }
          if (asyncSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not connect to server.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _meFuture = _fetchMe();
                    }),
                    child: const Text('Retry',
                        style: TextStyle(color: Color(0xFFF68B1F))),
                  ),
                ],
              ),
            );
          }

          final userData = asyncSnapshot.data!;
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
                                _radius != null
                                    ? 'Within $_radius km'
                                    : 'All providers',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ] else ...[
                              const Icon(Icons.location_off_rounded,
                                  size: 14, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Text('Location unavailable',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
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
                          onPressed: _providersLoading ? null : _fetchProviders,
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
                          onPressed: _fetchProviders,
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
                    child: Text(
                      _allProviders.isEmpty
                          ? 'No providers available yet.'
                          : 'No providers match your search.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      RecommendedProviderCard(provider: providers[index]),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final String sortBy;
  final int? radius;
  final bool hasLocation;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<int?> onRadiusChanged;

  const _FilterSheet({
    required this.sortBy,
    required this.radius,
    required this.hasLocation,
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
            label: 'Top Rated',
            value: 'rating',
            groupValue: sortBy,
            onTap: () {
              onSortChanged('rating');
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
                const Text('(enable location)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
