import 'dart:convert';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'dive_pair_actions_test.dart'
    show divePairMap, projectedDiveMaps, coincidentDivePairMaps;
import 'map_catalog_fixture.dart';

void main() {
  test(
      'coincident reciprocal Dive pairs block readiness with an explicit diagnostic for both roles',
      () {
    for (final role in DiveZoneRole.values) {
      final maps = coincidentDivePairMaps(role);
      final snapshot = catalogSnapshot(maps);
      final projection = RuntimeProjectProjection(
          project: snapshot.manifest,
          presentation: snapshot.manifest.effectivePresentation,
          payloadFiles: {
            for (final map in maps)
              'project/maps/${map.id}.json':
                  utf8.encode(jsonEncode(map.toJson()))
          },
          payloadDirectories: const {},
          compiledDialogueCount: 0,
          scrubbedSecretFieldCount: 0);
      final report =
          const GamePackageGameplayReadinessGate().evaluate(projection);
      final diagnostics = report.diagnostics
          .where((diagnostic) => diagnostic.code == 'dive.invalid_pair')
          .toList();
      expect(diagnostics, hasLength(4));
      expect(
          diagnostics.every((diagnostic) =>
              diagnostic.message.contains('Plusieurs points de Plongée')),
          isTrue);
      expect(
          diagnostics.every((diagnostic) =>
              diagnostic.severity == NarrativeProjectDiagnosticSeverity.error),
          isTrue);
    }
  });
  test(
      'preparation and broken or unsafe Dive pairs block playtest and export readiness',
      () {
    final preparations = [
      divePairMap('sea', DiveZoneRole.surface),
      divePairMap('deep', DiveZoneRole.underwater)
    ];
    final snapshot = catalogSnapshot(preparations);
    final linked = projectedDiveMaps(const DivePairActions()
        .build(catalogContext(snapshot, 'gameplay_zone.dive.link_pair_apply', {
      'mapId': 'sea',
      'zoneId': 'point',
      'targetMapId': 'deep',
      'targetZoneId': 'point'
    }))).values.toList();
    final obstructed = linked
        .map((map) => map.id != 'deep'
            ? map
            : map.copyWith(entities: [
                ...map.entities,
                const MapEntity(
                    id: 'block',
                    kind: MapEntityKind.sign,
                    pos: GridPos(x: 2, y: 2),
                    sign: MapEntitySignData())
              ]))
        .toList();
    for (final entry in [
      (preparations, true),
      (linked, false),
      (obstructed, true)
    ]) {
      final projection = RuntimeProjectProjection(
          project: snapshot.manifest,
          presentation: snapshot.manifest.effectivePresentation,
          payloadFiles: {
            for (final map in entry.$1)
              'project/maps/${map.id}.json':
                  utf8.encode(jsonEncode(map.toJson()))
          },
          payloadDirectories: const {},
          compiledDialogueCount: 0,
          scrubbedSecretFieldCount: 0);
      final report =
          const GamePackageGameplayReadinessGate().evaluate(projection);
      expect(
          report.diagnostics
              .any((diagnostic) => diagnostic.code.startsWith('dive.')),
          entry.$2);
      final structural =
          validateNarrativeProject(snapshot.manifest, maps: entry.$1);
      expect(
          structural.diagnostics
              .any((diagnostic) => diagnostic.code == 'dive.invalid_pair'),
          entry.$1 == preparations);
    }
  });
}
