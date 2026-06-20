// اختبار بسيط للتأكد إن التطبيق بيتبني من غير ما يضرب.
import 'package:flutter_test/flutter_test.dart';

import 'package:aqarat_panel/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const AqaratApp());
  });
}
