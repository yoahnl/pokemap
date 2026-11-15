import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_relief_fixture.dart';
import 'spatial_relief_tools_support.dart';

class _FailingVisuals extends ReliefVisuals {
  var failures = 1;

  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async {
    if (failures-- > 0) throw StateError('Personnage du PNJ absent : Léo');
    return SpatialNpcPreview({}, () {});
  }
}

void main() {
  testWidgets('a character preview problem is French and clears once fixed', (
    tester,
  ) async {
    final withNpc = reliefDocument(
      reliefToolMap().copyWith(
        entities: const [
          MapEntity(
            id: 'npc-leo',
            name: 'Léo',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(characterId: 'leo'),
          ),
        ],
      ),
    );
    final empty = reliefDocument(reliefToolMap().copyWith(id: 'b'));
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapEditingViewportSession();
    final visuals = _FailingVisuals();
    addTearDown(controller.dispose);
    addTearDown(view.dispose);
    Future<void> show(EditableMapDocument document) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: reliefToolProject(),
              visuals: visuals,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    await show(withNpc);
    const problem =
        'Aperçu des personnages indisponible : '
        'Bad state: Personnage du PNJ absent : Léo';
    expect(withNpc.error, problem);

    await show(empty);
    await show(withNpc);
    expect(withNpc.error, isNull);

    visuals.failures = 1;
    await show(empty);
    await show(withNpc);
    expect(withNpc.error, problem);
    withNpc.error = 'Une autre erreur';
    await show(empty);
    await show(withNpc);
    expect(withNpc.error, 'Une autre erreur');
  });
}
