import 'package:boo/models/provider_models.dart';
import 'package:flutter/material.dart';

class RecommendedProviderCard extends StatelessWidget {
  final ProviderModel provider;
  const RecommendedProviderCard({super.key, required this.provider});

  static Widget _imageFallback() => Container(
        height: 120,
        width: double.infinity,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.pets, color: Color(0xFF9CA3AF), size: 40),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/provider-profile',
          arguments: provider,
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: provider.imageUrl.isNotEmpty
                  ? Image.network(
                      provider.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            const SizedBox(height: 10),
            Text(
              provider.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _VerificationTag(isVerified: provider.isVerified),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  provider.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_rounded,
                    size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    provider.locationName,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // same as tapping the card
                  Navigator.pushNamed(
                    context,
                    '/provider-profile',
                    arguments: provider,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF68B1F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Book"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTag extends StatelessWidget {
  final bool isVerified;

  const _VerificationTag({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final color =
        isVerified ? const Color(0xFF15803D) : const Color(0xFF6B7280);
    final bg = isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          isVerified ? 'Verified Professional' : 'Identity Pending',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
