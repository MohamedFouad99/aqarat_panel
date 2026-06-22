import 'package:flutter/material.dart';

import 'site_footer.dart';
import 'site_header.dart';

/// هيكل موحّد لصفحات الموقع العام:
/// هيدر ثابت فوق + محتوى + فوتر ملزوق في آخر الصفحة دايماً (sticky footer)
/// حتى لو المحتوى أقصر من الشاشة — بطريقة متوافقة مع المحتوى القابل للتمرير.
class PublicPage extends StatelessWidget {
  const PublicPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SiteHeader(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // المحتوى يملأ ارتفاع الشاشة كحد أدنى عشان الفوتر ينزل تحت
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  child,
                  const SiteFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
