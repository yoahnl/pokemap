import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';

void main() {
  group('BorderPublicationTransaction', () {
    test('publishes in crash-safe order and applies memory last', () async {
      final events = <String>[];
      final store = _SnapshotStore(events);
      final manifest = _ManifestPort(events);
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: manifest,
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );
      final request = _request();

      final result = await transaction.publish(request);

      expect(events, <String>[
        'stage',
        'validate',
        'finalize',
        'replace-manifest',
        'apply-memory',
        'discard-stage',
      ]);
      expect(result.manifest, request.nextManifest);
      expect(
          result.snapshotFinalize.createdRelativePaths,
          request.files
              .map((file) => file.relativePath)
              .toList(growable: false));
      expect(manifest.applied, same(request.nextManifest));
      expect(manifest.expectedPrevious, same(request.previousManifest));
    });

    test('validation errors discard staging and preserve the manifest',
        () async {
      final events = <String>[];
      final store = _SnapshotStore(events);
      final manifest = _ManifestPort(events);
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: manifest,
        candidateValidator: _Validator(
          events,
          BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
            _diagnostic(
              code: 'border.publication.invalid',
              severity: BorderDiagnosticSeverity.error,
            ),
          ]),
        ),
      );

      await expectLater(
        transaction.publish(_request()),
        throwsA(
          isA<BorderPublicationTransactionException>().having(
            (error) => error.code,
            'code',
            BorderPublicationTransactionErrorCode.validationFailed,
          ),
        ),
      );

      expect(events, <String>['stage', 'validate', 'discard-stage']);
      expect(manifest.replaced, isNull);
      expect(manifest.applied, isNull);
    });

    test('core gate rejects masonry ground before committing the manifest',
        () async {
      final events = <String>[];
      final manifest = _ManifestPort(events);
      final transaction = BorderPublicationTransaction(
        snapshotStore: _SnapshotStore(events),
        manifestPort: manifest,
      );

      await expectLater(
        transaction.publish(_masonryGroundRequest()),
        throwsA(
          isA<BorderPublicationTransactionException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationTransactionErrorCode.validationFailed,
              )
              .having(
                (error) => error.diagnostics.diagnostics
                    .map((diagnostic) => diagnostic.code),
                'diagnostic codes',
                contains('border.publication.linear_ground_not_supported'),
              ),
        ),
      );

      expect(events, <String>['stage', 'discard-stage']);
      expect(manifest.replaced, isNull);
      expect(manifest.applied, isNull);
    });

    test('requires explicit acknowledgement for every warning code', () async {
      final events = <String>[];
      final transaction = BorderPublicationTransaction(
        snapshotStore: _SnapshotStore(events),
        manifestPort: _ManifestPort(events),
        candidateValidator: _Validator(
          events,
          BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
            _diagnostic(
              code: 'border.publication.overlap_warning',
              severity: BorderDiagnosticSeverity.warning,
            ),
          ]),
        ),
      );

      await expectLater(
        transaction.publish(_request()),
        throwsA(
          isA<BorderPublicationTransactionException>()
              .having(
            (error) => error.code,
            'code',
            BorderPublicationTransactionErrorCode.warningsNotAcknowledged,
          )
              .having(
            (error) => error.unacknowledgedWarningCodes,
            'warnings',
            <String>['border.publication.overlap_warning'],
          ),
        ),
      );
      expect(events, <String>['stage', 'validate', 'discard-stage']);

      events.clear();
      await transaction.publish(
        _request(
          acceptedWarningCodes: <String>{
            'border.publication.overlap_warning',
          },
        ),
      );
      expect(events, <String>[
        'stage',
        'validate',
        'finalize',
        'replace-manifest',
        'apply-memory',
        'discard-stage',
      ]);
    });

    test('finalization failure never replaces the manifest', () async {
      final events = <String>[];
      final store = _SnapshotStore(events)..finalizeError = StateError('move');
      final manifest = _ManifestPort(events);
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: manifest,
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );

      await expectLater(transaction.publish(_request()), throwsStateError);

      expect(events, <String>[
        'stage',
        'validate',
        'finalize',
        'discard-stage',
      ]);
      expect(manifest.replaced, isNull);
      expect(manifest.applied, isNull);
    });

    test('manifest replacement failure leaves memory and old manifest intact',
        () async {
      final events = <String>[];
      final manifest = _ManifestPort(events)
        ..replaceError = StateError('manifest');
      final transaction = BorderPublicationTransaction(
        snapshotStore: _SnapshotStore(events),
        manifestPort: manifest,
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );

      await expectLater(transaction.publish(_request()), throwsStateError);

      expect(events, <String>[
        'stage',
        'validate',
        'finalize',
        'replace-manifest',
        'discard-stage',
      ]);
      expect(manifest.replaced, isNull);
      expect(manifest.applied, isNull);
    });

    test('staging failure performs no later publication work', () async {
      final events = <String>[];
      final store = _SnapshotStore(events)..stageError = StateError('stage');
      final manifest = _ManifestPort(events);
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: manifest,
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );

      await expectLater(transaction.publish(_request()), throwsStateError);

      expect(events, <String>['stage']);
      expect(manifest.replaced, isNull);
      expect(manifest.applied, isNull);
    });

    test('rejects a manifest snapshot without its exact staged payload',
        () async {
      final complete = _completeCoreRequest();
      final events = <String>[];
      final transaction = BorderPublicationTransaction(
        snapshotStore: _SnapshotStore(events),
        manifestPort: _ManifestPort(events),
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );
      final request = BorderPublicationRequest(
        previousManifest: complete.previousManifest,
        nextManifest: complete.nextManifest,
        blueprintId: complete.blueprintId,
        resolverVersion: complete.resolverVersion,
        snapshotIntegrity: complete.snapshotIntegrity,
        canonicalGalleryReport: complete.canonicalGalleryReport,
        files: complete.files.skip(1).toList(growable: false),
      );

      await expectLater(
        transaction.publish(request),
        throwsA(
          isA<BorderPublicationTransactionException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationTransactionErrorCode.validationFailed,
              )
              .having(
                (error) => error.diagnostics.diagnostics
                    .map((diagnostic) => diagnostic.code),
                'diagnostic codes',
                contains('border.publication.snapshot_file_missing'),
              ),
        ),
      );

      expect(events, <String>['stage', 'validate', 'discard-stage']);
    });

    test('rejects staged pixels that do not match snapshot identity', () async {
      final complete = _completeCoreRequest();
      final original = complete.files.first;
      final mismatched = BorderSnapshotFilePayload(
        relativePath: original.relativePath,
        bytes: _pngBytes(red: 255, green: 0, blue: 255),
      );
      final events = <String>[];
      final transaction = BorderPublicationTransaction(
        snapshotStore: _SnapshotStore(events),
        manifestPort: _ManifestPort(events),
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );
      final request = BorderPublicationRequest(
        previousManifest: complete.previousManifest,
        nextManifest: complete.nextManifest,
        blueprintId: complete.blueprintId,
        resolverVersion: complete.resolverVersion,
        snapshotIntegrity: complete.snapshotIntegrity,
        canonicalGalleryReport: complete.canonicalGalleryReport,
        files: <BorderSnapshotFilePayload>[
          mismatched,
          ...complete.files.skip(1),
        ],
      );

      await expectLater(
        transaction.publish(request),
        throwsA(
          isA<BorderPublicationTransactionException>().having(
            (error) => error.diagnostics.diagnostics
                .map((diagnostic) => diagnostic.code),
            'diagnostic codes',
            contains('border.publication.snapshot_content_mismatch'),
          ),
        ),
      );
      expect(events, <String>['stage', 'validate', 'discard-stage']);
    });

    test(
      'validates payloads for catalog-known snapshots referenced by the new revision',
      () async {
        final complete = _completeCoreRequest();
        final knownSnapshot =
            complete.nextManifest.borderCatalog.visualSnapshots.first;
        final previous = complete.previousManifest.copyWith(
          borderCatalog: ProjectBorderCatalog(
            records: complete.previousManifest.borderCatalog.records,
            visualSnapshots: <BorderVisualSnapshot>[knownSnapshot],
          ),
        );
        final request = BorderPublicationRequest(
          previousManifest: previous,
          nextManifest: complete.nextManifest,
          blueprintId: complete.blueprintId,
          resolverVersion: complete.resolverVersion,
          snapshotIntegrity: complete.snapshotIntegrity,
          canonicalGalleryReport: complete.canonicalGalleryReport,
          files: complete.files.skip(1).toList(growable: false),
        );
        final events = <String>[];
        final transaction = BorderPublicationTransaction(
          snapshotStore: _SnapshotStore(events),
          manifestPort: _ManifestPort(events),
          candidateValidator: _Validator(
            events,
            const BorderDiagnosticsReport.empty(),
          ),
        );

        await expectLater(
          transaction.publish(request),
          throwsA(
            isA<BorderPublicationTransactionException>()
                .having(
                  (error) => error.code,
                  'code',
                  BorderPublicationTransactionErrorCode.validationFailed,
                )
                .having(
                  (error) => error.diagnostics.diagnostics
                      .map((diagnostic) => diagnostic.code),
                  'diagnostic codes',
                  contains('border.publication.snapshot_file_missing'),
                ),
          ),
        );
        expect(events, <String>['stage', 'validate', 'discard-stage']);
      },
    );

    test('reports an explicit committed outcome when memory refresh fails',
        () async {
      final events = <String>[];
      final manifest = _ManifestPort(events)
        ..applyError = StateError('memory refresh');
      final transaction = BorderPublicationTransaction(
        snapshotStore: _SnapshotStore(events),
        manifestPort: manifest,
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );

      await expectLater(
        transaction.publish(_request()),
        throwsA(
          isA<BorderPublicationTransactionException>()
              .having(
                (error) => error.code,
                'code',
                BorderPublicationTransactionErrorCode
                    .publishedButMemoryRefreshFailed,
              )
              .having(
                (error) => error.manifestCommitted,
                'manifest committed',
                isTrue,
              ),
        ),
      );

      expect(manifest.replaced, isNotNull);
      expect(events, <String>[
        'stage',
        'validate',
        'finalize',
        'replace-manifest',
        'apply-memory',
        'discard-stage',
      ]);
    });

    test('does not turn post-commit cleanup debt into publication failure',
        () async {
      final events = <String>[];
      final store = _SnapshotStore(events)
        ..discardError = StateError('cleanup');
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: _ManifestPort(events),
        candidateValidator: _Validator(
          events,
          const BorderDiagnosticsReport.empty(),
        ),
      );

      final result = await transaction.publish(_request());

      expect(result.stagingCleanupPending, isTrue);
      expect(events.last, 'discard-stage');
    });

    test('cleanup failure never masks a pre-commit validation failure',
        () async {
      final events = <String>[];
      final store = _SnapshotStore(events)
        ..discardError = StateError('cleanup');
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: _ManifestPort(events),
        candidateValidator: _Validator(
          events,
          BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
            _diagnostic(
              code: 'border.publication.invalid',
              severity: BorderDiagnosticSeverity.error,
            ),
          ]),
        ),
      );

      await expectLater(
        transaction.publish(_request()),
        throwsA(
          isA<BorderPublicationTransactionException>().having(
            (error) => error.code,
            'code',
            BorderPublicationTransactionErrorCode.validationFailed,
          ),
        ),
      );
    });
  });

  group('CoreBorderPublicationCandidateValidator', () {
    const validator = CoreBorderPublicationCandidateValidator();

    test('accepts a complete organic revision and exact manifest transition',
        () {
      final request = _completeCoreRequest();

      final result = validator.validate(request);

      expect(result, const BorderDiagnosticsReport.empty());
    });

    test('rejects unrelated manifest mutations during publication', () {
      final request = _completeCoreRequest();
      final changed = BorderPublicationRequest(
        previousManifest: request.previousManifest,
        nextManifest: request.nextManifest.copyWith(name: 'Unrelated change'),
        blueprintId: request.blueprintId,
        resolverVersion: request.resolverVersion,
        snapshotIntegrity: request.snapshotIntegrity,
        canonicalGalleryReport: request.canonicalGalleryReport,
        files: request.files,
      );

      final result = validator.validate(changed);

      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.publication.unrelated_manifest_mutation'),
      );
    });

    test('accepts a complete masonry revision through the common validator',
        () {
      final request = _completeCoreRequest();
      final record = request.nextManifest.borderCatalog.records.single;
      final revision = record.latestPublished!;
      final masonryDefinition = BorderBlueprintPublishedDefinition(
        name: revision.definition.name,
        previewSeed: revision.definition.previewSeed,
        template: BorderBlueprintTemplate.masonryLine,
        primitives: revision.definition.primitives,
        defaults: revision.definition.defaults,
        sortOrder: revision.definition.sortOrder,
      );
      final masonryRecord = BorderBlueprintRecord(
        id: record.id,
        draft: record.draft,
        latestPublished: BorderBlueprintRevision(
          revision: revision.revision,
          definition: masonryDefinition,
        ),
      );
      final next = request.nextManifest.copyWith(
        borderCatalog: ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[masonryRecord],
          visualSnapshots: request.nextManifest.borderCatalog.visualSnapshots,
        ),
      );
      final masonry = BorderPublicationRequest(
        previousManifest: request.previousManifest,
        nextManifest: next,
        blueprintId: request.blueprintId,
        resolverVersion: request.resolverVersion,
        snapshotIntegrity: request.snapshotIntegrity,
        canonicalGalleryReport: _gallery(
          blueprintId: request.blueprintId,
          definition: masonryDefinition,
        ),
        files: request.files,
      );

      final result = validator.validate(masonry);

      expect(result, const BorderDiagnosticsReport.empty());
    });
  });
}

