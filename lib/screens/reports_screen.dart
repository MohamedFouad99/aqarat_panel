import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/deal.dart';
import '../models/property.dart';
import '../models/property_request.dart';
import '../services/auth_service.dart';
import '../services/deal_service.dart';
import '../services/property_service.dart';
import '../services/request_service.dart';
import '../services/views_service.dart';

/// تقارير ومؤشرات أداء الوسيط (KPIs).
class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final _auth = AuthService();
  final _propertyService = PropertyService();
  final _requestService = RequestService();
  final _dealService = DealService();
  final _viewsService = ViewsService();
  final _fmt = NumberFormat.decimalPattern('en');

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تقاريري')),
        body: StreamBuilder<List<Deal>>(
          stream: _dealService.watchByBroker(uid),
          builder: (context, dealSnap) {
            return StreamBuilder<List<Property>>(
              stream: _propertyService.watchByOwner(uid),
              builder: (context, offerSnap) {
                return StreamBuilder<List<PropertyRequest>>(
                  stream: _requestService.watchClaimedBy(uid),
                  builder: (context, claimSnap) {
                    return FutureBuilder<Map<String, int>>(
                      future: _viewsService.fetchAll(),
                      builder: (context, viewSnap) {
                        if (!dealSnap.hasData ||
                            !offerSnap.hasData ||
                            !claimSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final deals = dealSnap.data!;
                        final offers = offerSnap.data!;
                        final claims = claimSnap.data!;
                        final views = viewSnap.data ?? {};

                        final offerIds = offers.map((o) => o.id).toSet();
                        final totalViews = views.entries
                            .where((e) => offerIds.contains(e.key))
                            .fold<int>(0, (s, e) => s + e.value);
                        final verified =
                            deals.where((d) => d.status == 'verified').toList();
                        final totalValue =
                            verified.fold<num>(0, (s, d) => s + d.value);
                        final totalComm =
                            verified.fold<num>(0, (s, d) => s + d.commission);

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 600
                                      ? 3
                                      : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                _kpi('إعلاناتي', '${offers.length}',
                                    Icons.home_work),
                                _kpi('إجمالي المشاهدات', '$totalViews',
                                    Icons.visibility),
                                _kpi('طلبات استلمتها', '${claims.length}',
                                    Icons.assignment_ind),
                                _kpi('صفقات موثّقة', '${verified.length}',
                                    Icons.verified),
                                _kpi('قيمة الصفقات',
                                    '${_fmt.format(totalValue)} ريال',
                                    Icons.payments),
                                _kpi('إجمالي العمولات',
                                    '${_fmt.format(totalComm)} ريال',
                                    Icons.account_balance_wallet),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('آخر الصفقات',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0A2540))),
                            const SizedBox(height: 8),
                            if (deals.isEmpty)
                              const Text('لا توجد صفقات بعد',
                                  style:
                                      TextStyle(color: Color(0xFF6B7785)))
                            else
                              ...deals.take(10).map((d) => Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.verified,
                                          color: Color(0xFF1E8E4E)),
                                      title: Text(d.offerTitle),
                                      subtitle: Text(
                                          'العميل: ${d.clientName} · ${_fmt.format(d.value)} ريال'),
                                    ),
                                  )),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0A2540), Color(0xFF15406B)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFC9A227), size: 26),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
