import 'package:avelune_studio/presentation/features/resources/border_pattern_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('three associations still require canonical validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorderPatternPanel(
            chosen: {
              for (final role in ['lineCap', 'lineStraight', 'lineCorner'])
                role: workspaceElement,
            },
            active: null,
            visuals: WorkspaceTestVisuals(),
            onAssign: (_, _) {},
          ),
        ),
      ),
    );
    expect(find.text('3 / 3 familles de pièces associées'), findsOneWidget);
    expect(
      find.text(
        'Associations complètes. Les raccords restent à valider avant publication.',
      ),
      findsOneWidget,
    );
  });
}
