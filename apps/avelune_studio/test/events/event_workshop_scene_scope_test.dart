import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('the events workshop loads what scene checks read', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'events_workshop_scope_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final scene = SceneAsset(
      id: 'route-29',
      name: 'Route 29',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'chime',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              ScenePlaySoundEffectInteractiveCommand(
                mediaAssetId: 'chime',
                volume: 1,
              ),
            ),
          ),
          SceneNode(
            id: 'wild',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'wild',
              battleTemplateId: 'tutorial',
            ),
          ),
          SceneNode(
            id: 'badge',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.awardBadge(badgeId: 'zephyr'),
            ),
          ),
        ],
      ),
    );
    final project = ProjectManifest(
      name: 'Johto',
      maps: const [],
      tilesets: const [],
      scenes: [scene],
      cinematicMediaAssets: [
        CinematicMediaAsset(
          id: 'chime',
          label: 'Carillon',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'audio/chime.ogg',
        ),
      ],
      encounterTables: const [
        ProjectEncounterTable(
          id: 'tutorial',
          name: 'Tutoriel',
          encounterKind: EncounterKind.walk,
          entries: [
            ProjectEncounterEntry(
              speciesId: 'rattata',
              minLevel: 5,
              maxLevel: 5,
            ),
          ],
        ),
      ],
      badges: const [BadgeDefinition(id: 'zephyr', label: 'Badge Zéphyr')],
    );
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'events-scope',
      project: project,
    );
    final maps = MapWorkspaceController(
      ProjectSession(
        sessionId: 'events-scope',
        name: project.name,
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(maps.dispose);
    const checked = [
      SceneDiagnosticCode.commandUnknownSoundMedia,
      SceneDiagnosticCode.battleTemplateRefMissing,
      SceneDiagnosticCode.consequenceUnknownBadge,
    ];
    List<SceneDiagnosticCode> missing() => [
      for (final code in checked)
        if (SceneProjectDiagnosticsContext(maps.project!)
            .diagnose(scene)
            .byCode(code)
            .isNotEmpty)
          code,
    ];

    await maps.initialize();
    expect(maps.error, isNull);
    expect(missing(), checked);

    await maps.ensureWorkshop(MapWorkspaceWorkshop.events);
    expect(maps.error, isNull);
    expect(missing(), isEmpty);
  });
}
