import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

/// دليل الوسطاء — كل المعلنين وعدد إعلاناتهم.
class AgentsPage extends StatelessWidget {
  const AgentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PropertyService();
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.groups, color: AppColors.navy),
                    SizedBox(width: 8),
                    Text('دليل الوسطاء',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Property>>(
                  stream: service.watchProperties(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final agents = _groupAgents(snapshot.data!);
                    if (agents.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('لا يوجد وسطاء حالياً')),
                      );
                    }
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          agents.map((a) => _card(context, a)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_Agent> _groupAgents(List<Property> props) {
    final map = <String, _Agent>{};
    for (final p in props) {
      final name = (p.advertiserName ?? '').trim();
      if (name.isEmpty) continue;
      final a = map.putIfAbsent(name, () => _Agent(name));
      a.count++;
      if (a.phone.isEmpty && (p.advertiserPhone ?? '').isNotEmpty) {
        a.phone = p.advertiserPhone!;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  Widget _card(BuildContext context, _Agent a) {
    return SizedBox(
      width: 240,
      child: Card(
        child: InkWell(
          onTap: () =>
              context.go('/advertiser/${Uri.encodeComponent(a.name)}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.navy,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${a.count} إعلان',
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                const Text('عرض الملف ←',
                    style: TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Agent {
  _Agent(this.name);
  final String name;
  String phone = '';
  int count = 0;
}
