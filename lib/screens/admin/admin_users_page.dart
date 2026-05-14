import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/services/admin_service.dart';
import 'package:flutter/material.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _role = 'all';
  late Future<List<dynamic>> _future;
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() => AdminService.instance.users(role: _role);

  void _refresh() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  Future<void> _confirmBan(Map<String, dynamic> user) async {
    final isBanned = user['is_banned'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AdminColors.danger),
            const SizedBox(width: 10),
            Text(isBanned ? 'Confirm Account Restore' : 'Confirm Account Ban'),
          ],
        ),
        content: Text(
          isBanned
              ? 'Are you sure you want to restore ${user['full_name']}?'
              : 'Are you sure you want to ban ${user['full_name']}? This will immediately revoke their access to the platform.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isBanned ? AdminColors.orange : AdminColors.danger,
                foregroundColor: Colors.white,
              ),
              child:
                  Text(isBanned ? 'Yes, Restore Account' : 'Yes, Confirm Ban'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AdminService.instance.setBanned(user['id'].toString(), !isBanned);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Directory',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900)),
                        Text('Manage Boo owners, providers, and admins.',
                            style: TextStyle(color: AdminColors.muted)),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _role,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All users')),
                      DropdownMenuItem(value: 'owner', child: Text('Owners')),
                      DropdownMenuItem(
                          value: 'provider', child: Text('Providers')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _role = v;
                        _future = _load();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const [];
                  return AdminCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFFFFF2E8)),
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Joined')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: rows.map((raw) {
                          final user = raw as Map<String, dynamic>;
                          final banned = user['is_banned'] == true;
                          return DataRow(
                            selected: _selected?['id'] == user['id'],
                            onSelectChanged: (_) =>
                                setState(() => _selected = user),
                            cells: [
                              DataCell(Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['full_name']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  Text(user['email']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AdminColors.muted)),
                                ],
                              )),
                              DataCell(Text(user['role']?.toString() ?? '')),
                              DataCell(AdminStatusPill(
                                text: banned
                                    ? 'Banned'
                                    : (user['verification_status']
                                            ?.toString() ??
                                        'Active'),
                                color: banned
                                    ? AdminColors.danger
                                    : Colors.green.shade700,
                              )),
                              DataCell(Text(_date(user['created_at']))),
                              DataCell(TextButton(
                                onPressed: () => _confirmBan(user),
                                child: Text(banned ? 'Restore' : 'Suspend'),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_selected != null)
          Container(
            width: 320,
            margin: const EdgeInsets.fromLTRB(0, 28, 28, 28),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                      radius: 44, child: Icon(Icons.person, size: 42)),
                  const SizedBox(height: 14),
                  Text(_selected!['full_name']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(_selected!['email']?.toString() ?? '',
                      style: const TextStyle(color: AdminColors.muted)),
                  const SizedBox(height: 20),
                  AdminStatusPill(
                    text: _selected!['role']?.toString() ?? '',
                    color: AdminColors.orange,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmBan(_selected!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_selected!['is_banned'] == true
                          ? 'Restore Account'
                          : 'Suspend Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }
}
