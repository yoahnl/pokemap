import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

BorderCreationDraft _spatial() => BorderCreationDraft(
  project: spatialBorderVariantProject(),
  unavailableResourceIds: () => const {},
);

BorderBlueprintRecord _ledge() => BorderBlueprintRecord(
  id: 'ledge',
  draft: BorderBlueprintDraft(
    baseRevision: 0,
    definition: BorderBlueprintDraftDefinition(
      name: 'Rebord',
      previewSeed: BorderSignedInt64.zero,
      template: BorderBlueprintTemplate.ledgeLine,
      primitives: [
        BorderPrimitiveDraft(
          id: 'whole',
          sourceElementId: 'tree',
          role: BorderPrimitiveRole.structureLarge,
          weight: 1000,
          anchorPx: const BorderPixelPos(x: 0, y: 0),
          currentMetrics: BorderPrimitiveAssetMetrics(
            assetFingerprint: 'native-ledge',
            pixelSize: const GridSize(width: 32, height: 32),
            opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
            defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
            occupancyMaskRle: 'border-rle-v1:32:32:1024',
          ),
          transforms: BorderTransformPolicy(
            allowedQuarterTurns: const [0],
            allowFlipX: false,
          ),
        ),
      ],
      defaults: BorderGenerationParams(
        irregularityPermille: 0,
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1,
      ),
      jumpBehavior: BorderJumpBehavior(durationMs: 500, peakHeightPx: 24),
      sortOrder: 0,
    ),
  ),
);

