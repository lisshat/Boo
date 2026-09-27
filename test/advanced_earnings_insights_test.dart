import 'package:flutter_test/flutter_test.dart';

import 'package:boo/services/advanced_earnings_insights.dart';

void main() {
  const calculator = AdvancedEarningsCalculator();

  test('calculates recorded total and average paid service', () {
    final result = calculator.calculate({
      'summary': {
        'totalEarnings': 1500,
        'completedCount': 3,
        'completedUnrecordedCount': 1,
      },
      'byCategory': [
        {'category': 'Grooming', 'total': 1000},
        {'category': 'Walks', 'total': 500},
      ],
      'byMonth': [
        {'month': '2026-08', 'total': 600},
        {'month': '2026-09', 'total': 900},
      ],
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
      ],
    });

    expect(result.recordedEarnings, 1500);
    expect(result.completedPaidServices, 2);
    expect(result.averageRecordedEarning, 750);
    expect(result.currency, 'KES');
    expect(result.comparison?.change, 300);
  });

  test('does not combine incompatible currencies', () {
    final result = calculator.calculate({
      'summary': {
        'totalEarnings': 1500,
        'completedCount': 2,
        'completedUnrecordedCount': 0,
      },
      'byCategory': [
        {'category': 'Grooming', 'total': 1500},
      ],
      'byMonth': [
        {'month': '2026-09', 'total': 1500},
      ],
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'USD',
        },
      ],
    });

    expect(result.recordedEarnings, isNull);
    expect(result.byCategory, isEmpty);
    expect(result.averageRecordedEarning, isNull);
  });

  test('handles missing amounts and empty data truthfully', () {
    final result = calculator.calculate({
      'summary': {
        'totalEarnings': null,
        'completedCount': 1,
        'completedUnrecordedCount': 1,
      },
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
      ],
    });

    expect(result.completedPaidServices, 0);
    expect(result.averageRecordedEarning, isNull);
    expect(result.hasData, isFalse);
  });

  test('unpaid and cancelled rows do not contribute to currency or totals', () {
    final result = calculator.calculate({
      'summary': {
        'totalEarnings': 500,
        'completedCount': 2,
        'completedUnrecordedCount': 1,
      },
      'byCategory': [
        {'category': 'Grooming', 'total': 500},
      ],
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
        {
          'status': 'cancelled',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'USD',
        },
        {
          'status': 'completed',
          'paymentStatus': 'pending',
          'currency': 'USD',
        },
      ],
    });

    expect(result.recordedEarnings, 500);
    expect(result.currency, 'KES');
  });

  test('session displays data only while Boo Pro access is current', () {
    final session = AdvancedEarningsSession();
    final insights = calculator.calculate({
      'summary': {
        'totalEarnings': 500,
        'completedCount': 1,
        'completedUnrecordedCount': 0,
      },
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
      ],
    });

    session.setAccess(true);
    final requestEpoch = session.requestEpoch;
    expect(session.accept(insights, requestEpoch), isTrue);
    expect(session.canDisplay, isTrue);
    session.setAccess(false);
    expect(session.canDisplay, isFalse);
    expect(session.accept(insights, requestEpoch), isFalse);
  });

  test('reactivation requires a new authoritative result', () {
    final session = AdvancedEarningsSession();
    final insights = calculator.calculate({
      'summary': {
        'totalEarnings': 500,
        'completedCount': 1,
        'completedUnrecordedCount': 0,
      },
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
      ],
    });

    session.setAccess(true);
    final oldEpoch = session.requestEpoch;
    session.accept(insights, oldEpoch);
    session.setAccess(false);
    session.setAccess(true);
    expect(session.canDisplay, isFalse);
    expect(session.accept(insights, oldEpoch), isFalse);
    expect(session.accept(insights, session.requestEpoch), isTrue);
  });

  test('account switching invalidates loaded analytics', () {
    final session = AdvancedEarningsSession();
    session.setAccess(true);
    final epoch = session.requestEpoch;
    final insights = calculator.calculate({
      'summary': {
        'totalEarnings': 500,
        'completedCount': 1,
        'completedUnrecordedCount': 0,
      },
      'recentBookings': [
        {
          'status': 'completed',
          'paymentStatus': 'provider_recorded_received',
          'currency': 'KES',
        },
      ],
    });
    session.accept(insights, epoch);
    session.clear();
    expect(session.canDisplay, isFalse);
    expect(session.accept(insights, epoch), isFalse);
  });
}
