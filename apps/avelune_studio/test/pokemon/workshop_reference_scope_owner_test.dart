import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _project = ProjectManifest(
  name: 'References',
  maps: [],
  tilesets: [],
  encounterTables: [
    ProjectEncounterTable(
      id: 'table',
      name: 'Table',
      encounterKind: EncounterKind.walk,
      entries: [],
    ),
  ],
);

void main() {
  test(
    'combat deletion requires an explicit complete reference analysis',
    () async {
      final port = _CombatPort();
      final owner = PokemonCombatController(port, changed: () {});
      await owner.load();
      owner.selectTable(_project.encounterTables.single);
      expect(await owner.deleteSelected(), isFalse);
      expect(port.deleted, 0);
      expect(port.analyzed, 0);
      expect(owner.error, contains('Analysez'));
      await owner.analyzeReferences();
      expect(port.analyzed, 1);
      expect(owner.snapshot!.referencesComplete, isTrue);
      expect(await owner.deleteSelected(), isTrue);
      expect(port.deleted, 1);
    },
  );

  test(
    'regional controller loads only the selected destination and reuses it',
    () async {
      final port = _RegionalPort();
      final owner = RegionalMapController(port, changed: () {});
      await owner.load();
      expect(port.reads, 0);
      owner.createRegion('Kanto');
      owner.createPoint('Town', 'town');
      expect(owner.point, isNotNull);
      expect(port.reads, 0);
      owner.editPoint(
        destination: ProjectRegionDestination(
          mapId: 'town',
          spawnId: 'arrival',
        ),
      );
      expect(await owner.loadMap('town'), isTrue);
      expect(port.reads, 1);
      expect(await owner.loadMap('town'), isTrue);
      expect(port.reads, 1);
    },
  );
}

final class _CombatPort
    implements PokemonCombatPort, PokemonCombatReferencePort {
  int analyzed = 0, deleted = 0;
  Completer<void>? pending;
  @override
  Future<PokemonCombatSnapshot> load() async => const PokemonCombatSnapshot(
    project: _project,
    maps: [],
    referencesComplete: false,
  );
  @override
  Future<PokemonCombatSnapshot> analyzeReferences() async {
    analyzed++;
    await pending?.future;
    return const PokemonCombatSnapshot(project: _project, maps: []);
  }

  @override
  Future<void> deleteTable(ProjectEncounterTable before) async {
    deleted++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _RegionalPort implements RegionalMapPort, RegionalMapDetailsPort {
  int reads = 0;
  @override
  Future<RegionalMapSource> load() async => RegionalMapSource(
    project: _project.copyWith(
      maps: [
        const ProjectMapEntry(
          id: 'town',
          name: 'Town',
          relativePath: 'maps/town.json',
        ),
      ],
    ),
    revision: 'revision',
    maps: {},
    images: {},
  );
  @override
  Future<MapData> readMap({
    required RegionalMapSource source,
    required String mapId,
  }) async {
    reads++;
    return const MapData(
      id: 'town',
      name: 'Town',
      size: GridSize(width: 4, height: 4),
    );
  }

  @override
  Future<Uint8List?> readImage(String path) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
