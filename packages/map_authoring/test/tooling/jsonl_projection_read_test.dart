import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL describes the canonical projection command', () async {
    final fixture = await _ProjectionFixture.create();
    addTearDown(fixture.dispose);
    final described = await fixture.success('describe', {});
    expect(
        (described['commands'] as List).cast<Map>().map((item) => item['id']),
        contains('projection'));
    expect(defaultAuthoringJsonlMaxInputBytes, 1024 * 1024);
    expect(const AuthoringSecurityLimits().maxTouchedResources, 500);
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'direct facade';
    test('$transport reconstructs an ordered two-page diff and UTF8 payload',
        () async {
      final fixture = await _ProjectionFixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.manifest.readAsBytes();
      final planned = await fixture.plan('map.delete_apply', {'mapId': 'map'},
          requestId: _largeRequestId);
      final projected = planned.toJson();
      final receipt = _object(projected['receipt']);
      final summary = _object(receipt['diff']);
      expect(summary['entryCount'], 2);
      final pages = await fixture.diff(summary, wire: wire, limit: 1);
      expect(pages, planned.receipt.diff.toJson()['entries']);
      expect(summary['fullDiffFingerprint'], _diffFingerprint(pages));
      final requestId = _object(receipt['requestId']);
      expect(requestId['projectionType'], 'jsonPayload');
      expect(await fixture.payload(requestId, wire: wire), _largeRequestId);
      expect(await fixture.manifest.readAsBytes(), before);
      expect(await fixture.map.exists(), isTrue);
      final first = await fixture.projection({
        'operation': 'diff',
        'diffRef': summary['diffRef'],
        'limit': 1,
      }, wire: wire);
      expect(first['startIndex'], 0);
      expect(first['nextCursor'], isA<String>());
      expect(
          await fixture.projection({
            'operation': 'diff',
            'diffRef': summary['diffRef'],
            'limit': 1,
          }, wire: wire),
          first);
      final defaultPage = await fixture.projection({
        'operation': 'diff',
        'diffRef': summary['diffRef'],
      }, wire: wire);
      expect(defaultPage['entries'], pages);
      expect(defaultPage['nextCursor'], isNull);
    });
  }

  test('JSONL keeps destructive confirmation replay and historical projections',
      () async {
    final fixture = await _ProjectionFixture.create();
    addTearDown(fixture.dispose);
    final before = await fixture.manifest.readAsBytes();
    final paginationFirst = await fixture
        .plan('map.delete_apply', {'mapId': 'map'}, requestId: _largeRequestId);
    final paginationSecond = await fixture.plan(
        'map.delete_apply', {'mapId': 'map'},
        requestId: '${_largeRequestId}_other');
    final paginationSummary =
        _object(_object(paginationFirst.toJson()['receipt'])['diff']);
    final otherPaginationSummary =
        _object(_object(paginationSecond.toJson()['receipt'])['diff']);
    final firstPage = await fixture.projection({
      'operation': 'diff',
      'diffRef': paginationSummary['diffRef'],
      'limit': 1,
    });
    await fixture.failure(
        'projection',
        {
          'operation': 'diff',
          'projectHandle': fixture.project.value,
          'diffRef': otherPaginationSummary['diffRef'],
          'cursor': firstPage['nextCursor'],
        },
        'projection.reference_unavailable');
    final first = await fixture.plan('fact.delete', {'factId': 'large'});
    final second = await fixture.plan('fact.delete', {'factId': 'large'});
    final firstSummary = _object(_object(first.toJson()['receipt'])['diff']);
    Future<Map<String, Object?>> restoreBefore(
        Map<String, Object?> summary) async {
      final row = _object((await fixture.diff(summary)).single);
      return {
        ...row,
        'before': await fixture.payload(_object(row['before'])),
      };
    }

    await fixture.failure(
        'apply',
        {
          'projectHandle': fixture.project.value,
          'planId': first.planId,
          'operationId': 'delete-large',
        },
        'confirmation.required');
    final foreignToken = await fixture.success('confirm', {
      'projectHandle': fixture.project.value,
      'planId': second.planId,
    });
    await fixture.failure(
        'apply',
        {
          'projectHandle': fixture.project.value,
          'planId': first.planId,
          'operationId': 'delete-large',
          'confirmationToken': foreignToken['confirmationToken'],
        },
        'confirmation.binding_mismatch');
    expect(await fixture.manifest.readAsBytes(), before);
    final confirmation = await fixture.success('confirm', {
      'projectHandle': fixture.project.value,
      'planId': first.planId,
    });
    final input = {
      'projectHandle': fixture.project.value,
      'planId': first.planId,
      'operationId': 'delete-large',
      'confirmationToken': confirmation['confirmationToken'],
    };
    final applied = await fixture.success('apply', input);
    final saved = await fixture.manifest.readAsBytes();
    final appliedReceipt = _object(applied['receipt']);
    final replay = await fixture.success('apply', input);
    expect(
        _object(replay['receipt'])['receiptId'], appliedReceipt['receiptId']);
    expect(_object(replay['receipt'])['status'], 'applied');
    expect(await fixture.manifest.readAsBytes(), saved);
    expect(await fixture.map.exists(), isTrue);
    final originalRows = [await restoreBefore(firstSummary)];
    expect(originalRows, first.receipt.diff.toJson()['entries']);
    expect(_diffFingerprint(originalRows), firstSummary['fullDiffFingerprint']);
    final changed = await fixture.plan('map.create', {
      'mapId': 'after',
      'name': 'After receipt',
      'width': 2,
      'height': 2,
    });
    await fixture.success('apply', {
      'projectHandle': fixture.project.value,
      'planId': changed.planId,
      'operationId': 'create-after',
    });
    final afterChange = await fixture.manifest.readAsBytes();
    expect([await restoreBefore(firstSummary)], originalRows);
    final history = await fixture.success('history', {
      'projectHandle': fixture.project.value,
      'limit': 20,
    });
    expect(
        (history['entries'] as List).map((entry) => _object(entry)['entryId']),
        contains(appliedReceipt['receiptId']));
    final reprojected = await fixture.projection({
      'operation': 'receipt',
      'receiptId': appliedReceipt['receiptId'],
    });
    final historical = _object(reprojected['receipt']);
    expect(historical['receiptId'], appliedReceipt['receiptId']);
    expect(historical['beforeRevision'], appliedReceipt['beforeRevision']);
    expect(historical['afterRevision'], appliedReceipt['afterRevision']);
    expect([await restoreBefore(_object(historical['diff']))], originalRows);
    expect(historical['requestId'], first.receipt.requestId);
    expect(await fixture.manifest.readAsBytes(), afterChange);
  });

  test('JSONL dry-run projections cannot acquire confirmation or apply',
      () async {
    final fixture = await _ProjectionFixture.create();
    addTearDown(fixture.dispose);
    final before = await fixture.manifest.readAsBytes();
    final planned = await fixture.plan('map.delete_apply', {'mapId': 'map'},
        requestId: _largeRequestId, dryRun: true);
    expect(planned.applicable, isFalse);
    expect(planned.nonApplicableReason, 'dry_run');
    final summary = _object(_object(planned.toJson()['receipt'])['diff']);
    expect(
        await fixture.diff(summary), planned.receipt.diff.toJson()['entries']);
    await fixture.failure(
        'confirm',
        {
          'projectHandle': fixture.project.value,
          'planId': planned.planId,
        },
        'plan.dry_run_not_applicable');
    await fixture.failure(
        'apply',
        {
          'projectHandle': fixture.project.value,
          'planId': planned.planId,
          'operationId': 'dry-run',
        },
        'plan.dry_run_not_applicable');
    expect(await fixture.manifest.readAsBytes(), before);
    expect(await fixture.map.exists(), isTrue);
  });

  test(
      'expired plans reject confirmation and apply without rewriting projections',
      () async {
    var now = DateTime.utc(2026, 10, 19, 12);
    final fixture = await _ProjectionFixture.create(clock: () => now);
    addTearDown(fixture.dispose);
    final before = await fixture.manifest.readAsBytes();
    final first = await fixture.plan('map.delete_apply', {'mapId': 'map'},
        requestId: _largeRequestId);
    final second = await fixture.plan('map.delete_apply', {'mapId': 'map'},
        requestId: '${_largeRequestId}_expired');
    final summary = _object(_object(first.toJson()['receipt'])['diff']);
    final rows = await fixture.diff(summary);
    expect(rows, first.receipt.diff.toJson()['entries']);
    now = now.add(const Duration(minutes: 11));
    await fixture.failure(
        'confirm',
        {
          'projectHandle': fixture.project.value,
          'planId': first.planId,
        },
        'plan.expired');
    await fixture.failure(
        'apply',
        {
          'projectHandle': fixture.project.value,
          'planId': second.planId,
          'operationId': 'expired-plan',
        },
        'plan.expired');
    expect(await fixture.diff(summary), rows);
    expect(await fixture.manifest.readAsBytes(), before);
  });

  test('expired workspaces reject old handles and reproject durable receipts',
      () async {
    var now = DateTime.utc(2026, 10, 19, 12);
    final fixture = await _ProjectionFixture.create(clock: () => now);
    addTearDown(fixture.dispose);
    final planned = await fixture.plan('fact.delete', {'factId': 'large'});
    final confirmation = await fixture.mutations
        .confirmMutation(fixture.project, planId: planned.planId);
    final applied = await fixture.mutations.applyMutation(fixture.project,
        planId: planned.planId,
        operationId: 'receipt-before-expiration',
        confirmationToken: confirmation.confirmationToken);
    final receipt = _object(applied.toJson()['receipt']);
    final summary = _object(receipt['diff']);
    final expectedRows = applied.receipt.diff.toJson()['entries'] as List;
    final expectedFingerprint = _diffFingerprint(expectedRows);
    expect(summary['fullDiffFingerprint'], expectedFingerprint);
    expect(expectedRows, planned.receipt.diff.toJson()['entries']);
    final rows = await fixture.diff(summary, wire: false);
    final descriptor = _object(_object(rows.single)['before']);
    expect(await fixture.payload(descriptor, wire: false),
        fixture.largeFact.toJson());
    final saved = await fixture.manifest.readAsBytes();
    final oldProject = fixture.project;
    final oldWorkspace = fixture.workspace;
    now = now.add(const Duration(hours: 2, minutes: 1));
    await fixture.failure(
        'projection',
        {
          'operation': 'diff',
          'projectHandle': oldProject.value,
          'diffRef': summary['diffRef'],
        },
        'workspace.handle_expired');
    for (final input in [
      {
        'operation': 'payload',
        'payloadRef': descriptor['payloadRef'],
        'offset': 0,
      },
      {'operation': 'receipt', 'receiptId': receipt['receiptId']},
    ]) {
      await fixture.failure(
          'projection',
          {
            ...input,
            'projectHandle': oldProject.value,
          },
          'workspace.handle_unknown');
    }
    await expectLater(
        () => fixture.mutations.readMutationPayloadChunk(oldProject,
            payloadRef: descriptor['payloadRef'] as String, offset: 0),
        throwsA(isA<WorkspaceHandleException>().having(
            (error) => error.code, 'code', 'workspace.handle_unknown')));
    final reopened =
        await fixture.success('open', {'projectRoot': fixture.directory.path});
    fixture.project = ProjectHandle(reopened['projectHandle'] as String);
    fixture.workspace = WorkspaceHandle(reopened['workspaceHandle'] as String);
    expect(fixture.project, isNot(oldProject));
    expect(fixture.workspace, isNot(oldWorkspace));
    for (final input in [
      {'operation': 'diff', 'diffRef': summary['diffRef']},
      {
        'operation': 'payload',
        'payloadRef': descriptor['payloadRef'],
        'offset': 0,
      },
    ]) {
      await fixture.failure(
          'projection',
          {
            ...input,
            'projectHandle': fixture.project.value,
          },
          'projection.reference_unavailable');
    }
    final reprojected = await fixture.projection({
      'operation': 'receipt',
      'receiptId': receipt['receiptId'],
    });
    final historical = _object(reprojected['receipt']);
    final historicalDiff = _object(historical['diff']);
    expect(historical['receiptId'], applied.receipt.receiptId);
    expect(historical['beforeRevision'], applied.receipt.beforeRevision);
    expect(historical['afterRevision'], applied.receipt.afterRevision);
    expect(historicalDiff['diffRef'], isNot(summary['diffRef']));
    expect(historicalDiff['fullDiffFingerprint'], expectedFingerprint);
    final historicalRows = await fixture.diff(historicalDiff);
    final historicalRow = _object(historicalRows.single);
    final historicalPayload = _object(historicalRow['before']);
    expect(historicalPayload['payloadRef'], isNot(descriptor['payloadRef']));
    expect(historicalPayload['rawSha256'], descriptor['rawSha256']);
    final restored = {
      ...historicalRow,
      'before': await fixture.payload(historicalPayload),
    };
    expect([restored], expectedRows);
    expect(_diffFingerprint([restored]), expectedFingerprint);
    expect(await fixture.manifest.readAsBytes(), saved);
  });

  test('JSONL projection contracts reject malformed and cross-operation fields',
      () async {
    final fixture = await _ProjectionFixture.create();
    addTearDown(fixture.dispose);
    final validDiff = <String, Object?>{
      'operation': 'diff',
      'projectHandle': fixture.project.value,
      'diffRef': 'diff_unknown',
    };
    final validPayload = <String, Object?>{
      'operation': 'payload',
      'projectHandle': fixture.project.value,
      'payloadRef': 'payload_unknown',
      'offset': 0,
    };
    for (final args in <Map<String, Object?>>[
      {},
      {...validDiff, 'operation': 'unknown'},
      {...validDiff, 'diffRef': ''},
      {...validDiff, 'diffRef': 12},
      {...validDiff, 'receiptId': 'receipt'},
      {...validDiff, 'payloadRef': 'payload'},
      {...validDiff, 'unexpected': true},
      for (final limit in [0, 201, -1, 1.5, '1'])
        {...validDiff, 'limit': limit},
      {...validPayload, 'payloadRef': ''},
      {...validPayload, 'receiptId': 'receipt'},
      {...validPayload, 'cursor': 'cursor'},
      for (final offset in [-1, 1.5, '0', null])
        {...validPayload, 'offset': offset},
      for (final byteLength in [0, -1, 131073, 1.5, '1'])
        {...validPayload, 'byteLength': byteLength},
      {
        'operation': 'receipt',
        'projectHandle': fixture.project.value,
        'receiptId': 'receipt',
        'limit': 1,
      },
      {
        'operation': 'receipt',
        'projectHandle': fixture.project.value,
        'receiptId': '',
      },
    ]) {
      await fixture.failure('projection', args, 'worker.request_invalid');
    }
    for (final args in [
      validDiff,
      {...validDiff, 'cursor': 'cursor_unknown'},
      validPayload,
    ]) {
      await fixture.failure(
          'projection', args, 'projection.reference_unavailable');
    }
    await fixture.failure(
        'projection',
        {
          'operation': 'receipt',
          'projectHandle': fixture.project.value,
          'receiptId': 'receipt_unknown',
        },
        'projection.receipt_unavailable');
  });

  test('canonical projection facade preserves bounds and read permission',
      () async {
    final fixture = await _ProjectionFixture.create();
    addTearDown(fixture.dispose);
    for (final limit in [0, 201]) {
      await expectLater(
          fixture.mutations.readMutationDiffPage(fixture.project,
              diffRef: 'diff_unknown', limit: limit),
          throwsArgumentError);
    }
    for (final (offset, byteLength) in [(-1, 1), (0, 0), (0, 131073)]) {
      await expectLater(
          fixture.mutations.readMutationPayloadChunk(fixture.project,
              payloadRef: 'payload_unknown',
              offset: offset,
              byteLength: byteLength),
          throwsArgumentError);
    }
    final denied = await _ProjectionFixture.create(
        actor: AuthoringActor(actorId: 'projection_denied', permissions: []));
    addTearDown(denied.dispose);
    for (final operation in ['receipt', 'diff', 'payload']) {
      final input = <String, Object?>{
        'operation': operation,
        if (operation == 'receipt') 'receiptId': 'receipt_unknown',
        if (operation == 'diff') 'diffRef': 'diff_unknown',
        if (operation == 'payload') ...{
          'payloadRef': 'payload_unknown',
          'offset': 0,
        },
      };
      await expectLater(
          denied.projection(input, wire: false),
          throwsA(isA<AuthoringAuthorizationException>().having(
              (error) => error.code,
              'code',
              'authorization.permission_denied')));
      await denied.failure(
          'projection',
          {
            ...input,
            'projectHandle': denied.project.value,
          },
          'authorization.permission_denied');
    }
  });

  test(
      'real JSONL preserves UTF8 before-images across commit restart and changes',
      () async {
    final fixture = await _ProjectionFixture.create();
    var client = await _ProjectionProcess.start(fixture.root.path);
    try {
      final oracle = await fixture.plan('fact.delete', {'factId': 'large'});
      final expectedRows = oracle.receipt.diff.toJson()['entries'] as List;
      final expectedFingerprint = _diffFingerprint(expectedRows);
      final catalog = await client.call('describe', {});
      expect(
          (catalog['commands'] as List).cast<Map>().map((item) => item['id']),
          contains('projection'));
      var opened =
          await client.call('open', {'projectRoot': fixture.directory.path});
      var project = opened['projectHandle'];
      final before = await fixture.manifest.readAsBytes();
      final validated =
          await client.call('validate', {'projectHandle': project});
      final planned = await client.call('plan', {
        'projectHandle': project,
        'request': {
          'requestId': 'delete-large-fact',
          'actionId': 'fact.delete',
          'actionVersion': 1,
          'workspaceHandle': opened['workspaceHandle'],
          'parameters': {'factId': 'large'},
          'expectedRevision': validated['snapshotRevision'],
          'idempotencyKey': 'delete-large-fact',
          'dryRun': false,
        },
      });
      final summary = _object(_object(planned['receipt'])['diff']);
      expect(summary['fullDiffFingerprint'], expectedFingerprint);
      final page = await client.call('projection', {
        'operation': 'diff',
        'projectHandle': project,
        'diffRef': summary['diffRef'],
        'limit': 1,
      });
      final row = _object((page['entries'] as List).single);
      final descriptor = _object(row['before']);
      expect(descriptor['projectionType'], 'jsonPayload');
      Future<Object?> readPayload(Map<String, Object?> value) => _readPayload(
          value,
          (input) => client.call('projection', {
                ...input,
                'projectHandle': project,
              }));
      expect(await readPayload(descriptor), fixture.largeFact.toJson());
      expect(await fixture.manifest.readAsBytes(), before);
      final foreign =
          await client.call('open', {'projectRoot': fixture.other.path});
      for (final input in [
        {'operation': 'diff', 'diffRef': summary['diffRef']},
        {
          'operation': 'payload',
          'payloadRef': descriptor['payloadRef'],
          'offset': 0
        },
      ]) {
        await client.call(
            'projection',
            {
              ...input,
              'projectHandle': foreign['projectHandle'],
            },
            error: 'projection.reference_unavailable');
      }
      await client
          .call('close', {'workspaceHandle': foreign['workspaceHandle']});
      await client.call(
          'apply',
          {
            'projectHandle': project,
            'planId': planned['planId'],
            'operationId': 'delete-large-fact',
          },
          error: 'confirmation.required');
      final confirmation = await client.call('confirm', {
        'projectHandle': project,
        'planId': planned['planId'],
      });
      final apply = {
        'projectHandle': project,
        'planId': planned['planId'],
        'operationId': 'delete-large-fact',
        'confirmationToken': confirmation['confirmationToken'],
      };
      final applied = await client.call('apply', apply);
      final saved = await fixture.manifest.readAsBytes();
      final receipt = _object(applied['receipt']);
      final replay = await client.call('apply', apply);
      expect(_object(replay['receipt'])['receiptId'], receipt['receiptId']);
      expect(await fixture.manifest.readAsBytes(), saved);
      expect(await readPayload(descriptor), fixture.largeFact.toJson());
      final afterDelete =
          await client.call('validate', {'projectHandle': project});
      final changed = await client.call('plan', {
        'projectHandle': project,
        'request': {
          'requestId': 'rename-after-receipt',
          'actionId': 'map.update_metadata',
          'actionVersion': 1,
          'workspaceHandle': opened['workspaceHandle'],
          'parameters': {'mapId': 'map', 'name': 'After historical receipt'},
          'expectedRevision': afterDelete['snapshotRevision'],
          'idempotencyKey': 'rename-after-receipt',
          'dryRun': false,
        },
      });
      await client.call('apply', {
        'projectHandle': project,
        'planId': changed['planId'],
        'operationId': 'rename-after-receipt',
      });
      final afterChange = await fixture.manifest.readAsBytes();
      await client.close();
      client = await _ProjectionProcess.start(fixture.root.path);
      opened =
          await client.call('open', {'projectRoot': fixture.directory.path});
      project = opened['projectHandle'];
      for (final input in [
        {'operation': 'diff', 'diffRef': summary['diffRef']},
        {
          'operation': 'payload',
          'payloadRef': descriptor['payloadRef'],
          'offset': 0
        },
      ]) {
        await client.call('projection', {...input, 'projectHandle': project},
            error: 'projection.reference_unavailable');
      }
      final historical = await client.call('projection', {
        'operation': 'receipt',
        'projectHandle': project,
        'receiptId': receipt['receiptId'],
      });
      final historicalReceipt = _object(historical['receipt']);
      expect(historicalReceipt['receiptId'], receipt['receiptId']);
      expect(historicalReceipt['beforeRevision'], receipt['beforeRevision']);
      expect(historicalReceipt['afterRevision'], receipt['afterRevision']);
      final historicalDiff = _object(historicalReceipt['diff']);
      expect(historicalDiff['fullDiffFingerprint'],
          summary['fullDiffFingerprint']);
      final historicalPage = await client.call('projection', {
        'operation': 'diff',
        'projectHandle': project,
        'diffRef': historicalDiff['diffRef'],
      });
      final historicalRow = _object((historicalPage['entries'] as List).single);
      expect(await readPayload(_object(historicalRow['before'])),
          fixture.largeFact.toJson());
      final restored = {...historicalRow, 'before': fixture.largeFact.toJson()};
      expect([restored], expectedRows);
      expect(_diffFingerprint([restored]), expectedFingerprint);
      expect(await fixture.manifest.readAsBytes(), afterChange);
      await client
          .call('close', {'workspaceHandle': opened['workspaceHandle']});
    } finally {
      await client.close();
      await fixture.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

final String _largeRequestId =
    'projection_${List.filled(40000, 'é界😀"\\').join()}_end';

Map<String, Object?> _object(Object? value) =>
    Map<String, Object?>.from(value as Map);

String _diffFingerprint(List<Object?> entries) =>
    computeAuthoringJsonFingerprint({'entries': entries},
        logicalName: 'authoring-confirmation-diff.json');

Future<Object?> _readPayload(Map<String, Object?> descriptor,
    Future<Map<String, Object?>> Function(Map<String, Object?>) read) async {
  final bytes = BytesBuilder(copy: false);
  final total = descriptor['byteLength'] as int;
  var offset = 0;
  var chunks = 0;
  while (offset < total) {
    final result = await read({
      'operation': 'payload',
      'payloadRef': descriptor['payloadRef'],
      'offset': offset,
      if (chunks > 0) 'byteLength': 128 * 1024,
    });
    final chunk = base64Decode(result['bytesBase64'] as String);
    expect(chunk, isNotEmpty);
    expect(chunk.length, lessThanOrEqualTo(128 * 1024));
    expect(result['offset'], offset);
    expect(result['nextOffset'], offset + chunk.length);
    expect(result['totalBytes'], total);
    expect(result['rawSha256'], descriptor['rawSha256']);
    expect(result['complete'], offset + chunk.length == total);
    bytes.add(chunk);
    offset += chunk.length;
    chunks++;
  }
  expect(chunks, greaterThan(1));
  final complete = bytes.takeBytes();
  expect(complete.length, total);
  expect(sha256.convert(complete).toString(), descriptor['rawSha256']);
  final end = await read({
    'operation': 'payload',
    'payloadRef': descriptor['payloadRef'],
    'offset': total,
    'byteLength': 1,
  });
  expect(base64Decode(end['bytesBase64'] as String), isEmpty);
  expect(end['nextOffset'], total);
  expect(end['complete'], isTrue);
  return jsonDecode(utf8.decode(complete));
}

final class _ProjectionFixture {
  _ProjectionFixture(this.root, this.directory, this.other, this.largeFact,
      this.snapshots, this.mutations, this.worker);

  final Directory root;
  final Directory directory;
  final Directory other;
  final NarrativeFactDefinition largeFact;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;

  File get manifest => File('${directory.path}/project.json');
  File get map => File('${directory.path}/maps/map.json');

  static Future<_ProjectionFixture> create(
      {DateTime Function()? clock, AuthoringActor? actor}) async {
    final root = await Directory.systemTemp.createTemp('projection-read-');
    final directory = await Directory('${root.path}/project').create();
    final other = await Directory('${root.path}/other').create();
    await Directory('${directory.path}/maps').create();
    final largeFact = NarrativeFactDefinition(
        id: 'large',
        label: 'Large',
        description: 'début_${List.filled(35000, 'é界😀"\\\n').join()}_fin');
    final manifest = ProjectManifest(name: 'Projection fixture', maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
    ], tilesets: const [], facts: [
      largeFact
    ]);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    await File('${other.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(name: 'Other', maps: const [], tilesets: const [])
            .toJson()));
    await File('${directory.path}/maps/map.json').writeAsString(jsonEncode(
        const MapData(
                id: 'map', name: 'Map', size: GridSize(width: 2, height: 2))
            .toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore(clock: clock);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, clock: clock, actor: actor);
    final read = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final fixture = _ProjectionFixture(root, directory, other, largeFact,
        snapshots, mutations, JsonlWorker(api: read, mutations: mutations));
    final opened =
        await fixture.success('open', {'projectRoot': directory.path});
    fixture.workspace = WorkspaceHandle(opened['workspaceHandle'] as String);
    fixture.project = ProjectHandle(opened['projectHandle'] as String);
    return fixture;
  }

  Future<AuthoringMutationPlanResult> plan(
      String action, Map<String, Object?> parameters,
      {String? requestId, bool dryRun = false}) async {
    final id = 'projection-${++sequence}';
    return mutations.planMutation(
        project,
        AuthoringRequest(
            requestId: requestId ?? id,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: workspace.value,
            parameters: parameters,
            expectedRevision: (await snapshots.load(project)).revision,
            idempotencyKey: id,
            dryRun: dryRun));
  }

  Future<AuthoringResult> command(
      String command, Map<String, Object?> args) async {
    final line = await worker.processLine(jsonEncode({
      'id': 'projection-${++sequence}',
      'command': command,
      'args': args,
    }));
    if (command == 'projection') {
      expect(utf8.encode(line).length, lessThanOrEqualTo(256 * 1024));
      expect(line, isNot(contains(root.path)));
    }
    return AuthoringResult.fromJson(jsonDecode(line) as Map<String, dynamic>);
  }

  Future<Map<String, Object?>> success(
      String command, Map<String, Object?> args) async {
    final result = await this.command(command, args);
    expect(result.status, AuthoringResultStatus.success,
        reason: result.error?.toJson().toString());
    return result.data;
  }

  Future<void> failure(
      String command, Map<String, Object?> args, String code) async {
    final result = await this.command(command, args);
    expect(result.status, AuthoringResultStatus.failure);
    expect(result.error?.details['domainCode'], code,
        reason: result.error?.toJson().toString());
  }

  Future<Map<String, Object?>> projection(Map<String, Object?> input,
      {bool wire = true}) async {
    if (wire) {
      return success('projection', {...input, 'projectHandle': project.value});
    }
    return switch (input['operation']) {
      'receipt' => mutations.reprojectMutationReceipt(project,
          receiptId: input['receiptId'] as String),
      'diff' => mutations.readMutationDiffPage(project,
          diffRef: input['diffRef'] as String,
          cursor: input['cursor'] as String?,
          limit: input['limit'] as int? ?? 200),
      'payload' => (await mutations.readMutationPayloadChunk(project,
              payloadRef: input['payloadRef'] as String,
              offset: input['offset'] as int,
              byteLength: input['byteLength'] as int? ?? 128 * 1024))
          .toJson(),
      _ => throw StateError('Unknown projection operation.'),
    };
  }

  Future<List<Object?>> diff(Map<String, Object?> summary,
      {bool wire = true, int limit = 1}) async {
    final rows = <Object?>[];
    final cursors = <String>{};
    String? cursor;
    do {
      final page = await projection({
        'operation': 'diff',
        'diffRef': summary['diffRef'],
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      }, wire: wire);
      expect(page['diffRef'], summary['diffRef']);
      expect(page['fullDiffFingerprint'], summary['fullDiffFingerprint']);
      expect(page['totalRows'], summary['entryCount']);
      expect(page['startIndex'], rows.length);
      expect((page['entries'] as List).length, inInclusiveRange(1, limit));
      rows.addAll(page['entries'] as List);
      cursor = page['nextCursor'] as String?;
      if (cursor != null) expect(cursors.add(cursor), isTrue);
    } while (cursor != null);
    expect(rows.length, summary['entryCount']);
    return rows;
  }

  Future<Object?> payload(Map<String, Object?> descriptor,
          {bool wire = true}) =>
      _readPayload(descriptor, (input) => projection(input, wire: wire));

  Future<void> dispose() async {
    await worker.close();
    await root.delete(recursive: true);
  }
}

final class _ProjectionProcess {
  _ProjectionProcess(this.process)
      : output = StreamIterator(process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())),
        errors = process.stderr.transform(utf8.decoder).join();

  final Process process;
  final StreamIterator<String> output;
  final Future<String> errors;
  var sequence = 0;
  Future<void>? closing;

  static Future<_ProjectionProcess> start(String root) async =>
      _ProjectionProcess(await Process.start(
          Platform.environment['POKEMAP_TEST_DART'] ?? 'dart',
          ['run', 'bin/pokemap_authoring.dart', '--root', root]));

  Future<Map<String, Object?>> call(String command, Map<String, Object?> args,
      {String? error}) async {
    process.stdin.writeln(jsonEncode({
      'id': 'projection-${++sequence}',
      'command': command,
      'args': args,
    }));
    await process.stdin.flush();
    expect(await output.moveNext(), isTrue);
    final line = output.current;
    if (command == 'projection') {
      expect(utf8.encode(line).length, lessThanOrEqualTo(256 * 1024));
    }
    final response =
        AuthoringResult.fromJson(jsonDecode(line) as Map<String, dynamic>);
    expect(
        response.status,
        error == null
            ? AuthoringResultStatus.success
            : AuthoringResultStatus.failure,
        reason: response.error?.toJson().toString());
    if (error != null) {
      expect(response.error!.details['domainCode'], error);
      return response.error!.details;
    }
    return response.data;
  }

  Future<void> close() => closing ??= _close();

  Future<void> _close() async {
    await process.stdin.close();
    final exit = await process.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () {
      process.kill();
      return -1;
    });
    await output.cancel();
    expect(exit, 0);
    expect(await errors, isEmpty);
  }
}