BorderPublicationRequest _request({
  Set<String> acceptedWarningCodes = const <String>{},
}) {
  final complete = _completeCoreRequest();
  return BorderPublicationRequest(
    previousManifest: complete.previousManifest,
    nextManifest: complete.nextManifest,
    blueprintId: complete.blueprintId,
    resolverVersion: complete.resolverVersion,
    snapshotIntegrity: complete.snapshotIntegrity,
    canonicalGalleryReport: complete.canonicalGalleryReport,
    files: complete.files,
    acceptedWarningCodes: acceptedWarningCodes,
  );
}

BorderPublicationRequest _masonryGroundRequest() {
  final complete = _completeCoreRequest();
  final record = complete.nextManifest.borderCatalog.records.single;
  final revision = record.latestPublished!;
  final snapshotId =
      complete.nextManifest.borderCatalog.visualSnapshots.first.id;
  final surfaceCatalog = ProjectSurfaceCatalog(
    atlases: <ProjectSurfaceAtlas>[
      ProjectSurfaceAtlas(
        id: 'ground-atlas',
        name: 'Ground atlas',
        tilesetId: 'tileset',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 2, height: 2),
          gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        ),
      ),
    ],
    animations: <ProjectSurfaceAnimation>[
      ProjectSurfaceAnimation(
        id: 'ground-isolated',
        name: 'Ground isolated',
        timeline: SurfaceAnimationTimeline(
          frames: <SurfaceAnimationFrame>[
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'ground-atlas',
                column: 0,
                row: 0,
              ),
              durationMs: 100,
            ),
          ],
        ),
      ),
    ],
    presets: <ProjectSurfacePreset>[
      ProjectSurfacePreset(
        id: 'ground-preset',
        name: 'Ground preset',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: <SurfaceVariantAnimationRef>[
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'ground-isolated',
            ),
          ],
        ),
      ),
    ],
  );
  final definition = BorderBlueprintPublishedDefinition(
    name: revision.definition.name,
    previewSeed: revision.definition.previewSeed,
    template: BorderBlueprintTemplate.masonryLine,
    primitives: revision.definition.primitives,
    defaults: revision.definition.defaults,
    ground: BorderPublishedGround(
      sourceSmartTilePresetId: 'ground-preset',
      edgeBandCells: 1,
      visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
        for (final role in standardSurfaceVariantRoleOrder) role: snapshotId,
      },
    ),
    sortOrder: revision.definition.sortOrder,
  );
  final nextRecord = BorderBlueprintRecord(
    id: record.id,
    draft: record.draft,
    latestPublished: BorderBlueprintRevision(
      revision: revision.revision,
      definition: definition,
    ),
  );
  final previous = complete.previousManifest.copyWith(
    surfaceCatalog: surfaceCatalog,
  );
  final next = complete.nextManifest.copyWith(
    surfaceCatalog: surfaceCatalog,
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[nextRecord],
      visualSnapshots: complete.nextManifest.borderCatalog.visualSnapshots,
    ),
  );
  return BorderPublicationRequest(
    previousManifest: previous,
    nextManifest: next,
    blueprintId: complete.blueprintId,
    resolverVersion: complete.resolverVersion,
    snapshotIntegrity: complete.snapshotIntegrity,
    canonicalGalleryReport: _gallery(
      blueprintId: complete.blueprintId,
      definition: definition,
    ),
    files: complete.files,
  );
}

