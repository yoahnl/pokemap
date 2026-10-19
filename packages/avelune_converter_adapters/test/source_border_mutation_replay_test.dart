import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelSize;
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('two canonical publications retain both snapshot assets and blobs',
      () async {
    final publications = <SourceBorderMutationReplay>[];
    final result = await publishPair(onPublication: publications.add);
    expect(publications, hasLength(2));
    expect(publications.first.resources.catalog.records, hasLength(1));
    expect(publications.first.files, hasLength(1));
    for (final record in publications.first.resources.catalog.records) {
      expect(result.resources.catalog.require(record.id).toJson(),
          record.toJson());
      expect(result.files[record.logicalPath],
          publications.first.files[record.logicalPath]);
      expect(result.resources.blobs[record.artifact.digest],
          publications.first.resources.blobs[record.artifact.digest]);
    }
    expect(() => result.files.clear(), throwsUnsupportedError);
    expect(() => result.files.values.first[0] = 0, throwsUnsupportedError);
    expect(() => result.resources.blobs.clear(), throwsUnsupportedError);
    expect(result.project.borderCatalog.records, hasLength(2));
    expect(result.files, hasLength(2));
    expect(result.resources.catalog.records, hasLength(2));
    expect(result.resources.blobs, hasLength(2));
    for (final record in result.resources.catalog.records) {
      expect(
          ContentArtifactRef.fromBytes(result.files[record.logicalPath]!,
              mediaType: 'image/png'),
          record.artifact);
      expect(result.resources.blobs[record.artifact.digest],
          result.files[record.logicalPath]);
    }
    final repeated = await publishPair();
    expect(canonicalJsonOf(result.resources.catalog.toJson()),
        canonicalJsonOf(repeated.resources.catalog.toJson()));
    expect(result.files, repeated.files);
    expect(result.resources.blobs, repeated.resources.blobs);
  });

  test('successive blueprints reuse an identical certified snapshot and blob',
      () async {
    final result = await publishPair(sharedPixels: true);
    expect(result.project.borderCatalog.records, hasLength(2));
    expect(result.files, hasLength(1));
    expect(result.resources.catalog.records, hasLength(1));
    expect(result.resources.blobs, hasLength(1));
  });

  test('publication still refuses an unused source artifact with a false MIME',
      () async {
    final artifact = NativeArtifact(bytes: utf8.encode('{}'));
    await expectLater(publishPair(additionalArtifacts: [artifact]),
        throwsA(isA<ArtifactStoreException>().having(
            (error) => error.code, 'code', 'artifact.mime_mismatch')));
  });

  test('publication still checks unused source artifacts against its byte limit',
      () async {
    final artifact = NativeArtifact(bytes: List<int>.filled(2048, 0));
    await expectLater(publishPair(additionalArtifacts: [artifact],
        limits: const NativeWriteLimits(maxArtifactBytes: 1024)),
        throwsA(isA<ArtifactStoreException>().having(
            (error) => error.code, 'code', 'artifact.too_large')));
  });

  test('publication refuses a valid handle that was never staged', () async {
    final absent = NativeArtifact(bytes: [1, 2, 3]);
    await expectLater(publishPair(sourceFrameHandle: absent.handle),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'artifact.unknown')));
  });

  test('resource replay refuses unexpected kinds, identities and paths', () {
    final blob =
        ContentArtifactRef.fromBytes([1, 2, 3], mediaType: 'image/png');
    for (final (change, code) in [
      (
        resourceChange(
            'dialogue', 'unknown', 'dialogues/unknown.json', utf8.encode('{}')),
        'jumps.resource.kind'
      ),
      (
        resourceChange('project', 'other', 'project.json', utf8.encode('{}')),
        'jumps.resource.kind'
      ),
      (
        resourceChange('project', 'project', 'other.json', utf8.encode('{}')),
        'jumps.resource.storage'
      ),
      (
        resourceChange(
            'assetCatalog', 'project', 'assets/other.json', utf8.encode('{}')),
        'jumps.resource.storage'
      ),
      (
        resourceChange(
            'assetBlob', 'sha256:${'0' * 64}', 'assets/other.blob', [1, 2, 3]),
        'jumps.resource.identity'
      ),
      (
        resourceChange(
            'assetBlob', blob.digest, 'assets/other.blob', [1, 2, 3]),
        'jumps.resource.storage'
      ),
      (
        resourceChange(
            'borderSnapshot', 'other', 'assets/other.png', [1, 2, 3]),
        'jumps.resource.kind'
      ),
      (
        resourceChange('borderSnapshot', 'assets/other.png', 'assets/other.png',
            [1, 2, 3]),
        'jumps.resource.storage'
      ),
    ]) {
      expect(() => applyChanges([change]), throwsA(failure(code)));
    }
  });

  test('resource replay refuses invalid catalog JSON and catalog schemas', () {
    for (final bytes in [
      [255],
      utf8.encode('{'),
      utf8.encode('[]'),
      utf8.encode('{}'),
      utf8.encode('{"schemaVersion":1,"records":[{}]}')
    ]) {
      expect(
          () => applyChanges([
                resourceChange(
                    'assetCatalog', 'project', assetCatalogStorageKey, bytes)
              ]),
          throwsA(failure('jumps.resource.catalog')));
    }
  });

  test('publication cannot introduce an unrelated asset record', () {
    final catalog = AssetCatalog(records: [
      AssetRecord(
          id: 'unrelated',
          logicalPath: 'assets/unrelated.png',
          artifact:
              ContentArtifactRef.fromBytes([1, 2, 3], mediaType: 'image/png'))
    ]);
    expect(
        () => applyChanges([
              resourceChange('assetCatalog', 'project', assetCatalogStorageKey,
                  utf8.encode(jsonEncode(catalog.toJson())))
            ]),
        throwsA(failure('jumps.resource.catalog')));
  });

  test(
      'resource replay refuses deletion, conflicting paths and stale preimages',
      () {
    expect(
        () => applyChanges([
              resourceChange(
                  'assetCatalog', 'project', assetCatalogStorageKey, null)
            ]),
        throwsA(failure('jumps.action')));
    final change = resourceChange(
        'assetCatalog',
        'project',
        assetCatalogStorageKey,
        utf8.encode(jsonEncode(AssetCatalog().toJson())));
    expect(() => applyChanges([change, change]),
        throwsA(failure('jumps.resource.conflict')));
    expect(
        () => applyChanges([
              AuthoringResourceChange(
                  resource:
                      AuthoringResourceRef(kind: 'assetCatalog', id: 'project'),
                  storageKey: assetCatalogStorageKey,
                  beforeBytes: [1],
                  afterBytes: change.afterBytes)
            ]),
        throwsA(failure('jumps.resource.preimage')));
  });

  test(
      'retained snapshots require exact PNG, catalog, blob and storage bindings',
      () async {
    final result = await publishPair();
    final path = result.files.keys.first;
    final old = result.resources.catalog.findByLogicalPath(path)!;
    final broken = [1, 2, 3];
    final reference =
        ContentArtifactRef.fromBytes(broken, mediaType: 'image/png');
    final invalidPng = SourceBorderReplayResources(
      catalog: AssetCatalog(records: [
        for (final record in result.resources.catalog.records)
          record.id == old.id ? record.copyWith(artifact: reference) : record
      ]),
      files: {...result.files, path: broken},
      blobs: {
        for (final entry in result.resources.blobs.entries)
          if (entry.key != old.artifact.digest) entry.key: entry.value,
        reference.digest: broken
      },
    );
    expect(
        () => applyChanges([], project: result.project, resources: invalidPng),
        throwsA(failure('native.png.header')));
    expect(
        () => applyChanges([],
            project: result.project,
            resources: SourceBorderReplayResources(
                catalog: result.resources.catalog, files: result.files)),
        throwsA(failure('jumps.resource.catalog')));
    expect(
        () => applyChanges([],
            project: result.project,
            resources: SourceBorderReplayResources(
                catalog: result.resources.catalog,
                files: {
                  ...result.files,
                  'assets/arbitrary.png': result.files[path]!
                },
                blobs: result.resources.blobs)),
        throwsA(failure('jumps.resource.storage')));
    expect(
        () => applyChanges([
              resourceChange('assetCatalog', 'project', assetCatalogStorageKey,
                  utf8.encode(jsonEncode(AssetCatalog().toJson())))
            ], project: result.project, resources: result.resources),
        throwsA(failure('jumps.resource.conflict')));
  });

  test('resource replay enforces cumulative quotas and cancellation', () async {
    final result = await publishPair();
    for (final limits in [
      const NativeWriteLimits(maxArtifacts: 1),
      const NativeWriteLimits(maxTotalArtifactBytes: 1),
      const NativeWriteLimits(maxTotalImagePixels: 1),
      const NativeWriteLimits(maxArtifactBytes: 1),
      const NativeWriteLimits(maxTotalDraftJsonBytes: 1),
    ]) {
      expect(
          () => applyChanges([],
              project: result.project,
              resources: result.resources,
              limits: limits),
          throwsA(isA<NativeWriteException>()));
    }
    final cancellation = ScanCancellation()..cancel();
    expect(
        () => applyChanges([], cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    expect(
        () => result.resources.catalog.records.clear(), throwsUnsupportedError);
  });
}

Future<SourceBorderMutationReplay> publishPair(
    {void Function(SourceBorderMutationReplay)? onPublication,
    bool sharedPixels = false,
    List<NativeArtifact> additionalArtifacts = const [],
    String? sourceFrameHandle,
    NativeWriteLimits limits = const NativeWriteLimits()}) async {
  var project = ProjectManifest(
    name: 'Border replay',
    version: ProjectVersion.v8,
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
          id: 'source', name: 'Source', relativePath: 'assets/source.png')
    ],
    elements: const [
      ProjectElementEntry(
          id: 'south',
          name: 'South',
          tilesetId: 'source',
          categoryId: 'border',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])
    ],
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
  );
  SourceBorderMutationReplay? result;
  for (var i = 0; i < 2; i++) {
    final pixels = image.Image(width: 32, height: 32, numChannels: 4);
    for (var y = 16; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        pixels.setPixelRgba(x, y, 80 + (sharedPixels ? 0 : i), 90, 100, 255);
      }
    }
    final artifact = NativeArtifact(bytes: image.encodePng(pixels));
    const anchor = BorderPixelPos(x: 16, y: 31);
    final prepared = const CanonicalBorderSnapshotCompiler().prepare(
      sourceElementId: 'south',
      anchorPx: anchor,
      frames: [
        CanonicalBorderSourceFrame(
            sourceProjectRelativePath: 'assets/source.png',
            encodedImageBytes: artifact.bytes)
      ],
    );
    final record = BorderBlueprintRecord(
        id: 'ledge-$i',
        draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: BorderBlueprintDraftDefinition(
              name: 'Ledge $i',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.ledgeLine,
              defaults: BorderGenerationParams(
                  irregularityPermille: 0,
                  detailDensityPermille: 0,
                  variationPermille: 0,
                  maxOverlapPx: 0,
                  gapTolerancePx: 0,
                  depthRows: 1,
                  allowAutoRotation: false),
              jumpBehavior: BorderJumpBehavior(side: BorderLineSide.primary),
              sortOrder: i,
              primitives: [
                BorderPrimitiveDraft(
                    id: 'south-$i',
                    sourceElementId: 'south',
                    role: BorderPrimitiveRole.structureLarge,
                    authoredOrientation: BorderPrimitiveOrientation.south,
                    weight: 1,
                    anchorPx: anchor,
                    transforms: BorderTransformPolicy(
                        allowFlipX: false, allowedQuarterTurns: [0]),
                    currentMetrics: prepared.metrics)
              ],
            )));
    for (final action in [
      (
        'border.blueprint.draft.upsert',
        <String, Object?>{
          'record': encodeBorderBlueprintRecordJson(record, formatVersion: 7)
        }
      ),
      (
        'border.blueprint.publish',
        <String, Object?>{
          'blueprintId': record.id,
          'primitiveSources': [
            {
              'primitiveId': 'south-$i',
              'frames': [
                {
                  'artifactHandle': sourceFrameHandle ?? artifact.handle,
                  'sourceProjectRelativePath': 'assets/source.png'
                }
              ]
            }
          ]
        }
      ),
    ]) {
      result = await replaySourceBorderMutation(
          project: project,
          maps: const {},
          mutation: NativeMutation(
              operationId: ConverterId('operation-$i-${action.$1}'),
              actionId: action.$1,
              sourceEntityIds: const [],
              targetEntityIds: const [],
              parameters: action.$2),
          artifacts: [artifact, ...additionalArtifacts],
          limits: limits,
          resources: result?.resources);
      project = result.project;
      if (action.$1 == 'border.blueprint.publish') onPublication?.call(result);
    }
  }
  return result!;
}

Matcher failure(String code) =>
    isA<NativeWriteException>().having((error) => error.code, 'code', code);

AuthoringResourceChange resourceChange(
        String kind, String id, String path, List<int>? after) =>
    AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: kind, id: id),
        storageKey: path,
        beforeBytes: after == null ? [0] : null,
        afterBytes: after);

SourceBorderMutationReplay applyChanges(
    Iterable<AuthoringResourceChange> changes,
    {ProjectManifest? project,
    SourceBorderReplayResources? resources,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation}) {
  final manifest = project ??
      ProjectManifest(
          name: 'Replay guards', maps: const [], tilesets: const []);
  final retained = resources ?? SourceBorderReplayResources();
  final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('replay-guards'),
      revision: 'sha256:${'0' * 64}',
      manifest: manifest,
      maps: const [],
      resourceFingerprints: const {});
  return SourceBorderMutationReplay.applyChanges(
      snapshot: snapshot,
      resources: retained,
      changes: changes,
      limits: limits,
      cancellation: cancellation);
}
