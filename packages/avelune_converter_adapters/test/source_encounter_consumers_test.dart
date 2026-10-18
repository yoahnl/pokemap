import 'support/native_encounter_qualification_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_encounter_consumers.dart';
import 'package:avelune_converter_adapters/src/source_encounter_terrain_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/source_external_original_fixture.dart';
import 'source_cut_obstacle_projection_test.dart' show cutNativeMaps;

final class _Files implements SourceFilePort {
  const _Files(this.source, this.roots);
  final NormalizedSourceProject source;
  final List<String> roots;
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = source.snapshot.entries.singleWhere((e) => e.fileId == id);
    for (final root in roots) {
      final file = File('$root/${entry.relativePath}');
      if (await file.exists()) return file.readAsBytes();
    }
    throw StateError('Missing inventoried source witness');
  }
}

void main() {
  final root = Platform.environment['AVELUNE_FIELD_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_FIELD_SOURCE_SNAPSHOT'];
  final scriptsRoot = Platform.environment['AVELUNE_FIELD_SCRIPTS_ROOT'];
  final skip = root == null || snapshot == null || scriptsRoot == null;
  const ids = {
    98: 'native_98',
    154: 'native_154',
    245: 'native_245',
    274: 'native_274'
  };
  late NormalizedSourceProject source;
  late NativeEncounterCatalogQualification qualification;
  late NativeEncounterCatalogBindingResult catalog;
  late List<Object?> pending;
  late List<NativeMutation> prefix;

  setUpAll(() async {
    if (skip) return;
    final original = await readExternalOriginalSource(root, snapshot,
        selectedMapIds: ids.keys.toSet(),
        overrideBytes: {
          'Data/Scripts.rxdata':
              await File('$scriptsRoot/Data/Scripts.rxdata').readAsBytes()
        });
    source = original.source;
    final files = _Files(source, [root, scriptsRoot]);
    qualification = await qualifyFixtureEncounterSource(source: source, files: files, selectedSourceMapIds: ids.keys);
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final fields = (await const SourceFieldObstacleBindingResolver().read(
        source: source,
        analysis: analysis,
        files: files,
        nativeEncounterQualification: qualification,
        nativeMapIds: ids))!;
    final projected = const SourceEventProjector().project(
        source: source,
        analysis: analysis,
        nativeMaps: cutNativeMaps(source),
        fieldObstacleBindings: fields.byEventIdentity,
        fieldObstacleRefusals: fields.refusals);
    pending = List<Object?>.from(
        projected.semanticEvidence['pendingCatalogCompanions'] as List);
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot,
        files: files,
        families: const {SourcePbsFamily.species, SourcePbsFamily.encounters});
    catalog = await const NativeEncounterCatalogBindings().bind(
        interpretationProfile: source.interpretationProfile,
        snapshot: source.snapshot,
        source: pbs,
        files: files,
        nativeMapIds: ids,
        qualification: qualification,
        sourceMapNames: {
          for (final m in source.maps) m.map.sourceMapId: m.map.name
        },
        ratePolicy: NativeEncounterRatePolicy
            .adaptSourceBasePercentToNativeConstantChance,
        fishingRatePolicy: NativeEncounterFishingRatePolicy
            .adaptSourceBaseFishingBiteChanceToNativeTable);
    final terrain = const SourceEncounterTerrainBinding().bind(
        source: source, nativeMapIds: ids, tableIdsBySourceMethod: const {});
    prefix = [
      ...projected.mutations,
      for (final entry in terrain.zonesBySourceMapId.entries)
        for (final zone in entry.value)
          NativeMutation(
              operationId: ConverterId('surf_${zone.id}'),
              actionId: 'gameplay_zone.create',
              sourceEntityIds: const [],
              targetEntityIds: [
                ConverterId(ids[entry.key]!),
                ConverterId(zone.id)
              ],
              parameters: {
                'mapId': ids[entry.key],
                'zone': jsonDecode(jsonEncode(zone.toJson()))
              })
    ];
  });

  SourceEncounterConsumers bind(
          {List<Object?>? requests, List<NativeMutation>? mutations}) =>
      SourceEncounterConsumers.bind(
          source: source,
          nativeMapIds: ids,
          tables: catalog.tables,
          catalogEvidence: catalog.evidence,
          qualification: qualification,
          pendingCompanions: requests ?? pending,
          precedingMutations: mutations ?? prefix);

  test('binds eleven real tables to exact terrain and six original rocks', () {
    final result = bind();
    expect(catalog.tables, hasLength(11));
    expect(result.companions, hasLength(6));
    final zones = result.zones.values.expand((z) => z).toList();
    expect(zones, hasLength(10));
    expect(result.zones[245], isEmpty);
    expect(zones.every((z) => z.kind == GameplayZoneKind.encounter), isTrue);
    expect(zones.every((z) => z.cellMask?.isNotEmpty == true), isTrue);
    expect(result.zones[98]!.single.cellMask, hasLength(67));
    expect(
        result.zones[274]!
            .every((z) => z.encounter!.encounterKind != EncounterKind.walk),
        isTrue);
    expect(result.evidence['sourceCadenceParityQualified'], isFalse);
    expect(result.evidence['playableCertified'], isFalse);
  }, skip: skip);

  test('refuses encounter publication without preceding typed Surf zones', () {
    expect(
        () => bind(
            mutations: prefix
                .where((m) => m.actionId != 'gameplay_zone.create')
                .toList()),
        throwsA(isA<NativeWriteException>().having(
            (e) => e.code, 'code', 'encounter_consumers.movement_missing')));
  }, skip: skip);

  test('refuses deferred encounters without their original obstacle action',
      () {
    expect(
        () => bind(
            mutations: prefix
                .where((m) => m.actionId != 'entity.set_field_obstacle')
                .toList()),
        throwsA(isA<NativeWriteException>().having(
            (e) => e.code, 'code', 'encounter_consumers.companion_owner')));
  }, skip: skip);

  for (final changed in [
    'table',
    'map',
    'normalization',
    'parameters',
    'qualificationHash',
    'qualificationVersion',
    'sourcePbsHash',
    'duplicate'
  ]) {
    test('refuses substituted companion $changed', () {
      final rows = (jsonDecode(jsonEncode(pending)) as List).cast<Object?>();
      final row = rows.first as Map;
      final proof =
          (row['binding'] as Map)['nativeRockSmashEncounterBinding'] as Map;
      switch (changed) {
        case 'table':
          proof['nativeTableHash'] = '0' * 64;
        case 'map':
          proof['nativeMapId'] = 'foreign';
        case 'normalization':
          proof['normalizationHash'] = '0' * 64;
        case 'parameters':
          (row['parameters'] as Map)['interactiveEncounter'] = null;
        case 'qualificationHash':
          proof['qualificationEvidenceHash'] = '0' * 64;
        case 'qualificationVersion':
          proof['version'] = 1;
        case 'sourcePbsHash':
          proof['sourcePbsHash'] = '0' * 64;
        case 'duplicate':
          rows.add(row);
      }
      expect(() => bind(requests: rows), throwsA(isA<NativeWriteException>()));
    }, skip: skip);
  }
}
