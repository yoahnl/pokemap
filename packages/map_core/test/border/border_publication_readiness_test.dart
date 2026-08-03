import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/stone_chain_line_fixture.dart';

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
        (
          BorderBlueprintTemplate.connectedLine,
          <BorderPublishedPrimitive>[
            fixture.primitive('post', BorderPrimitiveRole.lineCap),
            fixture.primitive('accent', BorderPrimitiveRole.lineCorner),
          ],
          <String>['lineStraight'],
        ),
        (
          BorderBlueprintTemplate.stoneChainLine,
          <BorderPublishedPrimitive>[
            fixture.primitive(
              'accent',
              BorderPrimitiveRole.structureMedium,
            ),
          ],
          <String>['structureLarge'],
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
        (
          BorderBlueprintTemplate.stoneChainLine,
          <BorderPublishedPrimitive>[
            fixture.primitive(
              'large-a',
              BorderPrimitiveRole.structureLarge,
            ),
            fixture.primitive('accent', BorderPrimitiveRole.accent),
          ],
          <String>['accent'],
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
      expect(
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.connectedLine,
        ),
        <BorderPrimitiveRole>{
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
          BorderPrimitiveRole.lineCorner,
        },
      );
      expect(
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.stoneChainLine,
        ),
        <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
          BorderPrimitiveRole.filler,
          BorderPrimitiveRole.lineCorner,
          BorderPrimitiveRole.lineCap,
        },
      );
      expect(
        borderTemplateRequiredPrimitiveRoles(
          template: BorderBlueprintTemplate.stoneChainLine,
          depthRows: 1,
        ),
        const <BorderPrimitiveRole>{BorderPrimitiveRole.structureLarge},
      );
      expect(
        borderTemplateRequiredPrimitiveRoles(
          template: BorderBlueprintTemplate.stoneChainLine,
          depthRows: 2,
        ),
        const <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
        },
      );
    });

    test('stone-chain optional roles remain optional', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'large-a',
            BorderPrimitiveRole.structureLarge,
          ),
          fixture.primitive(
            'large-b',
            BorderPrimitiveRole.structureLarge,
            snapshot: 1,
          ),
          fixture.primitive(
            'large-c',
            BorderPrimitiveRole.structureLarge,
            snapshot: 2,
          ),
        ],
        defaults: _stoneChainParams(depthRows: 1),
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isTrue);
      expect(_codes(result),
          isNot(contains('border.publication.required_role_missing')));
    });

    test('stone-chain rotation and depth rules are blocking and explicit', () {
      final fixture = _Fixture.complete();
      BorderBlueprintPublishedDefinition definition({
        required bool allowAutoRotation,
        required int depthRows,
      }) =>
          fixture.definitionFor(
            template: BorderBlueprintTemplate.stoneChainLine,
            primitives: <BorderPublishedPrimitive>[
              fixture.primitive(
                'large-a',
                BorderPrimitiveRole.structureLarge,
                quarterTurns: const <int>[0],
              ),
            ],
            defaults: BorderGenerationParams(
              irregularityPermille: 0,
              detailDensityPermille: 0,
              variationPermille: 0,
              maxOverlapPx: 1,
              gapTolerancePx: 1,
              depthRows: depthRows,
              allowAutoRotation: allowAutoRotation,
            ),
          );

      final rotationOff = _assess(
        fixture,
        definition: definition(allowAutoRotation: false, depthRows: 1),
      );
      final rotationOn = _assess(
        fixture,
        definition: definition(allowAutoRotation: true, depthRows: 1),
      );
      final invalidDepth = _assess(
        fixture,
        definition: definition(allowAutoRotation: false, depthRows: 3),
      );

      expect(rotationOff.canPublish, isTrue);
      expect(
        _codes(rotationOff),
        isNot(contains('border.publication.stone_chain_transform_unavailable')),
      );
      expect(rotationOn.canPublish, isFalse);
      expect(
        _codes(rotationOn),
        contains('border.publication.stone_chain_transform_unavailable'),
      );
      expect(invalidDepth.canPublish, isFalse);
      expect(
        _codes(invalidDepth),
        contains('border.publication.stone_chain_depth_rows_invalid'),
      );
    });

    test('stone-chain with fewer than three primary variants only warns', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'large-a',
            BorderPrimitiveRole.structureLarge,
          ),
        ],
        defaults: _stoneChainParams(depthRows: 1),
      );

      final result = _assess(fixture, definition: definition);
      final warning = result.diagnosticReport.diagnostics.singleWhere(
        (diagnostic) =>
            diagnostic.code ==
            'border.publication.stone_chain_primary_variety_low',
      );

      expect(result.canPublish, isTrue);
      expect(warning.severity, BorderDiagnosticSeverity.warning);
    });

    test('stone-chain cardinal assets require the two-tier planner', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'large-north',
            BorderPrimitiveRole.structureLarge,
            authoredOrientation: BorderPrimitiveOrientation.north,
          ),
        ],
        defaults: _stoneChainParams(depthRows: 1),
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains(
          'border.publication.stone_chain_cardinal_depth_one_unsupported',
        ),
      );
    });

    test('two-tier stone-chain requires an explicit face role', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(
        fixture,
        faceOrientations: const <BorderPrimitiveOrientation>[],
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.publication.stone_chain_face_role_missing'),
      );
    });

    test('two-tier stone-chain rejects incomplete cardinal coverage', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(
        fixture,
        faceOrientations: const <BorderPrimitiveOrientation>[
          BorderPrimitiveOrientation.north,
          BorderPrimitiveOrientation.east,
          BorderPrimitiveOrientation.south,
        ],
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.publication.stone_chain_directional_coverage_missing'),
      );
    });

    test('two-tier stone-chain rejects mixed legacy and cardinal modes', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(
        fixture,
        lipOrientations: const <BorderPrimitiveOrientation>[
          BorderPrimitiveOrientation.legacyAxis,
          BorderPrimitiveOrientation.east,
          BorderPrimitiveOrientation.south,
          BorderPrimitiveOrientation.west,
        ],
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.publication.stone_chain_mixed_orientation_modes'),
      );
    });

    test('two-tier auto-rotation can cover every direction by transform', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(
        fixture,
        allowAutoRotation: true,
        lipOrientations: const <BorderPrimitiveOrientation>[
          BorderPrimitiveOrientation.east,
        ],
        faceOrientations: const <BorderPrimitiveOrientation>[
          BorderPrimitiveOrientation.east,
        ],
        quarterTurns: const <int>[0, 1, 2, 3],
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isTrue);
      expect(
        _codes(result),
        isNot(
          contains(
            'border.publication.stone_chain_directional_coverage_missing',
          ),
        ),
      );
    });

    test('two-tier rotation-off requires exact N/E/S/W authored assets', () {
      final fixture = _Fixture.complete();
      final incomplete = _twoTierStoneChainDefinition(
        fixture,
        lipOrientations: const <BorderPrimitiveOrientation>[
          BorderPrimitiveOrientation.east,
        ],
        faceOrientations: const <BorderPrimitiveOrientation>[
          BorderPrimitiveOrientation.east,
        ],
        quarterTurns: const <int>[0, 1, 2, 3],
      );
      final complete = _twoTierStoneChainDefinition(fixture);

      final incompleteResult = _assess(fixture, definition: incomplete);
      final completeResult = _assess(fixture, definition: complete);

      expect(incompleteResult.canPublish, isFalse);
      expect(
        _codes(incompleteResult),
        contains('border.publication.stone_chain_directional_coverage_missing'),
      );
      expect(completeResult.canPublish, isTrue);
    });

    test('two-tier gap and low interlock budgets have stable warnings', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(
        fixture,
        gapTolerancePx: 1,
        maxOverlapPx: 3,
      );

      final result = _assess(fixture, definition: definition);
      final diagnostics = <String, BorderDiagnostic>{
        for (final diagnostic in result.diagnosticReport.diagnostics)
          diagnostic.code: diagnostic,
      };

      expect(result.canPublish, isTrue);
      expect(
        diagnostics['border.publication.stone_chain_gap_not_zero']?.severity,
        BorderDiagnosticSeverity.warning,
      );
      expect(
        diagnostics['border.publication.stone_chain_interlock_too_low']
            ?.severity,
        BorderDiagnosticSeverity.warning,
      );
    });

    test('requires connected-line mirror transforms for every topology role',
        () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive('post', BorderPrimitiveRole.lineCap, snapshot: 0),
          fixture.primitive('span', BorderPrimitiveRole.lineStraight,
              snapshot: 1),
          fixture.primitive('accent', BorderPrimitiveRole.lineCorner,
              snapshot: 2),
        ],
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isFalse);
      expect(
        _codes(result),
        contains('border.publication.connected_line_transform_unavailable'),
      );
    });

    test(
        'requires only quarter-turn zero when connected-line auto-rotation is disabled',
        () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'post',
            BorderPrimitiveRole.lineCap,
            snapshot: 0,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
          fixture.primitive(
            'span',
            BorderPrimitiveRole.lineStraight,
            snapshot: 1,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
          fixture.primitive(
            'accent',
            BorderPrimitiveRole.lineCorner,
            snapshot: 2,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
        ],
        defaults: BorderGenerationParams(
          irregularityPermille: 500,
          detailDensityPermille: 500,
          variationPermille: 500,
          maxOverlapPx: 1,
          gapTolerancePx: 1,
          depthRows: 2,
          allowAutoRotation: false,
        ),
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isTrue);
      expect(
        _codes(result),
        isNot(contains(
          'border.publication.connected_line_transform_unavailable',
        )),
      );
    });

    test(
        'keeps requiring connected-line quarter-turns when auto-rotation is enabled',
        () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'post',
            BorderPrimitiveRole.lineCap,
            snapshot: 0,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
          fixture.primitive(
            'span',
            BorderPrimitiveRole.lineStraight,
            snapshot: 1,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
          fixture.primitive(
            'accent',
            BorderPrimitiveRole.lineCorner,
            snapshot: 2,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
        ],
      );

      final result = _assess(fixture, definition: definition);
      final transformDiagnostics = result.diagnosticReport.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.code ==
                'border.publication.connected_line_transform_unavailable',
          )
          .toList(growable: false);

      expect(result.canPublish, isFalse);
      expect(transformDiagnostics, hasLength(14));
      expect(
        transformDiagnostics.map(
          (diagnostic) => diagnostic.parameters['quarterTurns'],
        ),
        everyElement(isNot(0)),
      );
    });

    test('accepts a real connected-line gallery covering both sides', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'post',
            BorderPrimitiveRole.lineCap,
            snapshot: 0,
            allowFlipX: true,
          ),
          fixture.primitive(
            'span',
            BorderPrimitiveRole.lineStraight,
            snapshot: 1,
            allowFlipX: true,
          ),
          fixture.primitive(
            'accent',
            BorderPrimitiveRole.lineCorner,
            snapshot: 2,
            allowFlipX: true,
          ),
        ],
      );
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
      final result = _assess(
        fixture,
        definition: definition,
        galleryReport: gallery.report,
      );

      expect(gallery.allCasesResolved, isTrue);
      expect(result.canPublish, isTrue);
      expect(
        gallery.report.samples.map((sample) => sample.galleryCase),
        <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.sharpCorner,
          BorderCanonicalGalleryCase.endpoint,
          BorderCanonicalGalleryCase.opening,
        ],
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
              allowFlipX: true,
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

    test(
        'accepts an unrotated masonry structure when automatic rotation is disabled',
        () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.masonryLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'large',
            BorderPrimitiveRole.structureLarge,
            quarterTurns: const <int>[0],
            allowFlipX: true,
          ),
        ],
        defaults: BorderGenerationParams(
          irregularityPermille: 500,
          detailDensityPermille: 500,
          variationPermille: 500,
          maxOverlapPx: 1,
          gapTolerancePx: 1,
          depthRows: 1,
          allowAutoRotation: false,
        ),
      );

      final result = _assess(fixture, definition: definition);

      expect(result.canPublish, isTrue);
      expect(
        _codes(result),
        isNot(contains('border.publication.orientation_missing')),
      );
    });

    test('rejects masonry structures that cannot render the inverted side', () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.masonryLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'large',
            BorderPrimitiveRole.structureLarge,
            quarterTurns: const <int>[0],
          ),
        ],
        defaults: BorderGenerationParams(
          irregularityPermille: 500,
          detailDensityPermille: 500,
          variationPermille: 500,
          maxOverlapPx: 1,
          gapTolerancePx: 1,
          depthRows: 1,
          allowAutoRotation: false,
        ),
      );

      final result = _assess(fixture, definition: definition);
      final missing = result.diagnosticReport.diagnostics.singleWhere(
        (diagnostic) =>
            diagnostic.code == 'border.publication.orientation_missing',
      );

      expect(result.canPublish, isFalse);
      expect(missing.parameters, <String, Object?>{
        'orientation': 'east',
        'quarterTurns': 0,
        'roleGroup': 'structure',
        'flipX': true,
      });
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

    test('checks candidate source-element and selected Smart Tile references',
        () {
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
      final missingSmartTile = _assess(
        fixture,
        definition: fixture.definitionFor(
          ground: _ground(
            presetId: 'missing-smart-tile',
            snapshotId: fixture.snapshotId(0),
          ),
        ),
      );

      expect(
        _codes(missingElement),
        contains('border.blueprint.source_element_missing'),
      );
      expect(
        _codes(missingSmartTile),
        contains('border.blueprint.source_smart_tile_preset_missing'),
      );
      expect(missingElement.canPublish, isFalse);
      expect(missingSmartTile.canPublish, isFalse);
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
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'large',
              BorderPrimitiveRole.structureLarge,
              allowFlipX: true,
            ),
          ],
          ground: ground,
        ),
        fixture.definitionFor(
          template: BorderBlueprintTemplate.stoneChainLine,
          primitives: <BorderPublishedPrimitive>[
            fixture.primitive(
              'large-a',
              BorderPrimitiveRole.structureLarge,
            ),
            fixture.primitive(
              'large-b',
              BorderPrimitiveRole.structureLarge,
              snapshot: 1,
            ),
            fixture.primitive(
              'large-c',
              BorderPrimitiveRole.structureLarge,
              snapshot: 2,
            ),
          ],
          ground: ground,
          defaults: _stoneChainParams(depthRows: 1),
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

    test(
        'ground role snapshots suffice once the source Smart Tile is published',
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
      expect(
        _codes(missingSnapshot),
        contains('border.blueprint.visual_snapshot_missing'),
      );
      expect(available.canPublish, isTrue);
    });

    test('ground readiness ignores mutable Smart Tile rules after snapshotting',
        () {
      final fixture = _Fixture.complete();
      final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const <ProjectSmartTileMaterial>[
            ProjectSmartTileMaterial(
              id: 'ground',
              name: 'Ground',
              connectionGroupId: 'ground',
            ),
          ],
          presets: <ProjectSmartTilePreset>[
            _publishedSmartTilePreset('changed-after-snapshot'),
          ],
        ),
      );
      final result = _assess(
        fixture,
        project: project,
        definition: fixture.definitionFor(
          ground: _ground(
            presetId: 'changed-after-snapshot',
            snapshotId: fixture.snapshotId(0),
          ),
        ),
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

    test('blocks stone-chain publication for a measured closed-loop seam gap',
        () {
      final fixture = _Fixture.complete();
      final definition = fixture.definitionFor(
        template: BorderBlueprintTemplate.stoneChainLine,
        primitives: <BorderPublishedPrimitive>[
          fixture.primitive(
            'large-a',
            BorderPrimitiveRole.structureLarge,
          ),
          fixture.primitive(
            'large-b',
            BorderPrimitiveRole.structureLarge,
            snapshot: 1,
          ),
          fixture.primitive(
            'large-c',
            BorderPrimitiveRole.structureLarge,
            snapshot: 2,
          ),
        ],
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 3,
          gapTolerancePx: 2,
          depthRows: 1,
          allowAutoRotation: false,
        ),
      );
      final stroke = stoneChainRectangularLoop(id: 'publication-gap-loop');
      final baselineRequest =
          StoneChainLineFixture(strokes: <BorderStroke>[stroke]).request;
      final baseline = resolveStoneChainLineBorder(baselineRequest);
      final seamX = stroke.points.first.x * baselineRequest.tileSizePx.width;
      final seamY = stroke.points.first.y * baselineRequest.tileSizePx.height;
      final placementsBySeamDistance =
          baseline.materialization!.placements.toList(growable: false)
            ..sort((left, right) {
              int squaredDistance(BorderResolvedPlacement placement) {
                final bounds = placement.opaqueWorldBoundsPx;
                final dx = bounds.x + bounds.width ~/ 2 - seamX;
                final dy = bounds.y + bounds.height ~/ 2 - seamY;
                return dx * dx + dy * dy;
              }

              final byDistance =
                  squaredDistance(left).compareTo(squaredDistance(right));
              return byDistance != 0
                  ? byDistance
                  : left.slotKey.compareTo(right.slotKey);
            });
      final evidence = resolveStoneChainLineBorderWithEvidence(
        StoneChainLineFixture(
          strokes: <BorderStroke>[stroke],
          overrides: <BorderSlotOverride>[
            for (final placement in placementsBySeamDistance.take(4))
              BorderSlotOverride(
                slotKey: placement.slotKey,
                variationSalt: BorderSignedInt64.zero,
                suppressed: true,
                locked: false,
              ),
          ],
        ).request,
      );
      final result = _assess(
        fixture,
        definition: definition,
        samples: _samplesWith(
          definition,
          _gapSample(
            BorderCanonicalGalleryCase.closedLoop,
            definition,
            longestGapPx: evidence.maximumGapPx,
          ),
        ),
      );

      expect(
        evidence.maximumGapPx,
        greaterThan(definition.defaults.gapTolerancePx),
      );
      expect(
        _codes(result),
        contains('border.publication.coverage_gap_exceeded'),
      );
      expect(result.canPublish, isFalse);
    });

    for (final (
          allowAutoRotation,
          expectedSeverity,
          expectedCanPublish,
        ) in <(bool, BorderDiagnosticSeverity, bool)>[
      (false, BorderDiagnosticSeverity.warning, true),
      (true, BorderDiagnosticSeverity.error, false),
    ]) {
      test(
        'keeps connected-line coverage gaps ${allowAutoRotation ? 'blocking with' : 'acknowledgeable without'} automatic rotation',
        () {
          final fixture = _Fixture.complete();
          final definition = fixture.definitionFor(
            template: BorderBlueprintTemplate.connectedLine,
            primitives: <BorderPublishedPrimitive>[
              fixture.primitive(
                'large',
                BorderPrimitiveRole.lineCap,
                snapshot: 0,
                allowFlipX: true,
              ),
              fixture.primitive(
                'post',
                BorderPrimitiveRole.lineStraight,
                snapshot: 1,
                allowFlipX: true,
              ),
              fixture.primitive(
                'span',
                BorderPrimitiveRole.lineCorner,
                snapshot: 2,
                allowFlipX: true,
              ),
            ],
            defaults: BorderGenerationParams(
              irregularityPermille: 500,
              detailDensityPermille: 500,
              variationPermille: 500,
              maxOverlapPx: 1,
              gapTolerancePx: 1,
              depthRows: 2,
              allowAutoRotation: allowAutoRotation,
            ),
          );
          final samples = <BorderPublicationGallerySample>[
            for (final galleryCase in borderCanonicalGalleryCasesForTemplate(
              definition.template,
            ))
              BorderPublicationGallerySample(
                galleryCase: galleryCase,
                coverageChecks: <BorderPublicationCoverageCheck>[
                  for (final component
                      in borderCanonicalCoverageComponentsForCase(
                    template: definition.template,
                    galleryCase: galleryCase,
                  ))
                    BorderPublicationCoverageCheck(
                      component: component,
                      longestContiguousGapPx: 2,
                      maximumPairwiseOverlapPx: 0,
                      gapTolerancePx: definition.defaults.gapTolerancePx,
                      maxOverlapPx: definition.defaults.maxOverlapPx,
                    ),
                ],
                structuralRuns: const <BorderPublicationStructuralRun>[],
              ),
          ];

          final result = _assess(
            fixture,
            definition: definition,
            samples: samples,
          );
          final gapDiagnostics = result.diagnosticReport.diagnostics
              .where(
                (diagnostic) =>
                    diagnostic.code ==
                    'border.publication.coverage_gap_exceeded',
              )
              .toList(growable: false);

          expect(result.canPublish, expectedCanPublish);
          expect(gapDiagnostics, hasLength(5));
          expect(
            gapDiagnostics.map((diagnostic) => diagnostic.severity),
            everyElement(expectedSeverity),
          );
        },
      );
    }

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

    test('requires both stone-chain evidence sides only at depth two', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(fixture);
      final passing = _passingSample(
        BorderCanonicalGalleryCase.endpoint,
        definition,
      );
      for (final missingPrimary in const <bool>[true, false]) {
        final missingSide = BorderPublicationGallerySample(
          galleryCase: passing.galleryCase,
          coverageChecks: passing.coverageChecks,
          structuralRuns: passing.structuralRuns,
          primaryStoneChainEvidence:
              missingPrimary ? null : _passingStoneChainEvidence(),
          invertedStoneChainEvidence:
              missingPrimary ? _passingStoneChainEvidence() : null,
        );
        final strictResult = _assess(
          fixture,
          definition: definition,
          samples: _samplesWith(definition, missingSide),
        );
        expect(strictResult.canPublish, isFalse, reason: '$missingPrimary');
      }
      final historicalResult = _assess(fixture);

      expect(historicalResult.canPublish, isTrue);
      expect(
        _passingSamplesFor(fixture.definition),
        everyElement(
          isA<BorderPublicationGallerySample>()
              .having(
                (sample) => sample.primaryStoneChainEvidence,
                'primary evidence',
                isNull,
              )
              .having(
                (sample) => sample.invertedStoneChainEvidence,
                'inverted evidence',
                isNull,
              ),
        ),
      );
    });

    test('blocks every two-tier evidence threshold independently per side', () {
      final fixture = _Fixture.complete();
      final definition = _twoTierStoneChainDefinition(fixture);
      final invalidInvertedEvidence = <BorderPublicationStoneChainEvidence>[
        _passingStoneChainEvidence(minimumCrossRowInterlockPixels: 7),
        _passingStoneChainEvidence(minimumVisibleFaceDepthPx: 11),
        _passingStoneChainEvidence(alignedJointRatioPermille: 251),
        _passingStoneChainEvidence(lipConnectedComponentCount: 2),
        _passingStoneChainEvidence(faceConnectedComponentCount: 2),
        _passingStoneChainEvidence(combinedConnectedComponentCount: 2),
      ];

      for (final invalidEvidence in invalidInvertedEvidence) {
        final passing = _passingSample(
          BorderCanonicalGalleryCase.endpoint,
          definition,
        );
        final invertedOnlyFailure = BorderPublicationGallerySample(
          galleryCase: passing.galleryCase,
          coverageChecks: passing.coverageChecks,
          structuralRuns: passing.structuralRuns,
          primaryStoneChainEvidence: _passingStoneChainEvidence(),
          invertedStoneChainEvidence: invalidEvidence,
        );

        final result = _assess(
          fixture,
          definition: definition,
          samples: _samplesWith(definition, invertedOnlyFailure),
        );

        expect(result.canPublish, isFalse, reason: '$invalidEvidence');
      }
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
    test('stone-chain evidence has value semantics and validates metrics', () {
      final first = _passingStoneChainEvidence();
      final same = _passingStoneChainEvidence();
      final different = _passingStoneChainEvidence(
        medianVisibleFaceDepthPx: 17,
      );
      final sample = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.endpoint,
        coverageChecks: const <BorderPublicationCoverageCheck>[],
        structuralRuns: const <BorderPublicationStructuralRun>[],
        primaryStoneChainEvidence: first,
        invertedStoneChainEvidence: same,
      );
      final sameSample = BorderPublicationGallerySample(
        galleryCase: BorderCanonicalGalleryCase.endpoint,
        coverageChecks: const <BorderPublicationCoverageCheck>[],
        structuralRuns: const <BorderPublicationStructuralRun>[],
        primaryStoneChainEvidence: same,
        invertedStoneChainEvidence: first,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
      expect(sample, sameSample);
      expect(sample.hashCode, sameSample.hashCode);
      expect(
        () => _passingStoneChainEvidence(lipPlacementCount: -1),
        throwsA(anyOf(isA<AssertionError>(), isA<ValidationException>())),
      );
      expect(
        () => _passingStoneChainEvidence(alignedJointRatioPermille: 1001),
        throwsA(anyOf(isA<AssertionError>(), isA<ValidationException>())),
      );
    });

    test('lip and face coverage wire names are stable', () {
      expect(
        borderCanonicalCoverageComponentV1WireName(
          BorderCanonicalCoverageComponent.lip,
        ),
        'lip',
      );
      expect(
        borderCanonicalCoverageComponentV1WireName(
          BorderCanonicalCoverageComponent.face,
        ),
        'face',
      );
    });

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

const List<BorderPrimitiveOrientation> _allCardinalOrientations =
    <BorderPrimitiveOrientation>[
  BorderPrimitiveOrientation.north,
  BorderPrimitiveOrientation.east,
  BorderPrimitiveOrientation.south,
  BorderPrimitiveOrientation.west,
];

BorderGenerationParams _stoneChainParams({
  required int depthRows,
  int gapTolerancePx = 0,
  int maxOverlapPx = 4,
  bool allowAutoRotation = false,
}) =>
    BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 1000,
      variationPermille: 1000,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: depthRows,
      allowAutoRotation: allowAutoRotation,
    );

BorderBlueprintPublishedDefinition _twoTierStoneChainDefinition(
  _Fixture fixture, {
  List<BorderPrimitiveOrientation> lipOrientations = _allCardinalOrientations,
  List<BorderPrimitiveOrientation> faceOrientations = _allCardinalOrientations,
  List<int> quarterTurns = const <int>[0],
  bool allowAutoRotation = false,
  int gapTolerancePx = 0,
  int maxOverlapPx = 4,
}) {
  const ids = <String>[
    'large-a',
    'large-b',
    'large-c',
    'large',
    'post',
    'span',
    'accent',
    'same',
  ];
  var idIndex = 0;
  return fixture.definitionFor(
    template: BorderBlueprintTemplate.stoneChainLine,
    primitives: <BorderPublishedPrimitive>[
      for (final orientation in lipOrientations)
        fixture.primitive(
          ids[idIndex++],
          BorderPrimitiveRole.structureLarge,
          authoredOrientation: orientation,
          quarterTurns: quarterTurns,
        ),
      for (final orientation in faceOrientations)
        fixture.primitive(
          ids[idIndex++],
          BorderPrimitiveRole.structureMedium,
          authoredOrientation: orientation,
          quarterTurns: quarterTurns,
        ),
    ],
    defaults: _stoneChainParams(
      depthRows: 2,
      gapTolerancePx: gapTolerancePx,
      maxOverlapPx: maxOverlapPx,
      allowAutoRotation: allowAutoRotation,
    ),
  );
}

BorderPublicationStoneChainEvidence _passingStoneChainEvidence({
  int lipPlacementCount = 8,
  int facePlacementCount = 8,
  int minimumCrossRowInterlockPixels = 8,
  int minimumVisibleFaceDepthPx = 12,
  int medianVisibleFaceDepthPx = 16,
  int alignedJointRatioPermille = 250,
  int lipConnectedComponentCount = 1,
  int faceConnectedComponentCount = 1,
  int combinedConnectedComponentCount = 1,
}) =>
    BorderPublicationStoneChainEvidence(
      lipPlacementCount: lipPlacementCount,
      facePlacementCount: facePlacementCount,
      minimumCrossRowInterlockPixels: minimumCrossRowInterlockPixels,
      minimumVisibleFaceDepthPx: minimumVisibleFaceDepthPx,
      medianVisibleFaceDepthPx: medianVisibleFaceDepthPx,
      alignedJointRatioPermille: alignedJointRatioPermille,
      lipConnectedComponentCount: lipConnectedComponentCount,
      faceConnectedComponentCount: faceConnectedComponentCount,
      combinedConnectedComponentCount: combinedConnectedComponentCount,
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
    primaryStoneChainEvidence:
        definition.template == BorderBlueprintTemplate.stoneChainLine &&
                definition.defaults.depthRows == 2
            ? _passingStoneChainEvidence()
            : null,
    invertedStoneChainEvidence:
        definition.template == BorderBlueprintTemplate.stoneChainLine &&
                definition.defaults.depthRows == 2
            ? _passingStoneChainEvidence()
            : null,
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
          depthRows: definition.defaults.depthRows,
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
        depthRows: definition.defaults.depthRows,
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
      (
        BorderBlueprintTemplate.connectedLine,
        BorderPrimitiveRole.lineCap ||
            BorderPrimitiveRole.lineStraight ||
            BorderPrimitiveRole.lineCorner,
      ) =>
        0,
      (
        BorderBlueprintTemplate.stoneChainLine,
        BorderPrimitiveRole.structureLarge ||
            BorderPrimitiveRole.lineCap ||
            BorderPrimitiveRole.lineCorner,
      ) =>
        0,
      (
        BorderBlueprintTemplate.stoneChainLine,
        BorderPrimitiveRole.structureMedium || BorderPrimitiveRole.filler,
      ) =>
        1,
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
      BorderBlueprintTemplate.connectedLine =>
        role == BorderPrimitiveRole.lineCap ||
            role == BorderPrimitiveRole.lineStraight ||
            role == BorderPrimitiveRole.lineCorner,
      BorderBlueprintTemplate.stoneChainLine =>
        role == BorderPrimitiveRole.structureLarge ||
            role == BorderPrimitiveRole.structureMedium ||
            role == BorderPrimitiveRole.filler ||
            role == BorderPrimitiveRole.lineCorner ||
            role == BorderPrimitiveRole.lineCap,
    };

BorderPublishedGround _ground({
  required String presetId,
  required String snapshotId,
}) =>
    BorderPublishedGround(
      sourceSmartTilePresetId: presetId,
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
    bool allowFlipX = false,
    BorderPrimitiveOrientation authoredOrientation =
        BorderPrimitiveOrientation.legacyAxis,
  }) =>
      BorderPublishedPrimitive(
        id: id,
        sourceElementId: 'element-$id',
        visualSnapshotId: snapshotId(snapshot),
        role: role,
        authoredOrientation: authoredOrientation,
        weight: 100,
        anchorPx: anchor,
        transforms: BorderTransformPolicy(
          allowFlipX: allowFlipX,
          allowedQuarterTurns: quarterTurns,
        ),
        publishedMetrics: metrics ?? this.metrics(),
      );

  BorderBlueprintPublishedDefinition definitionFor({
    BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
    List<BorderPublishedPrimitive>? primitives,
    BorderPublishedGround? ground,
    BorderGenerationParams? defaults,
  }) =>
      BorderBlueprintPublishedDefinition(
        name: 'Coast',
        previewSeed: BorderSignedInt64.zero,
        template: template,
        primitives: primitives ?? definition.primitives,
        defaults: defaults ??
            BorderGenerationParams(
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

ProjectSmartTilePreset _publishedSmartTilePreset(String id) =>
    ProjectSmartTilePreset(
      id: id,
      name: id,
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'ground',
      allowedMaterialIds: const <String>['ground'],
    );

ProjectManifest _project() => ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v6,
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
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'ground',
            name: 'Ground',
            connectionGroupId: 'ground',
          ),
        ],
        presets: <ProjectSmartTilePreset>[
          _publishedSmartTilePreset('sand'),
        ],
      ),
    );
