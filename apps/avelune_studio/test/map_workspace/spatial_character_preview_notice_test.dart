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
  Future<SpatialNpcPreview> spatialPreview(
    MapData map,
    ProjectManifest project,
  ) async {
    if (failures-- > 0) throw StateError('L’image de Léo est introuvable.');
    return SpatialNpcPreview({}, () {});
  }
}

class _DefinitionsVisuals extends ReliefVisuals {
  final previewed = <ProjectManifest>[];

  @override
  Future<SpatialNpcPreview> spatialPreview(
    MapData map,
    ProjectManifest project,
  ) async {
    previewed.add(project);
    final known = project.characters.map((character) => character.id).toSet();
    for (final entity in map.entities) {
      if (!known.contains(entity.npc?.characterId)) {
        throw StateError('Le personnage de ${entity.name} est absent.');
      }
    }
    return SpatialNpcPreview({}, () {});
  }
}

MapData _withLeo(MapData map) => map.copyWith(
  entities: const [
    MapEntity(
      id: 'npc-leo',
      name: 'Léo',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      npc: MapEntityNpcData(characterId: 'leo'),
    ),
  ],
);

Widget _viewport(
  EditableMapDocument document,
  ProjectManifest project,
  MapWorkspaceController controller,
  MapEditingViewportSession view,
  ReliefVisuals visuals,
) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SpatialMapEditingViewport(
      document: document,
      controller: controller,
      project: project,
      visuals: visuals,
      view: view,
      onChanged: () {},
    ),
  ),
);

void main() {
  testWidgets('a character preview problem is French and clears once fixed', (
    tester,
  ) async {
    final withNpc = reliefDocument(_withLeo(reliefToolMap()));
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
        _viewport(document, reliefToolProject(), controller, view, visuals),
      );
      await tester.pump();
      await tester.pump();
    }

    await show(withNpc);
    const problem =
        'Aperçu des personnages indisponible : '
        'L’image de Léo est introuvable.';
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

  testWidgets(
    'characters show at opening from the definitions the map displays',
    (tester) async {
      final stale = reliefToolProject();
      final opened = stale.copyWith(
        characters: const [
          ProjectCharacterEntry(id: 'leo', name: 'Léo', tilesetId: 'leo'),
        ],
      );
      final document = reliefDocument(_withLeo(reliefToolMap()));
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapEditingViewportSession();
      final visuals = _DefinitionsVisuals();
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      Future<void> show(ProjectManifest project) async {
        await tester.pumpWidget(
          _viewport(document, project, controller, view, visuals),
        );
        await tester.pump();
        await tester.pump();
      }

      await show(opened);
      expect(document.error, isNull);
      expect(visuals.previewed.single, same(opened));

      await show(stale);
      expect(
        document.error,
        'Aperçu des personnages indisponible : '
        'Le personnage de Léo est absent.',
      );

      await show(opened);
      expect(document.error, isNull);
      expect(visuals.previewed.last, same(opened));
    },
  );
}
