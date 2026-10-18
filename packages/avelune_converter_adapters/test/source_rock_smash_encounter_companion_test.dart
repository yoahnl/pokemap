import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_evidence.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/source_external_original_fixture.dart';
import 'source_cut_obstacle_projection_test.dart' show cutNativeMaps;

final class _Files implements SourceFilePort {
  const _Files(this.source, this.roots,
      {this.changedPath, this.overrides = const {}});
  final NormalizedSourceProject source;
  final List<String> roots;
  final String? changedPath;
  final Map<String, List<int>> overrides;

  @override
  Future<List<int>> read(ConverterId fileId) async {
    final entry =
        source.snapshot.entries.singleWhere((entry) => entry.fileId == fileId);
    if (overrides[entry.relativePath] case final replacement?) {
      return List.of(replacement);
    }
    for (final root in roots) {
      final file = File('$root/${entry.relativePath}');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (entry.relativePath == changedPath) bytes[bytes.length - 1] ^= 1;
      return bytes;
    }
    throw StateError('Missing explicit source witness: ${entry.relativePath}');
  }
}

void main() {
  final root = Platform.environment['AVELUNE_FIELD_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_FIELD_SOURCE_SNAPSHOT'];
  final scriptsRoot = Platform.environment['AVELUNE_FIELD_SCRIPTS_ROOT'];
  final skip = root == null || snapshot == null || scriptsRoot == null
      ? 'Requires the exact original Kanto inventory and explicit Johto source.'
      : false;
  const mapIds = {
    98: 'native_98',
    154: 'native_154',
    245: 'native_245',
    274: 'native_274'
  };
  group('qualified Rock Smash deferred native encounter companions', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceFilePort files;
    late NativeEncounterCatalogQualification qualification;
    late List<int> scripts;
    late SourceFieldObstacleBindings defaults;
    late SourceFieldObstacleBindings qualified;

    Future<SourceFieldObstacleBindings> resolve({
      NativeEncounterCatalogQualification? release,
      Map<int, String>? targets,
      SourceFilePort? witnesses,
    }) async =>
        (await const SourceFieldObstacleBindingResolver().read(
          source: source,
          analysis: analysis,
          files: witnesses ?? files,
          nativeEncounterQualification: release,
          nativeMapIds: targets,
        ))!;

    setUpAll(() async {
      scripts = await File('$scriptsRoot/Data/Scripts.rxdata').readAsBytes();
      final original = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: mapIds.keys.toSet(),
          overrideBytes: {'Data/Scripts.rxdata': scripts});
      source = original.source;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      files = _Files(source, [root, scriptsRoot!]);
      qualification = NativeEncounterCatalogQualification.builtinKantoV1();
      defaults = await resolve();
      qualified = await resolve(release: qualification, targets: mapIds);
    });

    test('default null retains six objects and six encounter quarantines', () {
      expect(defaults.byEventIdentity, hasLength(6));
      expect(defaults.refusals, hasLength(6));
      expect(defaults.badges, hasLength(3));
      expect(defaults.evidence['pendingCatalogCompanions'], isEmpty);
    });

    test(
        'genuine release binds twelve original objects without granting progress',
        () {
      expect(qualified.byEventIdentity, hasLength(12));
      expect(qualified.refusals, isEmpty);
      expect(qualified.badges, hasLength(3));
      final objects = qualified.byEventIdentity.values.toList();
      expect(
          objects.where((binding) =>
              binding.nativeKind == FieldObstacleKind.rockSmashRock),
          hasLength(7));
      expect(
          objects.where(
              (binding) => binding.nativeKind == FieldObstacleKind.cutTree),
          hasLength(1));
      expect(
          objects.where((binding) =>
              binding.nativeKind == FieldObstacleKind.strengthBoulder),
          hasLength(4));
      expect(objects.where((binding) => binding.pendingCatalogCompanion),
          hasLength(6));
      expect(qualified.evidence['pendingCatalogCompanions'], hasLength(6));
      expect(qualified.evidence['initialPlayerStateMutated'], isFalse);
      expect(
          qualified.mutations.where((mutation) =>
              mutation.actionId.contains('award') ||
              mutation.actionId.contains('unlock') ||
              mutation.actionId.contains('learn') ||
              mutation.actionId.contains('encounter')),
          isEmpty);
    });

    test(
        'companions bind the exact source native table and qualified tuple evidence',
        () async {
      final pbs = await const SourcePbsParser().read(
          snapshot: source.snapshot,
          files: files,
          families: const {
            SourcePbsFamily.encounters,
            SourcePbsFamily.species
          });
      final catalog = await const NativeEncounterCatalogBindings().bind(
          snapshot: source.snapshot,
          source: pbs,
          files: files,
          nativeMapIds: mapIds,
          sourceMapNames: {
            for (final map in source.maps) map.map.sourceMapId: map.map.name
          },
          qualification: qualification,
          ratePolicy: NativeEncounterRatePolicy
              .adaptSourceBasePercentToNativeConstantChance,
          fishingRatePolicy: NativeEncounterFishingRatePolicy
              .adaptSourceBaseFishingBiteChanceToNativeTable);
      final tableId = catalog.tableIdsBySourceMethod[154]!['RockSmash']!;
      final table = catalog.tables.singleWhere((table) => table.id == tableId);
      for (final binding in qualified.byEventIdentity.values
          .where((binding) => binding.pendingCatalogCompanion)) {
        expect(binding.nativeRockSmashEncounterTableId, tableId);
        final proof =
            binding.toJson()['nativeRockSmashEncounterBinding'] as Map;
        expect(proof['nativeMapId'], mapIds[154]);
        expect(proof['nativeTable'], table.toJson());
        expect(proof['nativeTableHash'], canonicalHashOf(table.toJson()).value);
        expect(
            proof['qualificationEvidenceHash'],
            canonicalHashOf(qualification.evidence,
                    limits: nativePsdkCatalogShardJsonLimits)
                .value);
        expect(proof.containsKey('qualification'), isFalse);
        expect(proof['version'], 2);
        expect((proof['tableBinding'] as Map)['method'], 'RockSmash');
        expect(binding.toJson()['nativeExecutionQualified'], isFalse);
        expect(binding.toJson()['pendingCatalogCompanion'], isTrue);
      }
    });

    test('qualified binding rejects missing or changed native map identity',
        () {
      final binding = qualified.byEventIdentity.values
          .firstWhere((binding) => binding.pendingCatalogCompanion);
      final event =
          analysis.eventAt(binding.sourceMapId, binding.sourceEventId)!;
      expect(
          binding.isBoundToEvent(
              source: source, analysis: analysis, event: event),
          isFalse);
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: event,
              nativeMapId: 'foreign'),
          isFalse);
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: analysis,
              event: event,
              nativeMapId: mapIds[154]),
          isTrue);
    });

    test(
        'projection records exact pending typed companions without inline encounters',
        () {
      final projected = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: cutNativeMaps(source),
          fieldObstacleBindings: qualified.byEventIdentity,
          fieldObstacleRefusals: qualified.refusals);
      final objects = projected.nativeMaps.values
          .expand((map) => map.entities)
          .where((entity) => entity.fieldObstacle != null)
          .toList();
      expect(objects, hasLength(12));
      expect(objects.every((entity) => entity.interactiveEncounter == null),
          isTrue);
      expect(
          objects.every(
              (entity) => entity.size == const GridSize(width: 1, height: 1)),
          isTrue);
      final requests =
          (projected.semanticEvidence['pendingCatalogCompanions'] as List)
              .cast<Map>();
      expect(requests, hasLength(6));
      for (final request in requests) {
        expect(request['actionId'], 'entity.set_interactive_encounter');
        final parameters = request['parameters'] as Map;
        expect(parameters['mapId'], mapIds[154]);
        final data = parameters['interactiveEncounter'] as Map;
        expect(data['trigger'], 'afterRockSmash');
        expect(data['reusePolicy'], 'oncePerMapInstance');
        expect(data['encounterTableId'], isNotEmpty);
        expect(
            projected.mutations.where((mutation) =>
                mutation.actionId == 'entity.set_field_obstacle' &&
                mutation.parameters['entityId'] == parameters['entityId']),
            hasLength(1));
      }
      final rows = (projected.semanticEvidence['events'] as List)
          .cast<Map>()
          .where((row) => row['nativeFieldObstacle'] is Map)
          .map((row) => row['nativeFieldObstacle'] as Map)
          .toList();
      expect(rows.where((row) => row['pendingCatalogCompanion'] == true),
          hasLength(6));
      expect(rows.where((row) => row['nativeExecutionQualified'] == false),
          hasLength(6));
      expect(
          projected.mutations.where((mutation) =>
              mutation.actionId.contains('fishing') ||
              mutation.actionId.contains('battle') ||
              mutation.actionId == 'entity.set_interactive_encounter'),
          isEmpty);
    });

    test('projection rejects a qualified companion from another native map',
        () {
      final maps = cutNativeMaps(source);
      maps[154] = maps[154]!.copyWith(id: 'foreign');
      final projected = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: maps,
          fieldObstacleBindings: qualified.byEventIdentity,
          fieldObstacleRefusals: qualified.refusals);
      expect(
          projected.nativeMaps[154]!.entities
              .where((entity) => entity.fieldObstacle != null),
          isEmpty);
      expect(projected.semanticEvidence['pendingCatalogCompanions'], isEmpty);
    });

    test(
        'missing native map mapping preserves required encounters in quarantine',
        () async {
      final result =
          await resolve(release: qualification, targets: {98: 'native_98'});
      expect(result.byEventIdentity, hasLength(6));
      expect(result.refusals, hasLength(6));
      expect(result.evidence['pendingCatalogCompanions'], isEmpty);
    });

    test('duplicate native map identities cannot qualify required encounters',
        () async {
      final result = await resolve(release: qualification, targets: {
        98: 'same',
        154: 'same',
        245: 'native_245',
        274: 'native_274'
      });
      expect(result.byEventIdentity, hasLength(6));
      expect(result.refusals, hasLength(6));
    });

    for (final path in [
      'Data/encounters.dat',
      'PBS/encounters.txt',
      'Data/species.dat',
      'PBS/pokemon.txt'
    ]) {
      test('changed $path bytes reject the exact qualification', () async {
        await expectLater(
            resolve(
                release: qualification,
                targets: mapIds,
                witnesses:
                    _Files(source, [root!, scriptsRoot!], changedPath: path)),
            throwsA(isA<ContractError>().having((error) => error.code, 'code',
                'source.field_obstacle.source_changed')));
      });
    }

    Future<SourceFieldObstacleBindings> resolveVariant(
        Map<String, List<int>> overrides) async {
      final variant = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: mapIds.keys.toSet(),
          overrideBytes: {'Data/Scripts.rxdata': scripts, ...overrides});
      final analyzed = SourceEventAnalyzer.forProject(variant.source,
              profile: SourceEventProfile.kantoForProject(variant.source))
          .analyze();
      return (await const SourceFieldObstacleBindingResolver().read(
          source: variant.source,
          analysis: analyzed,
          files: _Files(variant.source, [root, scriptsRoot!],
              overrides: {'Data/Scripts.rxdata': scripts, ...overrides}),
          nativeEncounterQualification: qualification,
          nativeMapIds: mapIds))!;
    }

    test(
        'empty and invalid PBS cannot turn compiled required tables into absence',
        () async {
      for (final bytes in [
        <int>[],
        'invalid encounter source'.codeUnits,
        '[154]\nRockSmash,11\n'.codeUnits
      ]) {
        final result = await resolveVariant({'PBS/encounters.txt': bytes});
        expect(
            result.byEventIdentity.values.where((binding) =>
                binding.sourceMapId == 154 &&
                binding.nativeKind == FieldObstacleKind.rockSmashRock),
            isEmpty);
        expect(
            (result.evidence['rockSmashEncounters'] as List).cast<Map>().where(
                (row) =>
                    row['sourceMapId'] == 154 && row['status'] == 'absent'),
            isEmpty);
        expect(result.evidence['pendingCatalogCompanions'], isEmpty);
      }
    });

    test('invalid compiled data refuses Smash even with the genuine release',
        () async {
      final result = await resolveVariant({
        'Data/encounters.dat': [4, 8, 48]
      });
      expect(
          result.byEventIdentity.values.where((binding) =>
              binding.nativeKind == FieldObstacleKind.rockSmashRock),
          isEmpty);
      expect(result.evidence['rockSmashEncounters'], isEmpty);
      expect(result.evidence['pendingCatalogCompanions'], isEmpty);
    });

    test(
        'missing PBS witness refuses every Smash and cannot reuse source proof',
        () async {
      final admitted = source.snapshot;
      final missing = SourceSnapshot(
          logicalProjectNamespace: admitted.logicalProjectNamespace,
          policyHash: admitted.policyHash,
          entries: admitted.entries
              .where((entry) => entry.relativePath != 'PBS/encounters.txt')
              .toList(),
          diagnostics: admitted.diagnostics,
          excludedPaths: admitted.excludedPaths,
          profileEvidence: admitted.profileEvidence,
          state: admitted.state);
      final normalized = await const RmxpSourceNormalizer().normalize(
          snapshot: missing,
          files: ExternalOriginalFiles(missing, root!,
              overrideBytes: {'Data/Scripts.rxdata': scripts}),
          selectedMapIds: mapIds.keys.toSet(),
          includeEventSystem: true);
      final analyzed = SourceEventAnalyzer.forProject(normalized,
              profile: SourceEventProfile.kantoForProject(normalized))
          .analyze();
      final result = (await const SourceFieldObstacleBindingResolver().read(
          source: normalized,
          analysis: analyzed,
          files: _Files(normalized, [root, scriptsRoot!]),
          nativeEncounterQualification: qualification,
          nativeMapIds: mapIds))!;
      expect(
          result.byEventIdentity.values.where((binding) =>
              binding.nativeKind == FieldObstacleKind.rockSmashRock),
          isEmpty);
      expect(result.evidence['rockSmashEncounters'], isEmpty);
      expect(result.evidence['pendingCatalogCompanions'], isEmpty);
      final binding = qualified.byEventIdentity.values
          .firstWhere((binding) => binding.pendingCatalogCompanion);
      expect(
          binding.isBoundToEvent(
              source: normalized,
              analysis: analyzed,
              event:
                  analyzed.eventAt(binding.sourceMapId, binding.sourceEventId)!,
              nativeMapId: mapIds[154]),
          isFalse);
    });

    test('a foreign analysis owner cannot reuse a qualified companion', () {
      final binding = qualified.byEventIdentity.values
          .firstWhere((binding) => binding.pendingCatalogCompanion);
      final event =
          analysis.eventAt(binding.sourceMapId, binding.sourceEventId)!;
      final foreign = SourceEventAnalysis(
          profile: analysis.profile,
          events: analysis.events,
          diagnostics: analysis.diagnostics);
      expect(
          binding.isBoundToEvent(
              source: source,
              analysis: foreign,
              event: event,
              nativeMapId: mapIds[154]),
          isFalse);
    });

    test('exposed proof mutations cannot change a private companion identity',
        () {
      final binding = qualified.byEventIdentity.values
          .firstWhere((binding) => binding.pendingCatalogCompanion);
      final proof = binding.toJson()['nativeRockSmashEncounterBinding'] as Map;
      (proof['nativeTable'] as Map)['id'] = 'forged';
      proof['qualificationEvidenceHash'] = 'forged';
      final next = binding.toJson()['nativeRockSmashEncounterBinding'] as Map;
      expect((next['nativeTable'] as Map)['id'],
          binding.nativeRockSmashEncounterTableId);
      expect(
          next['qualificationEvidenceHash'],
          canonicalHashOf(qualification.evidence,
                  limits: nativePsdkCatalogShardJsonLimits)
              .value);
    });

    test('84 distinct companion owners pack without copied world qualification',
        () async {
      final worldFiles = _Files(source,
          [root!, scriptsRoot!, root.replaceFirst(' - Kanto', ' - Hoenn')]);
      final pbs = await const SourcePbsParser()
          .read(snapshot: source.snapshot, files: worldFiles);
      final allMaps = source.snapshot.entries
          .where((entry) =>
              RegExp(r'^Data/Map\d+\.rxdata$').hasMatch(entry.relativePath))
          .map((entry) => int.parse(
              RegExp(r'Map(\d+)').firstMatch(entry.relativePath)!.group(1)!))
          .toList();
      final world = await NativeEncounterCatalogQualification.prepare(
          snapshot: source.snapshot,
          source: pbs,
          files: worldFiles,
          nativeCatalog: NativePsdkCatalogManifest.builtin(),
          selectedSourceMapIds: allMaps);
      expect(world.sourceMappings.length, greaterThan(100));
      expect(world.wildCases.length, greaterThan(1000));
      final fields =
          await resolve(release: world, targets: mapIds, witnesses: worldFiles);
      final originals = fields.byEventIdentity.values
          .where((binding) => binding.pendingCatalogCompanion)
          .toList();
      expect(originals, isNotEmpty);
      final requests = [
        for (var i = 0; i < 84; i++)
          originals[i % originals.length]
              .catalogCompanionRequest('native-owner-$i')!
      ];
      expect(
          requests
              .map((request) => (request['parameters'] as Map)['entityId'])
              .toSet(),
          hasLength(84));
      for (final request in requests) {
        final proof = ((request['binding']
            as Map)['nativeRockSmashEncounterBinding'] as Map);
        expect(
            proof['qualificationEvidenceHash'],
            canonicalHashOf(world.evidence,
                    limits: nativePsdkCatalogShardJsonLimits)
                .value);
        expect(proof.containsKey('qualification'), isFalse);
      }
      final payload = <String, Object?>{
        'fieldObstacles': [for (final request in requests) request['binding']],
        'fieldObstacleBindings': [
          for (final request in requests) request['binding']
        ],
        'pendingCatalogCompanions': requests,
      };
      final limits = sourceCatalogStudyWriteLimitsFor(allMaps.length);
      final packed = SourceEventEvidenceArtifacts.pack(payload, limits: limits);
      final packedRoot = jsonDecode(utf8.decode(packed.root.bytes)) as Map;
      final restored = packedRoot['kind'] == 'sourceEventProjectionChunks'
          ? utf8.decode([
                  for (final descriptor in packedRoot['chunks'] as List)
                ...base64Decode((jsonDecode(utf8.decode(packed.chunks
                    .singleWhere(
                        (chunk) => chunk.handle == descriptor['artifactHandle'])
                    .bytes)) as Map)['bytesBase64'] as String)
            ])
          : utf8.decode(packed.root.bytes);
      expect(restored,
          canonicalJsonOf(payload, limits: limits.artifactEvidenceJsonLimits));
    }, timeout: const Timeout(Duration(minutes: 3)));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
