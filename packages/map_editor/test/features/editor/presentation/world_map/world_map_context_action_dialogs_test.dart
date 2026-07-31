import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_context_action_dialogs.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('uses the shared DS confirmation for destructive object actions',
      (tester) async {
    bool? result;
    await _pumpLauncher(
      tester,
      onPressed: (context) async {
        result = await showWorldMapContextDeleteConfirmation(
          context: context,
          target: _target,
          title: 'Supprimer l’entité',
          message: 'L’entité sera supprimée définitivement.',
        );
      },
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
    expect(find.text('Supprimer l’entité'), findsOneWidget);
    expect(
      find.text('L’entité sera supprimée définitivement.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.widgetWithText(PokeMapButton, 'Supprimer'),
          )
          .variant,
      PokeMapButtonVariant.danger,
    );

    await tester.tap(find.widgetWithText(PokeMapButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PokeMapButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Builder(
        builder: (context) => PokeMapButton(
          onPressed: () => onPressed(context),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}

const _target = MapObjectContextTarget(
  MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.entity,
    id: 'npc',
    anchor: GridPos(x: 2, y: 3),
    size: GridSize(width: 1, height: 1),
  ),
);
