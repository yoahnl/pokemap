import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_converter/asset_review_panel.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../packages/avelune_converter_adapters/test/support/original_asset_fixture.dart';

Future<void> _loaded(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.text('Chargement des images source…').evaluate().isEmpty) return;
  }
  fail('The original source preview did not finish loading.');
}

void main() {
  late OriginalAssetFixture fixture;
  late AssetReviewSession session;
  late List<AssetReviewSession> changes;
  setUp(() async {
    fixture = await OriginalAssetFixture.create();
    changes = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    required AssetCandidate proposal,
    List<NativeArtifact>? artifacts,
    bool enabled = true,
    String? initialName,
    AssetCategory? initialCategory,
    bool approved = false,
  }) async {
    session = AssetReviewSession.create(
      sessionId: ConverterId('source-preview-session'),
      logicalProjectNamespace: proposal.logicalProjectNamespace,
      sourceSnapshotHash: proposal.sourceSnapshotHash,
      selectedSourceMapIds: const [1, 8, 12],
      outputMode: proposal.outputMode,
      proposalGenerationHash: canonicalHashOf('original-source-preview'),
      candidates: [proposal],
    );
    if (initialName != null || initialCategory != null) {
      session = session.editMetadata(
        candidateId: proposal.candidateId,
        expectedCandidateHash: proposal.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        name: initialName,
        category: initialCategory,
      );
    }
    if (approved) {
      final candidate = session.activeCandidates.single;
      session = session.decide(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: session.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true,
      );
    }
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ConverterAssetReviewPanel(
              artifacts: artifacts ?? [NativeArtifact(bytes: fixture.pngBytes)],
              limits: const NativeWriteLimits(),
              sourceFilePaths: {
                proposal.sources.single.fileId: OriginalAssetFixture.imagePath,
              },
              availableSources: proposal.sources,
              outputMode: session.outputMode,
              onModeChanged: (_) {},
              session: session,
              enabled: enabled,
              onSessionChanged: (next, expectedPreviousHash) {
                expect(expectedPreviousHash, session.canonicalHash);
                changes.add(next);
                setState(() => session = next);
              },
            ),
          ),
        ),
      ),
    );
    await _loaded(tester);
  }

  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  Finder approve() => find.byKey(const ValueKey('asset-review-approve'));
  Finder keep() => find.byKey(const ValueKey('asset-review-keep'));

  testWidgets(
    'classification and human review approve the exact corrected source version',
    (tester) async {
      final proposal = fixture.treeCandidate();
      await pump(tester, proposal: proposal);
      expect(tester.widget<StudioButton>(approve()).onPressed, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is AssetProposalPainter,
        ),
        findsNWidgets(2),
      );
      await tester.enterText(field('asset-review-name'), 'Arbre de Kanto');
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('asset-review-category')),
          )
          .onChanged!('nature');
      await tester.pump();
      expect(changes, isEmpty);
      await tester.ensureVisible(
        find.byKey(const ValueKey('asset-apply-metadata')),
      );
      await tester.tap(find.byKey(const ValueKey('asset-apply-metadata')));
      await tester.pump();
      final corrected = session.activeCandidates.single;
      expect(corrected.name, 'Arbre de Kanto');
      expect(corrected.category, AssetCategory.nature);
      expect(corrected.state, CandidateState.needsReview);
      await tester.ensureVisible(approve());
      await tester.tap(approve());
      await tester.pump();
      final approved = session.activeCandidates.single;
      expect(changes, hasLength(2));
      expect(approved.name, 'Arbre de Kanto');
      expect(approved.category, AssetCategory.nature);
      expect(approved.state, CandidateState.approved);
      expect(
        session.frame.approvedCandidateHashes[approved.candidateId],
        approved.canonicalHash,
      );
      expect(
        approved.parts.map((p) => p.toJson()).toList(),
        proposal.parts.map((p) => p.toJson()).toList(),
      );
      expect(
        approved.sources.map((s) => s.toJson()).toList(),
        proposal.sources.map((s) => s.toJson()).toList(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeping literal tiles requires no inferred category or export', (
    tester,
  ) async {
    final proposal = fixture.ambiguousCandidate();
    await pump(tester, proposal: proposal);
    await tester.ensureVisible(keep());
    await tester.tap(keep());
    await tester.pump();
    expect(changes, hasLength(1));
    final current = session.activeCandidates.single;
    expect(current.state, CandidateState.keepLiteral);
    expect(current.category, AssetCategory.unclassified);
    expect(current.approvedRevision, isNull);
    expect(
      current.parts.map((p) => p.toJson()).toList(),
      proposal.parts.map((p) => p.toJson()).toList(),
    );
    expect(
      session.activeDecisions.decisions.single.action,
      ReviewAction.keepLiteral,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renewing an approved review preserves its human name and category',
    (tester) async {
      await pump(
        tester,
        proposal: fixture.treeCandidate(),
        initialName: 'Mon arbre',
        initialCategory: AssetCategory.nature,
        approved: true,
      );
      final before = session.activeCandidates.single;
      await tester.ensureVisible(approve());
      await tester.tap(approve());
      await tester.pump();
      expect(changes, hasLength(1));
      final current = session.activeCandidates.single;
      expect(current.name, 'Mon arbre');
      expect(current.category, AssetCategory.nature);
      expect(current.revision, before.revision + 1);
      expect(current.approvedRevision, current.revision);
      expect(
        session.frame.approvedCandidateHashes[current.candidateId],
        current.canonicalHash,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing original pixels block approval with visible feedback', (
    tester,
  ) async {
    await pump(
      tester,
      proposal: fixture.treeCandidate(),
      artifacts: [],
      initialCategory: AssetCategory.nature,
    );
    expect(
      find.text(
        'L’aperçu source est indisponible. L’approbation de ces objets est bloquée.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<StudioButton>(approve()).onPressed, isNull);
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy review exposes no interactive approval or edits', (
    tester,
  ) async {
    await pump(tester, proposal: fixture.treeCandidate(), enabled: false);
    expect(tester.widget<StudioButton>(approve()).onPressed, isNull);
    expect(tester.widget<StudioButton>(keep()).onPressed, isNull);
    expect(
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('asset-review-category')),
          )
          .onChanged,
      isNull,
    );
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preview uses disjoint source parts and preserves the transparent canvas hole',
    (tester) async {
      await tester.runAsync(() async {
        final proposal = fixture.houseCandidate();
        final codec = await ui.instantiateImageCodec(
          Uint8List.fromList(fixture.pngBytes),
        );
        final raster = (await codec.getNextFrame()).image;
        codec.dispose();
        final recorder = ui.PictureRecorder();
        AssetProposalPainter(proposal, {
          proposal.sources.single.contentHash.value: raster,
        }).paint(ui.Canvas(recorder), const ui.Size(64, 96));
        final picture = recorder.endRecording();
        final rendered = await picture.toImage(64, 96);
        try {
          final rgba = (await rendered.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          List<int> pixel(int x, int y) =>
              rgba.sublist((y * 64 + x) * 4, (y * 64 + x) * 4 + 4);
          List<int> source(int x, int y) =>
              fixture.rgba.sublist((y * 256 + x) * 4, (y * 256 + x) * 4 + 4);
          expect(pixel(20, 20), source(148, 20));
          expect(pixel(20, 52), source(148, 212));
          expect(pixel(52, 84), source(180, 244));
          expect(pixel(52, 52)[3], 0);
        } finally {
          rendered.dispose();
          picture.dispose();
          raster.dispose();
        }
      });
    },
  );
}
