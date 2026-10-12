import 'package:avelune_converter/asset_review_canvas.dart';
import 'package:avelune_converter/asset_review_panel.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../packages/avelune_converter_adapters/test/support/original_asset_fixture.dart';

void main() {
  late OriginalAssetFixture fixture;
  late AssetReviewSession session;
  late List<bool> drafts;

  setUp(() async {
    fixture = await OriginalAssetFixture.create();
    final tree = fixture.treeCandidate();
    session = AssetReviewSession.create(
      sessionId: ConverterId('ui-review-session'),
      logicalProjectNamespace: tree.logicalProjectNamespace,
      sourceSnapshotHash: tree.sourceSnapshotHash,
      selectedSourceMapIds: const [1, 8],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: canonicalHashOf('original-ui-generation'),
      candidates: [tree, fixture.houseCandidate()],
    );
    drafts = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool scrollable = false,
    Size size = const Size(1600, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final panel = StatefulBuilder(
      builder: (context, setState) => ConverterAssetReviewPanel(
        artifacts: [NativeArtifact(bytes: fixture.pngBytes)],
        limits: const NativeWriteLimits(),
        sourceFilePaths: {
          fixture.treeCandidate().sources.single.fileId:
              OriginalAssetFixture.imagePath,
        },
        availableSources: fixture.treeCandidate().sources,
        outputMode: session.outputMode,
        onModeChanged: (_) {},
        session: session,
        enabled: enabled,
        onSessionChanged: (next, expectedPreviousHash) {
          expect(expectedPreviousHash, session.canonicalHash);
          setState(() => session = next);
        },
        onUnappliedDraftsChanged: drafts.add,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: panel,
                )
              : panel,
        ),
      ),
    );
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.text('Chargement des images source…').evaluate().isEmpty) return;
    }
    fail('Original source images did not finish loading.');
  }

  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Finder target, String value) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.enterText(target, value);
    await tester.pumpAndSettle();
  }

  AssetCandidate tree() => session.activeCandidates.firstWhere(
    (candidate) => candidate.candidateId == fixture.treeCandidate().candidateId,
  );

  testWidgets(
    'AC-10 metadata drafts expire approval only when explicitly applied',
    (tester) async {
      var current = tree();
      session = session.editMetadata(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: 'Arbre approuvé',
        category: AssetCategory.nature,
      );
      current = tree();
      session = session.decide(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true,
      );
      final before = session.canonicalHash;
      await pump(tester);
      await enter(tester, field('asset-review-name'), 'Arbre corrigé');
      await tester.pump();
      expect(drafts.last, isTrue);
      expect(session.canonicalHash, before);
      expect(find.text('Modifications à appliquer'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('asset-apply-metadata')));
      await tester.pump();
      expect(tree().name, 'Arbre corrigé');
      expect(tree().state, CandidateState.needsReview);
      expect(tree().approvedRevision, isNull);
      expect(drafts.last, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AC-10 invalid geometry remains visible without losing a draft', (
    tester,
  ) async {
    await pump(tester);
    final before = session.canonicalHash;
    await enter(tester, field('asset-canvas-width'), '-1');
    await tap(tester, find.byKey(const ValueKey('asset-apply-geometry')));
    await tester.pump();
    expect(session.canonicalHash, before);
    expect(
      tester.widget<TextField>(field('asset-canvas-width')).controller!.text,
      '-1',
    );
    expect(drafts.last, isTrue);
    expect(find.textContaining('Vérifiez les coordonnées'), findsOneWidget);
    await enter(tester, field('asset-canvas-width'), '96');
    await enter(tester, field('asset-anchor-x'), '48');
    await tap(tester, find.byKey(const ValueKey('asset-apply-geometry')));
    await tester.pump();
    expect(tree().canvasSize.width, 96);
    expect(tree().anchor.x, 48);
    expect(drafts.last, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AC-10 source crop correction loses unproved placement metadata',
    (tester) async {
      await pump(tester);
      final sourceHash = tree().sources.single.contentHash;
      await enter(tester, field('asset-part-source-x'), '32');
      await tap(tester, find.byKey(const ValueKey('asset-apply-geometry')));
      await tester.pump();
      final part = tree().parts.single;
      expect(part.sourceRect.x, 32);
      expect(part.locator.file, OriginalAssetFixture.imagePath);
      expect(part.locator.mapId, isNull);
      expect(part.locator.tileId, isNull);
      expect(part.sourceLayer, isNull);
      expect(part.sourcePriority, isNull);
      expect(tree().sources.single.contentHash, sourceHash);
      expect(tree().state, CandidateState.needsReview);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AC-10 metadata undo and redo restore exact candidate versions', (
    tester,
  ) async {
    await pump(tester);
    final original = tree().canonicalHash;
    await enter(tester, field('asset-review-name'), 'Arbre à conserver');
    await tap(tester, find.byKey(const ValueKey('asset-apply-metadata')));
    await tester.pump();
    final changed = tree().canonicalHash;
    await tap(tester, find.byKey(const ValueKey('asset-review-undo')));
    await tester.pump();
    expect(tree().canonicalHash, original);
    await tap(tester, find.byKey(const ValueKey('asset-review-redo')));
    await tester.pump();
    expect(tree().canonicalHash, changed);
    expect(
      tester.widget<TextField>(field('asset-review-name')).controller!.text,
      'Arbre à conserver',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AC-10 keep-literal remains consultable and undoable through filters',
    (tester) async {
      await pump(tester);
      final originalParts = tree().parts.map((part) => part.toJson()).toList();
      await tap(tester, find.byKey(const ValueKey('asset-review-keep')));
      await tester.pump();
      expect(tree().state, CandidateState.keepLiteral);
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('asset-review-filter')),
          )
          .onChanged!('keepLiteral');
      await tester.pump();
      expect(
        find.byKey(ValueKey('asset-open-${tree().candidateId.value}')),
        findsOneWidget,
      );
      expect(tree().parts.map((part) => part.toJson()).toList(), originalParts);
      await tap(tester, find.byKey(const ValueKey('asset-review-undo')));
      await tester.pump();
      expect(tree().state, CandidateState.needsReview);
      expect(tree().parts.map((part) => part.toJson()).toList(), originalParts);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 undo belongs to text fields until the canvas receives focus',
    (tester) async {
      await pump(tester);
      final original = tree().canonicalHash;
      await enter(tester, field('asset-review-name'), 'Arbre clavier');
      await tap(tester, find.byKey(const ValueKey('asset-apply-metadata')));
      await tester.pump();
      final changed = tree().canonicalHash;
      await tap(tester, field('asset-review-name'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(tree().canonicalHash, changed);
      await tap(tester, find.byKey(const ValueKey('asset-source-view')));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(tree().canonicalHash, original);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 union uses explicit offsets and split preserves every part',
    (tester) async {
      await pump(tester);
      final house = fixture.houseCandidate();
      await tap(
        tester,
        find.byKey(ValueKey('asset-select-${house.candidateId.value}')),
      );
      await tap(tester, find.byKey(const ValueKey('asset-review-union')));
      await tester.pump();
      await enter(tester, field('asset-union-name'), 'Arbre et maison');
      await enter(
        tester,
        field('asset-union-x-${house.candidateId.value}'),
        '96',
      );
      await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pump();
      final union = session.activeCandidates.single;
      expect(union.name, 'Arbre et maison');
      expect(union.parts, hasLength(4));
      expect(union.canvasSize.width, 160);
      expect(union.state, CandidateState.needsReview);
      expect(
        session.frame.candidates.where(
          (c) => c.state == CandidateState.superseded,
        ),
        hasLength(2),
      );
      await tap(tester, find.byKey(const ValueKey('asset-review-split')));
      await tester.pump();
      tester
          .widget<StudioSelect>(
            find.byKey(
              ValueKey('asset-split-group-${union.parts.first.partId.value}'),
            ),
          )
          .onChanged!('1');
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pump();
      expect(session.activeCandidates, hasLength(2));
      expect(session.activeCandidates.expand((c) => c.parts), hasLength(4));
      expect(
        session.activeCandidates.every(
          (c) => c.state == CandidateState.needsReview,
        ),
        isTrue,
      );
      await tap(tester, find.byKey(const ValueKey('asset-review-undo')));
      await tester.pump();
      expect(
        session.activeCandidates.single.canonicalHash,
        union.canonicalHash,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 creates an unapproved manual library object from source cells',
    (tester) async {
      await pump(tester);
      final canvas = tester.widget<ConverterAssetSourceCanvas>(
        find.byType(ConverterAssetSourceCanvas),
      );
      canvas.onSelectionChanged(const [(x: 0, y: 0), (x: 1, y: 0)]);
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('asset-create-manual')));
      await tester.pump();
      final manual = session.activeCandidates.last;
      expect(manual.state, CandidateState.needsReview);
      expect(manual.integrationMode, IntegrationMode.libraryOnly);
      expect(manual.approvedRevision, isNull);
      expect(manual.parts, hasLength(2));
      expect(manual.parts.map((p) => p.sourceRect.x).toList(), [0, 32]);
      expect(session.frame.placementClaims[manual.candidateId], isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 manual selection remains available without any detected proposal',
    (tester) async {
      session = AssetReviewSession.create(
        sessionId: session.sessionId,
        logicalProjectNamespace: session.logicalProjectNamespace,
        sourceSnapshotHash: session.sourceSnapshotHash,
        selectedSourceMapIds: session.selectedSourceMapIds,
        outputMode: session.outputMode,
        proposalGenerationHash: session.proposalGenerationHash,
        candidates: const [],
      );
      await pump(tester);
      final canvas = tester.widget<ConverterAssetSourceCanvas>(
        find.byType(ConverterAssetSourceCanvas),
      );
      canvas.onSelectionChanged(const [(x: 0, y: 0)]);
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('asset-create-manual')));
      await tester.pump();
      expect(session.activeCandidates, hasLength(1));
      expect(session.activeCandidates.single.parts, hasLength(1));
      expect(session.activeCandidates.single.approvedRevision, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 unavailable review locks all mutations and preserves its session',
    (tester) async {
      await pump(tester, enabled: false);
      for (final key in [
        'asset-review-keep',
        'asset-review-approve',
        'asset-review-union',
        'asset-review-split',
        'asset-review-undo',
        'asset-apply-metadata',
        'asset-apply-geometry',
      ]) {
        expect(
          tester.widget<StudioButton>(find.byKey(ValueKey(key))).onPressed,
          isNull,
        );
      }
      expect(
        tester.widget<TextField>(field('asset-review-name')).enabled,
        isFalse,
      );
      expect(drafts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 adding cells requires explicit placement and expires approval',
    (tester) async {
      var current = tree();
      session = session.editMetadata(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        category: AssetCategory.nature,
      );
      current = tree();
      session = session.decide(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true,
      );
      await pump(tester);
      final original = tree().canonicalHash;
      tester
          .widget<ConverterAssetSourceCanvas>(
            find.byType(ConverterAssetSourceCanvas),
          )
          .onSelectionChanged(const [(x: 2, y: 0)]);
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('asset-add-cells')));
      await tester.pumpAndSettle();
      await enter(tester, field('asset-add-x'), '64');
      await enter(tester, field('asset-add-y'), '0');
      await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      expect(tree().parts, hasLength(2));
      expect(tree().parts.last.sourceRect.x, 64);
      expect(tree().parts.last.destinationOffset.x, 64);
      expect(tree().parts.last.locator.file, OriginalAssetFixture.imagePath);
      expect(tree().canvasSize.width, 96);
      expect(tree().anchor.x, 32);
      expect(tree().anchor.y, 96);
      expect(tree().anchor.convention, AnchorConvention.explicit);
      expect(tree().state, CandidateState.needsReview);
      expect(tree().approvedRevision, isNull);
      await tap(tester, find.byKey(const ValueKey('asset-review-undo')));
      await tester.pump();
      expect(tree().canonicalHash, original);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 removing a source cell preserves every other pixel and refuses empty objects',
    (tester) async {
      await pump(tester);
      final original = tree().canonicalHash;
      final anchor = tree().anchor.toJson();
      tester
          .widget<ConverterAssetSourceCanvas>(
            find.byType(ConverterAssetSourceCanvas),
          )
          .onSelectionChanged(const [(x: 1, y: 0)]);
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('asset-remove-cells')));
      await tester.pump();
      expect(
        tree().parts
            .map((p) => p.sourceRect.width * p.sourceRect.height)
            .reduce((a, b) => a + b),
        64 * 96 - 32 * 32,
      );
      expect(
        tree().parts.every(
          (p) =>
              !(p.sourceRect.x < 64 &&
                  p.sourceRect.x + p.sourceRect.width > 32 &&
                  p.sourceRect.y < 32),
        ),
        isTrue,
      );
      expect(tree().anchor.toJson(), anchor);
      expect(
        tree().parts.every(
          (p) =>
              p.locator.file == OriginalAssetFixture.imagePath &&
              p.locator.mapId == null &&
              p.sourceLayer == null,
        ),
        isTrue,
      );
      final corrected = tree().canonicalHash;
      tester
          .widget<ConverterAssetSourceCanvas>(
            find.byType(ConverterAssetSourceCanvas),
          )
          .onSelectionChanged([
            for (var y = 0; y < 3; y++)
              for (var x = 0; x < 2; x++) (x: x, y: y),
          ]);
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('asset-remove-cells')));
      await tester.pump();
      expect(tree().canonicalHash, corrected);
      expect(find.textContaining('ne peut pas vider l’objet'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('asset-review-undo')));
      await tester.pump();
      expect(tree().canonicalHash, original);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 category for multiple candidates requires explicit confirmation',
    (tester) async {
      await pump(tester);
      final toggle = find.byKey(
        ValueKey('asset-select-${fixture.houseCandidate().candidateId.value}'),
      );
      await tester.ensureVisible(toggle);
      await tap(tester, toggle);
      await tap(tester, find.byKey(const ValueKey('asset-selection-category')));
      await tester.pumpAndSettle();
      final before = session.canonicalHash;
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('asset-selection-category-value')),
          )
          .onChanged!('object');
      await tester.pump();
      expect(session.canonicalHash, before);
      await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      expect(
        session.activeCandidates.every(
          (c) => c.category == AssetCategory.object,
        ),
        isTrue,
      );
      expect(
        session.activeCandidates.every((c) => c.approvedRevision == null),
        isTrue,
      );
      expect(
        session.activeDecisions.decisions.every(
          (d) => d.action != ReviewAction.approve,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 grouped review approves exact versions only after a counted confirmation',
    (tester) async {
      for (final candidate in session.activeCandidates.toList()) {
        session = session.editMetadata(
          candidateId: candidate.candidateId,
          expectedCandidateHash: candidate.canonicalHash,
          expectedSessionHash: session.canonicalHash,
          category: AssetCategory.object,
        );
      }
      await pump(tester);
      final toggle = find.byKey(
        ValueKey('asset-select-${fixture.houseCandidate().candidateId.value}'),
      );
      await tester.ensureVisible(toggle);
      await tap(tester, toggle);
      await tap(tester, find.byKey(const ValueKey('asset-selection-review')));
      await tester.pumpAndSettle();
      expect(
        find.text('Valider 2 objets pour la bibliothèque'),
        findsOneWidget,
      );
      expect(
        session.activeCandidates.every((c) => c.approvedRevision == null),
        isTrue,
      );
      await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      expect(
        session.activeCandidates.every(
          (c) =>
              c.state == CandidateState.approved &&
              c.approvedRevision == c.revision,
        ),
        isTrue,
      );
      expect(
        session.activeCandidates.every(
          (c) =>
              session.frame.approvedCandidateHashes[c.candidateId] ==
              c.canonicalHash,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 source cells are not transferred to another review session',
    (tester) async {
      await pump(tester);
      tester
          .widget<ConverterAssetSourceCanvas>(
            find.byType(ConverterAssetSourceCanvas),
          )
          .onSelectionChanged(const [(x: 0, y: 0)]);
      await tester.pump();
      expect(
        tester
            .widget<ConverterAssetSourceCanvas>(
              find.byType(ConverterAssetSourceCanvas),
            )
            .selectedCells,
        isNotEmpty,
      );
      session = AssetReviewSession.create(
        sessionId: ConverterId('another-ui-review-session'),
        logicalProjectNamespace: session.logicalProjectNamespace,
        sourceSnapshotHash: session.sourceSnapshotHash,
        selectedSourceMapIds: const [8],
        outputMode: session.outputMode,
        proposalGenerationHash: canonicalHashOf('another-proposal-generation'),
        candidates: [fixture.houseCandidate()],
      );
      await pump(tester);
      expect(
        tester
            .widget<ConverterAssetSourceCanvas>(
              find.byType(ConverterAssetSourceCanvas),
            )
            .selectedCells,
        isEmpty,
      );
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('asset-create-manual')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 adding overlapping destination cells refuses without changing the session',
    (tester) async {
      await pump(tester);
      final before = session.canonicalHash;
      tester
          .widget<ConverterAssetSourceCanvas>(
            find.byType(ConverterAssetSourceCanvas),
          )
          .onSelectionChanged(const [(x: 2, y: 0)]);
      await tester.pump();
      await tap(tester, find.byKey(const ValueKey('asset-add-cells')));
      await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
      expect(session.canonicalHash, before);
      expect(field('asset-add-x'), findsOneWidget);
      expect(find.textContaining('ne pas recouvrir'), findsOneWidget);
      expect(drafts.last, isTrue);
      await tap(tester, find.text('Annuler').last);
      expect(drafts.last, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 imported replacement intention is labelled uncertified and cannot be approved',
    (tester) async {
      var current = tree();
      session = session.editMetadata(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        category: AssetCategory.nature,
      );
      current = tree();
      final map = fixture.literalFixture.source.maps.firstWhere(
        (m) => m.map.sourceMapId == 1,
      );
      session = session.setIntegrationMode(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        integrationMode: IntegrationMode.replacePlacements,
        placementClaims: [
          SourcePlacementClaim(
            sourceSnapshotHash: session.sourceSnapshotHash,
            sourceMapHash: map.canonicalHash,
            sourceMapFileId: map.map.sourceFileId,
            sourceMapId: 1,
            sourceZ: 0,
            x: 0,
            y: 0,
            tileId: 384,
            partId: current.parts.single.partId,
          ),
        ],
        sourceMaps: [map],
      );
      await pump(tester);
      expect(
        find.text('Intention de substitution non certifiée'),
        findsOneWidget,
      );
      expect(find.text('Bibliothèque seulement'), findsNothing);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('asset-review-approve')),
            )
            .onPressed,
        isNull,
      );
      expect(tree().integrationMode, IntegrationMode.replacePlacements);
      expect(tree().approvedRevision, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 operation fields block save and cannot be dismissed by the barrier',
    (tester) async {
      await pump(tester);
      final toggle = find.byKey(
        ValueKey('asset-select-${fixture.houseCandidate().candidateId.value}'),
      );
      await tap(tester, toggle);
      await tap(tester, find.byKey(const ValueKey('asset-review-union')));
      await enter(tester, field('asset-union-name'), 'Nom non appliqué');
      expect(drafts.last, isTrue);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.dismissible, isFalse);
      final before = session.canonicalHash;
      await tap(tester, find.text('Annuler').last);
      expect(session.canonicalHash, before);
      expect(drafts.last, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AC-10 narrow inspector preserves invalid fields when reopened', (
    tester,
  ) async {
    await pump(tester);
    tester.view.physicalSize = const Size(1100, 720);
    await tester.pump();
    await tap(tester, find.byKey(const ValueKey('asset-open-inspector')));
    await enter(tester, field('asset-canvas-width'), 'invalide');
    expect(drafts.last, isTrue);
    await tap(tester, find.byKey(const ValueKey('confirm-reviewed-plan')));
    await tap(tester, find.byKey(const ValueKey('asset-open-inspector')));
    expect(
      tester.widget<TextField>(field('asset-canvas-width')).controller!.text,
      'invalide',
    );
    expect(drafts.last, isTrue);
    await tap(tester, find.byKey(const ValueKey('asset-discard-drafts')));
    expect(drafts.last, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AC-10 unapplied fields block approval and candidate switching', (
    tester,
  ) async {
    await pump(tester);
    await enter(tester, field('asset-anchor-x'), 'invalide');
    await tester.pump();
    expect(drafts.last, isTrue);
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('asset-review-approve')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(
              ValueKey(
                'asset-open-${fixture.houseCandidate().candidateId.value}',
              ),
            ),
          )
          .onTap,
      isNull,
    );
    await tap(tester, find.byKey(const ValueKey('asset-discard-drafts')));
    await tester.pump();
    expect(drafts.last, isFalse);
    expect(
      tester.widget<TextField>(field('asset-anchor-x')).controller!.text,
      tree().anchor.x.toString(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AC-10 applying metadata retains an unrelated invalid geometry draft',
    (tester) async {
      await pump(tester);
      await enter(tester, field('asset-canvas-width'), 'large');
      await enter(tester, field('asset-review-name'), 'Nom sauvegardable');
      await tap(tester, find.byKey(const ValueKey('asset-apply-metadata')));
      await tester.pump();
      expect(tree().name, 'Nom sauvegardable');
      expect(
        tester.widget<TextField>(field('asset-canvas-width')).controller!.text,
        'large',
      );
      expect(drafts.last, isTrue);
      expect(find.text('Modifications à appliquer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AC-10 review at the app width with enlarged text retains the source viewport',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, scrollable: true, size: const Size(1072, 800));
      final viewport = find.byKey(const ValueKey('asset-source-view'));
      expect(tester.getSize(viewport).width, greaterThan(300));
      expect(tester.getSize(viewport).height, greaterThan(180));
      await tap(tester, find.byKey(const ValueKey('asset-open-inspector')));
      expect(field('asset-review-name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(1280, 800), const Size(1100, 720)]) {
    testWidgets(
      'AC-10 review at $size retains a usable canvas and reachable inspector',
      (tester) async {
        await pump(tester);
        tester.view.physicalSize = size;
        await tester.pump();
        final canvas = find.byType(ConverterAssetSourceCanvas);
        expect(canvas, findsOneWidget);
        expect(tester.getSize(canvas).width, greaterThan(300));
        if (find
            .byKey(const ValueKey('asset-open-inspector'))
            .evaluate()
            .isNotEmpty) {
          await tap(tester, find.byKey(const ValueKey('asset-open-inspector')));
          await tester.pump();
        }
        expect(field('asset-review-name'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
