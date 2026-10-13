import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter/asset_review_panel.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../packages/avelune_converter_adapters/test/support/original_asset_fixture.dart';

void main() {
  testWidgets(
    'AC-10 revalidating the source keeps the active unsaved correction in the plan',
    (tester) async {
      final harness = (await tester.runAsync(_SessionHarness.create))!;
      try {
        await harness.pumpAndScan(tester);
        await tester.tap(find.byKey(const ValueKey('save-review-session')));
        await _wait(
          tester,
          () => find.text('Session enregistrée').evaluate().isNotEmpty,
        );
        final saved = (await tester.runAsync(harness.store.list))!.single;
        await tester.tap(find.text('Ressources'));
        await tester.pump();
        final panel = tester.widget<ConverterAssetReviewPanel>(
          find.byType(ConverterAssetReviewPanel),
        );
        final session = panel.session!;
        final sourceMapId = saved.reviewSet.segments.entries
            .singleWhere((entry) => entry.value.sessionId == session.sessionId)
            .key;
        final candidate = session.activeCandidates.first;
        final corrected = session.editMetadata(
          candidateId: candidate.candidateId,
          expectedCandidateHash: candidate.canonicalHash,
          expectedSessionHash: session.canonicalHash,
          name: 'Correction locale non enregistrée',
        );
        final correctedSet = saved.reviewSet.replaceSegment(
          sourceMapId: sourceMapId,
          next: corrected,
          expectedSetHash: saved.reviewSet.canonicalHash,
          expectedSegmentHash: session.canonicalHash,
        );
        panel.onSessionChanged!(corrected, session.canonicalHash);
        await tester.pump();
        await tester.tap(find.text('Source'));
        await tester.pump();
        final sourceField = find.descendant(
          of: find.byKey(const ValueKey('source-path')),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          sourceField,
          '${harness.fixture.literalFixture.sourceRootPath}-modified',
        );
        await tester.pump();
        await tester.enterText(
          sourceField,
          harness.fixture.literalFixture.sourceRootPath!,
        );
        await tester.pump();
        await tester.tap(find.text('Analyse'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('prepare-study')));
        await _wait(
          tester,
          () =>
              harness.workflow.state.prepared != null &&
              !harness.workflow.state.isBusy &&
              find
                  .text('Choix modifiés : préparez à nouveau le plan.')
                  .evaluate()
                  .isEmpty,
        );
        expect(
          harness.workflow.state.prepared!.reviewSet!.canonicalHash,
          correctedSet.canonicalHash,
        );
        expect(
          harness.workflow.state.settings!.reviewSet!.canonicalHash,
          correctedSet.canonicalHash,
        );
        expect(
          harness
              .workflow
              .state
              .prepared!
              .reviewSet!
              .segments[sourceMapId]!
              .canonicalHash,
          corrected.canonicalHash,
        );
        final stillSaved = (await tester.runAsync(harness.store.list))!.single;
        expect(stillSaved.canonicalHash, saved.canonicalHash);
        expect(
          stillSaved.reviewSet.canonicalHash,
          saved.reviewSet.canonicalHash,
        );
        expect(
          stillSaved.reviewSet.segments[sourceMapId]!.canonicalHash,
          session.canonicalHash,
        );
        expect(harness.workflow.state.approval, isNull);
        await tester.runAsync(harness.expectSourceUnchanged);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(harness.close);
      }
    },
    skip: !Platform.isMacOS,
  );
  testWidgets(
    'AC-10 loading saved reviews locks the current review until selection ends',
    (tester) async {
      final harness = (await tester.runAsync(_SessionHarness.create))!;
      try {
        await harness.pumpAndScan(tester);
        await tester.tap(find.byKey(const ValueKey('save-review-session')));
        await _wait(
          tester,
          () => find.text('Session enregistrée').evaluate().isNotEmpty,
        );
        await tester.tap(find.byKey(const ValueKey('load-review-session')));
        await tester.pump();
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('save-review-session')),
              )
              .onPressed,
          isNull,
        );
        await _wait(
          tester,
          () => find.text('Reprendre une session').evaluate().length > 1,
        );
        await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('save-review-session')),
              )
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(harness.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'AC-10 invalid saved context stays editable without a build exception',
    (tester) async {
      final harness = (await tester.runAsync(_SessionHarness.create))!;
      try {
        await harness.pumpAndScan(tester);
        await tester.tap(find.byKey(const ValueKey('save-review-session')));
        await _wait(
          tester,
          () => find.text('Session enregistrée').evaluate().isNotEmpty,
        );
        await tester.tap(find.text('Source'));
        await tester.pump();
        final folderField = find.descendant(
          of: find.byKey(const ValueKey('folder-name')),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(folderField);
        await tester.enterText(folderField, 'CON');
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('save-review-session')),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.text('Corrigez les champs du projet avant l’enregistrement.'),
          findsOneWidget,
        );
        await tester.enterText(folderField, 'avelune-study');
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('save-review-session')),
              )
              .onPressed,
          isNotNull,
        );
        final saved = (await tester.runAsync(harness.store.list))!.single;
        expect(saved.resumeSettings.folderName, 'avelune-study');
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(harness.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('AC-10 saves and reloads a real review in a fresh workflow', (
    tester,
  ) async {
    final harness = (await tester.runAsync(_SessionHarness.create))!;
    try {
      await harness.pumpAndScan(tester);
      final nameField = find.descendant(
        of: find.byKey(const ValueKey('project-name')),
        matching: find.byType(TextField),
      );
      await tester.tap(find.text('Source'));
      await tester.pump();
      await tester.enterText(nameField, 'Kanto étude enregistrée');
      await tester.tap(find.byKey(const ValueKey('save-review-session')));
      await _wait(
        tester,
        () => find.text('Session enregistrée').evaluate().isNotEmpty,
      );
      final saved = (await tester.runAsync(harness.store.list))!.single;
      expect(saved.resumeSettings.projectName, 'Kanto étude enregistrée');
      expect(saved.reviewSet.activeCandidates, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      final resumedWorkflow = ConverterWorkflow();
      harness.workflows.add(resumedWorkflow);
      await tester.pumpWidget(
        ConverterApp(workflow: resumedWorkflow, sessionStore: harness.store),
      );
      await tester.tap(find.byKey(const ValueKey('load-review-session')));
      await _wait(
        tester,
        () => find
            .byKey(ValueKey('load-session-${saved.reviewSet.sessionId.value}'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(
        find.byKey(ValueKey('load-session-${saved.reviewSet.sessionId.value}')),
      );
      await _wait(
        tester,
        () =>
            resumedWorkflow.state.prepared != null &&
            !resumedWorkflow.state.isBusy,
      );
      expect(
        resumedWorkflow.state.prepared!.reviewSet!.canonicalHash,
        saved.reviewSet.canonicalHash,
      );
      expect(
        resumedWorkflow.state.settings!.reviewSet!.canonicalHash,
        saved.reviewSet.canonicalHash,
      );
      expect(
        resumedWorkflow.state.settings!.projectName,
        'Kanto étude enregistrée',
      );
      expect(resumedWorkflow.state.approval, isNull);
      expect(resumedWorkflow.state.result, isNull);
      await tester.runAsync(harness.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(harness.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets(
    'AC-10 unsaved close keeps or discards only after explicit choice',
    (tester) async {
      final harness = (await tester.runAsync(_SessionHarness.create))!;
      try {
        await harness.pumpAndScan(tester);
        final first = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        expect(find.text('Enregistrer et fermer'), findsOneWidget);
        await tester.tap(find.widgetWithText(StudioButton, 'Rester'));
        await tester.pumpAndSettle();
        expect(await first, AppExitResponse.cancel);
        expect(await tester.runAsync(harness.store.list), isEmpty);
        final second = tester.binding.handleRequestAppExit();
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(StudioButton, 'Abandonner les changements'),
        );
        await tester.pumpAndSettle();
        expect(await second, AppExitResponse.exit);
        expect(await tester.runAsync(harness.store.list), isEmpty);
        await tester.runAsync(harness.expectSourceUnchanged);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(harness.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('AC-10 failed save cancels close and preserves the review', (
    tester,
  ) async {
    final harness = (await tester.runAsync(
      () => _SessionHarness.create(failSave: true),
    ))!;
    try {
      await harness.pumpAndScan(tester);
      final before = harness.workflow.state.prepared!.reviewSet!.canonicalHash;
      final response = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(StudioButton, 'Enregistrer et fermer'),
      );
      await _wait(
        tester,
        () => find.text('Enregistrement impossible').evaluate().isNotEmpty,
      );
      expect(await response, AppExitResponse.cancel);
      expect(harness.workflow.state.prepared!.reviewSet!.canonicalHash, before);
      expect(await tester.runAsync(harness.store.list), isEmpty);
      expect(find.text('Session enregistrée'), findsNothing);
      await tester.runAsync(harness.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(harness.close);
    }
  }, skip: !Platform.isMacOS);
}

Future<void> _wait(WidgetTester tester, bool Function() predicate) async {
  for (var i = 0; i < 1500 && !predicate(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    predicate(),
    isTrue,
    reason:
        'The real asynchronous session action did not finish: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>().join(" | ")}',
  );
}

final class _SessionHarness {
  _SessionHarness(this.root, this.fixture, this.store, this.workflow)
    : workflows = [workflow];
  final Directory root;
  final OriginalAssetFixture fixture;
  final LocalReviewSessionStore store;
  final ConverterWorkflow workflow;
  final List<ConverterWorkflow> workflows;

  static Future<_SessionHarness> create({bool failSave = false}) async {
    final root = await Directory.systemTemp.createTemp('ac10-app-session-');
    final fixture = await OriginalAssetFixture.create(
      sourceRootPath: '${root.path}/source',
    );
    await Directory('${root.path}/output').create();
    final store = LocalReviewSessionStore(
      rootPath: '${root.path}/support/reviews',
      checkpoint: failSave
          ? (stage, _) {
              if (stage == LocalReviewSessionWriteStage.beforePublish) {
                throw const FileSystemException('Controlled save failure');
              }
            }
          : null,
    );
    return _SessionHarness(root, fixture, store, ConverterWorkflow());
  }

  Future<void> pumpAndScan(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ConverterApp(
        workflow: workflow,
        sessionStore: store,
        initialSourcePath: fixture.literalFixture.sourceRootPath!,
        initialParentPath: '${root.path}/output',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('analyse-project')));
    await _wait(
      tester,
      () => workflow.state.prepared != null && !workflow.state.isBusy,
    );
  }

  Future<void> expectSourceUnchanged() async {
    for (final entry in fixture.literalFixture.sourceBytes.entries) {
      expect(
        await File('${fixture.literalFixture.sourceRootPath}/${entry.key}')
            .readAsBytes(),
        entry.value,
      );
    }
  }

  Future<void> close() async {
    for (final workflow in workflows) {
      await workflow.dispose();
    }
    await root.delete(recursive: true);
  }
}
