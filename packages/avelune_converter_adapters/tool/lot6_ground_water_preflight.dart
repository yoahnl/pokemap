import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_encounter_terrain_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Provide an unused absolute evidence directory.');
  }
  const evidenceParent = '/Users/karim/Project/avelune project/Inventaires/Kanto EV-10/lot6';
  final evidence = Directory(arguments.single);
  if (!evidence.isAbsolute || path.dirname(evidence.path) != evidenceParent ||
      path.normalize(evidence.path) != evidence.path ||
      await Directory(evidenceParent).resolveSymbolicLinks() != evidenceParent ||
      await FileSystemEntity.type(evidence.path, followLinks: false) != FileSystemEntityType.notFound) {
    throw ArgumentError('Evidence must be an unused child of the canonical lot6 directory.');
  }
  await evidence.create();
  final watch = Stopwatch()..start();
  final cancellation = ScanCancellation();
  final termination = ProcessSignal.sigterm.watch().listen((_) => cancellation.cancel());
  final result = <String, Object?>{
    'kind': 'sourceGroundWaterConnectionPreflightOnly',
    'scope': 'sourceGroundCollisionCanonicalDirectionalWallsWaterAndConnections',
    'finalPreparedDraftCertified': false,
    'finalNativeProjectCertified': false,
    'directedJumpBorderReplayIncluded': false,
    'sourceEventProjectionIncluded': false,
    'publicationPerformed': false,
    'sourceScriptsExecuted': 0,
    'aiSourceInferenceCalls': 0,
    'expectedMapCount': 383,
    'expectedConnectionCount': 131,
    'expectedArrivalCount': 8594,
    'expectedSourceAllowedNativeSurfCount': 0,
    'passed': false,
  };
  void phase(String name) {
    result['phase'] = name;
    stdout.writeln(jsonEncode({'phase': name, 'elapsedMs': watch.elapsedMilliseconds}));
  }
  SupplementedSourceTree? tree;
  try {
    const sourceRoot = '/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto';
    const inventoryRoot = '/Users/karim/Project/avelune project/Inventaires';
    final decisions = jsonDecode(await File('$inventoryRoot/Kanto EV-09/preuves/source_adaptations.json').readAsString()) as Map;
    final rawProfile = Map<String, Object?>.from(jsonDecode(await File(
        '$inventoryRoot/Kanto EV-10/source_profile_ev10_pickups.json').readAsString()) as Map);
    final profile = SourceInterpretationProfile.fromJson({
      ...rawProfile,
      'profileId': 'kanto-lot6-native-services-and-inline-audio',
      'sections': {
        ...rawProfile['sections'] as Map,
        'events.Audio_Play': {
          'index': 93, 'name': 'Audio_Play',
          'sha256': 'e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb',
        },
      },
    });
    if (profile.canonicalHash.value != '5f1a29b54188c97cd68d403a8fe586d3518644f09a0f5caff4fb7f0b4d692bf2') {
      throw StateError('The interpretation profile differs from full-conversion-03.');
    }
    result['interpretationProfile'] = profile.toJson();
    result['interpretationProfileHash'] = profile.canonicalHash.value;
    tree = await SupplementedSourceTree.open(sourceRoot, supplementalRootPaths: [
      sourceRoot.replaceFirst(' - Kanto', ' - Johto'),
      sourceRoot.replaceFirst(' - Kanto', ' - Hoenn'),
    ]);
    phase('scanSource');
    final snapshot = await SourceScanner().scan(source: tree,
        logicalProjectNamespace: ConverterId('ev09-real-source-defects'), cancellation: cancellation);
    if (snapshot.state != SourceScanState.complete ||
        snapshot.canonicalHash.value != decisions['snapshotHash'] ||
        snapshot.canonicalHash.value != '2271d628549b1900a3d2f076fb5a0b062fbaf824973684f3d30501d785c254ac') {
      throw StateError('The complete source inventory must match the full conversion.');
    }
    result['sourceSnapshotHash'] = snapshot.canonicalHash.value;
    result['profileEvidenceHash'] = snapshot.profile.evidenceHash.value;
    result['sourceRootPath'] = tree.rootPath;
    result['supplementalRootPaths'] = tree.supplementalRootPaths;
    final files = await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot, cancellation: cancellation);
    final ids = snapshot.entries.map((entry) => RegExp(r'^Data/Map(\d+)\.rxdata$')
        .firstMatch(entry.relativePath)).whereType<RegExpMatch>()
        .map((match) => int.parse(match.group(1)!)).toList()..sort();
    if (ids.length != 383) throw StateError('Expected exactly 383 source maps.');
    phase('normalizeSource');
    final source = await const RmxpSourceNormalizer().normalize(snapshot: snapshot,
        files: files, selectedMapIds: ids.toSet(), includeEventSystem: true,
        includeConnections: true, interpretationProfile: profile, cancellation: cancellation,
        sourceAdaptations: (decisions['decisions'] as List).map(SourceEventAdaptation.fromJson).toList(),
        missingItemBindings: (decisions['missingItemBindings'] as List).map(SourceMissingItemBinding.fromJson).toList());
    result['normalizationHash'] = source.canonicalHash.value;
    if (source.canonicalHash.value != '6e6ba0ffffa3d13c6afdf84fd202169f72a875eb0082d08cc5ec69b9764a582f') {
      throw StateError('The normalized source differs from full-conversion-03.');
    }
    final dynamicCommand = source.maps.singleWhere((map) => map.map.sourceMapId == 295).map.events
        .singleWhere((event) => event.sourceEventId == 12).pages
        .singleWhere((page) => page.originalPageIndex == 1).commands
        .singleWhere((command) => command.originalIndex == 17);
    if (dynamicCommand.code != 201 || dynamicCommand.parameters.first != 1) {
      throw StateError('The excluded dynamic transfer differs from its source command.');
    }
    result['dependencyDecision'] = LiteralDependencyDecision(
        sourceSnapshotHash: snapshot.canonicalHash,
        selectionHash: canonicalHashOf({'kind': 'literalSelection', 'version': 1,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
          'selectedSourceMapIds': ids}),
        locator: SourceLocator.fromJson({'file': 'Data/Map295.rxdata', 'mapId': 295,
          'eventId': 12, 'pageIndex': 1, 'commandIndex': 17,
          'tileId': null, 'line': null}),
        targetSourceMapId: null, decision: LiteralDependencyDisposition.excludeStudy).toJson();
    result['dynamicTransferSource'] = dynamicCommand.toJson();
    final resolver = SourceSemanticResolver.forProject(source);
    if (!resolver.profile.isQualified) throw StateError('Source passage profile is unqualified.');
    final nativeIds = {for (final id in ids) id: 'ground-water-map-$id'};
    phase('bindTerrain');
    final terrain = const SourceEncounterTerrainBinding().bind(source: source,
        nativeMapIds: nativeIds, tableIdsBySourceMethod: const {},
        expectedSourceSelectionHash: source.canonicalHash);
    final maps = <int, MapData>{};
    final masks = <int>{};
    var unqualifiedTransitions = 0;
    var wallPlacements = 0;
    phase('projectCollision');
    for (final original in source.maps) {
      cancellation.check();
      final map = original.map;
      final size = GridSize(width: map.width, height: map.height);
      final collision = SourceCollisionProjection.resolve(cells: [
        for (var y = 0; y < map.height; y++)
          for (var x = 0; x < map.width; x++) resolver.cellAt(map.sourceMapId, x, y),
      ], resolver: resolver, mapSize: size, includeNativeSurfTraversal: true);
      unqualifiedTransitions += collision.unqualifiedTransitionCount;
      final wallLayer = 'walls-${map.sourceMapId}';
      masks.addAll(collision.wallMasksByCell.values);
      wallPlacements += collision.wallMasksByCell.length;
      maps[map.sourceMapId] = MapData(id: nativeIds[map.sourceMapId]!, name: map.name,
          size: size, layers: [
            MapLayer.collision(id: 'collision-${map.sourceMapId}', name: 'Source passages',
                collisions: collision.fullyBlockedCells),
            if (collision.wallMasksByCell.isNotEmpty)
              MapLayer.tile(id: wallLayer, name: 'Source boundaries', cells: List.filled(map.width * map.height, 0)),
          ], placedElements: [
            for (final entry in collision.wallMasksByCell.entries)
              MapPlacedElement(id: 'wall-${map.sourceMapId}-${entry.key}',
                  layerId: wallLayer, elementId: 'ground-water-wall-${entry.value}',
                  pos: GridPos(x: entry.key % map.width, y: entry.key ~/ map.width),
                  properties: const {pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored}),
          ], gameplayZones: terrain.zonesBySourceMapId[map.sourceMapId]!);
    }
    final limits = sourceCatalogStudyWriteLimitsFor(383, includeNativeCatalog: true);
    phase('composeConnections');
    final connections = await const SourceConnectionStudyComposer().compose(source: source,
        nativeMaps: maps, files: files, limits: limits, cancellation: cancellation);
    final finalMaps = connections.nativeMaps;
    final manifest = ProjectManifest(name: 'Source ground water preflight only',
        maps: [for (final entry in finalMaps.entries) ProjectMapEntry(id: entry.value.id,
          name: entry.value.name, relativePath: 'maps/${entry.value.id}.json')],
        tilesets: [const ProjectTilesetEntry(id: 'ground-water-boundaries', name: 'Collision metadata only',
          relativePath: 'assets/collision-metadata-only.png',
          source: ProjectRegularAtlasTilesetSource(assetId: 'collision-metadata-only',
            pixelWidth: 32, pixelHeight: 32, tileWidth: 32, tileHeight: 32))],
        elementCategories: const [ProjectElementCategory(id: 'ground-water-boundaries', name: 'Source boundaries')],
        elements: [for (final mask in masks) ProjectElementEntry(id: 'ground-water-wall-$mask',
          name: 'Source boundary $mask', categoryId: 'ground-water-boundaries', tilesetId: 'ground-water-boundaries',
          frames: const [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
          collisionProfile: ElementCollisionProfile(source: ElementCollisionProfileSource.manual,
            collisionMask: sourceBoundaryCollisionMask(mask)))],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
        pokemon: const ProjectPokemonConfig(enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    final admittedIds = connections.mutations.expand((mutation) => mutation.sourceEntityIds).toSet();
    final arrivals = [for (final connection in source.connections)
      if (admittedIds.contains(connection.identity)) ...sourceConnectionArrivals(
        source: source, connection: connection, nativeMaps: finalMaps, cancellation: cancellation)];
    bool water(int mapId, GridPos position) => finalMaps[mapId]!.gameplayZones.any((zone) =>
        zone.kind == GameplayZoneKind.movement && zone.movement?.requiredMode == MovementMode.surf &&
        position.x >= zone.area.pos.x && position.y >= zone.area.pos.y &&
        position.x < zone.area.pos.x + zone.area.size.width && position.y < zone.area.pos.y + zone.area.size.height);
    final contradictions = [for (final arrival in arrivals)
      if (arrival.passage.isPassable == true && water(arrival.targetSourceMapId, arrival.targetPosition)) {
        'sourceMapId': arrival.targetSourceMapId, 'position': arrival.targetPosition.toJson(),
        'sourceEntryStatus': arrival.passage.status.name, 'nativeRequiresSurf': true,
      }];
    result.addAll({'mapCount': finalMaps.length, 'connectionCount': connections.mutations.length,
      'arrivalCount': arrivals.length, 'sourceAllowedNativeSurfCount': contradictions.length,
      'sourceAllowedNativeSurfExamples': contradictions.take(64).toList(),
      'directionalWallPlacements': wallPlacements, 'unqualifiedTransitionCount': unqualifiedTransitions,
      'connectionDiagnostics': connections.evidence['diagnostics'],
      'pierCells': [for (final position in [const GridPos(x: 9, y: 19), const GridPos(x: 15, y: 19)]) {
        'sourceMapId': 284, 'position': position.toJson(),
        'stack': resolver.cellAt(284, position.x, position.y).stack.map((tile) => tile.toJson()).toList(),
        'sourceEntryStatus': resolver.resolveConnectionEntryTile(resolver.cellAt(284, position.x, position.y)).status.name,
        'nativeRequiresSurf': water(284, position),
      }]});
    if (finalMaps.length != 383 || connections.mutations.length != 131 || arrivals.length != 8594 || contradictions.isNotEmpty) {
      throw StateError('The full connection census or water contradiction check differs from its expected scope.');
    }
    phase('validateConnections');
    const SourceEventArrivalValidator().validateConnections(manifest: manifest,
        maps: finalMaps.values.toList(), source: source,
        connectionMutations: connections.mutations, cancellation: cancellation);
    phase('verifySource');
    await files.verifyUnchanged();
    result.addAll({'sourceUnchanged': true, 'arrivalValidatorPassed': true, 'passed': true});
    phase('complete');
  } catch (error) {
    result.addAll({'failure': error.toString(),
      if (error is NativeWriteException) 'failureCode': error.code});
    rethrow;
  } finally {
    result['elapsedMs'] = watch.elapsedMilliseconds;
    result['evidenceHash'] = canonicalHashOf(result,
        limits: sourceCatalogStudyWriteLimitsFor(383, includeNativeCatalog: true).draftEvidenceJsonLimits).value;
    await File(path.join(evidence.path, 'ground-water-preflight.json'))
        .writeAsString(jsonEncode(result), flush: true);
    await tree?.close();
    await termination.cancel();
  }
}
