import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> wire() => {
  'kind': 'playMusicEffect',
  'mediaAssetId': 'fanfare',
  'volume': 0.8,
  'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 1000},
};

SceneAsset scene(SceneInteractiveCommand command) => SceneAsset(
  id: 'scene', name: 'Fanfare', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(id: 'cue', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(command)),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ], edges: [
    SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'cue', kind: SceneEdgeKind.defaultFlow),
    for (final port in ['completed', 'blocked'])
      SceneEdge(id: port, fromNodeId: 'cue', fromPortId: port, toNodeId: 'end', kind: SceneEdgeKind.actionCompleted),
  ]),
);

void main() {
  test('ME is a distinct typed command with exact JSON and output ports', () {
    final command = SceneInteractiveCommand.fromJson(wire());
    expect(command.kind.name, 'playMusicEffect');
    expect(command.outputPortIds, ['completed', 'blocked']);
    expect(command.toJson(), wire());
    expect(SceneInteractiveCommand.fromJson(jsonDecode(jsonEncode(command.toJson()))), command);
    expect(NarrativeCommandCatalog.canonical().byId('playMusicEffect')!.isPublishable, isTrue);
    final built = buildScenePayloadForNarrativeCommand(commandId: 'playMusicEffect', parameters: {
      'mediaAssetId': 'fanfare', 'volume': '0.8', 'fadeOutMs': '0', 'fadeInMs': '1000',
    }) as SceneActionPayload;
    expect(built.interactiveCommand, command);
  });

  test('ME rejects missing, extra, malformed and unbounded parameters', () {
    for (final data in [
      {...wire()}..remove('bgmInterruption'),
      {...wire(), 'role': 'effect'},
      {...wire(), 'volume': 1.1},
      {...wire(), 'volume': double.nan},
      {...wire(), 'mediaAssetId': ''},
      {...wire(), 'bgmInterruption': null},
      {...wire(), 'bgmInterruption': {'fadeOutMs': -1, 'fadeInMs': 0}},
      {...wire(), 'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 60001}},
      {...wire(), 'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 0, 'unknown': true}},
    ]) {
      expect(() => SceneInteractiveCommand.fromJson(data), throwsA(anything));
    }
  });

  test('ME indexes its sound dependency and rejects unsupported media and 3D', () {
    final command = SceneInteractiveCommand.fromJson(wire());
    final asset = scene(command);
    for (final kind in CinematicMediaAssetKind.values) {
      for (final loop in [false, true]) {
        final project = ProjectManifest(name: 'ME', maps: const [], tilesets: const [], scenes: [asset],
          cinematicMediaAssets: [CinematicMediaAsset(id: 'fanfare', label: 'Fanfare', kind: kind, relativePath: 'audio/fanfare.ogg', loopByDefault: loop)]);
        final valid = kind == CinematicMediaAssetKind.sound && !loop;
        expect(diagnoseSceneAgainstProject(asset, project).hasErrors, !valid);
        final uses = buildNarrativeDependencyIndex(project: project).usagesFor(
          const NarrativeDependencyKey(NarrativeDependencyTargetKind.media, 'fanfare'));
        expect(uses, hasLength(1));
        expect(uses.single.resolution, valid ? NarrativeDependencyResolution.resolved : NarrativeDependencyResolution.unavailable);
        final spatial = project.copyWith(settings: const ProjectSettings(dimension: ProjectDimension.threeD));
        expect(diagnoseInteractiveCommand(command: command, project: spatial), isNotEmpty);
      }
    }
    final missing = ProjectManifest(name: 'ME', maps: const [], tilesets: const [], scenes: [asset]);
    expect(diagnoseSceneAgainstProject(asset, missing).hasErrors, isTrue);
  });
}
