import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const int _resolverVersion = 1;

void main() {
  group('assessBorderPublicationReadiness', () {
    test('accepts a complete organic candidate without ground', () {
      final fixture = _Fixture.complete();
      final gallery = resolveOrganicEdgeCanonicalGallery(
        blueprintId: 'coast',
        blueprintRevision: BorderBlueprintRevision(
          revision: 1,
          definition: fixture.definition,
        ),
        visualSnapshots: fixture.snapshots,
        tileSizePx: const GridSize(width: 2, height: 2),
        resolverVersion: _resolverVersion,
      );

      final result = _assess(fixture, galleryReport: gallery.report);

      expect(gallery.allCasesResolved, isTrue);
      expect(result.canPublish, isTrue);
      expect(result.diagnosticReport.hasErrors, isFalse);
      expect(
        result.diagnosticReport.diagnostics.map((item) => item.code).toSet(),
        everyElement(
          anyOf(
            'border.publication.repetition_run',
            'border.publication.repetition_variety',
          ),
        ),
      );
    });

    test('requires the template structural roles', () {
      final fixture = _Fixture.complete();
      final cases = <(
        BorderBlueprintTemplate,
        List<BorderPublishedPrimitive>,
        List<String>
      )>[
        (
          BorderBlueprintTemplate.organicEdge,
          <BorderPublishedPrimitive>[
            fixture.primitive('accent', BorderPrimitiveRole.accent),
          ],
          <String>['structureLarge', 'structureMedium', 'filler'],
        ),
        (
          BorderBlueprintTemplate.masonryLine,
          <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.post),
          ],
          <String>['structureLarge', 'structureMedium', 'filler'],
        ),
        (
          BorderBlueprintTemplate.postAndRailLine,
          <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.post),
          ],
          <String>['span'],
        ),
      ];

      for (final (template, primitives, expectedRoles) in cases) {
        final definition = fixture.definitionFor(
          template: template,
          primitives: primitives,
        );
        final result = _assess(fixture, definition: definition);
        final diagnostic = result.diagnosticReport.diagnostics.singleWhere(
          (item) => item.code == 'border.publication.required_role_missing',
        );

        expect(result.canPublish, isFalse, reason: template.name);
        expect(diagnostic.parameters['roles'], expectedRoles);
      }
    });

    test('rejects every primitive role incompatible with its template', () {
      final fixture = _Fixture.complete();
      final cases = <(
        BorderBlueprintTemplate,
        List<BorderPublishedPrimitive>,
        List<String>
      )>[
        (
          BorderBlueprintTemplate.organicEdge,
          <BorderPublishedPrimitive>[
            ...fixture.definition.primitives,
            fixture.primitive('accent', BorderPrimitiveRole.accent),
            fixture.primitive('same', BorderPrimitiveRole.surfacePatch),
            fixture.primitive('empty', BorderPrimitiveRole.outerAccent),
            fixture.primitive('post', BorderPrimitiveRole.post),
            fixture.primitive('span', BorderPrimitiveRole.span),
          ],
          <String>['post', 'span'],
        ),
        (
          BorderBlueprintTemplate.masonryLine,
          <BorderPublishedPrimitive>[
            ...fixture.definition.primitives,
            fixture.primitive('accent', BorderPrimitiveRole.accent),
            fixture.primitive('post', BorderPrimitiveRole.post),
            fixture.primitive('span', BorderPrimitiveRole.span),
            fixture.primitive('same', BorderPrimitiveRole.surfacePatch),
            fixture.primitive('empty', BorderPrimitiveRole.outerAccent),
          ],
          <String>['outerAccent', 'span'],
        ),
        (
          BorderBlueprintTemplate.postAndRailLine,
          <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.post),
            fixture.primitive('span', BorderPrimitiveRole.span),
            fixture.primitive('accent', BorderPrimitiveRole.accent),
            fixture.primitive(
              'large-a',
              BorderPrimitiveRole.structureLarge,
            ),
            fixture.primitive(
              'large-b',
              BorderPrimitiveRole.structureMedium,
            ),
            fixture.primitive('large-c', BorderPrimitiveRole.filler),
            fixture.primitive('same', BorderPrimitiveRole.surfacePatch),
            fixture.primitive('empty', BorderPrimitiveRole.outerAccent),
          ],
          <String>[
            'filler',
            'outerAccent',
            'structureLarge',
            'structureMedium',
          ],
        ),
      ];

      for (final (template, primitives, expectedRoles) in cases) {
        final definition = fixture.definitionFor(
          template: template,
          primitives: primitives,
        );
        final result = _assess(fixture, definition: definition);
        final diagnostics = result.diagnosticReport.diagnostics
            .where(
              (item) =>
                  item.code ==
                  'border.publication.role_not_supported_by_template',
            )
            .toList(growable: false);

        expect(result.canPublish, isFalse, reason: template.name);
        final actualRoles = diagnostics
            .map((item) => item.parameters['role']! as String)
            .toList(growable: false)
          ..sort();
        expect(actualRoles, expectedRoles, reason: template.name);
        expect(
          diagnostics.map((item) => item.parameters['template']).toSet(),
          <String>{template.name},
          reason: template.name,
        );
      }
    });

    test('exposes the exact immutable role matrix for editor reuse', () {
      expect(
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.organicEdge,
        ),
        <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
          BorderPrimitiveRole.filler,
          BorderPrimitiveRole.accent,
          BorderPrimitiveRole.surfacePatch,
          BorderPrimitiveRole.outerAccent,
        },
      );
      expect(
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.masonryLine,
        ),
        <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
          BorderPrimitiveRole.filler,
          BorderPrimitiveRole.post,
          BorderPrimitiveRole.accent,
          BorderPrimitiveRole.surfacePatch,
        },
      );
      final lineRoles = borderAllowedPrimitiveRolesForTemplate(
        BorderBlueprintTemplate.postAndRailLine,
      );
      expect(
        lineRoles,
        <BorderPrimitiveRole>{
          BorderPrimitiveRole.post,
          BorderPrimitiveRole.span,
          BorderPrimitiveRole.accent,
          BorderPrimitiveRole.surfacePatch,
        },
      );
      expect(
        () => lineRoles.add(BorderPrimitiveRole.filler),
        throwsUnsupportedError,
      );
    });

    test('accepts the production fence draw passes in canonical evidence', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.postAndRailLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive('post', BorderPrimitiveRole.post, snapshot: 0),
          fixture.primitive('span', BorderPrimitiveRole.span, snapshot: 1),
        ],
      );
      final samples = <BorderPublicationGallerySample>[
        for (final galleryCase in borderCanonicalGalleryCasesForTemplate(
          BorderBlueprintTemplate.postAndRailLine,
        ))
          BorderPublicationGallerySample(
            galleryCase: galleryCase,
            coverageChecks: _passingCoverageChecks(galleryCase, definition),
            structuralRuns: galleryCase == BorderCanonicalGalleryCase.longEdge
                ? <BorderPublicationStructuralRun>[
                    BorderPublicationStructuralRun(
                      id: 'span-pass',
                      role: BorderPrimitiveRole.span,
                      quarterTurns: 0,
                      passIndex: 0,
                      primitiveIds: const <String>['span'],
                    ),
                    BorderPublicationStructuralRun(
                      id: 'post-pass',
                      role: BorderPrimitiveRole.post,
                      quarterTurns: 0,
                      passIndex: 1,
                      primitiveIds: const <String>['post'],
                    ),
                  ]
                : const <BorderPublicationStructuralRun>[],
          ),
      ];

      final result = _assess(
        fixture,
        definition: definition,
        samples: samples,
      );

      expect(
        _codes(result),
        isNot(contains('border.publication.gallery_run_contract_invalid')),
      );
    });

    test('accepts real canonical galleries for both line templates', () {
      final fixture = _Fixture.complete();
      final definitions = <BorderBlueprintPublishedDefinition>[
        fixture.definitionFor(
          template: BorderBlueprintTemplate.masonryLine,
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'large-a',
              BorderPrimitiveRole.structureLarge,
              snapshot: 0,
            ),
          ],
        ),
        fixture.definitionFor(
          template: BorderBlueprintTemplate.postAndRailLine,
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.post, snapshot: 0),
            fixture.primitive('span', BorderPrimitiveRole.span, snapshot: 1),
          ],
        ),
      ];

      for (final definition in definitions) {
        final gallery = resolveBorderCanonicalGallery(
          blueprintId: 'coast',
          blueprintRevision: BorderBlueprintRevision(
            revision: 1,
            definition: definition,
          ),
          visualSnapshots: fixture.snapshots,
          tileSizePx: const GridSize(width: 2, height: 2),
          resolverVersion: _resolverVersion,
        );
        final readiness = _assess(
          fixture,
          definition: definition,
          galleryReport: gallery.report,
        );

        expect(gallery.allCasesResolved, isTrue,
            reason: definition.template.name);
        expect(readiness.canPublish, isTrue, reason: definition.template.name);
        expect(
          _codes(readiness),
          isNot(contains('border.publication.gallery_run_contract_invalid')),
          reason: definition.template.name,
        );
      }
    });

    test('reports every missing required orientation deterministically', () {
      final fixture = _Fixture.complete();
      final result = _assess(
        fixture,
        definition: fixture.definitionFor(
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'large',
              BorderPrimitiveRole.structureLarge,
              quarterTurns: const <int>[2, 0],
            ),
          ],
        ),
      );
      final missing = result.diagnosticReport.diagnostics
          .where(
            (item) => item.code == 'border.publication.orientation_missing',
          )
          .toList(growable: false);

      expect(result.canPublish, isFalse);
      expect(
        missing.map((item) => item.parameters['orientation']),
        <String>['north', 'south'],
      );
      expect(
        missing.map((item) => item.parameters['roleGroup']),
        <String>['structure', 'structure'],
      );
    });

    test('checks post and span orientations independently', () {
      final fixture = _Fixture.complete();
      final result = _assess(
        fixture,
        definition: fixture.definitionFor(
          template: BorderBlueprintTemplate.postAndRailLine,
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.post),
            fixture.primitive(
              'span',
              BorderPrimitiveRole.span,
              quarterTurns: const <int>[0, 1, 2],
            ),
          ],
        ),
      );

      final missing = result.diagnosticReport.diagnostics
          .where(
            (item) => item.code == 'border.publication.orientation_missing',
          )
          .toList(growable: false);
      expect(missing, hasLength(1));
      expect(missing.single.parameters, <String, Object?>{
        'orientation': 'north',
        'quarterTurns': 3,
        'roleGroup': 'span',
      });
    });

    test('rejects out-of-asset anchors and invalid or empty occupancy', () {
      final fixture = _Fixture.complete();
      final invalid = _assess(
        fixture,
        definition: fixture.definitionFor(
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'invalid-rle',
              BorderPrimitiveRole.structureLarge,
              anchor: const BorderPixelPos(x: 2, y: 0),
              metrics: fixture.metrics(
                occupancy: 'not-rle',
                defaultAnchor: const BorderPixelPos(x: -1, y: 0),
              ),
            ),
          ],
        ),
      );
      final empty = _assess(
        fixture,
        definition: fixture.definitionFor(
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'empty',
              BorderPrimitiveRole.structureLarge,
              metrics: fixture.metrics(
                occupancy: 'border-rle-v1:4:0:4',
              ),
            ),
          ],
        ),
      );

      expect(
        _codes(invalid),
        containsAll(<String>[
          'border.blueprint.anchor_outside_asset',
          'border.blueprint.occupancy_mask_invalid',
        ]),
      );
      expect(
        _codes(empty),
        contains('border.blueprint.occupancy_mask_empty'),
      );
      expect(invalid.canPublish, isFalse);
      expect(empty.canPublish, isFalse);
    });

    test('rejects duplicate primitive identities before publication', () {
      final fixture = _Fixture.complete();
      final result = _assess(
        fixture,
        definition: fixture.definitionFor(
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive('same', BorderPrimitiveRole.structureLarge),
            fixture.primitive('same', BorderPrimitiveRole.filler),
          ],
        ),
      );

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.blueprint.duplicate_primitive_id'),
      );
    });

    test('checks snapshot existence, caller integrity, and metric dimensions',
        () {
      final fixture = _Fixture.complete();
      final primitive = fixture.primitive(
        'large',
        BorderPrimitiveRole.structureLarge,
      );
      final definition = fixture.definitionFor(
        primitives: <BorderPublishedPrimitive>[primitive],
      );
      final report = _validGalleryReport(
        blueprintId: 'coast',
        definition: definition,
      );

      final missing = _assess(
        fixture,
        definition: definition,
        visualSnapshots: const <BorderVisualSnapshot>[],
        snapshotIntegrity: const <String, BorderVisualSnapshotIntegrity>{},
        galleryReport: report,
      );
      final corrupt = _assess(
        fixture,
        definition: definition,
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          primitive.visualSnapshotId: BorderVisualSnapshotIntegrity(
            snapshotId: primitive.visualSnapshotId,
            metadataValid: true,
            filesPresent: false,
            contentFingerprintMatches: true,
          ),
        },
        galleryReport: report,
      );
      final mismatched = _assess(
        fixture,
        definition: definition,
        visualSnapshots: <BorderVisualSnapshot>[
          fixture.snapshot(0, width: 1, height: 2),
        ],
        galleryReport: report,
      );

      expect(
        _codes(missing),
        contains('border.blueprint.visual_snapshot_missing'),
      );
      expect(
        _codes(corrupt),
        contains('border.blueprint.visual_snapshot_invalid'),
      );
      expect(
        _codes(mismatched),
        contains('border.publication.snapshot_metrics_mismatch'),
      );
    });

    test('rejects duplicate snapshot ids independently of input order', () {
      final fixture = _Fixture.complete();
      final duplicateSnapshots = <BorderVisualSnapshot>[
        fixture.snapshot(0),
        fixture.snapshot(0, width: 1, height: 2),
        fixture.snapshot(1),
        fixture.snapshot(2),
      ];

      final first = _assess(
        fixture,
        visualSnapshots: duplicateSnapshots,
      );
      final second = _assess(
        fixture,
        visualSnapshots: duplicateSnapshots.reversed.toList(),
      );

      expect(first, second);
      expect(first.canPublish, isFalse);
      expect(
        _codes(first),
        contains('border.publication.duplicate_visual_snapshot_id'),
      );
    });

    test('checks candidate source-element and selected Surface references', () {
      final fixture = _Fixture.complete();
      final missingElement = _assess(
        fixture,
        definition: fixture.definitionFor(
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'missing-source',
              BorderPrimitiveRole.structureLarge,
            ),
          ],
        ),
      );
      final missingSurface = _assess(
        fixture,
        definition: fixture.definitionFor(
          ground: _ground(
            presetId: 'missing-surface',
            snapshotId: fixture.snapshotId(0),
          ),
        ),
      );

      expect(
        _codes(missingElement),
        contains('border.blueprint.source_element_missing'),
      );
      expect(
        _codes(missingSurface),
        contains('border.blueprint.source_surface_preset_missing'),
      );
      expect(missingElement.canPublish, isFalse);
      expect(missingSurface.canPublish, isFalse);
    });

    test('rejects ground for every linear template', () {
      final fixture = _Fixture.complete();
      final ground = _ground(
        presetId: 'sand',
        snapshotId: fixture.snapshotId(0),
      );
      final definitions = <BorderBlueprintPublishedDefinition>[
        fixture.definitionFor(
          template: BorderBlueprintTemplate.masonryLine,
          ground: ground,
        ),
        fixture.definitionFor(
          template: BorderBlueprintTemplate.postAndRailLine,
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.post, snapshot: 0),
            fixture.primitive('span', BorderPrimitiveRole.span, snapshot: 1),
          ],
          ground: ground,
        ),
      ];

      for (final definition in definitions) {
        final result = _assess(fixture, definition: definition);
        final errors = result.diagnosticReport.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity == BorderDiagnosticSeverity.error,
            )
            .toList(growable: false);

        expect(result.canPublish, isFalse, reason: definition.template.name);
        expect(errors, hasLength(1), reason: definition.template.name);
        expect(
          errors.single.code,
          'border.publication.linear_ground_not_supported',
          reason: definition.template.name,
        );
        expect(
          errors.single.parameters,
          <String, Object?>{'template': definition.template.name},
          reason: definition.template.name,
        );
        expect(
          errors.single.suggestedAction,
          'border.action.remove_ground_from_linear_blueprint',
          reason: definition.template.name,
        );
      }
    });

    test('ground role snapshots and isolated Surface fallback must resolve',
        () {
      final fixture = _Fixture.complete();
      final groundSnapshotId = fixture.snapshotId(3);
      final definition = fixture.definitionFor(
        ground: _ground(
          presetId: 'sand',
          snapshotId: groundSnapshotId,
        ),
      );
      final missingSnapshot = _assess(fixture, definition: definition);
      final available = _assess(
        fixture,
        definition: definition,
        visualSnapshots: <BorderVisualSnapshot>[
          ...fixture.snapshots,
          fixture.snapshot(3),
        ],
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          ...fixture.integrity,
          groundSnapshotId: fixture.validIntegrity(groundSnapshotId),
        },
      );
      final brokenProject = fixture.project.copyWith(
        surfaceCatalog: ProjectSurfaceCatalog(
          animations: <ProjectSurfaceAnimation>[
            _surfaceAnimation('sand-isolated'),
          ],
          presets: <ProjectSurfacePreset>[
            ProjectSurfacePreset(
              id: 'broken',
              name: 'Broken',
              variantAnimations: SurfaceVariantAnimationRefSet(
                refs: <SurfaceVariantAnimationRef>[
                  SurfaceVariantAnimationRef(
                    role: SurfaceVariantRole.isolated,
                    animationId: 'sand-isolated',
                  ),
                  SurfaceVariantAnimationRef(
                    role: SurfaceVariantRole.endNorth,
                    animationId: 'missing-animation',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      final brokenDefinition = fixture.definitionFor(
        ground: _ground(
          presetId: 'broken',
          snapshotId: fixture.snapshotId(0),
        ),
      );
      final broken = _assess(
        fixture,
        definition: brokenDefinition,
        project: brokenProject,
      );

      expect(
        _codes(missingSnapshot),
        contains('border.blueprint.visual_snapshot_missing'),
      );
      expect(available.canPublish, isTrue);
      expect(
        _codes(broken),
        contains('border.publication.ground_surface_unresolvable'),
      );
      final unresolved = broken.diagnosticReport.diagnostics.singleWhere(
        (item) => item.code == 'border.publication.ground_surface_unresolvable',
      );
      expect(unresolved.parameters['roles'], <String>['endNorth']);
      expect(
        unresolved.parameters['missingAnimationIds'],
        <String>['missing-animation'],
      );
      expect(broken.canPublish, isFalse);
    });

    test('ground Surface fallback uses the first authored reference', () {
      final fixture = _Fixture.complete();
      final project = fixture.project.copyWith(
        surfaceCatalog: ProjectSurfaceCatalog(
          animations: <ProjectSurfaceAnimation>[
            _surfaceAnimation('sand-horizontal'),
            _surfaceAnimation('sand-corner'),
          ],
          presets: <ProjectSurfacePreset>[
            ProjectSurfacePreset(
              id: 'first-authored-fallback',
              name: 'First authored fallback',
              variantAnimations: SurfaceVariantAnimationRefSet(
                refs: <SurfaceVariantAnimationRef>[
                  SurfaceVariantAnimationRef(
                    role: SurfaceVariantRole.horizontal,
                    animationId: 'sand-horizontal',
                  ),
                  SurfaceVariantAnimationRef(
                    role: SurfaceVariantRole.cornerNE,
                    animationId: 'sand-corner',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      final result = _assess(
        fixture,
        project: project,
        definition: fixture.definitionFor(
          ground: _ground(
            presetId: 'first-authored-fallback',
            snapshotId: fixture.snapshotId(0),
          ),
        ),
      );

      expect(
        _codes(result),
        isNot(contains('border.publication.ground_surface_unresolvable')),
      );
      expect(result.canPublish, isTrue);
    });

    test('blocks a missing gallery or a gap beyond candidate tolerance', () {
      final fixture = _Fixture.complete();
      final absent = _assess(
        fixture,
        galleryReport: BorderPublicationGalleryReport(
          resolverVersion: _resolverVersion,
          canonicalGalleryVersion: borderCanonicalGalleryVersion,
          candidateFingerprint: computeBorderPublicationCandidateFingerprint(
            blueprintId: 'coast',
            definition: fixture.definition,
            resolverVersion: _resolverVersion,
          ),
          samples: const <BorderPublicationGallerySample>[],
        ),
      );
      final gap = _assess(
        fixture,
        samples: _samplesWith(
          fixture.definition,
          _gapSample(
            BorderCanonicalGalleryCase.sharpConvexCorner,
            fixture.definition,
            longestGapPx: 3,
          ),
        ),
      );

      expect(
        _codes(absent),
        contains('border.publication.canonical_gallery_missing'),
      );
      expect(
        _codes(gap),
        contains('border.publication.coverage_gap_exceeded'),
      );
      expect(absent.canPublish, isFalse);
      expect(gap.canPublish, isFalse);
    });

    test('requires the exact canonical case set for the template', () {
      final fixture = _Fixture.complete();
      final incomplete = _passingSamplesFor(fixture.definition)
          .where(
            (sample) =>
                sample.galleryCase != BorderCanonicalGalleryCase.smallIsland,
          )
          .toList()
        ..add(BorderPublicationGallerySample(
          galleryCase: BorderCanonicalGalleryCase.endpoint,
          coverageChecks: <BorderPublicationCoverageCheck>[
            _passingCoverage(
              BorderCanonicalCoverageComponent.primary,
              fixture.definition,
            ),
          ],
          structuralRuns: const <BorderPublicationStructuralRun>[],
        ));

      final result = _assess(fixture, samples: incomplete);
      final diagnostic = result.diagnosticReport.diagnostics.singleWhere(
        (item) =>
            item.code == 'border.publication.canonical_gallery_incomplete',
      );

      expect(result.canPublish, isFalse);
      expect(diagnostic.parameters['missingCases'], <String>['smallIsland']);
      expect(diagnostic.parameters['unexpectedCases'], <String>['endpoint']);
    });

    test('requires both outer and inner coverage for the canonical hole', () {
      final fixture = _Fixture.complete();
      final incompleteHole = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.hole,
        coverageChecks: <BorderPublicationCoverageCheck>[
          _passingCoverage(
            BorderCanonicalCoverageComponent.outerLoop,
            fixture.definition,
          ),
        ],
        structuralRuns: const <BorderPublicationStructuralRun>[],
      );

      final result = _assess(
        fixture,
        samples: _samplesWith(fixture.definition, incompleteHole),
      );
      final diagnostic = result.diagnosticReport.diagnostics.singleWhere(
        (item) =>
            item.code ==
            'border.publication.canonical_sample_coverage_incomplete',
      );

      expect(result.canPublish, isFalse);
      expect(diagnostic.parameters['missingComponents'], <String>['innerLoop']);
      expect(diagnostic.parameters['unexpectedComponents'], isEmpty);
    });

    test('rejects canonical evidence fingerprinted for an older candidate', () {
      final fixture = _Fixture.complete();
      final oldDefinition = fixture.definition;
      final currentDefinition = fixture.definitionFor(
        primitives: <BorderPublishedPrimitive>[
          ...oldDefinition.primitives,
          fixture.primitive('accent', BorderPrimitiveRole.accent),
        ],
      );
      final staleReport = BorderPublicationGalleryReport(
        resolverVersion: _resolverVersion,
        canonicalGalleryVersion: borderCanonicalGalleryVersion,
        candidateFingerprint: computeBorderPublicationCandidateFingerprint(
          blueprintId: 'coast',
          definition: oldDefinition,
          resolverVersion: _resolverVersion,
        ),
        samples: _passingSamplesFor(currentDefinition),
      );

      final result = _assess(
        fixture,
        definition: currentDefinition,
        galleryReport: staleReport,
      );

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.publication.canonical_gallery_stale'),
      );
    });

    test('rejects gallery evidence from another resolver version', () {
      final fixture = _Fixture.complete();
      final report = BorderPublicationGalleryReport(
        resolverVersion: _resolverVersion + 1,
        canonicalGalleryVersion: borderCanonicalGalleryVersion,
        candidateFingerprint: computeBorderPublicationCandidateFingerprint(
          blueprintId: 'coast',
          definition: fixture.definition,
          resolverVersion: _resolverVersion + 1,
        ),
        samples: _passingSamplesFor(fixture.definition),
      );

      final result = _assess(fixture, galleryReport: report);

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.publication.canonical_gallery_version_mismatch'),
      );
    });

    test('rejects gallery evidence assessed with other generation limits', () {
      final fixture = _Fixture.complete();
      final staleSample = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.gentleCurve,
        coverageChecks: <BorderPublicationCoverageCheck>[
          BorderPublicationCoverageCheck(
            component: BorderCanonicalCoverageComponent.primary,
            longestContiguousGapPx: 2,
            maximumPairwiseOverlapPx: 0,
            gapTolerancePx: 2,
            maxOverlapPx: 1,
          ),
        ],
        structuralRuns: const <BorderPublicationStructuralRun>[],
      );
      final result = _assess(
        fixture,
        samples: _samplesWith(fixture.definition, staleSample),
      );

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        containsAll(<String>[
          'border.publication.canonical_coverage_parameters_mismatch',
          'border.publication.coverage_gap_exceeded',
        ]),
      );
    });

    test('warns without blocking on excessive overlap', () {
      final fixture = _Fixture.complete();
      final sample = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.longEdge,
        coverageChecks: <BorderPublicationCoverageCheck>[
          BorderPublicationCoverageCheck(
            component: BorderCanonicalCoverageComponent.primary,
            longestContiguousGapPx: 0,
            maximumPairwiseOverlapPx: 2,
            gapTolerancePx: 1,
            maxOverlapPx: 1,
          ),
        ],
        structuralRuns: const <BorderPublicationStructuralRun>[],
      );
      final result = _assess(
        fixture,
        samples: _samplesWith(fixture.definition, sample),
      );

      expect(result.canPublish, isTrue);
      expect(result.diagnosticReport.warningCount, 1);
      expect(
        _codes(result),
        contains('border.publication.coverage_overlap_exceeded'),
      );
    });

    test('warns for four repeats and low variety in twelve eligible slots', () {
      final fixture = _Fixture.complete();
      final sample = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.longEdge,
        coverageChecks: <BorderPublicationCoverageCheck>[
          ..._passingCoverageChecks(
            BorderCanonicalGalleryCase.longEdge,
            fixture.definition,
          ),
        ],
        structuralRuns: <BorderPublicationStructuralRun>[
          BorderPublicationStructuralRun(
            id: 'outer-pass',
            role: BorderPrimitiveRole.structureLarge,
            quarterTurns: 0,
            passIndex: 0,
            primitiveIds: const <String>[
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-b',
              'large-b',
              'large-a',
              'large-b',
              'large-a',
              'large-b',
              'large-a',
              'large-b',
            ],
          ),
        ],
      );
      final result = _assess(
        fixture,
        samples: _samplesWith(fixture.definition, sample),
      );

      expect(result.canPublish, isTrue);
      expect(
        _codes(result),
        containsAll(<String>[
          'border.publication.repetition_run',
          'border.publication.repetition_variety',
        ]),
      );
    });

    test('does not demand variety unavailable to the structural run', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive('large-a', BorderPrimitiveRole.structureLarge),
          fixture.primitive(
            'large-b',
            BorderPrimitiveRole.structureLarge,
            snapshot: 1,
            quarterTurns: const <int>[1, 2, 3],
          ),
          fixture.primitive(
            'large-c',
            BorderPrimitiveRole.structureLarge,
            snapshot: 2,
            quarterTurns: const <int>[1, 2, 3],
          ),
        ],
      );
      final sample = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.longEdge,
        coverageChecks: <BorderPublicationCoverageCheck>[
          ..._passingCoverageChecks(
            BorderCanonicalGalleryCase.longEdge,
            definition,
          ),
        ],
        structuralRuns: <BorderPublicationStructuralRun>[
          BorderPublicationStructuralRun(
            id: 'single-eligible-pass',
            role: BorderPrimitiveRole.structureLarge,
            quarterTurns: 0,
            passIndex: 0,
            primitiveIds: const <String>[
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
              'large-a',
            ],
          ),
        ],
      );
      final result = _assess(
        fixture,
        definition: definition,
        samples: _samplesWith(definition, sample),
      );

      expect(result.canPublish, isTrue);
      expect(
        _codes(result),
        isNot(contains('border.publication.repetition_run')),
      );
      expect(
        _codes(result),
        isNot(contains('border.publication.repetition_variety')),
      );
    });

    test(
        'sorts deterministic JSON-safe diagnostics independently of input order',
        () {
      final fixture = _Fixture.complete();
      final samples = _samplesWith(
        fixture.definition,
        _gapSample(
          BorderCanonicalGalleryCase.hole,
          fixture.definition,
        ),
      );
      final first = _assess(
        fixture,
        visualSnapshots: fixture.snapshots.reversed.toList(),
        snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
          for (final entry in fixture.integrity.entries.toList().reversed)
            entry.key: entry.value,
        },
        samples: samples.reversed.toList(),
      );
      final second = _assess(fixture, samples: samples);

      expect(first, second);
      for (final diagnostic in first.diagnosticReport.diagnostics) {
        expect(() => jsonEncode(diagnostic.parameters), returnsNormally);
      }
    });
  });

  group('publication gallery values', () {
    test('copy input collections and adapt coverage assessments', () {
      final primitiveIds = <String>['a'];
      final run = BorderPublicationStructuralRun(
        id: 'run',
        role: BorderPrimitiveRole.structureLarge,
        quarterTurns: 0,
        passIndex: 0,
        primitiveIds: primitiveIds,
      );
      primitiveIds.add('b');
      final assessment = assessBorderLoopCoverage(
        perimeterPx: 8,
        projections: <BorderStructuralCoverageProjection>[
          BorderStructuralCoverageProjection(
            placementId: 'placement',
            drawBand: BorderDrawBand.structure,
            passIndex: 0,
            intervals: <BorderCoverageInterval>[
              BorderCoverageInterval(startPx: 0, endPx: 8),
            ],
          ),
        ],
        gapTolerancePx: 0,
        maxOverlapPx: 0,
      );
      final check = BorderPublicationCoverageCheck.fromLoopAssessment(
        component: BorderCanonicalCoverageComponent.primary,
        assessment: assessment,
      );

      expect(run.primitiveIds, <String>['a']);
      expect(() => run.primitiveIds.add('c'), throwsUnsupportedError);
      expect(check.longestContiguousGapPx, 0);
      expect(check.maximumPairwiseOverlapPx, 0);
      expect(check.isWithinTolerance, isTrue);
    });

    test('rejects metrics outside the portable JSON integer range', () {
      expect(
        () => BorderPublicationCoverageCheck(
          component: BorderCanonicalCoverageComponent.primary,
          longestContiguousGapPx: int.parse('9007199254740992'),
          maximumPairwiseOverlapPx: 0,
          gapTolerancePx: 0,
          maxOverlapPx: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

BorderPublicationReadinessResult _assess(
  _Fixture fixture, {
  BorderBlueprintPublishedDefinition? definition,
  ProjectManifest? project,
  List<BorderVisualSnapshot>? visualSnapshots,
  Map<String, BorderVisualSnapshotIntegrity>? snapshotIntegrity,
  List<BorderPublicationGallerySample>? samples,
  BorderPublicationGalleryReport? galleryReport,
}) {
  final candidate = definition ?? fixture.definition;
  return assessBorderPublicationReadiness(
    blueprintId: 'coast',
    definition: candidate,
    resolverVersion: _resolverVersion,
    project: project ?? fixture.project,
    visualSnapshots: visualSnapshots ?? fixture.snapshots,
    snapshotIntegrity: snapshotIntegrity ?? fixture.integrity,
    canonicalGalleryReport: galleryReport ??
        _validGalleryReport(
          blueprintId: 'coast',
          definition: candidate,
          samples: samples,
        ),
  );
}

List<String> _codes(BorderPublicationReadinessResult result) => <String>[
      for (final diagnostic in result.diagnosticReport.diagnostics)
        diagnostic.code,
    ];

BorderPublicationGalleryReport _validGalleryReport({
  required String blueprintId,
  required BorderBlueprintPublishedDefinition definition,
  List<BorderPublicationGallerySample>? samples,
}) =>
    BorderPublicationGalleryReport(
      resolverVersion: _resolverVersion,
      canonicalGalleryVersion: borderCanonicalGalleryVersion,
      candidateFingerprint: computeBorderPublicationCandidateFingerprint(
        blueprintId: blueprintId,
        definition: definition,
        resolverVersion: _resolverVersion,
      ),
      samples: samples ?? _passingSamplesFor(definition),
    );

List<BorderPublicationGallerySample> _passingSamplesFor(
  BorderBlueprintPublishedDefinition definition,
) =>
    <BorderPublicationGallerySample>[
      for (final galleryCase
          in borderCanonicalGalleryCasesForTemplate(definition.template))
        _passingSample(galleryCase, definition),
    ];

List<BorderPublicationGallerySample> _samplesWith(
  BorderBlueprintPublishedDefinition definition,
  BorderPublicationGallerySample replacement,
) =>
    <BorderPublicationGallerySample>[
      for (final sample in _passingSamplesFor(definition))
        if (sample.galleryCase == replacement.galleryCase)
          replacement
        else
          sample,
    ];

BorderPublicationGallerySample _passingSample(
  BorderCanonicalGalleryCase galleryCase,
  BorderBlueprintPublishedDefinition definition,
) {
  BorderPrimitiveRole? runRole;
  for (final primitive in definition.primitives) {
    if (_isStructural(primitive.role, definition.template) &&
        primitive.transforms.allowedQuarterTurns.contains(0)) {
      runRole = primitive.role;
      break;
    }
  }
  final eligibleIds = runRole == null
      ? <String>[]
      : <String>[
          for (final primitive in definition.primitives)
            if (primitive.role == runRole &&
                primitive.transforms.allowedQuarterTurns.contains(0))
              primitive.id,
        ]
    ..sort();
  return BorderPublicationGallerySample(
    galleryCase: galleryCase,
    coverageChecks: _passingCoverageChecks(galleryCase, definition),
    structuralRuns: galleryCase == BorderCanonicalGalleryCase.longEdge &&
            runRole != null &&
            eligibleIds.isNotEmpty
        ? <BorderPublicationStructuralRun>[
            BorderPublicationStructuralRun(
              id: 'outer-pass',
              role: runRole,
              quarterTurns: 0,
              passIndex: _passIndex(definition.template, runRole),
              primitiveIds: <String>[
                for (var index = 0; index < 12; index += 1)
                  eligibleIds[index % eligibleIds.length],
              ],
            ),
          ]
        : const <BorderPublicationStructuralRun>[],
  );
}

BorderPublicationGallerySample _gapSample(
  BorderCanonicalGalleryCase galleryCase,
  BorderBlueprintPublishedDefinition definition, {
  int longestGapPx = 2,
}) =>
    BorderPublicationGallerySample(
      galleryCase: galleryCase,
      coverageChecks: <BorderPublicationCoverageCheck>[
        for (final component in borderCanonicalCoverageComponentsForCase(
          template: definition.template,
          galleryCase: galleryCase,
        ))
          BorderPublicationCoverageCheck(
            component: component,
            longestContiguousGapPx: component ==
                    borderCanonicalCoverageComponentsForCase(
                      template: definition.template,
                      galleryCase: galleryCase,
                    ).first
                ? longestGapPx
                : 0,
            maximumPairwiseOverlapPx: 0,
            gapTolerancePx: definition.defaults.gapTolerancePx,
            maxOverlapPx: definition.defaults.maxOverlapPx,
          ),
      ],
      structuralRuns: const <BorderPublicationStructuralRun>[],
    );

List<BorderPublicationCoverageCheck> _passingCoverageChecks(
  BorderCanonicalGalleryCase galleryCase,
  BorderBlueprintPublishedDefinition definition,
) =>
    <BorderPublicationCoverageCheck>[
      for (final component in borderCanonicalCoverageComponentsForCase(
        template: definition.template,
        galleryCase: galleryCase,
      ))
        _passingCoverage(component, definition),
    ];

BorderPublicationCoverageCheck _passingCoverage(
  BorderCanonicalCoverageComponent component,
  BorderBlueprintPublishedDefinition definition,
) =>
    BorderPublicationCoverageCheck(
      component: component,
      longestContiguousGapPx: 0,
      maximumPairwiseOverlapPx: definition.defaults.maxOverlapPx,
      gapTolerancePx: definition.defaults.gapTolerancePx,
      maxOverlapPx: definition.defaults.maxOverlapPx,
    );

int _passIndex(
  BorderBlueprintTemplate template,
  BorderPrimitiveRole role,
) =>
    switch ((template, role)) {
      (
        BorderBlueprintTemplate.organicEdge ||
            BorderBlueprintTemplate.masonryLine,
        BorderPrimitiveRole.structureLarge,
      ) =>
        0,
      (
        BorderBlueprintTemplate.organicEdge ||
            BorderBlueprintTemplate.masonryLine,
        BorderPrimitiveRole.structureMedium,
      ) =>
        1,
      (
        BorderBlueprintTemplate.organicEdge ||
            BorderBlueprintTemplate.masonryLine,
        BorderPrimitiveRole.filler,
      ) =>
        2,
      (BorderBlueprintTemplate.postAndRailLine, BorderPrimitiveRole.span) => 0,
      (BorderBlueprintTemplate.postAndRailLine, BorderPrimitiveRole.post) => 1,
      _ => throw StateError('Non-structural publication run role'),
    };

bool _isStructural(
  BorderPrimitiveRole role,
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge ||
      BorderBlueprintTemplate.masonryLine =>
        role == BorderPrimitiveRole.structureLarge ||
            role == BorderPrimitiveRole.structureMedium ||
            role == BorderPrimitiveRole.filler,
      BorderBlueprintTemplate.postAndRailLine =>
        role == BorderPrimitiveRole.post || role == BorderPrimitiveRole.span,
    };

BorderPublishedGround _ground({
  required String presetId,
  required String snapshotId,
}) =>
    BorderPublishedGround(
      sourceSurfacePresetId: presetId,
      edgeBandCells: 2,
      visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
        for (final role in standardSurfaceVariantRoleOrder) role: snapshotId,
      },
    );

final class _Fixture {
  _Fixture.complete()
      : snapshots = <BorderVisualSnapshot>[
          for (var index = 0; index < 3; index += 1) _snapshot(index),
        ],
        integrity = <String, BorderVisualSnapshotIntegrity>{
          for (var index = 0; index < 3; index += 1)
            _snapshotId(index): _validIntegrity(_snapshotId(index)),
        } {
    project = _project();
    definition = definitionFor(
      primitives: <BorderPublishedPrimitive>[
        primitive('large-a', BorderPrimitiveRole.structureLarge, snapshot: 0),
        primitive('large-b', BorderPrimitiveRole.structureLarge, snapshot: 1),
        primitive('large-c', BorderPrimitiveRole.structureLarge, snapshot: 2),
      ],
    );
  }

  late final BorderBlueprintPublishedDefinition definition;
  late final ProjectManifest project;
  final List<BorderVisualSnapshot> snapshots;
  final Map<String, BorderVisualSnapshotIntegrity> integrity;

  String snapshotId(int index) => _snapshotId(index);

  BorderVisualSnapshot snapshot(
    int index, {
    int width = 2,
    int height = 2,
  }) =>
      _snapshot(index, width: width, height: height);

  BorderVisualSnapshotIntegrity validIntegrity(String id) =>
      _validIntegrity(id);

  BorderPrimitiveAssetMetrics metrics({
    String occupancy = 'border-rle-v1:4:1:4',
    BorderPixelPos defaultAnchor = const BorderPixelPos(x: 1, y: 1),
  }) =>
      BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset',
        pixelSize: const GridSize(width: 2, height: 2),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
        defaultAnchorPx: defaultAnchor,
        occupancyMaskRle: occupancy,
      );

  BorderPublishedPrimitive primitive(
    String id,
    BorderPrimitiveRole role, {
    int snapshot = 0,
    List<int> quarterTurns = const <int>[0, 1, 2, 3],
    BorderPixelPos anchor = const BorderPixelPos(x: 1, y: 1),
    BorderPrimitiveAssetMetrics? metrics,
  }) =>
      BorderPublishedPrimitive(
        id: id,
        sourceElementId: 'element-$id',
        visualSnapshotId: snapshotId(snapshot),
        role: role,
        weight: 100,
        anchorPx: anchor,
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: quarterTurns,
        ),
        publishedMetrics: metrics ?? this.metrics(),
      );

  BorderBlueprintPublishedDefinition definitionFor({
    BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
    List<BorderPublishedPrimitive>? primitives,
    BorderPublishedGround? ground,
  }) =>
      BorderBlueprintPublishedDefinition(
        name: 'Coast',
        previewSeed: BorderSignedInt64.zero,
        template: template,
        primitives: primitives ?? definition.primitives,
        defaults: BorderGenerationParams(
          irregularityPermille: 500,
          detailDensityPermille: 500,
          variationPermille: 500,
          maxOverlapPx: 1,
          gapTolerancePx: 1,
          depthRows: 2,
        ),
        ground: ground,
        sortOrder: 0,
      );
}

String _snapshotId(int index) {
  final char = String.fromCharCode('a'.codeUnitAt(0) + index);
  final fingerprint = List<String>.filled(64, char).join();
  return 'border-snapshot-sha256:$fingerprint';
}

BorderVisualSnapshot _snapshot(
  int index, {
  int width = 2,
  int height = 2,
}) {
  final id = _snapshotId(index);
  final fingerprint = id.substring('border-snapshot-sha256:'.length);
  return BorderVisualSnapshot(
    id: id,
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$fingerprint.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: width,
          height: height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

BorderVisualSnapshotIntegrity _validIntegrity(String id) =>
    BorderVisualSnapshotIntegrity(
      snapshotId: id,
      metadataValid: true,
      filesPresent: true,
      contentFingerprintMatches: true,
    );

ProjectSurfaceAnimation _surfaceAnimation(String id) => ProjectSurfaceAnimation(
      id: id,
      name: id,
      timeline: SurfaceAnimationTimeline(
        frames: <SurfaceAnimationFrame>[
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'surface-atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 100,
          ),
        ],
      ),
    );

ProjectManifest _project() => ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      elements: <ProjectElementEntry>[
        for (final id in <String>[
          'large-a',
          'large-b',
          'large-c',
          'large',
          'accent',
          'post',
          'span',
          'invalid-rle',
          'empty',
          'same',
        ])
          ProjectElementEntry(
            id: 'element-$id',
            name: id,
            tilesetId: 'tileset',
            categoryId: 'border',
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(
        animations: <ProjectSurfaceAnimation>[
          _surfaceAnimation('sand-isolated'),
        ],
        presets: <ProjectSurfacePreset>[
          ProjectSurfacePreset(
            id: 'sand',
            name: 'Sand',
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: <SurfaceVariantAnimationRef>[
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'sand-isolated',
                ),
              ],
            ),
          ),
        ],
      ),
    );