BorderPublicationRequest _completeCoreRequest() {
  const snapshotService = BorderAssetSnapshotService();
  final preparations = <BorderAssetSnapshotPreparation>[
    for (var index = 0; index < 3; index += 1)
      snapshotService.prepare(
        BorderAssetSnapshotRequest(
          sourceElementId: 'element-large-$index',
          frames: <BorderAssetSnapshotSourceFrame>[
            BorderAssetSnapshotSourceFrame(
              sourceProjectRelativePath: 'assets/tilesets/source-$index.png',
              encodedImageBytes: _pngBytes(
                red: 40 + index * 50,
                green: 90 + index * 30,
                blue: 140 + index * 20,
              ),
              durationMs: 100,
            ),
          ],
        ),
      ),
  ];
  final snapshots = <BorderVisualSnapshot>[
    for (final preparation in preparations) preparation.snapshot,
  ];
  final publishedPrimitives = <BorderPublishedPrimitive>[
    for (var index = 0; index < 3; index += 1)
      _publishedPrimitive(index, preparations[index]),
  ];
  final publishedDefinition = BorderBlueprintPublishedDefinition(
    name: 'Coast',
    previewSeed: BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.organicEdge,
    primitives: publishedPrimitives,
    defaults: _coreParams(),
    sortOrder: 0,
  );
  final draftDefinition = BorderBlueprintDraftDefinition(
    name: 'Coast',
    previewSeed: BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.organicEdge,
    primitives: <BorderPrimitiveDraft>[
      for (var index = 0; index < 3; index += 1)
        BorderPrimitiveDraft(
          id: 'large-$index',
          sourceElementId: 'element-large-$index',
          role: BorderPrimitiveRole.structureLarge,
          weight: 100,
          anchorPx: const BorderPixelPos(x: 1, y: 1),
          transforms: _coreTransforms(),
          currentMetrics: preparations[index].metrics,
        ),
    ],
    defaults: _coreParams(),
    sortOrder: 0,
  );
  final previousRecord = BorderBlueprintRecord(
    id: 'coast',
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: draftDefinition,
    ),
  );
  final nextRecord = BorderBlueprintRecord(
    id: 'coast',
    draft: BorderBlueprintDraft(
      baseRevision: 1,
      definition: draftDefinition,
    ),
    latestPublished: BorderBlueprintRevision(
      revision: 1,
      definition: publishedDefinition,
    ),
  );
  final elements = <ProjectElementEntry>[
    for (var index = 0; index < 3; index += 1)
      ProjectElementEntry(
        id: 'element-large-$index',
        name: 'Large $index',
        tilesetId: 'tileset',
        categoryId: 'border',
        frames: const <TilesetVisualFrame>[
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
  ];
  final previous = ProjectManifest(
    name: 'Core candidate',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Border source',
        relativePath: 'assets/tilesets/border.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'border', name: 'Border'),
    ],
    elements: elements,
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[previousRecord],
    ),
  );
  final next = previous.copyWith(
    version: ProjectVersion.v2,
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[nextRecord],
      visualSnapshots: snapshots,
    ),
  );
  return BorderPublicationRequest(
    previousManifest: previous,
    nextManifest: next,
    blueprintId: 'coast',
    resolverVersion: 1,
    snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
      for (final snapshot in snapshots)
        snapshot.id: BorderVisualSnapshotIntegrity(
          snapshotId: snapshot.id,
          metadataValid: true,
          filesPresent: true,
          contentFingerprintMatches: true,
        ),
    },
    canonicalGalleryReport: _gallery(
      blueprintId: 'coast',
      definition: publishedDefinition,
    ),
    files: <BorderSnapshotFilePayload>[
      for (final preparation in preparations) ...preparation.files,
    ],
  );
}

