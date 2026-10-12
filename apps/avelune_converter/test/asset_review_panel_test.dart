import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_converter/asset_review_panel.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_studio/avelune_design_system.dart';
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
  setUp(() async => fixture = await OriginalAssetFixture.create());

  Future<void> pump(
    WidgetTester tester, {
    required AssetCandidate proposal,
    List<AssetCandidate> reviewed = const [],
    List<NativeArtifact>? artifacts,
    bool enabled = true,
    required ValueChanged<ConverterAssetReview> onReview,
    ValueChanged<ConverterId>? onEditing,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConverterAssetReviewPanel(
              proposals: [proposal],
              reviewedCandidates: reviewed,
              artifacts: artifacts ?? [NativeArtifact(bytes: fixture.pngBytes)],
              limits: const NativeWriteLimits(),
              outputMode: proposal.outputMode,
              onModeChanged: (_) {},
              onReview: onReview,
              onEditing: onEditing ?? (_) {},
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
    await _loaded(tester);
  }

  Finder approve(AssetCandidate candidate) =>
      find.byKey(ValueKey('approve-asset-${candidate.candidateId.value}'));
  Finder keep(AssetCandidate candidate) =>
      find.byKey(ValueKey('keep-asset-${candidate.candidateId.value}'));

  testWidgets(
    'classification and human review unlock the exact source proposal',
    (tester) async {
      final proposal = fixture.treeCandidate();
      final reviews = <ConverterAssetReview>[];
      final edits = <ConverterId>[];
      await pump(
        tester,
        proposal: proposal,
        onReview: reviews.add,
        onEditing: edits.add,
      );
      expect(tester.widget<StudioButton>(approve(proposal)).onPressed, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is AssetProposalPainter,
        ),
        findsOneWidget,
      );
      expect(find.text('À vérifier'), findsOneWidget);
      final name = find.descendant(
        of: find.byKey(ValueKey('asset-name-${proposal.candidateId.value}')),
        matching: find.byType(TextField),
      );
      await tester.enterText(name, 'Arbre de Kanto');
      tester
          .widget<StudioSelect>(
            find.byKey(
              ValueKey('asset-category-${proposal.candidateId.value}'),
            ),
          )
          .onChanged!('nature');
      await tester.pump();
      await tester.ensureVisible(approve(proposal));
      await tester.tap(approve(proposal));
      await tester.pump();
      expect(reviews, hasLength(1));
      expect(reviews.single.name, 'Arbre de Kanto');
      expect(reviews.single.category, AssetCategory.nature);
      expect(reviews.single.proposalHash, proposal.canonicalHash);
      expect(reviews.single.action, ReviewAction.approve);
      expect(edits, [proposal.candidateId, proposal.candidateId]);
      expect(
        reviews.single.applyTo(proposal).parts.map((p) => p.toJson()).toList(),
        proposal.parts.map((p) => p.toJson()).toList(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeping literal tiles requires no inferred category or export', (
    tester,
  ) async {
    final proposal = fixture.ambiguousCandidate();
    final reviews = <ConverterAssetReview>[];
    await pump(tester, proposal: proposal, onReview: reviews.add);
    await tester.ensureVisible(keep(proposal));
    await tester.tap(keep(proposal));
    await tester.pump();
    expect(reviews.single.action, ReviewAction.keepLiteral);
    expect(reviews.single.category, AssetCategory.unclassified);
    expect(reviews.single.applyTo(proposal).approvedRevision, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renewing an approved review preserves its human name and category',
    (tester) async {
      final proposal = fixture.treeCandidate();
      final original = ConverterAssetReview(
        candidateId: proposal.candidateId,
        proposalHash: proposal.canonicalHash,
        name: 'Mon arbre',
        category: AssetCategory.nature,
        action: ReviewAction.approve,
        humanConfirmed: true,
      );
      final reviews = <ConverterAssetReview>[];
      await pump(
        tester,
        proposal: proposal,
        reviewed: [original.applyTo(proposal)],
        onReview: reviews.add,
      );
      await tester.ensureVisible(approve(proposal));
      await tester.tap(approve(proposal));
      expect(reviews.single.name, 'Mon arbre');
      expect(reviews.single.category, AssetCategory.nature);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing original pixels block approval with visible feedback', (
    tester,
  ) async {
    final proposal = fixture.treeCandidate();
    final reviews = <ConverterAssetReview>[];
    await pump(
      tester,
      proposal: proposal,
      artifacts: [],
      onReview: reviews.add,
    );
    tester
        .widget<StudioSelect>(
          find.byKey(ValueKey('asset-category-${proposal.candidateId.value}')),
        )
        .onChanged!('nature');
    await tester.pump();
    expect(
      find.text(
        'L’aperçu source est indisponible. L’approbation de ces objets est bloquée.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<StudioButton>(approve(proposal)).onPressed, isNull);
    expect(reviews, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy review exposes no interactive approval or edits', (
    tester,
  ) async {
    final proposal = fixture.treeCandidate();
    await pump(
      tester,
      proposal: proposal,
      enabled: false,
      onReview: (_) => fail('Unexpected approval'),
    );
    expect(tester.widget<StudioButton>(approve(proposal)).onPressed, isNull);
    expect(tester.widget<StudioButton>(keep(proposal)).onPressed, isNull);
    expect(
      tester
          .widget<StudioSelect>(
            find.byKey(
              ValueKey('asset-category-${proposal.candidateId.value}'),
            ),
          )
          .onChanged,
      isNull,
    );
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
