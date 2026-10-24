import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> musicPlay() => {
  'kind': 'sceneMusic',
  'operation': 'play',
  'mediaAssetId': 'scene-theme',
  'volume': .8,
};

SceneAsset musicScene(SceneInteractiveCommand command) => SceneAsset(
  id: 'music-scene',
  name: 'Musique de scène',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'music',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(command),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'music',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: port,
          fromNodeId: 'music',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

void main() {
  for (final wire in [
    musicPlay(),
    {'kind': 'sceneMusic', 'operation': 'restore'},
    {'kind': 'sceneMusic', 'operation': 'fadeOut', 'durationMs': 60000},
  ]) {
    test('scene music round-trips its exact ${wire['operation']} contract', () {
      final command = SceneInteractiveCommand.fromJson(wire);
      expect(command.kind.name, 'sceneMusic');
      expect(command.outputPortIds, ['completed', 'blocked']);
      expect(command.toJson(), wire);
      expect(
        SceneInteractiveCommand.fromJson(jsonDecode(jsonEncode(wire))),
        command,
      );
    });
  }

  test('scene music rejects cross-operation fields and malformed values', () {
    for (final wire in [
      {...musicPlay()}..remove('volume'),
      {...musicPlay(), 'mediaAssetId': ''},
      {...musicPlay(), 'volume': double.nan},
      {...musicPlay(), 'volume': double.infinity},
      {...musicPlay(), 'volume': -.1},
      {...musicPlay(), 'volume': 1.1},
      {...musicPlay(), 'durationMs': 0},
      {...musicPlay(), 'loop': false},
      {...musicPlay(), 'operation': 'restore'},
      {'kind': 'sceneMusic', 'operation': 'restore', 'mediaAssetId': null},
      {'kind': 'sceneMusic', 'operation': 'fadeOut', 'durationMs': -1},
      {'kind': 'sceneMusic', 'operation': 'fadeOut', 'durationMs': 60001},
      {'kind': 'sceneMusic', 'operation': 'fadeOut', 'durationMs': 1.5},
      {'kind': 'sceneMusic', 'operation': 'fadeOut', 'durationMs': '1000'},
      {'kind': 'sceneMusic', 'operation': 'fadeOut'},
      {'kind': 'sceneMusic', 'operation': 'unknown'},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson(wire),
        throwsA(anything),
        reason: '$wire',
      );
    }
  });

  test('3D accepts only music channel owned by the scene', () {
    for (final channel in SceneMusicChannel.values) {
      for (final scope in SceneMusicScope.values) {
        final command = SceneMusicInteractiveCommand(
          operation: SceneMusicOperation.memorize,
          channel: channel,
          scope: scope,
        );
        final scene = musicScene(command);
        final project = ProjectManifest(
          name: 'Spatial',
          maps: [],
          tilesets: [],
          scenes: [scene],
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        );
        final accepted =
            channel == SceneMusicChannel.music &&
            scope == SceneMusicScope.scene;
        expect(
          SpatialGameplayCapabilities.supportsSceneNode(
            SceneExecutionProfile.world,
            scene.graph.nodes[1],
          ),
          accepted,
        );
        expect(
          diagnoseInteractiveCommand(
            command: command,
            project: project,
          ).isEmpty,
          accepted,
        );
      }
    }
  });

  test(
    'scene music catalog and payload builder expose the closed operations',
    () {
      final descriptor = NarrativeCommandCatalog.canonical().byId('sceneMusic');
      expect(descriptor, isNotNull);
      expect(descriptor!.isPublishable, isTrue);
      for (final parameters in [
        {'operation': 'play', 'mediaAssetId': 'scene-theme', 'volume': '0.8'},
        {'operation': 'restore'},
        {'operation': 'fadeOut', 'durationMs': '1000'},
      ]) {
        final payload =
            buildScenePayloadForNarrativeCommand(
                  commandId: 'sceneMusic',
                  parameters: parameters,
                )
                as SceneActionPayload;
        expect(
          payload.interactiveCommand!.toJson()['operation'],
          parameters['operation'],
        );
      }
    },
  );

  test(
    'scene music preserves zero boundaries and rejects pre-session execution',
    () {
      final play = SceneInteractiveCommand.sceneMusic(
        operation: SceneMusicOperation.play,
        mediaAssetId: 'scene-theme',
        volume: 0,
      );
      expect(SceneInteractiveCommand.fromJson(play.toJson()), play);
      final fade = SceneInteractiveCommand.sceneMusic(
        operation: SceneMusicOperation.fadeOut,
        durationMs: 0,
      );
      expect(SceneInteractiveCommand.fromJson(fade.toJson()), fade);
      expect(buildSceneRuntimePlan(musicScene(play)).canBuild, isTrue);
      expect(
        buildSceneRuntimePlan(
          SceneAsset.fromJson({
            ...musicScene(play).toJson(),
            'executionProfile': 'preSession',
          }),
        ).canBuild,
        isFalse,
      );
      expect(
        () => SceneInteractiveCommand.sceneMusic(
          operation: SceneMusicOperation.restore,
          volume: 0,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'scene music requires unique music media in 2D and indexes its dependency',
    () {
      final command = SceneInteractiveCommand.fromJson(musicPlay());
      final scene = musicScene(command);
      for (final kind in CinematicMediaAssetKind.values) {
        for (final loop in [false, true]) {
          final project = ProjectManifest(
            name: 'Musique',
            maps: const [],
            tilesets: const [],
            scenes: [scene],
            cinematicMediaAssets: [
              CinematicMediaAsset(
                id: 'scene-theme',
                label: 'Thème',
                kind: kind,
                relativePath: 'audio/theme.ogg',
                loopByDefault: loop,
              ),
            ],
          );
          final valid = kind == CinematicMediaAssetKind.music;
          expect(diagnoseSceneAgainstProject(scene, project).hasErrors, !valid);
          final usages = buildNarrativeDependencyIndex(project: project)
              .usagesFor(
                const NarrativeDependencyKey(
                  NarrativeDependencyTargetKind.media,
                  'scene-theme',
                ),
              );
          expect(usages, hasLength(1));
          expect(
            usages.single.resolution,
            valid
                ? NarrativeDependencyResolution.resolved
                : NarrativeDependencyResolution.unavailable,
          );
          final spatial = project.copyWith(
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          );
          expect(
            diagnoseInteractiveCommand(command: command, project: spatial),
            isEmpty,
          );
        }
      }
      final missing = ProjectManifest(
        name: 'Musique',
        maps: const [],
        tilesets: const [],
        scenes: [scene],
      );
      expect(diagnoseSceneAgainstProject(scene, missing).hasErrors, isTrue);
      final duplicate = missing.copyWith(
        cinematicMediaAssets: [
          for (final label in ['First', 'Second'])
            CinematicMediaAsset(
              id: 'scene-theme',
              label: label,
              kind: CinematicMediaAssetKind.music,
              relativePath: 'audio/theme.ogg',
            ),
        ],
      );
      expect(diagnoseSceneAgainstProject(scene, duplicate).hasErrors, isTrue);
      expect(
        buildNarrativeDependencyIndex(project: duplicate)
            .usagesFor(
              const NarrativeDependencyKey(
                NarrativeDependencyTargetKind.media,
                'scene-theme',
              ),
            )
            .single
            .resolution,
        NarrativeDependencyResolution.ambiguous,
      );
    },
  );
}
