import 'package:flutter_test/flutter_test.dart';

Future<void> chooseMapExtraTool(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    await tester.tap(find.byTooltip('Autres outils de carte'));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
