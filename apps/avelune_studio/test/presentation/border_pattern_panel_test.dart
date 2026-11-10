import 'package:avelune_studio/presentation/features/resources/border_pattern_panel.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

ResourceItem _piece() => ResourceItem(
  id: workspaceElement.id,
  name: workspaceElement.name,
  kind: ResourceKind.decors,
  element: workspaceElement,
);

Future<void> _pumpPanel(
  WidgetTester tester,
  List<String> roles, {
  bool straightOnly = false,
  bool followContourDirection = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: BorderPatternPanel(
        chosen: {for (final role in roles) role: _piece()},
        active: null,
        visuals: WorkspaceTestVisuals(),
        project: workspaceProject,
        straightOnly: straightOnly,
        followContourDirection: followContourDirection,
        onAssign: (_, _) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('a contour names the pieces it still needs before publication', (
    tester,
  ) async {
    await _pumpPanel(tester, ['lineStraight']);
    expect(find.text('1 / 3 familles de pièces associées'), findsOneWidget);
    expect(
      find.text('Pièces manquantes avant publication : extrémités, angles.'),
      findsOneWidget,
    );
    await _pumpPanel(tester, ['lineStraight', 'lineCap']);
    expect(
      find.text('Pièces manquantes avant publication : angles.'),
      findsOneWidget,
    );
  });

  testWidgets('only the explicit straight mode completes without corners', (
    tester,
  ) async {
    await _pumpPanel(tester, ['lineStraight', 'lineCap'], straightOnly: true);
    expect(find.text('2 / 2 familles de pièces associées'), findsOneWidget);
    expect(
      find.text(
        'Associations complètes. Les raccords restent à valider avant publication.',
      ),
      findsOneWidget,
    );
    await _pumpPanel(tester, ['lineStraight'], straightOnly: true);
    expect(
      find.text('Pièces manquantes avant publication : extrémités.'),
      findsOneWidget,
    );
  });

  testWidgets('a directed cliff asks for its inner corner by name', (
    tester,
  ) async {
    await _pumpPanel(tester, [
      'lineStraight',
      'lineCap',
      'lineCorner',
    ], followContourDirection: true);
    expect(find.text('3 / 4 familles de pièces associées'), findsOneWidget);
    expect(
      find.text('Pièces manquantes avant publication : angle rentrant.'),
      findsOneWidget,
    );
  });

  testWidgets('three associations still require canonical validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorderPatternPanel(
            chosen: {
              for (final role in ['lineCap', 'lineStraight', 'lineCorner'])
                role: ResourceItem(
                  id: workspaceElement.id,
                  name: workspaceElement.name,
                  kind: ResourceKind.decors,
                  element: workspaceElement,
                ),
            },
            active: null,
            visuals: WorkspaceTestVisuals(),
            project: workspaceProject,
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