BorderPublicationGalleryReport _gallery({
  required String blueprintId,
  required BorderBlueprintPublishedDefinition definition,
}) {
  return BorderPublicationGalleryReport(
    resolverVersion: 1,
    canonicalGalleryVersion: borderCanonicalGalleryVersion,
    candidateFingerprint: computeBorderPublicationCandidateFingerprint(
      blueprintId: blueprintId,
      definition: definition,
      resolverVersion: 1,
    ),
    samples: <BorderPublicationGallerySample>[
      for (final galleryCase
          in borderCanonicalGalleryCasesForTemplate(definition.template))
        BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: <BorderPublicationCoverageCheck>[
            for (final component in borderCanonicalCoverageComponentsForCase(
              template: definition.template,
              galleryCase: galleryCase,
            ))
              BorderPublicationCoverageCheck(
                component: component,
                longestContiguousGapPx: 0,
                maximumPairwiseOverlapPx: 0,
                gapTolerancePx: definition.defaults.gapTolerancePx,
                maxOverlapPx: definition.defaults.maxOverlapPx,
              ),
          ],
          structuralRuns: galleryCase == BorderCanonicalGalleryCase.longEdge
              ? <BorderPublicationStructuralRun>[
                  BorderPublicationStructuralRun(
                    id: 'outer-pass',
                    role: BorderPrimitiveRole.structureLarge,
                    quarterTurns: 0,
                    passIndex: 0,
                    primitiveIds: <String>[
                      for (var index = 0; index < 12; index += 1)
                        'large-${index % 3}',
                    ],
                  ),
                ]
              : const <BorderPublicationStructuralRun>[],
        ),
    ],
  );
}

