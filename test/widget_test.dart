import 'package:flutter_test/flutter_test.dart';

import 'package:iosapp_flutter/main.dart';

void main() {
  testWidgets('app renders main shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CrudApp());

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('购物车'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
