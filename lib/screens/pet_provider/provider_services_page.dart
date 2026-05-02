import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';

class ProviderServicesPage extends StatefulWidget {
  const ProviderServicesPage({super.key});

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late Future<List<dynamic>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _fetchServices();
  }

  Future<List<dynamic>> _fetchServices() async {
    final res = await ApiService.instance.get('/providers/me');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['services'] as List<dynamic>?) ?? [];
    }
    throw Exception('Failed to load services');
  }

  void _refresh() => setState(() => _servicesFuture = _fetchServices());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _servicesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _orange));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load services'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }
          final services = snap.data!;
          final active = services.where((s) => s['isActive'] == true).toList();
          final inactive = services.where((s) => s['isActive'] != true).toList();

          return RefreshIndicator(
            color: _orange,
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Active services (${active.length})',
                    action: 'Sort by popularity',
                  ),
                  const SizedBox(height: 8),
                  ...active.map((s) => _ServiceCard(service: s as Map<String, dynamic>, onRefresh: _refresh)),
                ],
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(label: 'Inactive services (${inactive.length})'),
                  const SizedBox(height: 8),
                  ...inactive.map((s) => _ServiceCard(service: s as Map<String, dynamic>, onRefresh: _refresh, muted: true)),
                ],
                if (services.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'No services yet.\nTap + to add your first service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black45, height: 1.6),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        onPressed: () => _showAddServiceSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddServiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddServiceSheet(onAdded: _refresh),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? action;

  const _SectionHeader({required this.label, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
        ),
        if (action != null) ...[
          const Spacer(),
          Text(action!, style: const TextStyle(fontSize: 12, color: Color(0xFFF68B1F))),
        ],
      ],
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final VoidCallback onRefresh;
  final bool muted;

  const _ServiceCard({required this.service, required this.onRefresh, this.muted = false});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  static const _orange = Color(0xFFF68B1F);
  bool _toggling = false;

  Future<void> _toggleActive() async {
    setState(() => _toggling = true);
    try {
      final serviceId = widget.service['serviceId'] as String?;
      final current = widget.service['isActive'] as bool? ?? true;
      // TODO: PATCH /services/:id { isActive: !current } — endpoint not yet built
      // For now this is a local-only toggle placeholder
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) widget.onRefresh();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.service['isActive'] as bool? ?? true;
    final price = widget.service['price'];
    final duration = widget.service['durationMinutes'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.muted ? Colors.white.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.service['serviceName'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: widget.muted ? Colors.black54 : Colors.black87,
                  ),
                ),
              ),
              if (_toggling)
                const SizedBox(
                  width: 32,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
                )
              else
                Switch(
                  value: isActive,
                  activeColor: _orange,
                  onChanged: (_) => _toggleActive(),
                ),
            ],
          ),
          if (widget.service['description'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.service['description'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          Row(
            children: [
              _Pill(label: 'KSh $price', color: _orange.withOpacity(0.1), textColor: _orange),
              const SizedBox(width: 8),
              _Pill(label: '$duration min', color: Colors.grey.shade100, textColor: Colors.black54),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Edit details', style: TextStyle(color: _orange, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Pill({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Add Service Sheet ──────────────────────────────────────────────────────────

class _AddServiceSheet extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddServiceSheet({required this.onAdded});

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  static const _orange = Color(0xFFF68B1F);
  static const _categories = ['grooming', 'boarding', 'training', 'veterinary', 'sitting', 'other'];
  static const _durations = [30, 60, 90, 120, 180, 240, 480];

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = 'grooming';
  int _duration = 60;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _priceCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // TODO: POST /services endpoint — not yet built on backend
      // final res = await ApiService.instance.post('/services', {
      //   'serviceName': _nameCtrl.text.trim(),
      //   'category': _category,
      //   'durationMinutes': _duration,
      //   'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      // });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pop(context);
      widget.onAdded();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _durationLabel(int min) {
    if (min < 60) return '$min min';
    if (min == 60) return '1 hour';
    if (min % 60 == 0) return '${min ~/ 60} hours';
    return '${min ~/ 60}h ${min % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          const Text('Service name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Full Puppy Groom',
              hintStyle: const TextStyle(color: Colors.black38),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final selected = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _orange : const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? _orange : Colors.grey.shade200),
                  ),
                  child: Text(
                    cat[0].toUpperCase() + cat.substring(1),
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _duration,
                          isExpanded: true,
                          items: _durations.map((d) {
                            return DropdownMenuItem(value: d, child: Text(_durationLabel(d)));
                          }).toList(),
                          onChanged: (v) { if (v != null) setState(() => _duration = v); },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price (KSh)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _priceCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0',
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canSave && !_saving ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor: _orange.withOpacity(0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Add service',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