void main() {
  test(
    'refreshing project dependencies preserves the current pattern input',
    () {
      final draft = _spatial()..name = 'Saisie conservée';
      draft.setSequenceLength('4');
      final current = draft.project.copyWith(name: 'Projet actualisé');
      draft.updateProject(current);
      expect(draft.project, same(current));
      expect(draft.name, 'Saisie conservée');
      expect(draft.sequenceLength, 4);
    },
  );

  for (final straight in [false, true]) {
    test(
      'new spatial draft retains all six configured steps (straight: $straight)',
      () {
        final draft = _spatial()..name = 'Motif';
        draft.setStraightOnly(straight);
        draft.followContourDirection = !straight;
        final source = resourceCatalog(draft.project)
            .firstWhere((item) => item.model3d?.id == 'oak');
        for (final role in draft.roles) {
          draft.assignRole(role, source);
        }
        expect(draft.setSequenceLength('6'), isTrue);
        expect(draft.complete, isTrue);
        expect(
          draft.sequencePrimitives.map((entry) => entry.sequenceIndex).toSet(),
          {0, 1, 2, 3, 4, 5},
        );
        final request = draft.buildRequest(publish: true);
        expect(request.sequenceLength, 6);
        expect(request.straightOnly, straight);
        expect(request.followContourDirection, !straight);
        expect(request.straightModelId, 'oak');
        expect(request.capModelId, 'oak');
        expect(request.publish, isTrue);
      },
    );
  }

  test(
    'resizing copies first-step settings and removes obsolete step overrides',
    () {
      final draft = _spatial()..straightOnly = true;
      final source = resourceCatalog(draft.project)
          .firstWhere((item) => item.model3d?.id == 'oak');
      for (final role in draft.roles) {
        draft.assignRole(role, source);
      }
      draft.setSettings(
        'lineStraight',
        const BorderModelSettings(animationSpeed: .75, blocksMovement: false),
      );
      draft.setSequenceLength('4');
      final last = draft.sequencePrimitives.firstWhere(
        (entry) =>
            entry.sequenceIndex == 3 &&
            entry.role == BorderPrimitiveRole.lineStraight,
      );
      expect(draft.primitiveModelSettings[last.id]!.animationSpeed, .75);
      draft.setPrimitiveSource(last.id, 'replacement');
      expect(draft.primitiveModelIds[last.id], 'replacement');
      draft.setSequenceLength('1');
      expect(draft.primitiveModelIds.containsKey(last.id), isFalse);
      expect(draft.primitiveModelSettings.containsKey(last.id), isFalse);
      expect(draft.settingsFor('lineStraight').animationSpeed, .75);
    },
  );

  test('invalid numeric drafts do not overwrite accepted pattern settings', () {
    final draft = _spatial();
    expect(draft.setSequenceLength('0'), isFalse);
    expect(draft.sequenceLength, 1);
    expect(draft.setSequenceLength('65'), isFalse);
    expect(draft.setAnimationSpeed('lineStraight', 'NaN'), isFalse);
    expect(draft.setAnimationSpeed('lineStraight', '17'), isFalse);
    expect(draft.setAnimationSpeed('lineStraight', '0,5'), isTrue);
    expect(draft.settingsFor('lineStraight').animationSpeed, .5);
    expect(draft.setCornerJoin('lineCorner', '9'), isFalse);
    expect(draft.setCornerJoin('lineCorner', '3'), isTrue);
    expect(draft.settingsFor('lineCorner').cornerJoinCells, 3);
  });

  test('ground ownership and masking stay mutually exclusive', () {
    final draft = _spatial();
    draft.setReplacesGround(true);
    expect(draft.setGroundLowering('1,25'), isTrue);
    expect(draft.groundBaseOffset, -1.25);
    expect(draft.setGroundLowering('-1'), isFalse);
    expect(draft.groundBaseOffset, -1.25);
    draft.setMasksGroundCells(true);
    expect(draft.replacesGround, isFalse);
    expect(draft.groundBaseOffset, 0);
    draft.setReplacesGround(true);
    expect(draft.masksGroundCells, isFalse);
  });

  test(
    'an unavailable model animation is refused without mutating the project',
    () {
      final project = spatialBorderProject();
      final before = project.toJson();
      final draft = BorderCreationDraft(
        project: project,
        initialRecord: project.borderCatalog.records.single,
        unavailableResourceIds: () => const {},
      );
      draft.setSettings(
        'lineStraight',
        const BorderModelSettings(animationIndex: 999),
      );
      expect(draft.settingsProblem, contains('animation sélectionnée'));
      expect(project.toJson(), before);
    },
  );

  test('native ledge requests retain their modules and expose only the existing jump side', () {
    final record = _ledge();
    final draft = BorderCreationDraft(
      project: workspaceProject,
      initialRecord: record,
      unavailableResourceIds: () => const {},
    );
    expect(draft.nativeLedge, isTrue);
    expect(draft.complete, isTrue);
    expect(draft.hasChanges, isFalse);
    draft.name = 'Rebord renommé';
    draft.jumpSide = BorderLineSide.inverted;
    final request = draft.buildRequest(publish: true);
    expect(request.expectedRecord, same(record));
    expect(request.blueprintId, 'ledge');
    expect(request.jumpSide, BorderLineSide.inverted);
    expect(request.capElementId, isNull);
    expect(record.draft.definition.primitives.single.sourceElementId, 'tree');
    expect(record.draft.definition.jumpBehavior!.durationMs, 500);
  });

  test('native ledge availability checks missing sources and diagnostics without changing definitions', () {
    final record = _ledge();
    final before = workspaceProject.toJson();
    expect(nativeLedgeSourcesAvailable(record, workspaceProject), isTrue);
    expect(
      nativeLedgeSourcesAvailable(
        record,
        workspaceProject,
        unavailableResourceIds: {'atlas'},
      ),
      isFalse,
    );
    expect(
      nativeLedgeSourcesAvailable(
        record,
        workspaceProject.copyWith(elements: []),
      ),
      isFalse,
    );
    expect(
      nativeLedgeSourcesAvailable(
        record,
        workspaceProject.copyWith(tilesets: []),
      ),
      isFalse,
    );
    expect(workspaceProject.toJson(), before);
  });
}
