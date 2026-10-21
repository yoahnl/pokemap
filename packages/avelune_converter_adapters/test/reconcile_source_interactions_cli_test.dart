import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../tool/reconcile_source_interactions.dart' as cli;

void main() {
  test('reconciliation CLI rejects incomplete and relative arguments',
      () async {
    await expectLater(cli.reconcileSourceInteractions([]), throwsArgumentError);
    await expectLater(
      cli.reconcileSourceInteractions([
        'relative.json',
        '/projection.json',
        '/mutations.json',
        '/project',
        '/output',
        'revision',
      ]),
      throwsArgumentError,
    );
  });

  test('reconciliation CLI rejects existing, overlapping and symlink outputs',
      () async {
    final created =
        await Directory.systemTemp.createTemp('reconciliation-guards-');
    final root = Directory(await created.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final project = await Directory('${root.path}/project').create();
    final existing = await Directory('${root.path}/existing').create();
    final alias = Link('${root.path}/alias');
    await alias.create(project.path);
    final inputs = <String>[];
    for (final name in ['inventory', 'projection', 'mutations']) {
      final file = File('${root.path}/$name.json');
      await file.writeAsString(jsonEncode({}));
      inputs.add(file.path);
    }
    for (final destination in [
      existing.path,
      '${project.path}/audit',
      '${alias.path}/audit',
    ]) {
      await expectLater(
          cli.reconcileSourceInteractions([
            ...inputs,
            project.path,
            destination,
            'revision',
          ]),
          throwsStateError);
    }
    expect(await Directory('${project.path}/audit').exists(), isFalse);
    expect(await Directory('${root.path}/audit').exists(), isFalse);
  });

  test('reconciliation CLI refuses unproven input envelopes without publishing',
      () async {
    final created =
        await Directory.systemTemp.createTemp('reconciliation-envelopes-');
    final root = Directory(await created.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final project = await Directory('${root.path}/project').create();
    final inputs = <String>[];
    for (final name in ['inventory', 'projection', 'mutations']) {
      final file = File('${root.path}/$name.json');
      await file.writeAsString(jsonEncode({}));
      inputs.add(file.path);
    }
    final output = '${root.path}/audit';
    await expectLater(
        cli.reconcileSourceInteractions([
          ...inputs,
          project.path,
          output,
          'revision',
        ]),
        throwsStateError);
    expect(await Directory(output).exists(), isFalse);
  });

  test(
      'reconciliation CLI exports a read-only ledger from coherent current inputs',
      () async {
    final fixture = await _fixture();
    addTearDown(() => fixture.root.delete(recursive: true));
    final before = await fixture.projectFiles();
    final summary = await cli.reconcileSourceInteractions(fixture.arguments);
    expect((summary['summary'] as Map)['eventCount'], 1);
    expect(summary['globalPlayabilityCertified'], isFalse);
    final ledger =
        jsonDecode(await File('${fixture.output}/ledger.json').readAsString())
            as Map;
    expect(ledger['kind'], 'sourceInteractionReconciliation');
    expect(((ledger['events'] as List).single as Map)['converterDecision'],
        'quarantinedWholeEvent');
    expect(await fixture.projectFiles(), before);
    expect(await Directory('${fixture.project}/.pokemap').exists(), isFalse);
    final receipt = jsonDecode(
            await File('${fixture.output}/read-receipt.json').readAsString())
        as Map;
    expect(receipt['nativeProjectReobservedUnchanged'], isTrue);
    expect(receipt['nativeMutationCalls'], 0);
    expect(receipt['observedNativeCounts'], containsPair('maps', 1));
    expect(receipt['observedNativeCounts'], containsPair('scenes', 0));
    expect(receipt['observedNativeCounts'],
        containsPair('sourceFidelityCertified', false));
    expect(receipt['inputs'], hasLength(3));
    expect(await File('${fixture.output}/events.csv').readAsString(),
        contains('sourceMapId'));
    expect(await File('${fixture.output}/events.csv').readAsString(),
        contains('selectedExpectedObjectsOnly'));
    expect(await File('${fixture.output}/pages.csv').readAsString(),
        contains('originalPageIndex'));
    expect(await File('${fixture.output}/pages.csv').readAsString(),
        contains('pageNativeCoverageCertified'));
    await expectLater(
        cli.reconcileSourceInteractions(fixture.arguments), throwsStateError);
    expect(await fixture.projectFiles(), before);
  });

  for (final mutation in [
    'revision',
    'snapshot',
    'expanded',
    'draft',
    'mutationRevision'
  ]) {
    test('reconciliation CLI refuses $mutation provenance before publication',
        () async {
      final fixture = await _fixture();
      addTearDown(() => fixture.root.delete(recursive: true));
      final input = File(fixture.arguments[
          mutation == 'expanded' || mutation == 'mutationRevision' ? 2 : 1]);
      final json =
          jsonDecode(await input.readAsString()) as Map<String, Object?>;
      if (mutation == 'revision') json['toolRevision'] = 'old';
      if (mutation == 'snapshot') json['sourceSnapshotHash'] = 'd' * 64;
      if (mutation == 'expanded') json['expanded'] = false;
      if (mutation == 'draft') json['nativeDraftHash'] = 'e' * 64;
      if (mutation == 'mutationRevision') json['toolRevision'] = 'old';
      await input.writeAsString(jsonEncode(json));
      final before = await fixture.projectFiles();
      await expectLater(
          cli.reconcileSourceInteractions(fixture.arguments), throwsStateError);
      expect(await Directory(fixture.output).exists(), isFalse);
      expect(await fixture.projectFiles(), before);
    });
  }

  for (final field in [
    'logicalProjectNamespace',
    'normalizationHash',
    'sourceProfileHash',
    'interpretationProfileHash',
    'preparationHash',
    'sourceProjectionRawSha256'
  ]) {
    test('reconciliation CLI refuses mismatched mutation $field', () async {
      final fixture = await _fixture();
      addTearDown(() => fixture.root.delete(recursive: true));
      final file = File(fixture.arguments[2]);
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      json[field] = field == 'logicalProjectNamespace' ? 'another' : 'f' * 64;
      await file.writeAsString(jsonEncode(json));
      await expectLater(
          cli.reconcileSourceInteractions(fixture.arguments), throwsStateError);
      expect(await Directory(fixture.output).exists(), isFalse);
    });
  }

  for (final state in ['match', 'different', 'missing']) {
    test('reconciliation CLI compares typed entity mutations as $state',
        () async {
      final fixture = await _fixture(withEntity: true);
      addTearDown(() => fixture.root.delete(recursive: true));
      final mapFile = File('${fixture.project}/maps/map.json');
      final map = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      if (state != 'match') {
        await mapFile.writeAsString(jsonEncode(map
            .copyWith(
                entities: state == 'missing'
                    ? []
                    : [map.entities.single.copyWith(name: 'Changed')])
            .toJson()));
      }
      final before = await fixture.projectFiles();
      await cli.reconcileSourceInteractions(fixture.arguments);
      final ledger =
          jsonDecode(await File('${fixture.output}/ledger.json').readAsString())
              as Map;
      final event = (ledger['events'] as List).single as Map;
      expect(event['nativeComparison'], state);
      expect((event['expectedObjects'] as List).single['status'], state);
      expect(await fixture.projectFiles(), before);
    });
  }
}

Future<_Fixture> _fixture({bool withEntity = false}) async {
  final created = await Directory.systemTemp.createTemp('reconciliation-cli-');
  final root = Directory(await created.resolveSymbolicLinks());
  final project = await Directory('${root.path}/project').create();
  await Directory('${project.path}/maps').create();
  const manifest = ProjectManifest(name: 'Native', maps: [
    ProjectMapEntry(id: 'map', name: 'Native', relativePath: 'maps/map.json'),
  ], tilesets: []);
  const entity = MapEntity(
      id: 'actor',
      name: 'Actor',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
      properties: {'sourceEventIdentity': 's1:synthetic-event'});
  final map = MapData(
      id: 'map',
      name: 'Native',
      size: GridSize(width: 3, height: 3),
      layers: [],
      entities: withEntity ? [entity] : []);
  await File('${project.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  await File('${project.path}/maps/map.json')
      .writeAsString(jsonEncode(map.toJson()));
  final snapshot = 'a' * 64, normalization = 'b' * 64, profile = 'c' * 64;
  final inventory = {
    'kind': 'sourceInteractionInventory',
    'schemaVersion': 1,
    'toolRevision': 'revision',
    'logicalProjectNamespace': 'synthetic',
    'sourceSnapshotHash': snapshot,
    'normalizationHash': normalization,
    'analysisProfileHash': profile,
    'mapCount': 1,
    'eventCount': 1,
    'pageCount': 1,
    'events': [
      {
        'sourceIdentity': 's1:synthetic-event',
        'sourceMapId': 1,
        'sourceEventId': 1,
        'locator': {'mapId': 1, 'eventId': 1},
        'pages': [
          {'originalPageIndex': 0}
        ],
      }
    ],
  };
  final projection = {
    'kind': 'rc01CurrentConverterEventProjection',
    'nativeDraftHash': 'd' * 64,
    'preparationHash': 'e' * 64,
    'toolRevision': 'revision',
    'logicalProjectNamespace': 'synthetic',
    'sourceSnapshotHash': snapshot,
    'normalizationHash': normalization,
    'sourceProfileHash': profile,
    'events': [
      {
        'sourceIdentity': 's1:synthetic-event',
        'locator': {'mapId': 1, 'eventId': 1},
        'status': 'quarantinedWholeEvent',
        'gaps': ['unsupportedProof'],
        'pages': [
          {'originalPageIndex': 0}
        ],
      }
    ],
  };
  final mutations = {
    'kind': 'rc01CurrentConverterExpandedEventMutations',
    'toolRevision': 'revision',
    'schemaVersion': 1,
    'expanded': true,
    'sourceSnapshotHash': snapshot,
    'normalizationHash': normalization,
    'sourceProfileHash': profile,
    'logicalProjectNamespace': 'synthetic',
    'nativeDraftHash': 'd' * 64,
    'preparationHash': 'e' * 64,
    'selection': 'sourceOwnerContainsExactProjectedEventIdentity',
    'sourceProjectionRawSha256':
        crypto.sha256.convert(utf8.encode(jsonEncode(projection))).toString(),
    'mutations': [
      if (withEntity)
        {
          'ordinal': 0,
          'operationId': 'operation',
          'actionId': 'entity.upsert',
          'actionVersion': 1,
          'sourceEntityIds': ['s1:synthetic-event'],
          'targetEntityIds': ['map', 'actor'],
          'parameters': {'mapId': 'map', 'entity': entity.toJson()}
        }
    ],
  };
  final inputs = <String>[];
  for (final entry in {
    'inventory': inventory,
    'projection': projection,
    'mutations': mutations
  }.entries) {
    final file = File('${root.path}/${entry.key}.json');
    await file.writeAsString(jsonEncode(entry.value));
    inputs.add(file.path);
  }
  return _Fixture(root, project.path, '${root.path}/audit',
      [...inputs, project.path, '${root.path}/audit', 'revision']);
}

final class _Fixture {
  _Fixture(this.root, this.project, this.output, this.arguments);
  final Directory root;
  final String project;
  final String output;
  final List<String> arguments;
  Future<Map<String, String>> projectFiles() async => {
        for (final name in ['project.json', 'maps/map.json'])
          name: await File('$project/$name').readAsString(),
      };
}
