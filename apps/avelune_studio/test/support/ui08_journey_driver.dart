import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'm2_ui_fixture.dart';

EventWorkspacePage ui08Page(WidgetTester tester) =>
    tester.widget<EventWorkspacePage>(find.byType(EventWorkspacePage));

Future<void> ui08Open(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip('Histoire'),
    ),
  );
  await tester.pumpAndSettle();
  await ui08Tap(tester, 'Événements');
}

Future<void> ui08Tap(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await pumpIo(tester, frames: 12);
}

Future<void> ui08Select(
  WidgetTester tester,
  String label,
  String option,
) async {
  final target = find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == label,
  );
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await pumpIo(tester, frames: 12);
}
