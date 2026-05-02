import 'package:boo/models/provider_models.dart';
import 'package:flutter/material.dart';

class BookingFailedScreen {
  static const orange = Color(0xFFF68B1F);

  static Future<void> show(
    BuildContext context, {
    required ProviderModel provider,
    required ServiceModel service,
    String? reason,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    ),
                    const Expanded(
                      child: Text(
                        'Booking Status',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Image with error badge
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: Image.network(
                      provider.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.pets, color: Color(0xFF9CA3AF), size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "We couldn't complete your booking with ${provider.name.split(' ').first}. Please try again.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF6B7280), height: 1.4, fontSize: 13),
                ),
              ),

              const SizedBox(height: 20),

              // Reason card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REASON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason ?? 'Your booking didn\'t go through. This is usually a connection issue — please check your internet and tap Try Again.',
                      style: const TextStyle(
                          color: Color(0xFF374151), height: 1.4, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Try Again',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
                child: const Text('Back to Profile',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
