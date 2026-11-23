// اختبارات لا تحتاج Firebase: صفحة "حسابي" والتحققات المشتركة.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:aqarat_panel/public/account_page.dart';
import 'package:aqarat_panel/services/compare_service.dart';
import 'package:aqarat_panel/services/favorites_service.dart';
import 'package:aqarat_panel/services/recently_viewed_service.dart';
import 'package:aqarat_panel/utils/validators.dart';

void main() {
  group('AccountPage', () {
    setUp(() {
      FavoritesService.instance.ids.value = {};
      CompareService.instance.ids.value = [];
      RecentlyViewedService.instance.ids.value = [];
    });

    Future<void> pumpPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const AccountPage()),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    /// النص [text] داخل بطاقة "حسابي" التي عنوانها [label].
    Finder inTile(String label, String text) => find.descendant(
          of: find.widgetWithText(ListTile, label),
          matching: find.text(text),
        );

    testWidgets('shows item counts as badges', (tester) async {
      FavoritesService.instance.ids.value = {'a', 'b', 'c'};
      CompareService.instance.ids.value = ['x', 'y'];
      await pumpPage(tester);

      expect(inTile('المفضلة', '3'), findsOneWidget);
      expect(inTile('المقارنة', '2'), findsOneWidget);
    });

    testWidgets('badge updates when the list changes', (tester) async {
      await pumpPage(tester);
      expect(inTile('شاهدت مؤخرًا', '1'), findsNothing);

      RecentlyViewedService.instance.ids.value = ['p1'];
      await tester.pump();
      expect(inTile('شاهدت مؤخرًا', '1'), findsOneWidget);
    });

    testWidgets('hides badge when the list is empty', (tester) async {
      await pumpPage(tester);
      expect(inTile('المفضلة', '0'), findsNothing);
      expect(inTile('المقارنة', '0'), findsNothing);
    });
  });

  group('Validators.saudiPhone', () {
    test('accepts local and international formats', () {
      expect(Validators.saudiPhone('0512345678'), isNull);
      expect(Validators.saudiPhone('+966512345678'), isNull);
      expect(Validators.saudiPhone('966 51 234 5678'), isNull);
    });

    test('rejects invalid numbers', () {
      expect(Validators.saudiPhone(null), isNotNull);
      expect(Validators.saudiPhone(''), isNotNull);
      expect(Validators.saudiPhone('0612345678'), isNotNull);
      expect(Validators.saudiPhone('05123'), isNotNull);
    });
  });
}
