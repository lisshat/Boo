import 'package:flutter/material.dart';

class AdminColors {
  static const orange = Color(0xFFFF8A00);
  static const brown = Color(0xFF8A4B00);
  static const ink = Color(0xFF24160B);
  static const muted = Color(0xFF7A6A5B);
  static const bg = Color(0xFFFFF7F1);
  static const panel = Color(0xFFFFFCF8);
  static const line = Color(0xFFEBD9CA);
  static const danger = Color(0xFFD42121);
  static const blue = Color(0xFF007EA7);
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdminColors.panel,
        border: Border.all(color: AdminColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const AdminStatusPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

Color adminStatusColor(String status) {
  switch (status) {
    case 'approved':
    case 'verified':
    case 'completed':
    case 'accepted':
      return Colors.green.shade700;
    case 'rejected':
    case 'cancelled':
    case 'declined':
      return AdminColors.danger;
    case 'pending':
      return AdminColors.orange;
    default:
      return AdminColors.muted;
  }
}

