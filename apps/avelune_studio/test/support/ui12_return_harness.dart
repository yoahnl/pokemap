import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

/// Two scenes that both link the same presentation, in a real project.
///
/// The return journey A → P → B → P → A can only be judged in the workspace
/// host: the defect lives in how the host remembers where the author came
/// from, not in any callback payload.
class Ui12ReturnHarness {
  Ui12ReturnHarness({
    required this.directory,
    required this.session,
    required this.maps,
    required this.controller,
    required this.presentationId,
    required this.sceneA,
    required this.sceneB,
    required this.nodeA,
    required this.nodeB,
    required this.narrativeAdapter,
    required this.scenePort,
    required this.presentationPort,
  });

  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final MapWorkspaceController controller;
  final String presentationId;
  final SceneAsset sceneA;
  final SceneAsset sceneB;
  final String nodeA;
  final String nodeB;

  final LocalNarrativeAdapter narrativeAdapter;
  final LocalSceneAdapter scenePort;
  final LocalPresentationAdapter presentationPort;

  static Future<Ui12ReturnHarness> create() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ui12_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    final manifestFile = File('${directory.path}/project.json');
    final seeded = ProjectManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    await manifestFile.writeAsString(
      jsonEncode(seeded.copyWith(version: ProjectVersion.v7).toJson()),
    );
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'UI12',
      directoryPath: directory.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadProject(session);

    final presentationId = await _publishPresentation(session, maps);
    final scenes = await _publishScenes(session, maps, presentationId);

    final controller = MapWorkspaceController(session, maps);
    await controller.initialize();
    return Ui12ReturnHarness(
      directory: directory,
      session: session,
      maps: maps,
      controller: controller,
      presentationId: presentationId,
      sceneA: scenes.$1,
      sceneB: scenes.$2,
      nodeA: scenes.$3,
      nodeB: scenes.$4,
      narrativeAdapter: LocalNarrativeAdapter(
        session: session,
        mapAdapter: maps,
      ),
      scenePort: LocalSceneAdapter(session: session, mapAdapter: maps),
      presentationPort: LocalPresentationAdapter(
        session: session,
        mapAdapter: maps,
      ),
    );
  }

  static Future<String> _publishPresentation(
    ProjectSession session,
    LocalMapWorkspaceAdapter maps,
  ) async {
    final owner = MapWorkspaceController(session, maps);
    await owner.initialize();
    final narrative = NarrativeWorkspaceController(
      owner,
      LocalNarrativeAdapter(session: session, mapAdapter: maps),
      () {},
      (_, _) async {},
    );
    final presentations = PresentationWorkspaceController(
      narrative,
      LocalPresentationAdapter(session: session, mapAdapter: maps),
      changed: () {},
    );
    try {
      if (!await presentations.create(
        title: 'Départ du train',
        templateId: 'titleIdentity',
      )) {
        throw StateError(presentations.error ?? 'création refusée');
      }
      final id = presentations.activeId!;
      final layer = PresentationLayer(
        id: '$id.layer',
        label: 'Titre',
        zIndex: 0,
      );
      presentations.apply('presentationLayer.create', {
        'layer': encodePresentationLayer(layer),
      });
      presentations.apply('presentationTrack.create', {
        'track': {
          'id': '$id.track',
          'label': 'Titre',
          'kind': PresentationTrackKind.visual.name,
          'clips': [
            encodePresentationClip(
              PresentationTextClip(
                id: '$id.clip',
                startUs: 0,
                durationUs: 4000000,
                layerId: layer.id,
                text: 'Le train part',
                style: PresentationTextStyle(fontSize: 48),
              ),
            ),
          ],
        },
      });
      if (!await presentations.save()) {
        throw StateError(presentations.error ?? 'publication refusée');
      }
      return id;
    } finally {
      presentations.dispose();
      narrative.dispose();
      owner.dispose();
    }
  }

  static Future<(SceneAsset, SceneAsset, String, String)> _publishScenes(
    ProjectSession session,
    LocalMapWorkspaceAdapter maps,
    String presentationId,
  ) async {
    final manifest = await maps.loadProject(session);
    final base = await maps.loadMap(session, manifest.maps.first);
    (SceneAsset, String) linked(String name) {
      final scene = createSceneDraftInProject(
        manifest,
        name: name,
      ).createdScene;
      final node = addSceneLinkedAssetNodeDraft(
        scene,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: presentationId,
        ),
        title: 'Présentation liée',
      );
      return (node.updatedScene, node.createdNode.id);
    }

    final a = linked('Scène A');
    final b = linked('Scène B');
    await LocalNarrativeAdapter(session: session, mapAdapter: maps).publish(
      NarrativePublication(base: base, current: base.map, scenes: [a.$1, b.$1]),
    );
    return (a.$1, b.$1, a.$2, b.$2);
  }

  Future<void> dispose() async {
    controller.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
