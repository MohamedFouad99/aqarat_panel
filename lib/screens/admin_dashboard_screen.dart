import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/user_service.dart';

/// لوحة مدير النظام (الأدمن): متابعة عامة + إدارة المستخدمين + البلاغات.
class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final _auth = AuthService();
  final _users = UserService();
  final _reports = ReportService();
  final _db = FirebaseFirestore.instance;

  Future<int> _count(String collection) async {
    final snap = await _db.collection(collection).count().get();
    return snap.count ?? 0;
  }

  Future<int> _countVerifiedDeals() async {
    final snap = await _db
        .collection('deals')
        .where('status', isEqualTo: 'verified')
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة مدير النظام'),
            actions: [
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.public, color: Colors.white, size: 18),
                label: const Text('الموقع',
                    style: TextStyle(color: Colors.white)),
              ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout),
                onPressed: _auth.signOut,
              ),
            ],
            bottom: const TabBar(
              indicatorColor: Color(0xFFC9A227),
              labelColor: Color(0xFFE3C766),
              unselectedLabelColor: Colors.white,
              tabs: [
                Tab(text: 'المستخدمون', icon: Icon(Icons.people)),
                Tab(text: 'البلاغات', icon: Icon(Icons.flag)),
              ],
            ),
          ),
          body: Column(
            children: [
              _kpiBand(),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  children: [_usersTab(), _reportsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiBand() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _count('properties'),
        _count('requests'),
        _countVerifiedDeals(),
      ]),
      builder: (context, snap) {
        final c = snap.data ?? [0, 0, 0];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _kpi('الإعلانات', '${c[0]}', Icons.home_work),
              _kpi('الطلبات', '${c[1]}', Icons.assignment),
              _kpi('صفقات موثّقة', '${c[2]}', Icons.verified),
            ],
          ),
        );
      },
    );
  }

  Widget _kpi(String label, String value, IconData icon) => Container(
        width: 130,
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0A2540), Color(0xFF15406B)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC9A227), size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );

  Widget _usersTab() {
    return StreamBuilder<List<UserProfile>>(
      stream: _users.watchAllUsers(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!;
        if (users.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمون'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _userCard(context, users[i]),
        );
      },
    );
  }

  Widget _userCard(BuildContext context, UserProfile u) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(u.name.isEmpty ? '(بدون اسم)' : u.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (u.verified)
                  const Icon(Icons.verified,
                      color: Color(0xFF1E8E4E), size: 18),
              ],
            ),
            if (u.phone.isNotEmpty || u.email.isNotEmpty)
              Text(
                  [u.phone, u.email].where((e) => e.isNotEmpty).join(' · '),
                  style: const TextStyle(
                      color: Color(0xFF6B7785), fontSize: 13)),
            if (u.city.isNotEmpty)
              Text('الاختصاص: ${u.city}'
                  '${u.districts.isNotEmpty ? " (${u.districts.join("، ")})" : ""}',
                  style: const TextStyle(
                      color: Color(0xFF6B7785), fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<UserRole>(
                    initialValue: u.role,
                    isDense: true,
                    decoration: const InputDecoration(
                        labelText: 'الدور', border: OutlineInputBorder()),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r.arabicLabel)))
                        .toList(),
                    onChanged: (r) {
                      if (r != null) _users.setRole(u.uid, r);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('موثّق', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: u.verified,
                      onChanged: (v) => _users.setVerified(u.uid, v),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportsTab() {
    return StreamBuilder<List<ReportItem>>(
      stream: _reports.watchOpen(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const Center(child: Text('لا توجد بلاغات مفتوحة ✅'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = items[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Color(0xFFD9534F)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              r.propertyTitle.isEmpty
                                  ? 'إعلان #${r.propertyId}'
                                  : r.propertyTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('السبب: ${r.reason}'),
                    if (r.note.isNotEmpty) Text('ملاحظة: ${r.note}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (r.propertyId.isNotEmpty)
                          TextButton.icon(
                            onPressed: () =>
                                context.go('/property/${r.propertyId}'),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('فتح الإعلان'),
                          ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _reports.resolve(r.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('تم المعالجة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
