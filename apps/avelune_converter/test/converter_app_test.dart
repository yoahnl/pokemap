import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter/asset_review_panel.dart';
import 'package:avelune_converter/desktop_services.dart';
import 'package:avelune_converter/vision_panel.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../../../packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart';

void main() {
  testWidgets('missing atlas images can be bound and prepared explicitly', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    const expected = 'Graphics/Tilesets/OriginalAtlas1';
    const backup = 'Graphics/Tilesets/OriginalAtlas1_backup.png';
    await tester.runAsync(
      () =>
          File('${source.sourcePath}/$expected.png')
              .rename('${source.sourcePath}/$backup'),
    );
    _setWindow(tester, const Size(1600, 1000));
    try {
      await tester.pumpWidget(
        ConverterApp(
          workflow: source.workflow,
          initialSourcePath: source.sourcePath,
          initialParentPath: source.output.path,
          sessionStore: LocalReviewSessionStore(
            rootPath: '${source.root.path}/sessions',
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.snapshot != null &&
            !source.workflow.state.isBusy,
      );
      await tester.ensureVisible(find.text('Tout sélectionner'));
      await tester.tap(find.text('Tout sélectionner'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('acknowledge-study')),
      );
      await tester.tap(find.byKey(const ValueKey('acknowledge-study')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared != null &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.prepared!.canApprove, isFalse);
      final picker = find.byKey(
        const ValueKey('atlas-image-binding-$expected'),
      );
      expect(picker, findsOneWidget);
      final select = tester.widget<StudioSelect>(picker);
      expect(select.options.keys, contains(backup));
      select.onChanged!(backup);
      await tester.pump();
      expect(source.workflow.state.prepared, isNull);
      expect(source.workflow.state.approval, isNull);
      expect(tester.widget<StudioSelect>(picker).value, backup);
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared?.canApprove == true &&
            !source.workflow.state.isBusy,
      );
      final prepared = source.workflow.state.prepared!;
      expect(prepared.settings.imageBindings.single.sourceRelativePath, backup);
      expect(
        prepared.normalizedSource.tilesets.single.images
            .singleWhere((image) => image.role == 'tileset')
            .appliedImageBinding!
            .sourceRelativePath,
        backup,
      );
      final recipe = source.workflow.exportStudyPlanRecipe();
      expect(
        ConverterStudyPlanRecipe.fromJson(recipe.toJson())
            .settings
            .imageBindings
            .single
            .sourceRelativePath,
        backup,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('dependency choices remain visible until explicit preparation', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () => _OriginalSource.create(
        maps: [
          LiteralFixtureMap(
            id: 1,
            warpParameters: [
              [0, 8, 0, 0, 0, 0],
              [0, 12, 0, 0, 0, 0],
            ],
          ),
          LiteralFixtureMap(id: 8),
          LiteralFixtureMap(id: 12),
        ],
      ),
    ))!;
    _setWindow(tester, const Size(1600, 1000));
    final store = LocalReviewSessionStore(
      rootPath: '${source.root.path}/sessions',
    );
    Iterable<StudioSelect> choices() => tester
        .widgetList<StudioSelect>(find.byType(StudioSelect))
        .where((s) => s.label.startsWith('Transfert'));
    try {
      await tester.pumpWidget(
        ConverterApp(
          workflow: source.workflow,
          initialSourcePath: source.sourcePath,
          initialParentPath: source.output.path,
          sessionStore: store,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.snapshot != null &&
            !source.workflow.state.isBusy,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('select-map-1')));
      await tester.tap(find.byKey(const ValueKey('select-map-1')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('acknowledge-study')),
      );
      await tester.tap(find.byKey(const ValueKey('acknowledge-study')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared != null &&
            !source.workflow.state.isBusy,
      );
      await tester.tap(find.text('Vérification'));
      await tester.pump();
      expect(choices(), hasLength(2));
      choices().first.onChanged!('excludeStudy');
      await tester.pump();
      expect(source.workflow.state.prepared, isNull);
      expect(choices(), hasLength(2));
      expect(choices().first.value, 'excludeStudy');
      expect(choices().last.onChanged, isNotNull);
      choices().last.onChanged!('excludeStudy');
      await tester.pump();
      expect(choices().map((s) => s.value), ['excludeStudy', 'excludeStudy']);
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('create-study-project')),
            )
            .onPressed,
        isNull,
      );
      expect(source.workflow.state.approval, isNull);
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared?.canApprove == true &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.settings!.dependencyDecisions, hasLength(2));
      expect(source.nativeStages, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('imported plan limits survive preparation and session save', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    _setWindow(tester, const Size(1600, 1000));
    final planPath = '${source.root.path}/bounded-plan.json';
    final store = LocalReviewSessionStore(
      rootPath: '${source.root.path}/sessions',
    );
    ConverterWorkflow? restored;
    try {
      await tester.runAsync(() async {
        final snapshot = await source.workflow.scanSource(
          ConverterSourceSelection(
            rootPath: source.sourcePath,
            logicalProjectNamespace: ConverterId('original-bounded-plan'),
          ),
        );
        source.workflow.updateSettings(
          ConverterStudySettings(
            projectName: 'Original bounded import',
            parentPath: source.output.path,
            folderName: 'bounded-import',
            selectedSourceMapIds: [1, 8],
            normalizationLimits: const SourceNormalizationLimits(maxMaps: 16),
            writeLimits: const NativeWriteLimits(
              maxArtifacts: 48,
              maxMutations: 64,
              maxTotalImagePixels: 33554432,
            ),
            profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason: 'Controlled original fixture.',
            ),
          ),
        );
        await source.workflow.prepareStudy();
        await const LocalStudyPlanStore().writeNew(
          source.workflow.exportStudyPlanRecipe(),
          planPath,
        );
      });
      await tester.pumpWidget(
        ConverterApp(
          workflowFactory: () => restored = ConverterWorkflow(),
          pathPicker: (kind) async =>
              kind == ConverterPathKind.planFile ? planPath : null,
          sessionStore: store,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('load-conversion-plan')));
      await _waitFor(
        tester,
        () => restored?.state.prepared != null && !restored!.state.isBusy,
      );
      await tester.tap(find.text('Analyse'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('acknowledge-study')),
      );
      await tester.tap(find.byKey(const ValueKey('acknowledge-study')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(
        tester,
        () =>
            restored!.state.prepared != null &&
            !restored!.state.isBusy &&
            !restored!
                .state
                .prepared!
                .settings
                .profileAcknowledgement
                .humanConfirmed,
      );
      expect(restored!.state.prepared!.settings.writeLimits.maxArtifacts, 48);
      expect(restored!.state.prepared!.settings.writeLimits.maxMutations, 64);
      expect(
        restored!.state.prepared!.settings.writeLimits.maxTotalImagePixels,
        33554432,
      );
      expect(
        restored!.state.prepared!.settings.writeLimits.maxImagePixels,
        16777216,
      );
      expect(
        restored!.state.prepared!.settings.normalizationLimits.maxMaps,
        16,
      );
      await tester.tap(find.byKey(const ValueKey('save-review-session')));
      await _waitFor(
        tester,
        () => find.text('Session enregistrée').evaluate().isNotEmpty,
      );
      final saved = (await tester.runAsync(store.list))!.single;
      expect(saved.resumeSettings.writeLimits.maxArtifacts, 48);
      expect(saved.resumeSettings.writeLimits.maxMutations, 64);
      expect(saved.resumeSettings.writeLimits.maxTotalImagePixels, 33554432);
      expect(saved.resumeSettings.writeLimits.maxImagePixels, 16777216);
      expect(saved.resumeSettings.normalizationLimits.maxMaps, 16);
      expect(restored!.state.approval, isNull);
      expect(restored!.state.result, isNull);
      expect(tester.takeException(), isNull);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('source analysis waits for an explicit named map selection', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await tester.pumpWidget(
        ConverterApp(
          workflow: source.workflow,
          initialSourcePath: source.sourcePath,
          initialParentPath: source.output.path,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.snapshot != null &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.prepared, isNull);
      expect(find.text('Original map 1 · 001'), findsOneWidget);
      expect(find.text('Original map 8 · 008'), findsOneWidget);
      expect(
        tester
            .widget<StudioToggleRow>(find.byKey(const ValueKey('select-map-1')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('prepare-study')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('select-map-1')));
      await tester.tap(find.byKey(const ValueKey('select-map-1')));
      await tester.pump();
      expect(source.workflow.state.prepared, isNull);
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared != null &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.prepared!.settings.selectedSourceMapIds, [
        1,
      ]);
      expect(
        source.workflow.state.prepared!.composition.nativeMaps,
        hasLength(1),
      );
      expect(source.nativeStages, isEmpty);
      await tester.runAsync(source.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('segmented review selects one named source map at a time', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      await _showResources(tester);
      expect(find.byKey(const ValueKey('review-map-selector')), findsOneWidget);
      final selector = _reviewMapSelector(tester);
      expect(selector.options, {'1': 'Original map 1', '8': 'Original map 8'});
      expect(selector.value, '1');
      final first = _reviewPanel(tester);
      expect(first.session!.selectedSourceMapIds, [1, 8]);
      expect(_claimedReviewMaps(first.session!), {1});
      expect(first.session!.activeCandidates, isNotEmpty);
      final firstKey = first.key;
      await _selectReviewMap(tester, '8');
      final second = _reviewPanel(tester);
      expect(second.session!.selectedSourceMapIds, [1, 8]);
      expect(_claimedReviewMaps(second.session!), {8});
      expect(second.key, isNot(firstKey));
      expect(
        tester
            .widget<ConverterVisionPanel>(find.byType(ConverterVisionPanel))
            .session
            .canonicalHash,
        second.session!.canonicalHash,
      );
      expect(
        second.availableSources.map((s) => s.fileId).toSet(),
        second.session!.activeCandidates
            .expand((c) => c.sources)
            .map((s) => s.fileId)
            .toSet(),
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets(
    'segmented review corrections preserve the other map and reject old callbacks',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      _setWindow(tester, const Size(1600, 1000));
      try {
        await _scanAndPrepare(tester, source);
        await _showResources(tester);
        final first = _reviewPanel(tester);
        final firstSession = first.session!;
        expect(_claimedReviewMaps(firstSession), {1});
        final firstNext = _renameReviewCandidate(
          firstSession,
          'Objet de la carte 1',
        );
        first.onSessionChanged!(firstNext, firstSession.canonicalHash);
        await tester.pump();
        await _selectReviewMap(tester, '8');
        final second = _reviewPanel(tester);
        final secondSession = second.session!;
        final secondNext = _renameReviewCandidate(
          secondSession,
          'Objet de la carte 8',
        );
        second.onSessionChanged!(secondNext, secondSession.canonicalHash);
        await tester.pump();
        first.onSessionChanged!(
          _renameReviewCandidate(firstSession, 'Ancien callback refusé'),
          firstSession.canonicalHash,
        );
        await tester.pump();
        expect(
          _reviewPanel(tester).session!.canonicalHash,
          secondNext.canonicalHash,
        );
        await _selectReviewMap(tester, '1');
        expect(
          _reviewPanel(tester).session!.canonicalHash,
          firstNext.canonicalHash,
        );
        await _acknowledgeAndPrepare(tester, source);
        final candidates = source.workflow.state.prepared!.assetCandidates;
        expect(
          candidates.where((c) => c.name == 'Objet de la carte 1'),
          hasLength(1),
        );
        expect(
          candidates.where((c) => c.name == 'Objet de la carte 8'),
          hasLength(1),
        );
        expect(
          candidates.where((c) => c.name == 'Ancien callback refusé'),
          isEmpty,
        );
        expect(
          source.workflow.state.prepared!.settings.assetOutputMode,
          AssetOutputMode.sharedAtlas,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'segmented review drafts block map changes without losing the field',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      _setWindow(tester, const Size(1600, 1000));
      try {
        await _scanAndPrepare(tester, source);
        await _showResources(tester);
        expect(
          find.byKey(const ValueKey('review-map-selector')),
          findsOneWidget,
        );
        final changeMap = _reviewMapSelector(tester).onChanged!;
        final before = _reviewPanel(tester).session!.canonicalHash;
        final field = find.descendant(
          of: find.byKey(const ValueKey('asset-review-name')),
          matching: find.byType(TextField),
        );
        if (field.evaluate().isEmpty) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('asset-open-inspector')),
          );
          await tester.tap(find.byKey(const ValueKey('asset-open-inspector')));
          await tester.pumpAndSettle();
        }
        await tester.enterText(field, 'Brouillon conservé carte 1');
        await tester.pump();
        await tester.pump();
        expect(_reviewMapSelector(tester).onChanged, isNull);
        expect(_button(tester, 'save-review-session').onPressed, isNull);
        changeMap('8');
        await tester.pump();
        expect(_reviewMapSelector(tester).value, '1');
        expect(_reviewPanel(tester).session!.canonicalHash, before);
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Brouillon conservé carte 1',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('segmented review output mode changes every map atomically', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      await _showResources(tester);
      final first = _reviewPanel(tester);
      expect(first.session!.selectedSourceMapIds, [1, 8]);
      expect(_claimedReviewMaps(first.session!), {1});
      first.onModeChanged(AssetOutputMode.standaloneObjects);
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared?.settings.assetOutputMode ==
                AssetOutputMode.standaloneObjects &&
            !source.workflow.state.isBusy,
      );
      expect(
        _reviewPanel(tester).session!.outputMode,
        AssetOutputMode.standaloneObjects,
      );
      await _selectReviewMap(tester, '8');
      expect(
        _reviewPanel(tester).session!.outputMode,
        AssetOutputMode.standaloneObjects,
      );
      expect(
        _reviewPanel(tester).outputMode,
        AssetOutputMode.standaloneObjects,
      );
      final settings = source.workflow.state.prepared!.settings.toJson();
      final reviewSet = settings['reviewSet']! as Map;
      final segments = reviewSet['segments']! as List;
      expect(segments, hasLength(2));
      expect(
        segments.every(
          (row) => (row as Map)['session']['outputMode'] == 'standaloneObjects',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets(
    'segmented review saves and resumes all corrected maps together',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      _setWindow(tester, const Size(1600, 1000));
      final store = LocalReviewSessionStore(
        rootPath: '${source.root.path}/sessions',
      );
      ConverterWorkflow? resumed;
      try {
        await _scanAndPrepare(tester, source, sessionStore: store);
        await _showResources(tester);
        final first = _reviewPanel(tester);
        expect(first.session!.selectedSourceMapIds, [1, 8]);
        expect(_claimedReviewMaps(first.session!), {1});
        first.onSessionChanged!(
          _renameReviewCandidate(first.session!, 'Carte 1 sauvegardée'),
          first.session!.canonicalHash,
        );
        await tester.pump();
        await _selectReviewMap(tester, '8');
        final second = _reviewPanel(tester);
        second.onSessionChanged!(
          _renameReviewCandidate(second.session!, 'Carte 8 sauvegardée'),
          second.session!.canonicalHash,
        );
        await tester.pump();
        expect(_button(tester, 'save-review-session').onPressed, isNotNull);
        await tester.tap(find.byKey(const ValueKey('save-review-session')));
        await _waitFor(
          tester,
          () =>
              find.text('Session enregistrée').evaluate().isNotEmpty ||
              find.text('Enregistrement impossible').evaluate().isNotEmpty,
          pumpDuration: const Duration(milliseconds: 10),
        );
        expect(find.text('Session enregistrée'), findsOneWidget);
        final stored = (await tester.runAsync(store.list))!.single;
        final document = stored.toJson();
        expect(document['version'], 4);
        final reviewSet = document['reviewSet']! as Map;
        expect((reviewSet['segments']! as List), hasLength(2));
        await tester.pumpWidget(const SizedBox());
        resumed = ConverterWorkflow();
        await tester.pumpWidget(
          ConverterApp(
            workflow: resumed,
            sessionStore: store,
            folderOpener: (_) async {},
          ),
        );
        await tester.tap(find.byKey(const ValueKey('load-review-session')));
        await _waitFor(
          tester,
          () => find
              .byKey(ValueKey('load-session-${reviewSet['sessionId']}'))
              .evaluate()
              .isNotEmpty,
          pumpDuration: const Duration(milliseconds: 10),
        );
        await tester.tap(
          find.byKey(ValueKey('load-session-${reviewSet['sessionId']}')),
        );
        await _waitFor(
          tester,
          () => find
              .text('Session reprise · source vérifiée')
              .evaluate()
              .isNotEmpty,
          pumpDuration: const Duration(milliseconds: 10),
        );
        expect(resumed.state.approval, isNull);
        expect(
          _reviewPanel(tester).session!.activeCandidates
              .where((c) => c.name == 'Carte 1 sauvegardée'),
          hasLength(1),
        );
        await _selectReviewMap(tester, '8');
        expect(
          _reviewPanel(tester).session!.activeCandidates
              .where((c) => c.name == 'Carte 8 sauvegardée'),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
        await tester.runAsync(source.expectSourceUnchanged);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await resumed?.dispose();
        });
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('starts with five steps and an unavailable analysis action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ConverterApp());

    for (final step in [
      'Source',
      'Analyse',
      'Ressources',
      'Vérification',
      'Export',
    ]) {
      expect(find.text(step), findsOneWidget);
    }
    final action = tester.widget<StudioButton>(
      find.byKey(const ValueKey('analyse-project')),
    );
    expect(action.onPressed, isNull);
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('save-conversion-plan')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Charger un plan local'), findsOneWidget);
    final rect = tester.getRect(find.byKey(const ValueKey('action-bar')));
    expect(rect.bottom, lessThanOrEqualTo(800));
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a local plan is freshly restored and still needs approval', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    _setWindow(tester, const Size(1600, 1000));
    final planPath = '${source.root.path}/reviewed-plan.json';
    ConverterWorkflow? restored;
    try {
      await _scanAndPrepare(
        tester,
        source,
        planSavePicker: () async => planPath,
      );
      await _acknowledgeAndPrepare(tester, source);
      final recipe = source.workflow.exportStudyPlanRecipe();
      await tester.tap(find.byKey(const ValueKey('save-conversion-plan')));
      await tester.pump();
      await _waitFor(
        tester,
        () => find.textContaining('Plan enregistré.').evaluate().isNotEmpty,
      );
      expect(File(planPath).existsSync(), isTrue);
      expect(
        (await tester.runAsync(
          () => const LocalStudyPlanStore().read(planPath),
        ))!.canonicalHash,
        recipe.canonicalHash,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        ConverterApp(
          workflowFactory: () => restored = ConverterWorkflow(),
          pathPicker: (kind) async =>
              kind == ConverterPathKind.planFile ? planPath : null,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('load-conversion-plan')));
      await tester.pump();
      await _waitFor(
        tester,
        () =>
            restored?.state.prepared != null &&
            !restored!.state.isBusy &&
            find
                .textContaining('Une nouvelle approbation')
                .evaluate()
                .isNotEmpty,
      );
      expect(
        restored!.exportStudyPlanRecipe().canonicalHash,
        recipe.canonicalHash,
      );
      expect(restored!.state.approval, isNull);
      expect(restored!.state.result, isNull);
      expect(source.nativeStages, isEmpty);
      expect(find.textContaining('Une nouvelle approbation'), findsOneWidget);
      await _approveInDialog(tester);
      await _waitFor(tester, () => restored!.state.result != null);
      expect(restored!.state.result!.published, isTrue);
      expect(find.textContaining('Une nouvelle approbation'), findsNothing);
      expect(find.text('Projet d’étude publié et vérifié.'), findsOneWidget);
      await tester.runAsync(source.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await restored?.dispose();
        await source.close();
      });
    }
  }, skip: !Platform.isMacOS);

  testWidgets('a malformed local plan leaves the source form editable', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('ac16-invalid-plan-widget-'),
    ))!;
    _setWindow(tester, const Size(1280, 800));
    try {
      final plan = File('${root.path}/invalid.json');
      await tester.runAsync(() => plan.writeAsString('{"unexpected":true}'));
      await tester.pumpWidget(
        ConverterApp(
          pathPicker: (kind) async =>
              kind == ConverterPathKind.planFile ? plan.path : null,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('load-conversion-plan')));
      await tester.pump();
      await _waitFor(
        tester,
        () => find
            .textContaining('Le plan local n’a pas pu')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('choose-source')))
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('Projet d’étude publié'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => root.delete(recursive: true));
    }
  }, skip: !Platform.isMacOS);

  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];

  testWidgets('export explains native ledges and exact preparation budgets', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () => _nativeLedgeSource(scriptsPath!),
    ))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      final prepared = source.workflow.state.prepared!;
      final draft = prepared.nativeDraft!;
      final semantics = draft.compositionEvidence['sourceSemantics'] as Map;
      expect((semantics['directedJumps'] as Map)['importedJumpCount'], 1);
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(find.textContaining('Rebords : 1 importé(s)'), findsOneWidget);
      expect(
        find.textContaining('Le parcours animé reste à tester dans le Player.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          '${draft.artifacts.length + draft.sourceArtifacts.length} fichiers / ${prepared.settings.writeLimits.maxArtifacts}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          '${draft.mutations.length} opérations / ${prepared.settings.writeLimits.maxMutations}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          '${draft.validatedJsonByteLength} octets / ${prepared.settings.writeLimits.maxTotalDraftJsonBytes}',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(source.nativeStages, isEmpty);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);
  testWidgets('an excluded ledge has a visible reason and exact source cell', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () => _nativeLedgeSource(scriptsPath!, eventFootprint: true),
    ))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      final semantics =
          source
                  .workflow
                  .state
                  .prepared!
                  .nativeDraft!
                  .compositionEvidence['sourceSemantics']
              as Map;
      final jumps = semantics['directedJumps'] as Map;
      expect(jumps['importedJumpCount'], 0);
      expect(
        (jumps['diagnostics'] as List).single['code'],
        'jumps.source_event_footprint',
      );
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(
        find.textContaining(
          'Rebords : 0 importé(s) automatiquement ; 1 conservé(s)',
        ),
        findsOneWidget,
      );
      expect(find.text('Rebord à vérifier'), findsOneWidget);
      await tester.ensureVisible(find.text('Rebord à vérifier'));
      await tester.tap(find.text('Rebord à vérifier'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Un événement occupe le départ'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Original map 1 · 001 · case (2, 2) · vers le bas'),
        findsOneWidget,
      );
      expect(source.nativeStages, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);

  testWidgets('qualified and quarantined events are visible before creation', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () async => _OriginalSource.create(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt': utf8.encode(
            '[1]\nWalkCharset = OriginalPlayer\n',
          ),
          'Graphics/Characters/OriginalPlayer.png': image.encodePng(
            image.Image(width: 128, height: 192, numChannels: 4),
          ),
        },
        maps: [
          LiteralFixtureMap(
            id: 1,
            width: 4,
            height: 4,
            layers: [
              List.filled(16, 384),
              List.filled(16, 0),
              List.filled(16, 0),
            ],
            events: const [
              LiteralFixtureEvent(
                id: 1,
                x: 1,
                y: 1,
                pages: [
                  LiteralFixtureEventPage(
                    characterName: 'OriginalPlayer',
                    commands: [
                      LiteralFixtureEventCommand(101, ['Bienvenue']),
                    ],
                  ),
                ],
              ),
              LiteralFixtureEvent(
                id: 2,
                x: 2,
                y: 2,
                pages: [
                  LiteralFixtureEventPage(
                    commands: [
                      LiteralFixtureEventCommand(355, ['unknown_reward()']),
                      LiteralFixtureEventCommand(123, ['A', 0]),
                    ],
                  ),
                ],
              ),
            ],
          ),
          LiteralFixtureMap(id: 8),
        ],
      ),
    ))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(
        find.text(
          'Événements : 1 adapté(s) automatiquement sans IA ; 1 en quarantaine.',
        ),
        findsOneWidget,
      );
      expect(find.text('Événement conservé en quarantaine'), findsOneWidget);
      expect(
        find.textContaining('les événements restent à convertir'),
        findsNothing,
      );
      expect(source.nativeStages, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);

  testWidgets('semantic losses are visible before native creation', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () async => _OriginalSource.create(
        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        extraFiles: {
          'PBS/metadata.txt': utf8.encode(
            '[1]\nWalkCharset = OriginalPlayer\n',
          ),
          'Graphics/Characters/OriginalPlayer.png': image.encodePng(
            image.Image(width: 128, height: 192, numChannels: 4),
          ),
        },
        maps: [
          LiteralFixtureMap(
            id: 1,
            layers: const [
              [384, 391, 392],
              [0, 0, 0],
              [0, 0, 0],
            ],
          ),
          LiteralFixtureMap(id: 8),
        ],
        tilesets: [
          LiteralFixtureTileset(id: 1, terrainTags: {391: 20}),
        ],
      ),
    ))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(find.textContaining('Qualification partielle :'), findsOneWidget);
      expect(find.text('Comportement source à vérifier'), findsWidgets);
      await tester.ensureVisible(
        find.text('Comportement source à vérifier').first,
      );
      await tester.tap(find.text('Comportement source à vérifier').first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ils restent fermés dans ce projet.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(source.nativeStages, isEmpty);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);

  testWidgets(
    'caret and selection keep the prepared plan, text edits invalidate it',
    (tester) async {
      final harness = await tester.runAsync(_OriginalSource.create);
      final source = harness!;
      _setWindow(tester, const Size(1280, 800));
      try {
        await _scanAndPrepare(tester, source);
        await tester.tap(find.text('Source'));
        await tester.pump();
        final field = find.descendant(
          of: find.byKey(const ValueKey('source-path')),
          matching: find.byType(TextField),
        );
        await tester.tap(field);
        await tester.pump();
        final controller = tester.widget<TextField>(field).controller!;
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(
          find.text('Choix modifiés : préparez à nouveau le plan.'),
          findsNothing,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(source.workflow.state.isBusy, isFalse);
        expect(source.nativeStages, isEmpty);
        await tester.enterText(field, '${source.sourcePath}-modified');
        await tester.pump();
        expect(
          find.text('Choix modifiés : préparez à nouveau le plan.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Export'));
        await tester.pump();
        expect(_button(tester, 'create-study-project').onPressed, isNull);
        expect(source.workflow.state.result, isNull);
        expect(source.nativeStages, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'real project requires both study acknowledgement and exact plan approval',
    (tester) async {
      final harness = await tester.runAsync(_OriginalSource.create);
      final source = harness!;
      _setWindow(tester, const Size(1600, 1000));
      String? openedFolder;
      try {
        await _scanAndPrepare(
          tester,
          source,
          folderOpener: (value) async => openedFolder = value,
        );
        await tester.tap(find.text('Export'));
        await tester.pump();
        expect(_button(tester, 'create-study-project').onPressed, isNull);
        expect(source.nativeStages, isEmpty);
        await _acknowledgeAndPrepare(tester, source);
        await tester.tap(find.text('Ressources'));
        await tester.pump();
        expect(find.text('Original atlas'), findsOneWidget);
        await tester.tap(find.text('Vérification'));
        await tester.pump();
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        expect(find.text('Données source reconstruites'), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Export'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('create-study-project')));
        await tester.pumpAndSettle();
        expect(_button(tester, 'confirm-reviewed-plan').onPressed, isNull);
        expect(source.nativeStages, isEmpty);
        await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
        await tester.pumpAndSettle();
        expect(source.nativeStages, isEmpty);
        await _approveInDialog(tester);
        await _waitFor(tester, () => source.workflow.state.result != null);
        final result = source.workflow.state.result!;
        expect(result.receipt.verified, isTrue);
        expect(result.receipt.mapHashes, hasLength(2));
        expect(result.published, isTrue);
        expect(result.playableCertified, isFalse);
        expect(find.text('Projet d’étude publié et relu'), findsOneWidget);
        await tester.runAsync(() async {
          expect(await Directory(result.projectPath).exists(), isTrue);
          expect(
            await Directory('${source.output.path}/avelune-study').exists(),
            isTrue,
          );
          await source.expectSourceUnchanged();
        });
        await tester.ensureVisible(
          find.byKey(const ValueKey('show-result-folder')),
        );
        await tester.tap(find.byKey(const ValueKey('show-result-folder')));
        await tester.pump();
        expect(openedFolder, result.projectPath);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'cancelled native creation exposes recovery and asks for approval on retry',
    (tester) async {
      final entered = Completer<void>();
      final release = Completer<void>();
      String? recoveredFolder;
      String? openedFolder;
      var pause = true;
      final harness = await tester.runAsync(
        () => _OriginalSource.create(
          checkpoint: (stage, stagingRoot, _) async {
            if (stage == NativeWriteStage.afterBootstrap && pause) {
              pause = false;
              recoveredFolder = stagingRoot;
              entered.complete();
              await release.future;
            }
          },
        ),
      );
      final source = harness!;
      _setWindow(tester, const Size(1280, 800));
      try {
        await _scanAndPrepare(
          tester,
          source,
          folderOpener: (value) async => openedFolder = value,
        );
        await _acknowledgeAndPrepare(tester, source);
        await tester.tap(find.text('Export'));
        await tester.pump();
        await _approveInDialog(tester);
        await _waitFor(tester, () => entered.isCompleted);
        expect(_button(tester, 'cancel-job').onPressed, isNotNull);
        await tester.tap(find.byKey(const ValueKey('cancel-job')));
        await tester.pump();
        release.complete();
        await _waitFor(tester, () => !source.workflow.state.isBusy);
        expect(source.workflow.state.result, isNull);
        expect(source.workflow.state.failure!.stagingPath, recoveredFolder);
        expect(find.text(recoveredFolder!), findsOneWidget);
        expect(
          find.textContaining('La préparation est interrompue'),
          findsOneWidget,
        );
        expect(find.text('Projet d’étude publié et relu'), findsNothing);
        await tester.ensureVisible(
          find.byKey(const ValueKey('show-recovered-folder')),
        );
        await tester.tap(find.byKey(const ValueKey('show-recovered-folder')));
        await tester.pump();
        expect(openedFolder, recoveredFolder);
        await tester.runAsync(() async {
          expect(await Directory(recoveredFolder!).exists(), isTrue);
          expect(
            await Directory('${source.output.path}/avelune-study').exists(),
            isFalse,
          );
          await source.expectSourceUnchanged();
        });
        await tester.tap(find.byKey(const ValueKey('create-study-project')));
        await tester.pumpAndSettle();
        expect(_button(tester, 'confirm-reviewed-plan').onPressed, isNull);
        await tester.tap(find.byKey(const ValueKey('approve-plan')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
        await tester.pump();
        await _waitFor(tester, () => source.workflow.state.result != null);
        expect(
          source.workflow.state.result!.receipt.stagingRoot,
          isNot(recoveredFolder),
        );
        expect(
          find.byKey(const ValueKey('show-recovered-folder')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      } finally {
        if (!release.isCompleted) release.complete();
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('inaccessible source has a useful error and can be retried', (
    tester,
  ) async {
    final harness = await tester.runAsync(_OriginalSource.create);
    final source = harness!;
    _setWindow(tester, const Size(1280, 800));
    try {
      await tester.pumpWidget(
        ConverterApp(
          workflow: source.workflow,
          initialSourcePath: '${source.sourcePath}/missing',
          initialParentPath: source.output.path,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await tester.pump();
      await _waitFor(
        tester,
        () =>
            source.workflow.state.failure != null &&
            !source.workflow.state.isBusy,
      );
      expect(
        find.textContaining('Ce projet n’a pas pu être lu'),
        findsOneWidget,
      );
      expect(find.text('Projet d’étude publié et relu'), findsNothing);
      expect(source.nativeStages, isEmpty);
      await tester.tap(find.text('Source'));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('source-path')),
          matching: find.byType(TextField),
        ),
        source.sourcePath,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await tester.pump();
      await _waitFor(
        tester,
        () =>
            source.workflow.state.snapshot != null &&
            !source.workflow.state.isBusy,
      );
      await tester.ensureVisible(find.text('Tout sélectionner'));
      await tester.tap(find.text('Tout sélectionner'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await tester.pump();
      await _waitFor(
        tester,
        () =>
            source.workflow.state.prepared != null &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.failure, isNull);
      expect(
        source.workflow.state.prepared!.composition.nativeMaps,
        hasLength(2),
      );
      expect(find.textContaining('Ce projet n’a pas pu être lu'), findsNothing);
      expect(source.nativeStages, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  for (final size in [const Size(1280, 800), const Size(1600, 1000)]) {
    testWidgets(
      'long paths and map names remain usable at ${size.width}x${size.height}',
      (tester) async {
        final harness = await tester.runAsync(
          () => _OriginalSource.create(
            sourceSuffix:
                'source/${List.filled(6, 'original-source-with-a-deliberately-long-directory-name').join('/')}',
            maps: [
              LiteralFixtureMap(
                id: 1,
                name: List.filled(
                  4,
                  'Une route originale au nom très long',
                ).join(' '),
              ),
              LiteralFixtureMap(id: 8),
            ],
          ),
        );
        final source = harness!;
        _setWindow(tester, size);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        try {
          await _scanAndPrepare(tester, source);
          await _acknowledgeAndPrepare(tester, source);
          for (final step in [
            'Source',
            'Analyse',
            'Ressources',
            'Vérification',
            'Export',
          ]) {
            await tester.ensureVisible(find.text(step));
            await tester.tap(find.text(step));
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
            final footer = tester.getRect(
              find.byKey(const ValueKey('action-bar')),
            );
            expect(footer.bottom, lessThanOrEqualTo(size.height));
            expect(footer.height, greaterThanOrEqualTo(44));
            expect(tester.takeException(), isNull, reason: step);
            if (step == 'Vérification') {
              for (final key in ['source-map-canvas', 'target-map-canvas']) {
                final canvas = tester.getRect(find.byKey(ValueKey(key)));
                expect(canvas.width, greaterThan(250));
                expect(canvas.height, greaterThanOrEqualTo(280));
              }
            }
          }
          expect(_button(tester, 'create-study-project').onPressed, isNotNull);
          await tester.tap(find.byKey(const ValueKey('create-study-project')));
          await tester.pumpAndSettle();
          expect(_button(tester, 'confirm-reviewed-plan').onPressed, isNull);
          expect(tester.takeException(), isNull);
          expect(source.nativeStages, isEmpty);
          await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
          await tester.pumpAndSettle();
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(source.close);
        }
      },
      skip: !Platform.isMacOS,
    );
  }

  testWidgets(
    'keyboard traversal reaches all five steps and text shortcuts stay in fields',
    (tester) async {
      final harness = await tester.runAsync(_OriginalSource.create);
      final source = harness!;
      _setWindow(tester, const Size(1280, 800));
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      try {
        await tester.pumpWidget(
          ConverterApp(
            workflow: source.workflow,
            initialSourcePath: source.sourcePath,
            initialParentPath: source.output.path,
          ),
        );
        final editable = find.descendant(
          of: find.byKey(const ValueKey('source-path')),
          matching: find.byType(EditableText),
        );
        await _tabTo(tester, editable);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        final field = tester.widget<EditableText>(editable);
        expect(
          field.controller.selection,
          TextSelection(baseOffset: 0, extentOffset: source.sourcePath.length),
        );
        expect(source.workflow.state.snapshot, isNull);
        await _tabTo(tester, find.text('Analyser le projet'));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await _waitFor(
          tester,
          () =>
              source.workflow.state.snapshot != null &&
              !source.workflow.state.isBusy,
        );
        await _tabTo(tester, find.text('Tout sélectionner'));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await _tabTo(tester, find.text('Préparer la sélection'));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await _waitFor(
          tester,
          () =>
              source.workflow.state.prepared != null &&
              !source.workflow.state.isBusy,
        );
        for (final step in ['Ressources', 'Vérification', 'Export', 'Source']) {
          await _tabTo(tester, find.text(step));
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(tester.takeException(), isNull, reason: step);
        }
        await _tabTo(tester, editable);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        expect(
          find.text('Choix modifiés : préparez à nouveau le plan.'),
          findsNothing,
        );
        expect(source.workflow.state.isBusy, isFalse);
        expect(source.nativeStages, isEmpty);
        final current = tester.widget<EditableText>(editable);
        tester.testTextInput.enterText('${source.sourcePath}-changed');
        await tester.pump();
        expect(current.controller.text, '${source.sourcePath}-changed');
        expect(
          find.text('Choix modifiés : préparez à nouveau le plan.'),
          findsOneWidget,
        );
        expect(source.nativeStages, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );
}

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

StudioButton _button(WidgetTester tester, String key) =>
    tester.widget<StudioButton>(find.byKey(ValueKey(key)));

Future<void> _tabTo(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final element = tester.element(target);
    final widget = element.widget;
    final focused = widget is EditableText
        ? widget.focusNode.hasFocus
        : Focus.of(element).hasFocus;
    if (focused) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  throw StateError('Keyboard traversal did not reach $target.');
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() done, {
  Duration pumpDuration = Duration.zero,
}) async {
  for (var attempt = 0; attempt < 1500 && !done(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(pumpDuration);
  }
  if (!done()) {
    throw TimeoutException(
      'Real converter job did not reach the expected state.',
    );
  }
  await tester.pump();
}

Future<void> _scanAndPrepare(
  WidgetTester tester,
  _OriginalSource source, {
  Future<void> Function(String)? folderOpener,
  ConverterPlanSavePicker? planSavePicker,
  LocalReviewSessionStore? sessionStore,
}) async {
  await tester.pumpWidget(
    ConverterApp(
      workflow: source.workflow,
      initialSourcePath: source.sourcePath,
      initialParentPath: source.output.path,
      folderOpener: folderOpener ?? (_) async {},
      planSavePicker: planSavePicker ?? () async => null,
      sessionStore: sessionStore,
    ),
  );
  await tester.tap(find.byKey(const ValueKey('analyse-project')));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        source.workflow.state.snapshot != null && !source.workflow.state.isBusy,
  );
  await tester.ensureVisible(find.text('Tout sélectionner'));
  await tester.tap(find.text('Tout sélectionner'));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('prepare-study')));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        source.workflow.state.prepared != null && !source.workflow.state.isBusy,
  );
  expect(source.workflow.state.prepared!.composition.nativeMaps, hasLength(2));
}

ConverterAssetReviewPanel _reviewPanel(WidgetTester tester) => tester
    .widget<ConverterAssetReviewPanel>(find.byType(ConverterAssetReviewPanel));

StudioSelect _reviewMapSelector(WidgetTester tester) => tester
    .widget<StudioSelect>(find.byKey(const ValueKey('review-map-selector')));

Future<void> _showResources(WidgetTester tester) async {
  await tester.tap(find.text('Ressources'));
  await tester.pump();
}

Future<void> _selectReviewMap(WidgetTester tester, String value) async {
  final selector = _reviewMapSelector(tester);
  await tester.ensureVisible(find.byKey(const ValueKey('review-map-selector')));
  await tester.tap(find.byKey(const ValueKey('review-map-selector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(selector.options[value]!).last);
  await tester.pumpAndSettle();
}

Set<int> _claimedReviewMaps(AssetReviewSession session) => session
    .frame
    .placementClaims
    .values
    .expand((claims) => claims)
    .map((claim) => claim.sourceMapId)
    .toSet();

AssetReviewSession _renameReviewCandidate(
  AssetReviewSession session,
  String name,
) {
  final candidate = session.activeCandidates.first;
  return session.editMetadata(
    candidateId: candidate.candidateId,
    expectedCandidateHash: candidate.canonicalHash,
    expectedSessionHash: session.canonicalHash,
    name: name,
  );
}

Future<void> _acknowledgeAndPrepare(
  WidgetTester tester,
  _OriginalSource source,
) async {
  await tester.tap(find.text('Analyse'));
  await tester.pump();
  await tester.ensureVisible(find.byKey(const ValueKey('acknowledge-study')));
  await tester.tap(find.byKey(const ValueKey('acknowledge-study')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('prepare-study')));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        source.workflow.state.prepared?.canApprove == true &&
        !source.workflow.state.isBusy,
  );
}

Future<void> _approveInDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('create-study-project')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('approve-plan')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
  await tester.pump();
}

final class _OriginalSource {
  _OriginalSource(
    this.root,
    this.output,
    this.fixture,
    this.workflow,
    this.nativeStages,
  );

  final Directory root;
  final Directory output;
  final LiteralTileFixture fixture;
  final ConverterWorkflow workflow;
  final List<NativeWriteStage> nativeStages;
  String get sourcePath => fixture.sourceRootPath!;

  static Future<_OriginalSource> create({
    NativeWriteCheckpoint? checkpoint,
    String sourceSuffix = 'source',
    List<LiteralFixtureMap>? maps,
    List<int>? scriptsBytes,
    Map<String, List<int>> extraFiles = const {},
    List<LiteralFixtureTileset>? tilesets,
    bool includeEventSystem = false,
  }) async {
    final root = await Directory.systemTemp.createTemp('ac09-original-widget-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/$sourceSuffix',
        scriptsBytes: scriptsBytes,
        includeEventSystem: includeEventSystem,
        extraFiles: extraFiles,
        tilesets: tilesets,
        maps: maps ?? [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8)],
      );
      final stages = <NativeWriteStage>[];
      final workflow = ConverterWorkflow(
        nativeWriteCheckpoint: (stage, stagingRoot, projectPath) async {
          stages.add(stage);
          await checkpoint?.call(stage, stagingRoot, projectPath);
        },
      );
      return _OriginalSource(root, output, fixture, workflow, stages);
    } catch (_) {
      await root.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> expectSourceUnchanged() async {
    for (final entry in fixture.sourceBytes.entries) {
      expect(await File('$sourcePath/${entry.key}').readAsBytes(), entry.value);
    }
  }

  Future<void> close() async {
    await workflow.dispose();
    await root.delete(recursive: true);
  }
}

Future<_OriginalSource> _nativeLedgeSource(
  String scriptsPath, {
  bool eventFootprint = false,
}) async {
  final atlas = image.Image(width: 256, height: 64, numChannels: 4);
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      atlas.setPixelRgba(x, y, 31, 41, 59, 255);
    }
  }
  for (var y = 48; y < 64; y++) {
    for (var x = 0; x < 32; x++) {
      atlas.setPixelRgba(x, y, 73, 83, 97, 255);
    }
  }
  final middle = List<int>.filled(25, 0)..[12] = 392;
  return _OriginalSource.create(
    scriptsBytes: await File(scriptsPath).readAsBytes(),
    extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
      'Graphics/Characters/OriginalPlayer.png': image.encodePng(
        image.Image(width: 128, height: 192, numChannels: 4),
      ),
    },
    maps: [
      LiteralFixtureMap(
        id: 1,
        width: 5,
        height: 5,
        layers: [List.filled(25, 384), middle, List.filled(25, 0)],
        events: eventFootprint
            ? const [
                LiteralFixtureEvent(
                  id: 11,
                  x: 2,
                  y: 2,
                  pages: [LiteralFixtureEventPage(commands: [])],
                ),
              ]
            : const [],
      ),
      LiteralFixtureMap(id: 8),
    ],
    tilesets: [
      LiteralFixtureTileset(
        id: 1,
        png: image.encodePng(atlas),
        passages: {392: 7},
        terrainTags: {392: 1},
      ),
    ],
  );
}
