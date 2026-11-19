import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart' show MapAuthoringException;
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late Directory root;
  MapWorkspaceController? workspace;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio-map-interactions-',
    );
    root = Directory(await temporary.resolveSymbolicLinks());
  });
  tearDown(() async {
    workspace?.dispose();
    workspace = null;
    await root.delete(recursive: true);
  });

  Future<void> seed(
    ProjectManifest project,
    MapData first,
    MapData second,
  ) async {
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    for (final map in [first, second]) {
      final entry = project.maps.singleWhere((entry) => entry.id == map.id);
      await File('${root.path}/${entry.relativePath}')
          .writeAsString(jsonEncode(map.toJson()));
    }
  }

  Future<MapWorkspaceController> open() async {
    workspace?.dispose();
    final controller = MapWorkspaceController(
      ProjectSession(
        sessionId: root.path,
        name: 'Atelier',
        directoryPath: root.path,
      ),
      LocalMapWorkspaceAdapter(),
    );
    workspace = controller;
    await controller.initialize();
    await controller.activate(workspaceEntries.first);
    expect(controller.error, isNull);
    return controller;
  }

  test('warp.ladder.configure saves and clears a spatial ladder while refusing a passive arrival', () async {
    MapData spatial(String id) => MapData(
      id: id,
      name: id,
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    final manifest = workspaceProject.copyWith(
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
    );
    await seed(manifest, spatial('a'), spatial('b'));
    final editor = await open();
    final document = editor.active!;
    final commands = WarpEditingCommands(document, editor.project!);
    final warp = commands.place(
      workspaceEntries.last,
      const GridPos(x: 2, y: 3),
    );
    final arrival = commands.placeArrival(const GridPos(x: 4, y: 5));
    final ladder = MapWarpLadder(
      direction: MapWarpLadderDirection.down,
      facing: EntityFacing.east,
    );
    commands.configureLadder(warp.id, ladder);
    final beforeRefusal = document.current;
    expect(
      () => commands.configureLadder(arrival.id, ladder),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          'warp.ladder_invalid_binding',
        ),
      ),
    );
    expect(document.current, same(beforeRefusal));
    expect(await editor.save(document), isTrue, reason: editor.error);
    final reopened = await open();
    final restored = WarpEditingCommands(reopened.active!, reopened.project!);
    expect(restored.selected(warp.id), warp.copyWith(ladder: ladder));
    expect(restored.selected(arrival.id), arrival);
    restored.configureLadder(warp.id, null);
    expect(
      await reopened.save(reopened.active!),
      isTrue,
      reason: reopened.error,
    );
    expect((await open()).active!.current.warps, [warp, arrival]);
  });

  test('entity.set_interactive_encounter and entity.set_presentation persist and refuse incompatible owners', () async {
    const tree = MapEntity(
      id: 'tree',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 3),
      editorVisual: MapEntityEditorVisual(elementId: 'tree'),
      properties: {'preserve': 'yes'},
    );
    const npc = MapEntity(
      id: 'guide',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 3),
      npc: MapEntityNpcData(displayName: 'Guide'),
    );
    const table = ProjectEncounterTable(
      id: 'trees',
      name: 'Arbres',
      encounterKind: EncounterKind.headbutt,
      entries: [
        ProjectEncounterEntry(speciesId: 'sentret', minLevel: 2, maxLevel: 2),
      ],
    );
    final manifest = workspaceProject.copyWith(
      elementCategories: [
        const ProjectElementCategory(id: 'decor', name: 'Décor'),
      ],
      encounterTables: [table],
    );
    await seed(
      manifest,
      workspaceMap('a').copyWith(entities: [tree, npc]),
      workspaceMap('b'),
    );
    final editor = await open();
    final document = editor.active!;
    final commands = MapEntityEditingCommands(document, editor.project!);
    final encounter = MapEntityInteractiveEncounterData(
      trigger: InteractiveEncounterTrigger.headbutt,
      encounterTableId: table.id,
      reusePolicy: InteractiveEncounterReusePolicy.oncePerMapInstance,
    );
    final presentation = MapEntityPresentation(
      variants: [
        MapEntityPresentationVariant(
          id: 'guide-page',
          condition: NarrativeEventConditionExpression.all([]),
          blocksMovement: false,
          size: const GridSize(width: 2, height: 1),
        ),
      ],
    );
    commands.setInteractiveEncounter(tree.id, encounter);
    commands.setPresentation(npc.id, presentation);
    final beforeRefusal = document.current;
    expect(
      () => commands.setPresentation(tree.id, presentation),
      throwsA(
        isA<MapAuthoringException>().having(
          (error) => error.code,
          'code',
          'entity.presentation_invalid',
        ),
      ),
    );
    expect(
      () => commands.setInteractiveEncounter(npc.id, encounter),
      throwsA(
        isA<MapAuthoringException>().having(
          (error) => error.code,
          'code',
          'entity.interactive_encounter_invalid',
        ),
      ),
    );
    expect(document.current, same(beforeRefusal));
    expect(await editor.save(document), isTrue, reason: editor.error);
    final reopened = await open();
    expect(reopened.active!.current.entities, [
      tree.copyWith(interactiveEncounter: encounter),
      npc.copyWith(presentation: presentation),
    ]);
    final restored = MapEntityEditingCommands(
      reopened.active!,
      reopened.project!,
    );
    restored.setPresentation(npc.id, null);
    restored.setInteractiveEncounter(tree.id, null);
    expect(
      await reopened.save(reopened.active!),
      isTrue,
      reason: reopened.error,
    );
    expect((await open()).active!.current.entities, [tree, npc]);
  });
}
