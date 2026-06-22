import 'package:flutter/material.dart';

import '../../models/property.dart';
import 'property_card.dart';

/// شبكة كروت عقارات متجاوبة — مستخدمة في أكتر من صفحة.
class PropertyGrid extends StatelessWidget {
  const PropertyGrid(this.items, {super.key, this.maxColumns = 4});

  final List<Property> items;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    var cols = width > 1100
        ? 4
        : width > 800
            ? 3
            : width > 520
                ? 2
                : 1;
    if (cols > maxColumns) cols = maxColumns;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PropertyCard(property: items[i]),
    );
  }
}
