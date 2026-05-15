double bookingTotalAmount({
  required double price,
  required String? pricingUnit,
  required int durationMinutes,
}) {
  final normalized = _normalizePricingUnit(pricingUnit);
  final duration = durationMinutes > 0 ? durationMinutes : 0;

  switch (normalized) {
    case 'per_hour':
      return price * (duration > 0 ? duration / 60 : 1);
    case 'per_day':
    case 'per_night':
      return price * (duration > 0 ? duration / 1440 : 1);
    default:
      return price;
  }
}

String formatKsh(num amount) {
  final rounded = amount.round();
  if (rounded >= 1000) {
    return 'KSh ${rounded ~/ 1000},${(rounded % 1000).toString().padLeft(3, '0')}';
  }
  return 'KSh $rounded';
}

String pricingUnitLabel(String? value) {
  switch (_normalizePricingUnit(value)) {
    case 'per_hour':
      return 'per hour';
    case 'per_night':
      return 'per night';
    case 'per_day':
      return 'per day';
    default:
      return 'per session';
  }
}

String _normalizePricingUnit(String? value) {
  switch (value?.trim().toLowerCase().replaceAll(' ', '_')) {
    case 'per_hour':
      return 'per_hour';
    case 'per_night':
      return 'per_night';
    case 'per_day':
      return 'per_day';
    default:
      return 'per_session';
  }
}
