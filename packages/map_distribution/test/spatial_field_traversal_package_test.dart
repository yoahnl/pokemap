import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/cs_audio_package_fixture.dart';

void main() {
  for (final whirlpool in [false, true]) {
    test(
        '${whirlpool ? 'Whirlpool' : 'Waterfall'} spatial packages declare their new movement contract',
        () {
      final files = csAudioPayload(ProjectDimension.threeD);
      final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!))
              as Map<String, dynamic>);
      files['project/project.json'] = utf8.encode(jsonEncode(project
          .copyWith(
              settings:
                  project.settings.copyWith(surf: const ProjectSurfSettings()))
          .toJson()));
      final initial = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      final map = initial.copyWith(gameplayZones: [
        MapGameplayZone(
            id: 'route',
            kind: GameplayZoneKind.fieldAction,
            area: const MapRect(
                pos: GridPos(x: 1, y: 1), size: GridSize(width: 3, height: 1)),
            fieldAction: whirlpool
                ? const FieldActionZonePayload(
                    actionKind: FieldActionZoneKind.whirlpool,
                    whirlpool: WhirlpoolZonePayload(
                        entry: GridPos(x: 0, y: 0),
                        path: [GridPos(x: 1, y: 0)],
                        exit: GridPos(x: 2, y: 0),
                        direction: MapConnectionDirection.east))
                : const FieldActionZonePayload(
                    actionKind: FieldActionZoneKind.waterfall,
                    waterfall: WaterfallZonePayload(
                        entry: GridPos(x: 0, y: 0),
                        path: [GridPos(x: 1, y: 0)],
                        exit: GridPos(x: 2, y: 0),
                        direction: MapConnectionDirection.east))),
        const MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 0, y: 0), size: GridSize(width: 8, height: 8)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf))
      ]);
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.toJson()));
      final before = jsonEncode(files);
      const required = SpatialGameplayCapabilities.fieldTraversalCapabilityId;
      final base = [
        SpatialGameplayCapabilities.capabilityId,
        SurfGameplayCapabilities.capabilityId
      ];
      expect(
          () => const GamePackageBuilder().build(
              manifest: csAudioManifest(ProjectDimension.threeD, base),
              payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.message,
              'field route semantics',
              contains(required))));
      final built = const GamePackageBuilder().build(
          manifest:
              csAudioManifest(ProjectDimension.threeD, [...base, required]),
          payloadFiles: files);
      final current = AveluneRuntimeCompatibility.host();
      GamePackageHostCompatibility host(Set<String> capabilities) =>
          GamePackageHostCompatibility(
              hubVersion: built.manifest.compatibility.minHubVersion,
              runtimeApiVersion: current.runtimeApiVersion,
              supportedRuntimeApiVersions: current.supportedRuntimeApiVersions,
              capabilities: capabilities,
              supportedProjectFormats: current.supportedProjectFormats,
              currentProjectFormat: current.currentProjectFormat,
              currentProjectFormats: current.currentProjectFormats,
              supportedSaveFormats: {
                ...current.supportedSaveFormats,
                built.manifest.compatibility.saveFormat
              });
      expect(
          () => GamePackageInspector(
                  hostCompatibility:
                      host({...current.capabilities}..remove(required)))
              .inspect(built.packageBytes),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.code,
              'safe older-host rejection',
              'capabilityUnsupported')));
      final inspected = GamePackageInspector(
              hostCompatibility: host({...current.capabilities}))
          .inspect(built.packageBytes);
      expect(inspected.manifest.compatibility.requiredCapabilities,
          contains(required));
      expect(jsonEncode(files), before);
    });
  }
  test('Strength push sound requires explicit audio v3', () {
    final files = csAudioPayload(ProjectDimension.threeD,
        audio: ProjectAudioSettings(cues: {
          ProjectSoundCue.fieldStrengthPush:
              const ProjectSoundBinding(source: ProjectSoundSource.builtin)
        }));
    final base = [
      ProjectAudioCapabilities.capabilityId,
      ProjectAudioCapabilities.extendedCapabilityId
    ];
    expect(
        () => const GamePackageBuilder().build(
            manifest: csAudioManifest(ProjectDimension.threeD, base),
            payloadFiles: files),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'push sound semantics',
            contains(ProjectAudioCapabilities.fieldMovementCapabilityId))));
    final built = const GamePackageBuilder().build(
        manifest: csAudioManifest(ProjectDimension.threeD,
            [...base, ProjectAudioCapabilities.fieldMovementCapabilityId]),
        payloadFiles: files);
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains(ProjectAudioCapabilities.fieldMovementCapabilityId));
  });
}
