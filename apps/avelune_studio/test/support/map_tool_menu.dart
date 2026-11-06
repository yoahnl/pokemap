import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip_selection.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';

Future<void> chooseMapExtraTool(WidgetTester tester, String label) async {
  final family = find.descendant(
    of: find.byType(MapWorkspaceToolStrip),
    matching: find.widgetWithText(StudioButton, label),
  );
  if (family.evaluate().isNotEmpty) {
    await tester.ensureVisible(family.first);
    await tester.tap(family.first);
  } else {
    final populate = mapPopulateTools.any((tool) => tool.$1 == label);
    await tester.tap(
      find.byTooltip(populate ? 'Peupler la carte' : 'Autres outils de carte'),
    );
    await tester.pumpAndSettle();
    final item = find.widgetWithText(PopupMenuItem<String>, label);
    await tester.ensureVisible(item);
    await tester.tap(item);
  }
  await tester.pumpAndSettle();
}
