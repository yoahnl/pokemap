import 'dart:io';
import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart'
    show WorkspaceAccessException;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart' show CanonicalJson;

import 'package:path/path.dart' as p;

import 'package:test/test.dart';

import '../tool/resource_pack_volume.dart';

void main() {
  final output = Directory.systemTemp.path;
  List<String> local(List<String> args) => [
    '--mode',
    'local',
    '--output',
    output,
    ...args,
  ];

  test('a small original resources campaign emits independently inspected persistence evidence', () async {
    final directory = await Directory.systemTemp.createTemp(
      'p12-tool-roundtrip-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final tool = p.join(
      Directory.current.path,
      'tool',
      'resource_pack_volume.dart',
    );
    final config = p.join(
      Directory.current.path,
      '.dart_tool',
      'package_config.json',
    );
    final output = p.join(directory.path, 'evidence');
    final result = await Process.run('dart', [
      '--packages=$config',
      tool,
      '--mode',
      'local',
      '--campaign',
      'resources',
      '--resources',
      '2',
      '--output',
      output,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final receipt = jsonDecode(
      await File(p.join(output, 'receipt.json')).readAsString(),
    ) as Map;
    expect(receipt['formatVersion'], 1);
    expect(receipt['kind'], 'resource_pack_volume');
    expect(receipt['status'], 'completed');
    final campaign = (receipt['campaigns'] as List).single as Map;
    expect(campaign['requested']['resources'], 2);
    expect(campaign['generator']['pid'], isNot(campaign['worker']['pid']));
    expect(campaign['worker']['exitCode'], 0);
    expect(campaign['result']['importedResourceCount'], 2);
    expect(campaign['result']['undoBusinessEqualsInitial'], isTrue);
    expect(campaign['result']['redoBusinessEqualsImported'], isTrue);
    expect(campaign['result']['exportedResourceCount'], 2);
    expect(campaign['result']['originalImagesPreserved'], isTrue);
    expect(campaign['result']['sourceAndArchiveARemovedBeforeExport'], isTrue);
    expect(campaign['metrics']['maxBytesInFlight'], isNull);
    expect(campaign['metrics']['ioByteCoverage'], 'unavailable');
    final scoped = campaign['metrics']['scopedIo'];
    expect(scoped['coverage'], 'partial');
    expect(scoped['byteUnit'], 'bytes');
    expect(campaign['metrics']['counterUnits'], 'operations');
    expect(
      scoped['byteCounters']['io.harness.archive.completedWriteInputBytes'],
      campaign['result']['exportA']['byteLength'] +
          campaign['result']['exportC']['byteLength'],
    );
    for (final key in [
      'io.snapshot.readerReturnedBytes',
      'io.snapshot.streamDeliveredBytes',
      'io.resourcePack.stageSource.readBytes',
      'io.resourcePack.workerVerify.readBytes',
      'io.gateway.verification.readBytes',
      'io.gateway.stagedPayload.completedWriteInputBytes',
    ]) {
      expect(scoped['byteCounters'][key], greaterThan(0), reason: key);
    }
    expect(scoped['journalWriteOperationCount'], greaterThan(0));
    expect(scoped['pollResponses'], isNotEmpty);
    expect(scoped['phaseDeltas'], isNotEmpty);
    expect(scoped['globalReadBytes'], isNull);
    expect(scoped['globalWriteBytes'], isNull);
    expect(
      scoped['unobservedBoundaries']['io.gateway.journal.readBytes'],
      isNull,
    );

    expect(campaign['rss']['measurement'], 'sampled_current_rss');
    expect(campaign['rss']['sampleCount'], greaterThan(0));
    expect(campaign['rss']['intervalMs'], 100);
    ResourcePackVolumeReceipt.validate(Map<String, dynamic>.from(receipt));
    for (final change in <void Function(Map)>[
      (copy) => copy['status'] = 'running',
      (copy) => copy['sourcesUnchanged'] = false,
      (copy) => copy['campaigns'][0]['metrics']['maxBytesInFlight'] = 4096,
      (copy) => copy['campaigns'][0]['metrics']['ioByteCoverage'] = 'complete',
      (copy) =>
          copy['campaigns'][0]['result']['undoBusinessEqualsInitial'] = false,
      (copy) => copy['campaigns'][0]['generator']['pid'] =
          copy['campaigns'][0]['worker']['pid'],
    ]) {
      final copy = jsonDecode(jsonEncode(receipt)) as Map;
      change(copy);
      expect(
        () =>
            ResourcePackVolumeReceipt.validate(Map<String, dynamic>.from(copy)),
        throwsFormatException,
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('poll elapsed sums cannot exceed count times their maximum', () {
    for (final values in [(1, 3, 1), (2, 7, 3)]) {
      final receipt = _validationReceipt('resources');
      receipt['campaigns'][0]['metrics']['scopedIo']['pollResponses'] = [
        {
          'stage': 'fixture',
          'count': values.$1,
          'totalMicroseconds': values.$2,
          'maxMicroseconds': values.$3,
        },
      ];
      expect(
        () => ResourcePackVolumeReceipt.validate(receipt),
        throwsFormatException,
      );
    }
  });

  test('poll elapsed sums preserve valid zero duration observations', () {
    for (final count in [1, 2]) {
      final receipt = _validationReceipt('resources');
      receipt['campaigns'][0]['metrics']['scopedIo']['pollResponses'] = [
        {
          'stage': 'fixture',
          'count': count,
          'totalMicroseconds': 0,
          'maxMicroseconds': 0,
        },
      ];
      expect(
        () => ResourcePackVolumeReceipt.validate(receipt),
        returnsNormally,
      );
    }
  });

  test('receipt scoped observations reject misleading units totals and coverage', () {
    final receipt = _validationReceipt('resources');
    ResourcePackVolumeReceipt.validate(receipt);
    for (final mutate in <void Function(Map)>[
      (m) => m.remove('scopedIo'),
      (m) => m['scopedIo']['coverage'] = 'complete',
      (m) => m['scopedIo']['byteUnit'] = 'operations',
      (m) => m['scopedIo']['byteCounters']['filesystem.read'] = 7,
      (m) => m['scopedIo']['byteCounters']['io.harness.archive.readBytes'] = -1,
      (m) => m['scopedIo']['globalReadBytes'] = 0,
      (m) =>
          m['scopedIo']['unobservedBoundaries']['io.gateway.journal.readBytes'] =
              0,
      (m) => m['scopedIo']['gaps'] = <String>[],
      (m) => m['scopedIo']['incompleteWorkerOperations'] = 1,
      (m) => m['scopedIo']['maxArchiveReadAtRequestBytes'] = 1048577,
      (m) => m['scopedIo']['pollResponses'] = [
        {
          'stage': 'prepare',
          'count': 1,
          'totalMicroseconds': 1,
          'maxMicroseconds': 2,
        },
      ],
      (m) => m['scopedIo']['phaseDeltas'] = [
        {
          'phase': 'inspect',
          'byteCounters': {'io.harness.archive.readBytes': 1},
          'operationCounters': <String, int>{},
          'incompleteWorkerOperations': 0,
        },
      ],
      (m) =>
          m['authoringOperationCounters']['io.gateway.resource.readBytes'] = 7,
      (m) => m['scopedIo']['journalWriteOperationCount'] = 1,
    ]) {
      final copy = _validationCopy(receipt);
      mutate(copy['campaigns'][0]['metrics'] as Map);
      expect(
        () => ResourcePackVolumeReceipt.validate(copy),
        throwsFormatException,
      );
    }
  });

  test('observed concrete reader preserves six capabilities and exact boundary bytes', () async {
    final root = await Directory.systemTemp.createTemp('p12-reader-');
    addTearDown(() => root.delete(recursive: true));
    final observer = ResourcePackVolumeObserver();
    final reader = ResourcePackVolumeProjectFileReader(observer);
    const original = LocalProjectFileReader();
    expect(reader, isA<ProjectFileReader>());
    expect(reader, isA<ProjectResourceStreamReader>());
    expect(reader, isA<ProjectResourceIdentityReader>());
    expect(reader, isA<ProjectSnapshotCacheIdentityReader>());
    expect(reader, isA<ProjectDirectoryReader>());
    expect(reader, isA<ProjectResourceProbeReader>());
    expect(reader.supportsStreamingResources, isTrue);
    final canonical = await reader.canonicalizeDirectory(root.path);
    expect(canonical, await original.canonicalizeDirectory(root.path));
    await Directory(p.join(root.path, 'assets')).create();
    final bytes = utf8.encode('été😀');
    await File(p.join(root.path, 'assets', 'source.bin')).writeAsBytes(bytes);
    final first = await reader.readBytes(
      projectRoot: canonical,
      relativePath: 'assets/source.bin',
    );
    expect(
      first,
      await original.readBytes(
        projectRoot: canonical,
        relativePath: 'assets/source.bin',
      ),
    );
    expect(() => first.add(0), throwsUnsupportedError);
    expect(
      await reader.readBytes(
        projectRoot: canonical,
        relativePath: 'assets/source.bin',
      ),
      bytes,
    );
    expect(
      observer.counters['io.snapshot.readerReturnedBytes'],
      bytes.length * 2,
    );
    expect(
      await reader.readIdentity(
        projectRoot: canonical,
        relativePath: 'assets/source.bin',
      ),
      await original.readIdentity(
        projectRoot: canonical,
        relativePath: 'assets/source.bin',
      ),
    );
    final probe = await reader.probeResource(
      projectRoot: canonical,
      relativePath: 'assets/source.bin',
    );
    expect(probe.status, ProjectResourceProbeStatus.exists);
    expect(
      probe.identity,
      await original.readIdentity(
        projectRoot: canonical,
        relativePath: 'assets/source.bin',
      ),
    );
    expect(
      (await reader.probeResource(
        projectRoot: canonical,
        relativePath: '../escape',
      )).status,
      ProjectResourceProbeStatus.unsafePath,
    );
    expect(
      (await reader.probeResource(
        projectRoot: canonical,
        relativePath: 'missing',
      )).status,
      ProjectResourceProbeStatus.missing,
    );
    expect(
      await reader.readIdentity(
        projectRoot: canonical,
        relativePath: 'missing',
      ),
      isNull,
    );
    final files = await reader.listFiles(
      projectRoot: canonical,
      relativeDirectory: 'assets',
    );
    expect(files, ['assets/source.bin']);
    expect(() => files.add('other'), throwsUnsupportedError);
    await expectLater(
      reader.readBytes(projectRoot: canonical, relativePath: '../escape'),
      throwsA(
        isA<WorkspaceAccessException>().having(
          (e) => e.code,
          'code',
          'workspace.path_traversal',
        ),
      ),
    );
    await File(p.join(root.path, 'project.json')).writeAsString(
      jsonEncode(
        ProjectManifest(name: 'Reader', maps: [], tilesets: []).toJson(),
      ),
    );
    final revisions = <String>[];
    for (final implementation in <ProjectFileReader>[original, reader]) {
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [canonical],
        fileReader: implementation,
      );
      final handles = WorkspaceHandleStore();
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: implementation,
        handles: handles,
      ).openProject(canonical);
      revisions.add(
        (await ProjectSnapshotLoader(handles: handles)
                .load(opened.projectHandle))
            .revision,
      );
      handles.closeWorkspace(opened.workspaceHandle);
    }
    expect(revisions.toSet(), hasLength(1));
  });

  test('observed reader streaming keeps backpressure cancellation and identity errors', () async {
    final root = await Directory.systemTemp.createTemp('p12-reader-stream-');
    addTearDown(() => root.delete(recursive: true));
    final observer = ResourcePackVolumeObserver();
    final reader = ResourcePackVolumeProjectFileReader(observer);
    final canonical = await reader.canonicalizeDirectory(root.path);
    final file = File(p.join(root.path, 'source.bin'));
    final bytes = List<int>.generate(300000, (i) => i % 251);
    await file.writeAsBytes(bytes);
    final stream = StreamIterator(
      reader.openRead(projectRoot: canonical, relativePath: 'source.bin'),
    );
    expect(await stream.moveNext(), isTrue);
    final firstLength = stream.current.length;
    expect(stream.current, bytes.take(firstLength).toList());
    expect(firstLength, lessThan(bytes.length));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(observer.counters['io.snapshot.streamDeliveredBytes'], firstLength);
    await stream.cancel();
    expect(observer.counters['io.snapshot.streamDeliveredBytes'], firstLength);
    observer.counters.clear();
    var changed = false;
    await expectLater(
      reader
          .openRead(projectRoot: canonical, relativePath: 'source.bin')
          .asyncMap((chunk) async {
            if (!changed) {
              changed = true;
              await file.writeAsBytes([9]);
            }
            return chunk;
          })
          .drain<void>(),
      throwsA(
        isA<WorkspaceAccessException>().having(
          (e) => e.code,
          'code',
          'workspace.path_changed_during_read',
        ),
      ),
    );
  });

  test('harness disk boundaries count returned reads and completed writes independently', () async {
    final root = await Directory.systemTemp.createTemp('p12-disk-observed-');
    addTearDown(() => root.delete(recursive: true));
    final observer = ResourcePackVolumeObserver();
    final file = await File(p.join(root.path, 'source'))
        .writeAsBytes([1, 2, 3, 4, 5, 6, 7]);
    final source = ResourcePackVolumeDiskSource(file, observer);
    addTearDown(source.close);
    expect(source.readAtSync(0, 2), [1, 2]);
    expect(source.readAtSync(4, 3), [5, 6, 7]);
    expect(observer.counters['io.harness.archive.readBytes'], 5);
    expect(() => source.readAtSync(6, 2), throwsStateError);
    expect(observer.counters['io.harness.archive.readBytes'], 6);
    final sink = ResourcePackVolumeDiskSink(
      p.join(root.path, 'target'),
      observer,
    );
    await sink.write(Uint8List.fromList([1, 2, 3]));
    expect(observer.counters['io.harness.archive.completedWriteInputBytes'], 3);
    await sink.write(Uint8List.fromList([4, 5, 6, 7]));
    await sink.finish();
    await expectLater(
      sink.write(Uint8List.fromList([8])),
      throwsA(isA<FileSystemException>()),
    );
    expect(observer.counters['io.harness.archive.completedWriteInputBytes'], 7);
    expect(await File(sink.path).readAsBytes(), [1, 2, 3, 4, 5, 6, 7]);
    final metrics = observer.metrics();
    expect(metrics['scopedIo']['maxArchiveReadAtRequestBytes'], 3);
    expect(metrics['maxBytesInFlight'], isNull);
  });

  test(
    'observation phases keep separate byte operation and elapsed poll units',
    () async {
      final observer = ResourcePackVolumeObserver();
      await observer.phase('first');
      observer.incrementCounter('io.gateway.resource.readBytes', by: 3);
      observer.incrementCounter('filesystem.read');
      await observer.phase('second');
      observer.incrementCounter('io.gateway.resource.readBytes', by: 2);
      observer.incrementCounter(
        'io.resourcePack.workerCoverage.incompleteOperations',
      );
      observer.recordPoll('prepare', 4);
      observer.recordPoll('prepare', 9);
      final metrics = observer.metrics();
      final scoped = metrics['scopedIo'];
      expect(metrics['authoringOperationCounters'], {'filesystem.read': 1});
      expect(scoped['byteCounters'], {'io.gateway.resource.readBytes': 5});
      expect(scoped['incompleteWorkerOperations'], 1);
      expect(scoped['workerAggregateCoverage'], 'incomplete');
      expect(
        scoped['phaseDeltas']
            .where((p) => p['phase'] == 'first')
            .single['byteCounters'],
        {'io.gateway.resource.readBytes': 3},
      );
      expect(
        scoped['phaseDeltas']
            .where((p) => p['phase'] == 'second')
            .single['byteCounters'],
        {'io.gateway.resource.readBytes': 2},
      );
      expect(scoped['pollResponses'], [
        {
          'stage': 'prepare',
          'count': 2,
          'totalMicroseconds': 13,
          'maxMicroseconds': 9,
        },
      ]);
      expect(scoped['pollTimingUnit'], 'microseconds');
    },
  );

  test('help requires no campaign or local execution', () {
    expect(ResourcePackVolumeOptions.parse(['--help']).help, isTrue);
  });

  test('empty or implicit execution never starts a volume campaign', () {
    expect(() => ResourcePackVolumeOptions.parse([]), throwsFormatException);
    expect(
      () => ResourcePackVolumeOptions.parse([
        '--campaign',
        'resources',
        '--resources',
        '10',
        '--output',
        output,
      ]),
      throwsFormatException,
    );
  });

  test('resource campaign preserves distinct requested counts', () {
    final options = ResourcePackVolumeOptions.parse(
      local(['--campaign', 'resources', '--resources', '10,1000,10000']),
    );
    expect(options.campaign, ResourcePackVolumeCampaign.resources);
    expect(options.resourceCounts, [10, 1000, 10000]);
    expect(options.outputPath, output);
    expect(options.archiveBytes, 536870912);
  });

  test('entry campaign is separate from resource and capacity extremes', () {
    final options = ResourcePackVolumeOptions.parse(
      local(['--campaign', 'entries', '--zip-entries', '20000']),
    );
    expect(options.campaign, ResourcePackVolumeCampaign.entries);
    expect(options.zipEntries, 20000);
    expect(options.resourceCounts, isEmpty);
    expect(
      () => ResourcePackVolumeOptions.parse(
        local(['--campaign', 'entries', '--resources', '10000']),
      ),
      throwsFormatException,
    );
  });

  test(
    'capacity request remains bounded by independent useful and ZIP caps',
    () {
      final options = ResourcePackVolumeOptions.parse(
        local([
          '--campaign',
          'capacity',
          '--payload-bytes',
          '524288000',
          '--archive-bytes',
          '536870912',
        ]),
      );
      expect(options.campaign, ResourcePackVolumeCampaign.capacity);
      expect(options.payloadBytes, 524288000);
      for (final args in [
        ['--payload-bytes', '524288001'],
        ['--archive-bytes', '536870913'],
        ['--archive-bytes', '0'],
      ]) {
        expect(
          () => ResourcePackVolumeOptions.parse(
            local(['--campaign', 'capacity', ...args]),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('unknown duplicate malformed and irrelevant flags fail explicitly', () {
    for (final args in [
      ['--unexpected', 'yes'],
      ['--mode', 'local'],
      ['--resources'],
      ['--resources', '10,10'],
      ['--resources', '-1'],
      ['--resources', '10001'],
      ['--resources', '10,x'],
      ['--payload-bytes', '1000'],
    ]) {
      expect(
        () => ResourcePackVolumeOptions.parse(
          local(['--campaign', 'resources', '--resources', '10', ...args]),
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'invalid resource counts are rejected independently of duplicate flags',
    () {
      for (final counts in ['10,10', '-1', '10001', '10,x', '']) {
        expect(
          () => ResourcePackVolumeOptions.parse(
            local(['--campaign', 'resources', '--resources', counts]),
          ),
          throwsFormatException,
        );
      }
      final counts = ResourcePackVolumeOptions.parse(
        local(['--campaign', 'resources', '--resources', '10']),
      ).resourceCounts;
      expect(() => counts.add(1000), throwsUnsupportedError);
    },
  );

  test('campaign and absolute evidence output must be explicit', () {
    expect(
      () => ResourcePackVolumeOptions.parse(local(['--resources', '10'])),
      throwsFormatException,
    );
    expect(
      () => ResourcePackVolumeOptions.parse([
        '--mode',
        'local',
        '--campaign',
        'resources',
        '--resources',
        '10',
        '--output',
        'relative-evidence',
      ]),
      throwsFormatException,
    );
  });
  test('strict numeric options reject alternate integer spellings', () {
    for (final raw in ['+1', '01', ' 1', '1 ', '1, 2']) {
      expect(
        () => ResourcePackVolumeOptions.parse(
          local(['--campaign', 'resources', '--resources', raw]),
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'entry plan counts actual referenced pages separately from resources',
    () {
      expect(planEntryLayout(4), {
        'zipEntries': 4,
        'imageFiles': 1,
        'resources': 1,
        'licenseFiles': 1,
      });
      expect(planEntryLayout(20000), {
        'zipEntries': 20000,
        'imageFiles': 19997,
        'resources': 9999,
        'licenseFiles': 1,
      });
      for (final count in [0, 3, 20001]) {
        expect(() => planEntryLayout(count), throwsFormatException);
      }
    },
  );

  test(
    'original PNG stored scanlines are deterministic valid zlib pixel bytes',
    () async {
      final directory = await Directory.systemTemp.createTemp('p12-png-fast-');
      addTearDown(() => directory.delete(recursive: true));
      final first = File(p.join(directory.path, 'first.png'));
      final same = File(p.join(directory.path, 'same.png'));
      final different = File(p.join(directory.path, 'different.png'));
      await writeOriginalPng(first, 16, 16, 257);
      await writeOriginalPng(same, 16, 16, 257);
      await writeOriginalPng(different, 16, 16, 258);
      final bytes = await first.readAsBytes();
      expect(bytes.length, pngStoredByteLength(16, 16));
      expect(pngStoredByteLength(4096, 4096), 67182643);
      expect(bytes, await same.readAsBytes());
      expect(
        sha256.convert(bytes),
        isNot(sha256.convert(await different.readAsBytes())),
      );
      final encoded = <int>[];
      for (var offset = 8; offset < bytes.length;) {
        final size = ByteData.sublistView(bytes).getUint32(offset);
        final kind = ascii.decode(bytes.sublist(offset + 4, offset + 8));
        expect(['IHDR', 'IDAT', 'IEND'], contains(kind));
        if (kind == 'IDAT')
          encoded.addAll(bytes.sublist(offset + 8, offset + 8 + size));
        offset += size + 12;
      }
      final pixels = ZLibDecoder().convert(encoded);
      expect(pixels.length, 16 * (1 + 16 * 4));
      for (var row = 0; row < 16; row++) {
        expect(pixels[row * 65], 0);
      }
      expect(pixels.sublist(1, 5), [1, 1, 0, 255]);
      for (final dimensions in [(0, 16), (16, 0), (8193, 16)]) {
        expect(
          () => pngStoredByteLength(dimensions.$1, dimensions.$2),
          throwsFormatException,
        );
      }
    },
  );

  test('small capacity planning reserves actual canonical catalogue and stops at one scanline', () async {
    final plan = await planCapacity(
      145000,
      536870912,
      width: 64,
      fullHeight: 64,
    );
    expect(plan['catalogBytes'], greaterThan(0));
    expect(plan['usefulPayloadBytes'], lessThanOrEqualTo(145000));
    expect(
      plan['sourceBytes'] + plan['catalogBytes'],
      plan['usefulPayloadBytes'],
    );
    expect(plan['nextRow']['usefulPayloadBytes'], greaterThan(145000));
    expect(plan['limitingConstraint'], 'useful_payload_bytes');
    await expectLater(
      planCapacity(1, 536870912, width: 64, fullHeight: 64),
      throwsFormatException,
    );
    await expectLater(
      planCapacity(524288001, 536870912),
      throwsFormatException,
    );
  });
  test('malformed receipt objects are rejected as format failures', () {
    for (final campaigns in [
      [42],
      [<String, dynamic>{}],
    ]) {
      expect(
        () => ResourcePackVolumeReceipt.validate({
          'formatVersion': 1,
          'kind': 'resource_pack_volume',
          'status': 'completed',
          'sourcesUnchanged': true,
          'campaigns': campaigns,
        }),
        throwsFormatException,
      );
    }
  });

  test('receipt validation rejects missing business fingerprints', () {
    final receipt = _validationReceipt('resources');
    final result = receipt['campaigns'][0]['result'];
    for (final fingerprints in [
      <String, dynamic>{},
      {...result['businessFingerprints'] as Map, 'initial': null},
      {...result['businessFingerprints'] as Map, 'imported': 42},
      {...result['businessFingerprints'] as Map, 'afterUndo': 'short'},
    ]) {
      final copy = _validationCopy(receipt);
      copy['campaigns'][0]['result']['businessFingerprints'] = fingerprints;
      expect(
        () => ResourcePackVolumeReceipt.validate(copy),
        throwsFormatException,
      );
    }
  });

  test(
    'receipt validation rejects declared entry count differing from actual',
    () {
      final receipt = _validationCopy(_validationReceipt('entries'));
      receipt['campaigns'][0]['requested']['zipEntries'] = 20000;
      receipt['campaigns'][0]['result']['requested']['zipEntries'] = 20000;
      expect(
        () => ResourcePackVolumeReceipt.validate(receipt),
        throwsFormatException,
      );
    },
  );

  test('receipt validation rejects capacity exceeding useful or ZIP caps', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (c) => c['result']['actual']['usefulPayloadBytes'] = 524288001,
      (c) => c['result']['actual']['archiveBytes'] = 536870913,
      (c) => c['result']['actual']['usefulPayloadBytes'] = 4001,
      (c) => c['result']['actual']['archiveBytes'] = 5001,
    ]) {
      final receipt = _validationReceipt('capacity');
      change(receipt['campaigns'][0]);
      expect(
        () => ResourcePackVolumeReceipt.validate(receipt),
        throwsFormatException,
      );
    }
  });

  test(
    'receipt validation accepts resource10 and bounded entry capacity records',
    () {
      for (final campaign in ['resources', 'entries', 'capacity']) {
        expect(
          () =>
              ResourcePackVolumeReceipt.validate(_validationReceipt(campaign)),
          returnsNormally,
        );
      }
    },
  );
  test('receipt validation rejects malformed required numbers and inconsistent bytes', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (r) => r['formatVersion'] = 1.0,
      (r) => r['campaigns'][0]['generator']['pid'] = '101',
      (r) => r['campaigns'][0]['worker']['exitCode'] = 0.0,
      (r) => r['campaigns'][0]['rss']['intervalMs'] = 100.0,
      (r) => r['campaigns'][0]['rss']['samples'][0]['pid'] = 102.0,
      (r) => r['campaigns'][0]['requested']['zipEntries'] = 4.0,
      (r) => r['campaigns'][0]['requested']['archiveBytes'] = 536870913,
      (r) => r['campaigns'][0]['requested']['payloadBytes'] = 524288001,
      (r) => r['campaigns'][0]['result']['actual']['zipEntries'] = 4.0,
      (r) => r['campaigns'][0]['result']['actual']['sourceBytes'] = '1455',
      (r) => r['campaigns'][0]['result']['actual']['sourceBytes'] = 1456,
      (r) => r['campaigns'][0]['result']['actual']['manifestBytes'] = 4194305,
      (r) => r['campaigns'][0]['result']['resourceCount'] = 1.0,
      (r) => r['campaigns'][0]['result']['archive']['byteLength'] = 4499,
      (r) => r['campaigns'][0]['result']['campaign'] = 'resources',
    ]) {
      final receipt = _validationCopy(_validationReceipt('entries'));
      change(receipt);
      expect(
        () => ResourcePackVolumeReceipt.validate(receipt),
        throwsFormatException,
      );
    }
  });
  test('A1 accepts the complete explicit AOT option trio', () {
    expect(
      () => ResourcePackVolumeOptions.parse(local([
        '--campaign', 'resources', '--resources', '2',
        '--worker-executable', p.join(output, 'worker'),
        '--worker-sha256', 'a' * 64,
        '--worker-build-receipt', p.join(output, 'build.json'),
      ])),
      returnsNormally,
    );
  });

  test('A1 rejects AOT receipts without pinned worker evidence', () {
    final receipt = _validationCopy(_validationReceipt('resources'));
    receipt['execution'] = {
      'supervisor': 'dart-jit', 'generator': 'dart-jit', 'worker': 'dart-aot',
    };
    receipt['campaigns'][0]['generator']['kind'] = 'dart-jit';
    receipt['campaigns'][0]['worker']['kind'] = 'dart-aot';
    expect(
      () => ResourcePackVolumeReceipt.validate(receipt),
      throwsFormatException,
    );
  });

  test('A1 rejects incomplete relative malformed and duplicate AOT options', () {
    final flags = [
      '--worker-executable', p.join(output, 'worker'),
      '--worker-sha256', 'a' * 64,
      '--worker-build-receipt', p.join(output, 'build.json'),
    ];
    for (var mask = 1; mask < 7; mask++) {
      final selected = [
        for (var i = 0; i < 3; i++)
          if (mask & (1 << i) != 0) ...flags.sublist(i * 2, i * 2 + 2),
      ];
      expect(() => ResourcePackVolumeOptions.parse(local([
        '--campaign', 'resources', '--resources', '2', ...selected,
      ])), throwsFormatException);
    }
    for (final invalid in [
      [...flags]..[1] = 'relative-worker',
      [...flags]..[3] = 'A' * 64,
      [...flags]..[3] = 'short',
      [...flags]..[5] = 'relative-build.json',
      [...flags, '--worker-sha256', 'a' * 64],
    ]) {
      expect(() => ResourcePackVolumeOptions.parse(local([
        '--campaign', 'resources', '--resources', '2', ...invalid,
      ])), throwsFormatException);
    }
  });

  test('A1 AOT worker argv excludes Dart flags while generator stays JIT', () {
    List<String> command(String mode, {String? worker}) =>
        resourcePackVolumeChildCommand(
          dartExecutable: '/sdk/dart', tool: '/repo/tool.dart',
          config: '/repo/config.json', mode: mode, request: '/owned/request.json',
          workerExecutable: worker,
        );
    expect(command('worker', worker: '/owned/worker'), [
      '/owned/worker', '--internal-worker', '/owned/request.json',
    ]);
    expect(command('worker'), [
      '/sdk/dart', '--packages=/repo/config.json', '/repo/tool.dart',
      '--internal-worker', '/owned/request.json',
    ]);
    expect(command('generate', worker: '/owned/worker'), [
      '/sdk/dart', '--packages=/repo/config.json', '/repo/tool.dart',
      '--internal-generate', '/owned/request.json',
    ]);
    expect(() => command('unknown'), throwsFormatException);
  });

  test('A1 protocol fixture verifies build pins and rejects drift', () async {
    final fixture = await _AotFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final worker = await ResourcePackVolumeAotWorker.verifyBuild(
      fixture.options, fixture.sourceIdentity,
    );
    expect(worker.executable, fixture.executable.path);
    expect(worker.buildId, fixture.build['workerBuildId']);
    for (final change in <void Function(Map<String, dynamic>)>[
      (b) => b['workerBuildId'] = 'f' * 64,
      (b) => b['packageConfigSha256'] = 'f' * 64,
      (b) => b['sourceManifestSha256'] = 'f' * 64,
      (b) => b['sourceFilesSha256']['tool.dart'] = 'f' * 64,
      (b) => b['resolvedProductPackageRoots']['map_core'] = '/foreign/core',
      (b) => b['dartSdkVersion'] = 'different SDK',
      (b) => b['targetOS'] = 'different OS',
      (b) => b['targetArchitecture'] = 'different architecture',
      (b) => b['sourcesAndConfigUnchangedDuringBuild'] = false,
      (b) => b['compileCommand'] = ['dart', 'compile', 'exe'],
      (b) => b.remove('workerBuildId'),
    ]) {
      final invalid = _validationCopy(fixture.build);
      change(invalid);
      await fixture.receipt.writeAsString(jsonEncode(invalid));
      await expectLater(
        ResourcePackVolumeAotWorker.verifyBuild(fixture.options, fixture.sourceIdentity),
        throwsFormatException,
      );
    }
    await fixture.receipt.writeAsString(jsonEncode(fixture.build));
    await worker.checkUnchanged();
    await fixture.executable.writeAsString('changed fixture');
    await expectLater(worker.checkUnchanged(), throwsFormatException);
    await expectLater(
      ResourcePackVolumeAotWorker.verifyBuild(fixture.options, fixture.sourceIdentity),
      throwsFormatException,
    );
  });

  test('A1 protocol fixture rejects identity claims and changed receipt', () async {
    final fixture = await _AotFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final worker = await ResourcePackVolumeAotWorker.verifyBuild(
      fixture.options, fixture.sourceIdentity,
    );
    await expectLater(worker.proofAfterRun(), throwsFormatException);
    for (final change in <void Function(Map<String, dynamic>)>[
      (i) => i['executionKind'] = 'dart-jit',
      (i) => i['buildId'] = 'f' * 64,
      (i) => i['dartSdkVersion'] = 'other SDK',
      (i) => i['targetOS'] = 'other OS',
      (i) => i['targetArchitecture'] = 'other arch',
      (i) => i.remove('buildId'),
    ]) {
      final invalid = _validationCopy(fixture.identity);
      change(invalid);
      expect(() => worker.verifyIdentity(invalid), throwsFormatException);
    }
    worker.verifyIdentity(fixture.identity);
    expect((await worker.proofAfterRun())['binarySha256AfterRun'], fixture.build['workerExecutableRawSha256']);
    await fixture.receipt.writeAsString('{}');
    await expectLater(worker.checkUnchanged(), throwsFormatException);
  });

  test('A1 rejects missing nonexecutable and symlink worker files', () async {
    final fixture = await _AotFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    if (!Platform.isWindows) {
      final chmod = await Process.run('chmod', ['600', fixture.executable.path]);
      expect(chmod.exitCode, 0);
      await expectLater(ResourcePackVolumeAotWorker.verifyBuild(
        fixture.options, fixture.sourceIdentity,
      ), throwsFormatException);
      expect((await Process.run('chmod', ['700', fixture.executable.path])).exitCode, 0);
      final link = await Link(p.join(fixture.directory.path, 'linked-worker')).create(fixture.executable.path);
      final options = fixture.parseOptions(executable: link.path);
      await expectLater(ResourcePackVolumeAotWorker.verifyBuild(options, fixture.sourceIdentity), throwsFormatException);
    }
    await fixture.executable.delete();
    await expectLater(ResourcePackVolumeAotWorker.verifyBuild(
      fixture.options, fixture.sourceIdentity,
    ), throwsFormatException);
  });

  test('A1 AOT receipt proof is required and internally consistent', () async {
    final fixture = await _AotFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final worker = await ResourcePackVolumeAotWorker.verifyBuild(fixture.options, fixture.sourceIdentity);
    worker.verifyIdentity(fixture.identity);
    final receipt = _validationCopy(_validationReceipt('resources'));
    receipt['sourceIdentity'] = fixture.sourceIdentity;
    receipt['sourceIdentityAfter'] = _validationCopy(fixture.sourceIdentity);
    receipt['execution'] = {'supervisor': 'dart-jit', 'generator': 'dart-jit', 'worker': 'dart-aot'};
    receipt['campaigns'][0]['generator']['kind'] = 'dart-jit';
    receipt['campaigns'][0]['worker'].addAll(await worker.proofAfterRun());
    receipt['campaigns'][0]['worker']['command'] = [
      worker.executable, '--internal-worker', p.join(fixture.directory.path, 'request.json'),
    ];
    ResourcePackVolumeReceipt.validate(receipt);
    for (final change in <void Function(Map<String, dynamic>)>[
      (r) => r['campaigns'][0]['worker']['kind'] = 'dart-jit',
      (r) => r['campaigns'][0]['worker']['binarySha256AfterRun'] = 'f' * 64,
      (r) => r['campaigns'][0]['worker']['identity']['executionKind'] = 'dart-jit',
      (r) => r['campaigns'][0]['worker']['buildId'] = 'f' * 64,
      (r) => r['campaigns'][0]['worker']['sourceConfigIdentityMatched'] = false,
      (r) => r['campaigns'][0]['worker']['buildInputs']['packageConfigSha256'] = 'f' * 64,
      (r) => r['campaigns'][0]['worker']['buildReceiptSha256'] = 'missing',
      (r) => r['campaigns'][0]['worker'].remove('compileCommand'),
      (r) => r['campaigns'][0]['worker']['command'] = ['dart', '--packages=config', 'tool.dart'],
      (r) => r['sourceIdentityAfter']['packageConfigSha256'] = 'f' * 64,
    ]) {
      final invalid = _validationCopy(receipt);
      change(invalid);
      expect(() => ResourcePackVolumeReceipt.validate(invalid), throwsFormatException);
    }
  });

  test('A1 real Dart identity is JIT without a compiled build define', () async {
    final result = await Process.run('dart', [
      '--packages=${p.join(Directory.current.path, '.dart_tool', 'package_config.json')}',
      p.join(Directory.current.path, 'tool', 'resource_pack_volume.dart'),
      '--internal-worker-identity',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final identity = jsonDecode(result.stdout as String) as Map;
    expect(identity['executionKind'], 'dart-jit');
    expect(identity['buildId'], isEmpty);
    expect(identity['kind'], 'resource_pack_volume_worker_identity');
  });

  test('A1 protocol-only identity process validates output and exit', () async {
    final fixture = await _AotFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    Future<ResourcePackVolumeAotWorker> prepared(String output, {int code = 0}) async {
      await fixture.writeIdentityResponse(output, code: code);
      return ResourcePackVolumeAotWorker.verifyBuild(fixture.options, fixture.sourceIdentity);
    }
    final worker = await prepared(jsonEncode(fixture.identity));
    await worker.probeIdentity();
    expect((await worker.proofAfterRun())['kind'], 'dart-aot');
    for (final output in [
      jsonEncode({...fixture.identity, 'executionKind': 'dart-jit'}),
      jsonEncode({...fixture.identity, 'buildId': 'f' * 64}),
      '{malformed',
    ]) {
      final invalid = await prepared(output);
      await expectLater(invalid.probeIdentity(), throwsFormatException);
    }
    final failing = await prepared(jsonEncode(fixture.identity), code: 7);
    await expectLater(failing.probeIdentity(), throwsFormatException);
    await expectLater(failing.proofAfterRun(), throwsFormatException);
  }, skip: Platform.isWindows);

  test('A1 missing AOT executable refuses before creating campaign output', () async {
    final directory = await Directory.systemTemp.createTemp('p12-aot-preflight-');
    addTearDown(() => directory.delete(recursive: true));
    final output = p.join(directory.path, 'evidence');
    final result = await Process.run('dart', [
      '--packages=${p.join(Directory.current.path, '.dart_tool', 'package_config.json')}',
      p.join(Directory.current.path, 'tool', 'resource_pack_volume.dart'),
      '--mode', 'local', '--campaign', 'resources', '--resources', '2',
      '--output', output,
      '--worker-executable', p.join(directory.path, 'missing-worker'),
      '--worker-sha256', 'a' * 64,
      '--worker-build-receipt', p.join(directory.path, 'missing-build.json'),
    ]);
    expect(result.exitCode, 64, reason: '${result.stdout}\n${result.stderr}');
    expect(await Directory(output).exists(), isFalse);
    expect('${result.stderr}', contains('regular files'));
  });
  final aotExecutionOmissions = <String, void Function(Map<String, dynamic>)>{
    'omitted execution': (r) => r.remove('execution'),
    'null execution': (r) => r['execution'] = null,
    'omitted execution and AOT generator': (r) {
      r.remove('execution');
      r['campaigns'][0]['generator']['kind'] = 'dart-aot';
    },
    'null execution and AOT generator': (r) {
      r['execution'] = null;
      r['campaigns'][0]['generator']['kind'] = 'dart-aot';
    },
    'omitted execution and omitted generator kind': (r) {
      r.remove('execution');
      r['campaigns'][0]['generator'].remove('kind');
    },
    'null execution and null generator kind': (r) {
      r['execution'] = null;
      r['campaigns'][0]['generator']['kind'] = null;
    },
  };
  for (final entry in aotExecutionOmissions.entries) {
    test('A1 V2 rejects ${entry.key} on a coherent AOT receipt', () async {
      final fixture = await _AotFixture.create();
      addTearDown(() => fixture.directory.delete(recursive: true));
      final receipt = await _coherentAotReceipt(fixture);
      ResourcePackVolumeReceipt.validate(receipt);
      ResourcePackVolumeReceipt.validate(_validationReceipt('resources'));
      entry.value(receipt);
      expect(
        () => ResourcePackVolumeReceipt.validate(receipt),
        throwsFormatException,
      );
    });
  }

  test('A1 V2 rejects contradictory explicit AOT execution labels', () async {
    final fixture = await _AotFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final receipt = await _coherentAotReceipt(fixture);
    ResourcePackVolumeReceipt.validate(receipt);
    for (final change in <void Function(Map<String, dynamic>)>[
      (r) => r['execution'].remove('supervisor'),
      (r) => r['execution']['supervisor'] = null,
      (r) => r['execution']['supervisor'] = 'dart-aot',
      (r) => r['execution'].remove('generator'),
      (r) => r['execution']['generator'] = null,
      (r) => r['execution']['generator'] = 'dart-aot',
      (r) => r['campaigns'][0]['generator'].remove('kind'),
      (r) => r['campaigns'][0]['generator']['kind'] = null,
      (r) => r['campaigns'][0]['generator']['kind'] = 'dart-aot',
    ]) {
      final invalid = _validationCopy(receipt);
      change(invalid);
      expect(
        () => ResourcePackVolumeReceipt.validate(invalid),
        throwsFormatException,
      );
    }
  });
}

Map<String, dynamic> _validationCopy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

Future<Map<String, dynamic>> _coherentAotReceipt(_AotFixture fixture) async {
  final worker = await ResourcePackVolumeAotWorker.verifyBuild(
    fixture.options,
    fixture.sourceIdentity,
  );
  worker.verifyIdentity(fixture.identity);
  final receipt = _validationCopy(_validationReceipt('resources'));
  receipt['sourceIdentity'] = fixture.sourceIdentity;
  receipt['sourceIdentityAfter'] = _validationCopy(fixture.sourceIdentity);
  receipt['execution'] = {
    'supervisor': 'dart-jit',
    'generator': 'dart-jit',
    'worker': 'dart-aot',
  };
  receipt['campaigns'][0]['generator']['kind'] = 'dart-jit';
  receipt['campaigns'][0]['worker'].addAll(await worker.proofAfterRun());
  receipt['campaigns'][0]['worker']['command'] = [
    worker.executable,
    '--internal-worker',
    p.join(fixture.directory.path, 'request.json'),
  ];
  return receipt;
}

final class _AotFixture {
  _AotFixture(this.directory, this.executable, this.receipt, this.sourceIdentity, this.build);

  final Directory directory;
  final File executable, receipt;
  final Map<String, dynamic> sourceIdentity, build;

  ResourcePackVolumeOptions get options => parseOptions();

  ResourcePackVolumeOptions parseOptions({String? executable}) =>
      ResourcePackVolumeOptions.parse([
        '--mode', 'local', '--campaign', 'resources', '--resources', '2',
        '--output', p.join(directory.path, 'unused-output'),
        '--worker-executable', executable ?? this.executable.path,
        '--worker-sha256', build['workerExecutableRawSha256'] as String,
        '--worker-build-receipt', receipt.path,
      ]);

  Map<String, dynamic> get identity => {
    'formatVersion': 1,
    'kind': 'resource_pack_volume_worker_identity',
    'executionKind': 'dart-aot',
    'buildId': build['workerBuildId'],
    for (final key in ['dartSdkVersion', 'targetOS', 'targetArchitecture']) key: build[key],
  };

  Future<void> writeIdentityResponse(String output, {int code = 0}) async {
    final quoted = output.replaceAll("'", "'\"'\"'");
    await executable.writeAsString(
      '#!/bin/sh\n[ "\$1" = "--internal-worker-identity" ] || exit 42\n'
      "printf '%s\\n' '$quoted'\nexit $code\n",
    );
    build['workerExecutableRawSha256'] = sha256.convert(await executable.readAsBytes()).toString();
    await receipt.writeAsString(jsonEncode(build));
  }

  static Future<_AotFixture> create() async {
    final temporary = await Directory.systemTemp.createTemp('p12-aot-protocol-only-');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    final executable = await File(p.join(directory.path, 'uncompiled-protocol-fixture'))
        .writeAsString('Original protocol fixture; never executed as an AOT binary.');
    if (!Platform.isWindows) {
      final result = await Process.run('chmod', ['700', executable.path]);
      expect(result.exitCode, 0);
    }
    final sourceFiles = {'tool.dart': 'a' * 64};
    final sourceIdentity = <String, dynamic>{
      'toolCanonicalPath': p.join(directory.path, 'tool.dart'),
      'sourceFiles': sourceFiles,
      'sourceFingerprint': sha256.convert(CanonicalJson.encodeUtf8(sourceFiles)).toString(),
      'packageConfigSha256': 'b' * 64,
      'productPackageRoots': {
        for (final name in ['map_core', 'map_authoring', 'map_distribution', 'map_gameplay'])
          name: p.join(directory.path, name),
      },
    };
    final inputs = ResourcePackVolumeAotWorker.buildInputs(sourceIdentity);
    final id = sha256.convert(CanonicalJson.encodeUtf8(inputs)).toString();
    final build = <String, dynamic>{
      ...inputs,
      'kind': 'resource_pack_volume_worker_build',
      'workerExecutableCanonicalPath': executable.path,
      'workerExecutableRawSha256': sha256.convert(await executable.readAsBytes()).toString(),
      'workerBuildId': id,
      'sourcesAndConfigUnchangedDuringBuild': true,
      'compileCommand': [Platform.resolvedExecutable, 'compile', 'exe',
        '-DP12_RESOURCE_PACK_WORKER_BUILD_ID=$id', sourceIdentity['toolCanonicalPath'],
        '-o', executable.path,
      ],
    };
    final receipt = await File(p.join(directory.path, 'build.json')).writeAsString(jsonEncode(build));
    return _AotFixture(directory, executable, receipt, sourceIdentity, build);
  }
}

Map<String, dynamic> _validationReceipt(String campaign) {
  final requested = <String, dynamic>{
    'campaign': campaign,
    'resources': campaign == 'resources' ? 10 : 0,
    'zipEntries': campaign == 'entries' ? 4 : 20000,
    'payloadBytes': campaign == 'resources' ? 524288000 : 4000,
    'archiveBytes': campaign == 'resources' ? 536870912 : 5000,
  };
  final result = campaign == 'resources'
      ? <String, dynamic>{
          'campaign': campaign,
          'status': 'completed',
          'businessFingerprints': {
            'initial': 'a' * 64,
            'afterUndo': 'a' * 64,
            'imported': 'b' * 64,
            'afterRedo': 'b' * 64,
            'afterExport': 'b' * 64,
          },
          'originalImageHashes': [
            for (var i = 1; i <= 10; i++) i.toRadixString(16).padLeft(64, '0'),
          ],
          'importedResourceCount': 10,
          'exportedResourceCount': 10,
          'undoBusinessEqualsInitial': true,
          'redoBusinessEqualsImported': true,
          'originalImagesPreserved': true,
          'sourceAndArchiveARemovedBeforeExport': true,
          'sessionCloseAwaited': true,
          for (final name in ['exportA', 'exportC'])
            name: {
              'resourceCount': 10,
              'fileCount': 10,
              'catalogBytes': 11317,
              'payloadBytes': 25047,
              'byteLength': 30762,
              'rawSha256': 'c' * 64,
            },
        }
      : <String, dynamic>{
          'campaign': campaign,
          'status': 'completed',
          'requested': _validationCopy(requested),
          'actual': {
            'sourceBytes': 1455,
            'catalogBytes': 1461,
            'manifestBytes': 1200,
            'usefulPayloadBytes': 2916,
            'archiveBytes': 4500,
            'zipEntries': 4,
            'catalogJsonNodes': 100,
            'catalogJsonDepth': 12,
          },
          'resourceCount': 1,
          'archive': {'byteLength': 4500, 'rawSha256': 'c' * 64},
          'officialInspectionAccepted': true,
        };
  return {
    'formatVersion': 1,
    'kind': 'resource_pack_volume',
    'status': 'completed',
    'sourcesUnchanged': true,
    'campaigns': [
      {
        'requested': requested,
        'generator': {'pid': 101, 'exitCode': 0},
        'worker': {'pid': 102, 'exitCode': 0},
        'metrics': _validationMetrics(),
        'rss': {
          'measurement': 'sampled_current_rss',
          'intervalMs': 100,
          'sampleCount': 1,
          'samples': [
            {'pid': 102, 'rssBytes': 1024},
          ],
        },
        'result': result,
      },
    ],
  };
}

Map<String, dynamic> _validationMetrics() => {
  'ioByteCoverage': 'unavailable',
  'maxBytesInFlight': null,
  'authoringOperationCounters': {'journal.completedWrites': 2},
  'counterUnits': 'operations',
  'scopedIo': {
    'coverage': 'partial',
    'byteUnit': 'bytes',
    'byteCounters': {
      'io.harness.archive.readBytes': 3,
      'io.harness.archive.completedWriteInputBytes': 4,
    },
    'globalReadBytes': null,
    'globalWriteBytes': null,
    'incompleteWorkerOperations': 0,
    'workerAggregateCoverage': 'successful_calls_only',
    'maxArchiveReadAtRequestBytes': 3,
    'journalWriteOperationCount': 2,
    'unobservedBoundaries': {
      'io.gateway.journal.readBytes': null,
      'io.gateway.descriptor.readBytes': null,
    },
    'phaseDeltas': [
      {
        'phase': 'fixture',
        'byteCounters': {
          'io.harness.archive.readBytes': 3,
          'io.harness.archive.completedWriteInputBytes': 4,
        },
        'operationCounters': {'journal.completedWrites': 2},
        'incompleteWorkerOperations': 0,
      },
    ],
    'pollTimingUnit': 'microseconds',
    'pollResponses': [
      {
        'stage': 'fixture',
        'count': 1,
        'totalMicroseconds': 3,
        'maxMicroseconds': 3,
      },
    ],
    'gaps': [
      'journal and descriptor readAsString bytes unavailable',
      'history/blob/audit/idempotency and private capture stores are outside these boundaries',
      'decode/copy heaps and global I/O are not observed',
      'failed worker prefix aggregates may be unavailable',
    ],
  },
};
