import 'dart:convert';

import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_provider/recommended_provider_card.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/services/favorites_service.dart';
import 'package:flutter/material.dart';

class FavoriteProvidersScreen extends StatefulWidget {
  const FavoriteProvidersScreen({super.key});

  @override
  State<FavoriteProvidersScreen> createState() =>
      _FavoriteProvidersScreenState();
}

class _FavoriteProvidersScreenState extends State<FavoriteProvidersScreen> {
  static const orange = Color(0xFFF68B1F);
  late Future<List<ProviderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFavorites();
  }

  Future<List<ProviderModel>> _loadFavorites() async {
    await FavoritesManager.instance.load();
    final ids = FavoritesManager.instance.ids;
    if (ids.isEmpty) return [];

    final res = await ApiService.instance.get('/providers');
    if (res.statusCode != 200) {
      throw Exception('Could not load favorite providers');
    }

    final providers = (jsonDecode(res.body) as List<dynamic>)
        .map((item) => ProviderModel.fromJson(item as Map<String, dynamic>))
        .where((provider) => ids.contains(provider.id))
        .toList();
    providers.sort((a, b) => a.name.compareTo(b.name));
    return providers;
  }

  void _refresh() {
    setState(() => _future = _loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Favorite Providers',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<ProviderModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: orange),
              );
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load favorites',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: _refresh,
              );
            }

            final providers = snapshot.data ?? const <ProviderModel>[];
            if (providers.isEmpty) {
              return const _MessageState(
                icon: Icons.favorite_border_rounded,
                title: 'No favorites yet',
                message: 'Tap the heart on a provider profile to save them.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return RecommendedProviderCard(provider: providers[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: Color(0xFFF68B1F)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
