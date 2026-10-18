import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

const _zone = MapGameplayZone(
    id: 'native-walk-zone',
    kind: GameplayZoneKind.movement,
    area: MapRect(
        pos: GridPos(x: 1, y: 0), size: GridSize(width: 1, height: 1)),
    movement: MovementZonePayload(requiredMode: MovementMode.walk));

Map<String, dynamic> _json(MapData map) =>
    jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>;

NativeProjectDraft _withMap(NativeProjectDraft draft, MapData map) =>
    copyNativeFixtureDraft(draft, mutations: [
      for (final mutation in draft.mutations)
        if (mutation.actionId == 'map.save')
          copyNativeFixtureMutation(mutation,
              parameters: {...mutation.parameters, 'map': _json(map)})
        else
          mutation
    ]);

void main() {
  test('execution context binds native rectangular zones and rejects changes',
      () async {
    final fixture = await LiteralTileFixture.create();
    final map = MapData(
        id: 'native-map',
        name: 'Native geometry',
        size: const GridSize(width: 3, height: 1),
        layers: [],
        gameplayZones: const [_zone]);
    final profile = SourceEventProfile.kantoForProject(fixture.source);
    final resolver = const SourceEventExecutionContextResolver();
    final context = await resolver.read(
        source: fixture.source,
        base: null,
        nativeMaps: {1: map},
        files: fixture.files);
    expect(context.isQualified, isFalse);
    expect(context.isBoundTo(fixture.source, profile, {1: map}), isTrue);
    final roundTrip = MapData.fromJson(_json(map));
    expect(context.isBoundTo(fixture.source, profile, {1: roundTrip}), isTrue);
    final rebound = await resolver.read(
        source: fixture.source,
        base: null,
        nativeMaps: {1: roundTrip},
        files: fixture.files);
    expect(context.sharesNativeBindingWith(rebound), isTrue);
    for (final changed in [
      map.copyWith(id: 'another-native-map'),
      map.copyWith(size: const GridSize(width: 4, height: 1)),
      map.copyWith(gameplayZones: []),
      map.copyWith(gameplayZones: [
        _zone.copyWith(
            area: _zone.area.copyWith(pos: const GridPos(x: 0, y: 0)))
      ]),
      map.copyWith(gameplayZones: [
        _zone.copyWith(
            area: _zone.area.copyWith(
                size: const GridSize(width: 2, height: 1)))
      ]),
      map.copyWith(gameplayZones: [_zone.copyWith(id: 'another-zone')]),
    ]) {
      expect(context.isBoundTo(fixture.source, profile, {1: changed}), isFalse);
      final changedContext = await resolver.read(
          source: fixture.source,
          base: null,
          nativeMaps: {1: changed},
          files: fixture.files);
      expect(context.sharesNativeBindingWith(changedContext), isFalse);
    }
    expect(context.isBoundTo(fixture.source, profile, {8: map}), isFalse);
    expect(context.isBoundTo(fixture.source, profile, {}), isFalse);
  });

  test('native writer saves and reloads rectangular gameplay geometry', () async {
    final root = await Directory.systemTemp.createTemp('native-map-geometry-');
    addTearDown(() => root.delete(recursive: true));
    final fixture = await NativeWriterFixture.create(root.path);
    final map = fixture.expectedMap.copyWith(gameplayZones: const [_zone]);
    final draft = _withMap(fixture.draft, map);
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await const NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    expect(receipt.verified, isTrue);
    final manifest = jsonDecode(
        await File('${receipt.projectPath}/project.json').readAsString()) as Map;
    final relative = (manifest['maps'] as List).single['relativePath'];
    final saved = MapData.fromJson(jsonDecode(
        await File('${receipt.projectPath}/$relative').readAsString()));
    expect(saved, map);
    expect(saved.gameplayZones.single.area.pos, const GridPos(x: 1, y: 0));
    expect(receipt.mapHashes, hasLength(1));
  });

  test('literal provenance refuses unapproved rectangular zones before staging',
      () async {
    final root = await Directory.systemTemp.createTemp('literal-map-geometry-');
    addTearDown(() => root.delete(recursive: true));
    final fixture = await LiteralTileFixture.create();
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Native geometry',
        parentPath: root.path,
        folderName: 'native');
    final changed = literal.nativeMaps[1]!
        .copyWith(gameplayZones: const [_zone]);
    final draft = _withMap(literal.draft!, changed);
    final approval = approveNativeFixtureDraft(draft);
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(approval.plan, approval.context, draft),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.composition.contents')));
    expect(stages, isEmpty);
    expect(await root.list().toList(), isEmpty);
  });

  final sourceRoot = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshotPath = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test('attested door transfer contexts bind native rectangular zones', () async {
    final fixture = await readExternalOriginalSource(sourceRoot!, snapshotPath!,
        selectedMapIds: {6, 7},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final source = fixture.source;
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.kantoForProject(source))
        .analyze();
    final maps = {
      for (final entry in source.maps)
        entry.map.sourceMapId: MapData(
            id: 'native-map-${entry.map.sourceMapId}',
            name: entry.map.name,
            size: GridSize(width: entry.map.width, height: entry.map.height),
            layers: [],
            gameplayZones: const [_zone])
    };
    final base = NativeProjectDraft(
        source: source,
        projectName: 'Attested doors with native zones',
        parentPath: Directory.systemTemp.path,
        folderName: 'attested-door-native-zones',
        mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
        artifacts: [],
        mutations: [
          for (final entry in maps.entries)
            NativeMutation(
                operationId: ConverterId('map-${entry.key}'),
                actionId: 'map.save',
                sourceEntityIds: [source.mapIdentity(entry.key)],
                targetEntityIds: [ConverterId(entry.value.id)],
                parameters: {'map': _json(entry.value)})
        ]);
    final programs = sourceStaticDoorPrograms(source: source, analysis: analysis);
    final contexts = await const SourceEventExecutionContextResolver()
        .readStaticTransfers(
            source: source,
            base: base,
            nativeMaps: maps,
            files: fixture.files,
            programs: programs,
            analysis: analysis);
    final door = analysis.eventAt(7, 1)!;
    final context = contexts[door.identity]!;
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
    expect(context.isBoundTo(source, analysis.profile, maps), isTrue);
    final changed = {
      ...maps,
      7: maps[7]!.copyWith(gameplayZones: [
        _zone.copyWith(
            area: _zone.area.copyWith(pos: const GridPos(x: 0, y: 0)))
      ])
    };
    expect(context.isBoundTo(source, analysis.profile, changed), isFalse);
  }, skip: sourceRoot == null || snapshotPath == null);
}