BorderPublishedPrimitive _publishedPrimitive(
  int index,
  BorderAssetSnapshotPreparation preparation,
) {
  return BorderPublishedPrimitive(
    id: 'large-$index',
    sourceElementId: 'element-large-$index',
    visualSnapshotId: preparation.snapshot.id,
    role: BorderPrimitiveRole.structureLarge,
    weight: 100,
    anchorPx: const BorderPixelPos(x: 1, y: 1),
    transforms: _coreTransforms(),
    publishedMetrics: preparation.metrics,
  );
}

BorderTransformPolicy _coreTransforms() => BorderTransformPolicy(
      // The shared fixture is also projected as masonry below; masonry's
      // complete orientation contract requires the reflected side.
      allowFlipX: true,
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
    );

BorderGenerationParams _coreParams() => BorderGenerationParams(
      irregularityPermille: 500,
      detailDensityPermille: 500,
      variationPermille: 500,
      maxOverlapPx: 1,
      gapTolerancePx: 1,
      depthRows: 2,
    );

Uint8List _pngBytes({
  required int red,
  required int green,
  required int blue,
}) {
  final image = img.Image(width: 2, height: 2, numChannels: 4);
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      image.setPixelRgba(x, y, red, green, blue, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

BorderDiagnostic _diagnostic({
  required String code,
  required BorderDiagnosticSeverity severity,
}) {
  return BorderDiagnostic(
    code: code,
    severity: severity,
    phase: BorderDiagnosticPhase.publication,
    scope: BorderDiagnosticScope.blueprint,
    blueprintId: 'coast',
    suggestedAction: 'border.action.review',
  );
}

final class _Validator implements BorderPublicationCandidateValidator {
  _Validator(this.events, this.report);

  final List<String> events;
  final BorderDiagnosticsReport report;

  @override
  BorderDiagnosticsReport validate(BorderPublicationRequest request) {
    events.add('validate');
    return report;
  }
}

final class _SnapshotStore implements BorderAssetSnapshotStore {
  _SnapshotStore(this.events);

  final List<String> events;
  Object? stageError;
  Object? finalizeError;
  Object? discardError;

  @override
  Future<BorderAssetSnapshotStage> stage(
    List<BorderSnapshotFilePayload> files,
  ) async {
    events.add('stage');
    if (stageError case final error?) throw error;
    return BorderAssetSnapshotStage(
      id: 'stage',
      files: <BorderStagedSnapshotFile>[
        for (final file in files)
          BorderStagedSnapshotFile(
            relativePath: file.relativePath,
            contentSha256: file.contentSha256,
          ),
      ],
    );
  }

  @override
  Future<BorderAssetSnapshotFinalizeResult> finalize(
    BorderAssetSnapshotStage stage,
  ) async {
    events.add('finalize');
    if (finalizeError case final error?) throw error;
    return BorderAssetSnapshotFinalizeResult(
      createdRelativePaths: <String>[
        for (final file in stage.files) file.relativePath,
      ],
      deduplicatedRelativePaths: const <String>[],
    );
  }

  @override
  Future<void> discard(BorderAssetSnapshotStage stage) async {
    events.add('discard-stage');
    if (discardError case final error?) throw error;
  }
}

final class _ManifestPort implements BorderPublicationManifestPort {
  _ManifestPort(this.events);

  final List<String> events;
  Object? replaceError;
  Object? applyError;
  ProjectManifest? replaced;
  ProjectManifest? expectedPrevious;
  ProjectManifest? applied;

  @override
  Future<void> atomicallyReplace({
    required ProjectManifest previousManifest,
    required ProjectManifest nextManifest,
  }) async {
    events.add('replace-manifest');
    if (replaceError case final error?) throw error;
    expectedPrevious = previousManifest;
    replaced = nextManifest;
  }

  @override
  void applyInMemory(ProjectManifest manifest) {
    events.add('apply-memory');
    if (applyError case final error?) throw error;
    applied = manifest;
  }
}
