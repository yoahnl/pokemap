import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/source_encounter_terrain_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  final profilePath = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  test('real Kanto map 284 keeps walkable overlays outside Surf requirements',
      () async {
    final bytes = <String, List<int>>{
      for (final name in [
        'Data/Map284.rxdata',
        'Data/MapInfos.rxdata',
        'Data/Tilesets.rxdata'
      ])
        name: await File('$root/$name').readAsBytes(),
      'Data/Scripts.rxdata': await File(scripts!).readAsBytes()
    };
    final entries = [
      for (final entry in bytes.entries)
        SourceFileEntry(
            fileId: ConverterId(
                'lot6-local:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}'),
            relativePath: entry.key,
            kind: SourceNodeKind.file,
            byteLength: entry.value.length,
            sha256: Sha256Hash(sha256.convert(entry.value).toString()),
            format: 'ruby-marshal',
            family: 'rmxp')
    ];
    expect(entries.first.sha256!.value,
        'ff6dc12cbc690a8fc8f07e58a947d7bab9de145be09cf9c9e1a9fead421263cd');
    expect(entries[2].sha256!.value,
        'abaf32c9a21e8c1e68e44a40b64d06ba7ab467af9d8c8a8b0696ee319f514b1c');
    final snapshot = SourceSnapshot(
        logicalProjectNamespace: ConverterId('lot6-local-kanto-map284'),
        policyHash: SourceScanPolicy().canonicalHash,
        entries: entries,
        diagnostics: [],
        excludedPaths: [],
        profileEvidence: [],
        state: SourceScanState.complete);
    final profile = SourceInterpretationProfile.fromJson(
        jsonDecode(await File(profilePath!).readAsString()));
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot,
        files: LiteralFixtureFiles(snapshot, bytes),
        selectedMapIds: {284},
        interpretationProfile: profile);
    expect(source.maps, hasLength(1));
    final semantic = SourceSemanticResolver.forProject(source);
    expect(semantic.profile.isQualified, isTrue);
    final terrain = SourceEncounterTerrainResolver(resolver: semantic);
    final result = const SourceEncounterTerrainBinding().bind(
        source: source,
        nativeMapIds: {284: 'native284'},
        tableIdsBySourceMethod: {});
    final movements = result.zonesBySourceMapId[284]!;
    expect(movements.every((zone) => zone.kind == GameplayZoneKind.movement),
        isTrue);
    final movementCells = {
      for (final zone in movements)
        for (var y = zone.area.pos.y;
            y < zone.area.pos.y + zone.area.size.height;
            y++)
          for (var x = zone.area.pos.x;
              x < zone.area.pos.x + zone.area.size.width;
              x++)
            GridPos(x: x, y: y)
    };
    final overlays = {
      for (var x = 11; x <= 20; x++) GridPos(x: x, y: 2),
      const GridPos(x: 9, y: 17),
      const GridPos(x: 15, y: 17),
      const GridPos(x: 9, y: 19),
      const GridPos(x: 15, y: 19)
    };
    final actualOverlays = <GridPos>{};
    final map = source.maps.single.map;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final cell = semantic.cellAt(284, x, y);
        final walk = semantic.resolveConnectionEntryTile(cell).isPassable;
        final water = {5, 6, 7}.contains(terrain.resolveTerrainTag(cell));
        final surf = terrain.resolveSurfEntryTile(cell).isPassable;
        final pos = GridPos(x: x, y: y);
        expect(
            movementCells.contains(pos), water && walk == false && surf == true,
            reason: '($x,$y)');
        if (water && walk == true && surf == true) actualOverlays.add(pos);
      }
    }
    expect(actualOverlays, overlays);
    expect(movementCells, hasLength(203));
    final row = (result.evidence['maps'] as List).single as Map;
    expect((row['waterCells'] as Map)['count'], 217);
    final world = GameplayWorldState.initial(
        map: MapData(
            id: 'native284',
            name: map.name,
            size: GridSize(width: map.width, height: map.height),
            gameplayZones: movements),
        playerPos: const GridPos(x: 9, y: 19));
    for (final pos in overlays) {
      expect(world.isWaterCell(pos.x, pos.y), isFalse);
    }
    for (final x in [9, 15]) {
      final cell = semantic.cellAt(284, x, 19);
      expect(semantic.resolveConnectionEntryTile(cell).isPassable, isTrue);
      expect(terrain.resolveTerrainTag(cell), 7);
    }
    for (final name
        in bytes.keys.where((name) => name != 'Data/Scripts.rxdata')) {
      expect(await File('$root/$name').readAsBytes(), bytes[name]);
    }
    expect(await File(scripts).readAsBytes(), bytes['Data/Scripts.rxdata']);
  },
      skip: root == null || scripts == null || profilePath == null
          ? 'Requires explicit local Kanto root, scripts archive and oracle profile.'
          : false);
}
