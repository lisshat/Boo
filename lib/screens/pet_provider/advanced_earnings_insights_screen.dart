import 'package:flutter/material.dart';

import '../../services/advanced_earnings_insights.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/premium_access_service.dart';
import '../../widgets/premium_feature_gate.dart';

Future<void> openAdvancedEarningsInsights(BuildContext context) async {
  final decision = PremiumAccessController.instance.evaluate(
    PremiumFeature.advancedEarningsInsights,
    featureReady: true,
  );
  if (!decision.allowed) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: PremiumFeatureGate(
          feature: PremiumFeature.advancedEarningsInsights,
          featureReady: true,
          child: const Text('Advanced earnings insights are available here.'),
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AdvancedEarningsInsightsScreen()),
  );
}

class AdvancedEarningsInsightsScreen extends StatefulWidget {
  const AdvancedEarningsInsightsScreen({super.key});

  @override
  State<AdvancedEarningsInsightsScreen> createState() =>
      _AdvancedEarningsInsightsScreenState();
}

class _AdvancedEarningsInsightsScreenState
    extends State<AdvancedEarningsInsightsScreen> {
  late Future<AdvancedEarningsInsights> _future;
  final _session = AdvancedEarningsSession();
  final _accessController = PremiumAccessController.instance;

  @override
  void initState() {
    super.initState();
    _accessController.addListener(_onAccessChanged);
    _session.setAccess(_hasAccess);
    _future = _load();
  }

  bool get _hasAccess => _accessController
      .evaluate(
        PremiumFeature.advancedEarningsInsights,
        featureReady: true,
      )
      .allowed;

  void _onAccessChanged() {
    if (!mounted) return;
    final allowed = _hasAccess;
    final wasAllowed = _session.allowed;
    _session.setAccess(allowed);
    if (allowed && !wasAllowed) {
      setState(() => _future = _load());
    }
    // The AnimatedBuilder below rebuilds immediately. When access is lost,
    // the session epoch invalidates any request already in flight.
    if (!allowed) setState(() {});
  }

  Future<AdvancedEarningsInsights> _load() async {
    if (!_hasAccess) throw StateError('Boo Pro access required');
    final requestEpoch = _session.requestEpoch;
    final accountId = await AuthService.instance.getUserId();
    if (accountId == null || accountId.trim().isEmpty) {
      throw StateError('Authentication required');
    }
    final data = await BookingService.instance.getProviderEarnings(
      allowFallback: false,
    );
    final currentId = await AuthService.instance.getUserId();
    if (!mounted || currentId != accountId) {
      throw StateError('Account changed');
    }
    final insights = const AdvancedEarningsCalculator().calculate(data);
    if (!_session.accept(insights, requestEpoch)) {
      throw StateError('Stale earnings result');
    }
    return insights;
  }

  void _retry() {
    final decision = _accessController.evaluate(
      PremiumFeature.advancedEarningsInsights,
      featureReady: true,
    );
    if (!decision.allowed) return;
    setState(() => _future = _load());
  }

  @override
  void dispose() {
    _accessController.removeListener(_onAccessChanged);
    _session.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PremiumAccessController.instance,
      builder: (context, _) {
        final decision = _accessController.evaluate(
          PremiumFeature.advancedEarningsInsights,
          featureReady: true,
        );
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F7FB),
            elevation: 0,
            title: const Text('Advanced earnings',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: SafeArea(
            child: FutureBuilder<AdvancedEarningsInsights>(
              future: _future,
              builder: (context, snapshot) {
                if (!decision.allowed) {
                  return _accessState(decision);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return _ErrorState(onRetry: _retry);
                }
                final insights = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    _retry();
                    await _future;
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [_InsightsContent(insights: insights)],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _accessState(PremiumAccessDecision decision) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PremiumFeatureGate(
        feature: decision.feature,
        featureReady: true,
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.insights});

  final AdvancedEarningsInsights insights;

  @override
  Widget build(BuildContext context) {
    final currency = insights.currency;
    final amount = currency == null || insights.recordedEarnings == null
        ? '—'
        : '$currency ${insights.recordedEarnings!.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Advanced earnings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Boo Pro',
                style: TextStyle(
                  color: Color(0xFFB85D00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Recorded earnings from completed services with provider-recorded payments.',
          style: TextStyle(color: Colors.black54, height: 1.35),
        ),
        const SizedBox(height: 18),
        _MetricCard(label: 'Recorded earnings', value: amount),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Completed paid services',
                value: '${insights.completedPaidServices}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
            child: _MetricCard(
                label: 'Average recorded earning',
                value: insights.averageRecordedEarning == null || currency == null
                    ? '—'
                    : '$currency ${insights.averageRecordedEarning!.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (!insights.hasData)
          const _EmptyCard(
            message: 'Complete a paid booking to start seeing your earnings trends.',
          )
        else ...[
          if (insights.comparison != null)
            _ComparisonCard(comparison: insights.comparison!, currency: currency),
          if (insights.byMonth.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(title: 'Monthly recorded earnings', children: [
              for (final entry in insights.byMonth.reversed.take(6))
                _ValueRow(
                  label: entry.key,
                  value: currency == null
                      ? '—'
                      : '$currency ${entry.value.toStringAsFixed(2)}',
                ),
            ]),
          ],
          if (insights.byCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(title: 'Recorded earnings by service category', children: [
              for (final entry in insights.byCategory)
                _ValueRow(
                  label: entry.key,
                  value: currency == null
                      ? '—'
                      : '$currency ${entry.value.toStringAsFixed(2)}',
                ),
            ]),
          ],
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison, required this.currency});
  final EarningsPeriodComparison comparison;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final sign = comparison.change >= 0 ? '+' : '';
    return _Section(title: 'Period comparison', children: [
      _ValueRow(
        label: comparison.currentPeriod,
        value: currency == null
            ? '—'
            : '$currency ${comparison.currentTotal.toStringAsFixed(2)}',
      ),
      _ValueRow(
        label: 'vs ${comparison.previousPeriod}',
        value: currency == null
            ? '—'
            : '$sign$currency ${comparison.change.toStringAsFixed(2)}',
      ),
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_outlined,
                  color: Color(0xFFFF8A00)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No earnings insights yet',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load advanced earnings.'),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
}
