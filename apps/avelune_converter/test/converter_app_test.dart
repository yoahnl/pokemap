import '../../../packages/avelune_converter_core/test/support/interpretation_profile_fixture.dart';
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
  testWidgets('blocked preparation exposes explicit supplemental item choices',
      (tester) async {
    final source = (await tester.runAsync(() => _OriginalSource.create(
        scriptsBytes: syntheticInterpretationArchive,
        includeEventSystem: true,
        extraFiles: {
          'Data/items.dat': literalFixtureMarshal(<Object?, Object?>{}),
        },
        maps: [
          LiteralFixtureMap(id: 1, warpParameters: [[1, 8, 0, 0, 0, 0]],
              events: const [LiteralFixtureEvent(id: 2, x: 1, y: 0, pages: [
                LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(111, [12, 'pbItemBall(:ETHER)']),
                  LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
                  LiteralFixtureEventCommand(0, [], indent: 1),
                  LiteralFixtureEventCommand(412, []),
                  LiteralFixtureEventCommand(0, []),
                ]),
              ])]),
          LiteralFixtureMap(id: 8),
        ])))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      final donorPath = '${source.root.path}/donor';
      final profilePath = '${source.root.path}/profile.json';
      await tester.runAsync(() async {
        await Directory('$donorPath/Data').create(recursive: true);
        await File('$donorPath/Data/items.dat').writeAsBytes(literalFixtureMarshal({
          const LiteralFixtureSymbol('ETHER'):
              const LiteralFixtureObject('GameData::Item', {
            '@id': LiteralFixtureSymbol('ETHER'), '@real_name': 'Ether',
            '@real_name_plural': 'Ethers', '@real_portion_name': null,
            '@real_portion_name_plural': null, '@pocket': 2, '@price': 600,
            '@sell_price': 300, '@bp_price': 1, '@field_use': 1,
            '@battle_use': 2, '@flags': ['Fling_30'], '@consumable': true,
            '@show_quantity': null, '@move': null,
            '@real_description': 'Original source Ether', '@pbs_file_suffix': '',
          }),
        }));
        await File(profilePath).writeAsString(
            jsonEncode(syntheticSourceInterpretationProfile.toJson()));
      });
      await tester.pumpWidget(ConverterApp(
          workflow: source.workflow,
          initialSourcePath: source.sourcePath,
          initialParentPath: source.output.path,
          pathPicker: (kind) async => switch (kind) {
            ConverterPathKind.supplementalFolder => donorPath,
            ConverterPathKind.interpretationProfileFile => profilePath,
            _ => null,
          }));
      await tester.ensureVisible(find.byKey(const ValueKey('add-supplemental-source')));
      await tester.tap(find.byKey(const ValueKey('add-supplemental-source')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(tester, () => source.workflow.state.snapshot != null && !source.workflow.state.isBusy);
      await tester.ensureVisible(find.byKey(const ValueKey('choose-interpretation-profile')));
      await tester.tap(find.byKey(const ValueKey('choose-interpretation-profile')));
      await _waitFor(tester, () => find.textContaining('Profil de scripts sélectionné').evaluate().isNotEmpty);
      await tester.ensureVisible(find.text('Tout sélectionner'));
      await tester.tap(find.text('Tout sélectionner'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(tester, () => source.workflow.state.prepared != null && !source.workflow.state.isBusy);
      expect(source.workflow.state.prepared!.canApprove, isFalse);
      final picker = find.byKey(const ValueKey('missing-item-binding-ETHER'));
      expect(picker, findsOneWidget);
      final select = tester.widget<StudioSelect>(picker);
      expect(select.value, '');
      expect(select.options['_converter_sources/1/Data/items.dat'], donorPath);
      select.onChanged!('_converter_sources/1/Data/items.dat');
      await tester.pumpAndSettle();
      expect(source.workflow.state.prepared, isNull);
      expect(tester.widget<StudioSelect>(picker).value,
          '_converter_sources/1/Data/items.dat');
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(tester, () => source.workflow.state.prepared != null && !source.workflow.state.isBusy);
      expect(source.workflow.state.prepared!.settings.missingItemBindings.single.sourceSymbol, 'ETHER');
      expect(source.workflow.state.prepared!.canApprove, isFalse);
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(_button(tester, 'create-study-project').onPressed, isNull);
      expect(source.nativeStages, isEmpty);
      await tester.runAsync(source.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('content picker prepares world without object review and invalidates on change', (tester) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source, contentScope: ConverterContentScope.world);
      await _acknowledgeAndPrepare(tester, source);
      final prepared = source.workflow.state.prepared!;
      expect(prepared.settings.contentScope, ConverterContentScope.world);
      expect(prepared.reviewSet, isNull);
      expect(find.byKey(const ValueKey('save-review-session')), findsNothing);
      await tester.tap(find.text('Ressources'));
      await tester.pump();
      expect(find.byType(ConverterAssetReviewPanel), findsNothing);
      expect(find.textContaining('Ce mode ne prépare pas de revue d’objets'), findsOneWidget);
      await tester.tap(find.text('Analyse'));
      await tester.pump();
      final picker = find.byKey(const ValueKey('content-scope'));
      expect(tester.widget<StudioSelect>(picker).value, 'world');
      expect(find.textContaining('L’eau reste fermée sans Surf.'), findsOneWidget);
      expect(find.textContaining('PNJ, objets interactifs, dialogues, combats, rencontres et musiques ne sont pas importés'), findsOneWidget);
      expect(tester.widget<StudioSelect>(picker).options, {
        'world': 'Monde explorable (cartes, collisions, personnage)',
        'full': 'Monde, interactions et musiques',
      });
      tester.widget<StudioSelect>(picker).onChanged!('full');
      await tester.pumpAndSettle();
      expect(source.workflow.state.prepared, isNull);
      expect(source.workflow.state.approval, isNull);
      expect(tester.widget<StudioSelect>(picker).value, 'full');
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(tester, () => source.workflow.state.prepared != null && !source.workflow.state.isBusy);
      expect(source.workflow.state.prepared!.settings.contentScope, ConverterContentScope.full);
      expect(source.workflow.state.prepared!.reviewSet, isNotNull);
      await tester.tap(find.text('Ressources'));
      await tester.pump();
      expect(find.byType(ConverterAssetReviewPanel), findsOneWidget);
      await tester.runAsync(source.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('native preparation shows its own phase before creating files',
      (tester) async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final source = (await tester.runAsync(() => _OriginalSource.create(
      workflowCheckpoint: (phase, _, _) async {
        if (phase.name == 'projectNativeMutations') {
          entered.complete();
          await release.future;
        }
      },
    )))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await _scanAndPrepare(tester, source);
      await _acknowledgeAndPrepare(tester, source);
      await tester.tap(find.text('Export'));
      await tester.pump();
      await _approveInDialog(tester);
      await _waitFor(tester, () => entered.isCompleted);
      expect(find.text('Assemblage du projet à créer'), findsOneWidget);
      expect(find.text('Création du projet Avelune'), findsNothing);
      expect(source.nativeStages, isEmpty);
      expect(_button(tester, 'cancel-job').onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('cancel-job')));
      await tester.pump();
      release.complete();
      await _waitFor(tester, () => !source.workflow.state.isBusy);
      expect(source.workflow.state.failure!.code, 'workflow.cancelled');
      expect(source.workflow.state.result, isNull);
      expect(source.nativeStages, isEmpty);
      await tester.runAsync(source.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      if (!release.isCompleted) release.complete();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  testWidgets('source defects require an explicit reversible presentation decision', (tester) async {
    final source = (await tester.runAsync(() => _OriginalSource.create(maps: [
      LiteralFixtureMap(id: 1, events: [const LiteralFixtureEvent(id: 2, x: 1, y: 0,
        pages: [LiteralFixtureEventPage(tileId: 511, commands: [LiteralFixtureEventCommand(0, [])])])]),
    ])))!;
    _setWindow(tester, const Size(1600, 1000));
    try {
      await tester.pumpWidget(ConverterApp(workflow: source.workflow,
        initialSourcePath: source.sourcePath, initialParentPath: source.output.path,
        sessionStore: LocalReviewSessionStore(rootPath: '${source.root.path}/sessions')));
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(tester, () => source.workflow.state.snapshot != null && !source.workflow.state.isBusy);
      await tester.ensureVisible(find.text('Tout sélectionner'));
      await tester.tap(find.text('Tout sélectionner'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('acknowledge-study')));
      await tester.tap(find.byKey(const ValueKey('acknowledge-study')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(tester, () => source.workflow.state.prepared != null && !source.workflow.state.isBusy);
      expect(source.workflow.state.prepared!.settings.sourceAdaptations, isEmpty);
      final issue = source.workflow.state.prepared!.sourceAdaptationInventory.issues.singleWhere((value) => value.action != null);
      final picker = find.byKey(ValueKey('source-adaptation-${issue.action!.targetKey}'));
      expect(picker, findsOneWidget);
      expect(tester.widget<StudioSelect>(picker).value, '');
      tester.widget<StudioSelect>(picker).onChanged!('apply');
      await tester.pumpAndSettle();
      if (find.text('Abandonner les changements').evaluate().isNotEmpty) {
        await tester.tap(find.text('Abandonner les changements'));
        await tester.pumpAndSettle();
      }
      expect(source.workflow.state.prepared, isNull);
      expect(source.workflow.state.approval, isNull);
      expect(tester.widget<StudioSelect>(picker).value, 'apply');
      await tester.tap(find.byKey(const ValueKey('prepare-study')));
      await _waitFor(tester, () => source.workflow.state.prepared != null && !source.workflow.state.isBusy);
      final adapted = source.workflow.state.prepared!;
      expect(adapted.settings.sourceAdaptations.single.kind, SourceEventAdaptationKind.omitInvalidEventTileGraphic);
      expect(adapted.normalizedSource.eventImages.where((value) => value.sourceTileId == 511), isEmpty);
      tester.widget<StudioSelect>(picker).onChanged!('');
      await tester.pumpAndSettle();
      if (find.text('Abandonner les changements').evaluate().isNotEmpty) {
        await tester.tap(find.text('Abandonner les changements'));
        await tester.pumpAndSettle();
      }
      expect(source.workflow.state.prepared, isNull);
      expect(tester.widget<StudioSelect>(picker).value, '');
      await tester.runAsync(source.expectSourceUnchanged);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

  final knownArchivePath = Platform.environment['AVELUNE_KNOWN_SCRIPTS_ARCHIVE'];
  testWidgets('known source detects a profile and preserves manual and literal choices on rescan', (tester) async {
    final bytes = (await tester.runAsync(() => File(knownArchivePath!).readAsBytes()))!;
    final source = (await tester.runAsync(() => _OriginalSource.create(
      scriptsBytes: bytes, withoutInterpretationProfile: true)))!;
    final other = (await tester.runAsync(() => LiteralTileFixture.create(
      sourceRootPath: '${source.root.path}/other-source', scriptsBytes: bytes)))!;
    var pickedSource = other.sourceRootPath!;
    final manual = File('${source.root.path}/manual-profile.json');
    await tester.runAsync(() => manual.writeAsString(jsonEncode(syntheticSourceInterpretationProfile.toJson())));
    _setWindow(tester, const Size(1600, 1000));
    try {
      await tester.pumpWidget(ConverterApp(workflow: source.workflow,
        initialSourcePath: source.sourcePath, initialParentPath: source.output.path,
        pathPicker: (kind) async => kind == ConverterPathKind.interpretationProfileFile
          ? manual.path : kind == ConverterPathKind.sourceFolder ? pickedSource : null));
      Future<void> scan() async {
        await tester.tap(find.byKey(const ValueKey('analyse-project')));
        await _waitFor(tester, () => source.workflow.state.snapshot != null && !source.workflow.state.isBusy);
      }
      await scan();
      expect(find.text('Règles Pokémon Essentials reconnues automatiquement.'), findsOneWidget);
      final choose = find.byKey(const ValueKey('choose-interpretation-profile'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await _waitFor(tester, () => find.text('Profil de scripts sélectionné : synthetic-static-profile').evaluate().isNotEmpty);
      await tester.tap(find.text('Source').first);
      await tester.pump();
      await scan();
      expect(find.text('Profil de scripts sélectionné : synthetic-static-profile'), findsOneWidget);
      await tester.tap(find.text('Source').first);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('choose-source')));
      await tester.tap(find.byKey(const ValueKey('choose-source')));
      await _waitFor(tester, () => source.workflow.state.prepared == null);
      await tester.pump();
      await scan();
      expect(find.text('Règles Pokémon Essentials reconnues automatiquement.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('clear-interpretation-profile')));
      await tester.tap(find.byKey(const ValueKey('clear-interpretation-profile')));
      await tester.pump();
      await tester.tap(find.text('Source').first);
      await tester.pump();
      await scan();
      expect(find.textContaining('Sans profil de scripts : étude littérale'), findsOneWidget);
      expect(find.byKey(const ValueKey('clear-interpretation-profile')), findsNothing);
      pickedSource = source.sourcePath;
      await tester.tap(find.text('Source').first);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('choose-source')));
      await tester.tap(find.byKey(const ValueKey('choose-source')));
      await tester.pumpAndSettle();
      await scan();
      expect(find.text('Règles Pokémon Essentials reconnues automatiquement.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('clear-interpretation-profile')));
      await tester.tap(find.byKey(const ValueKey('clear-interpretation-profile')));
      await tester.pump();
      await tester.tap(find.text('Source').first);
      await tester.pump();
      await tester.enterText(find.descendant(of: find.byKey(const ValueKey('source-path')),
        matching: find.byType(TextField)), other.sourceRootPath!);
      await tester.pump();
      await scan();
      expect(find.text('Règles Pokémon Essentials reconnues automatiquement.'), findsOneWidget);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS || knownArchivePath == null);

  testWidgets('source interpretation selection is explicit and clearable', (tester) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    final profile = File('${source.root.path}/selected-profile.json');
    await tester.runAsync(() => profile.writeAsString(jsonEncode(syntheticSourceInterpretationProfile.toJson())));
    _setWindow(tester, const Size(1600, 1000));
    try {
      await tester.pumpWidget(ConverterApp(workflow: source.workflow,
        initialSourcePath: source.sourcePath, initialParentPath: source.output.path,
        pathPicker: (kind) async => kind == ConverterPathKind.interpretationProfileFile ? profile.path : null));
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(tester, () => source.workflow.state.snapshot != null && !source.workflow.state.isBusy);
      final choose = find.byKey(const ValueKey('choose-interpretation-profile'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await _waitFor(tester, () => find.text('Profil de scripts sélectionné : synthetic-static-profile').evaluate().isNotEmpty);
      expect(find.byKey(const ValueKey('clear-interpretation-profile')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('clear-interpretation-profile')));
      await tester.tap(find.byKey(const ValueKey('clear-interpretation-profile')));
      await tester.pump();
      expect(find.byKey(const ValueKey('clear-interpretation-profile')), findsNothing);
      expect(find.textContaining('Sans profil de scripts : étude littérale'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.close);
    }
  });

  for (final scope in [ConverterContentScope.full, ConverterContentScope.world]) {
    testWidgets('nine-map ${scope.name} budget survives public preparation',
        (tester) async {
      final source = (await tester.runAsync(() => _OriginalSource.create(
          maps: [for (var id = 1; id <= 9; id++) LiteralFixtureMap(id: id)])))!;
      final store = LocalReviewSessionStore(rootPath: '${source.root.path}/sessions');
      ConverterWorkflow? resumed;
      _setWindow(tester, const Size(1600, 1000));
      try {
        await _scanAndPrepare(tester, source, sessionStore: store, contentScope: scope);
        final initial = source.workflow.state.prepared!;
        final expectedBytes = scope == ConverterContentScope.full ? 536870912 : 268435456;
        expect(initial.settings.selectedSourceMapIds, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
        expect(initial.settings.writeLimits.maxTotalArtifactBytes, expectedBytes);
        if (scope == ConverterContentScope.full) {
          await _showResources(tester);
          expect(_reviewPanel(tester).limits.maxTotalArtifactBytes, expectedBytes);
          await tester.tap(find.text('Analyse'));
          await tester.pump();
          await tester.ensureVisible(find.byKey(const ValueKey('save-review-session')));
          await tester.tap(find.byKey(const ValueKey('save-review-session')));
          await _waitFor(tester,
              () => find.text('Session enregistrée').evaluate().isNotEmpty);
          final saved = (await tester.runAsync(store.list))!.single;
          expect(saved.resumeSettings.writeLimits.maxTotalArtifactBytes, expectedBytes);
          expect(source.workflow.state.prepared, same(initial));
          await tester.tap(find.byKey(const ValueKey('prepare-study')));
          await _waitFor(tester, () =>
              source.workflow.state.prepared != null &&
              !identical(source.workflow.state.prepared, initial) &&
              !source.workflow.state.isBusy);
          expect(source.workflow.state.prepared!.settings.writeLimits.maxTotalArtifactBytes,
              expectedBytes);
          await tester.pumpWidget(const SizedBox());
          resumed = ConverterWorkflow();
          await tester.pumpWidget(ConverterApp(workflow: resumed, sessionStore: store));
          await tester.tap(find.byKey(const ValueKey('load-review-session')));
          final session = find.byKey(ValueKey('load-session-${saved.reviewSet.sessionId.value}'));
          await _waitFor(tester, () => session.evaluate().isNotEmpty);
          await tester.tap(session);
          await _waitFor(tester, () =>
              find.text('Session reprise · source vérifiée').evaluate().isNotEmpty &&
              resumed!.state.prepared != null && !resumed.state.isBusy);
          expect(resumed.state.prepared!.settings.contentScope, ConverterContentScope.full);
          expect(resumed.state.prepared!.settings.selectedSourceMapIds,
              initial.settings.selectedSourceMapIds);
          expect(resumed.state.prepared!.settings.writeLimits.maxTotalArtifactBytes,
              expectedBytes);
          expect(resumed.state.approval, isNull);
          expect(resumed.state.result, isNull);
        } else {
          expect(initial.reviewSet, isNull);
          expect(find.byKey(const ValueKey('save-review-session')), findsNothing);
        }
        expect(source.nativeStages, isEmpty);
        expect(await tester.runAsync(() => source.output.list().isEmpty), isTrue);
        await tester.runAsync(source.expectSourceUnchanged);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        if (resumed != null) await tester.runAsync(resumed.dispose);
        await tester.runAsync(source.close);
      }
    }, skip: !Platform.isMacOS);
  }

  testWidgets(
    'one-map native budget survives resource review and session save',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      final store = LocalReviewSessionStore(
        rootPath: '${source.root.path}/sessions',
      );
      _setWindow(tester, const Size(1600, 1000));
      try {
        await tester.pumpWidget(
          ConverterApp(
            workflow: source.workflow,
            sessionStore: store,
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
        await tester.ensureVisible(find.byKey(const ValueKey('select-map-1')));
        await tester.tap(find.byKey(const ValueKey('select-map-1')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('prepare-study')));
        await _waitFor(
          tester,
          () =>
              source.workflow.state.prepared != null &&
              !source.workflow.state.isBusy,
        );
        expect(source.workflow.state.prepared!.settings.selectedSourceMapIds, [1]);
        await _showResources(tester);
        final panel = tester.widget<ConverterAssetReviewPanel>(
          find.byType(ConverterAssetReviewPanel),
        );
        expect(panel.limits.maxArtifacts, 4096);
        expect(panel.limits.maxMutations, 32768);
        await tester.tap(find.text('Export'));
        await tester.pump();
        final prepared = source.workflow.state.prepared!;
        final draft = prepared.nativeDraft!;
        final uniqueHandles = {
          for (final artifact in [...draft.artifacts, ...draft.sourceArtifacts])
            artifact.handle
        };
        expect(
          find.text(
            'Plan : ${uniqueHandles.length} ressources uniques / 4096, '
            '${draft.sourceArtifacts.length} témoins source, '
            '${draft.mutations.length} opérations / 32768, '
            '${draft.validatedJsonByteLength} octets / ${prepared.settings.writeLimits.maxTotalDraftJsonBytes}.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Analyse'));
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const ValueKey('save-review-session')),
        );
        await tester.tap(find.byKey(const ValueKey('save-review-session')));
        await _waitFor(
          tester,
          () => find.text('Session enregistrée').evaluate().isNotEmpty,
        );
        final saved = (await tester.runAsync(store.list))!.single;
        expect(saved.resumeSettings.writeLimits.maxArtifacts, 4096);
        expect(saved.resumeSettings.writeLimits.maxMutations, 32768);
        await tester.runAsync(source.expectSourceUnchanged);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'cold provenance refusal cannot be replaced through prepare save or retry',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      final store = LocalReviewSessionStore(
        rootPath: '${source.root.path}/sessions',
      );
      final first = '${source.root.path}/reference-first';
      final second = '${source.root.path}/reference-second';
      const relative = 'Audio/BGM/unused.ogg';
      ConverterWorkflow? resumed;
      _setWindow(tester, const Size(1600, 1000));
      try {
        final stored = (await tester.runAsync(() async {
          await Directory('$first/Audio/BGM').create(recursive: true);
          await Directory('$second/Audio/BGM').create(recursive: true);
          await File('$second/$relative').writeAsBytes([1, 7, 19]);
          final snapshot = await source.workflow.scanSource(
            ConverterSourceSelection(
              rootPath: source.sourcePath,
              supplementalRootPaths: [first, second],
              logicalProjectNamespace: ConverterId('cold-provenance-widget'),
            ),
          );
          source.workflow.updateSettings(
            ConverterStudySettings(
              projectName: 'Cold provenance',
              parentPath: source.output.path,
              folderName: 'cold-provenance',
              selectedSourceMapIds: [1, 8],
              assetOutputMode: AssetOutputMode.standaloneObjects,
              profileAcknowledgement: SourceStudyAcknowledgement(
                sourceSnapshotHash: snapshot.canonicalHash,
                profileEvidenceHash: snapshot.profile.evidenceHash,
                humanConfirmed: true,
                reason: 'Controlled original source.',
              ),
            ),
          );
          final prepared = await source.workflow.prepareStudy();
          expect(prepared.canApprove, isTrue);
          final saved = await store.create(
            reviewSet: prepared.reviewSet!,
            resumeSettings: LocalReviewResumeSettings(
              sourceRootPath: source.sourcePath,
              supplementalRootPaths: [first, second],
              sharedSourceFiles: source.workflow.state.sharedSourceFiles,
              destinationParentPath: source.output.path,
              projectName: prepared.settings.projectName,
              folderName: prepared.settings.folderName,
              normalizationLimits: prepared.settings.normalizationLimits,
              writeLimits: prepared.settings.writeLimits,
              profileAcknowledgement: LocalReviewProfileAcknowledgement(
                sourceSnapshotHash: prepared.sourceSnapshotHash,
                profileEvidenceHash: prepared.profileEvidenceHash,
                humanConfirmed: true,
                reason: 'Controlled original source.',
              ),
            ),
          );
          expect(
            saved.resumeSettings.sharedSourceFiles.single.referenceRootPath,
            second,
          );
          await File('$second/$relative').rename('$first/$relative');
          return saved;
        }))!;
        var picks = 0;
        var selectedSource = source.sourcePath;
        var selectedSupplements = [first, second];
        var supplementalPick = 0;
        resumed = ConverterWorkflow();
        await tester.pumpWidget(
          ConverterApp(
            workflow: resumed,
            sessionStore: store,
            pathPicker: (kind) async {
              picks++;
              return kind == ConverterPathKind.supplementalFolder
                  ? selectedSupplements[supplementalPick++]
                  : selectedSource;
            },
          ),
        );
        await tester.tap(find.byKey(const ValueKey('load-review-session')));
        final sessionKey = ValueKey(
          'load-session-${stored.reviewSet.sessionId.value}',
        );
        await _waitFor(
          tester,
          () => find.byKey(sessionKey).evaluate().isNotEmpty,
        );
        await tester.tap(find.byKey(sessionKey));
        await _waitFor(
          tester,
          () =>
              find
                  .text('Session conservée · source à retrouver')
                  .evaluate()
                  .isNotEmpty &&
              !resumed!.state.isBusy,
        );
        expect(
          resumed.state.snapshot!.canonicalHash,
          stored.reviewSet.sourceSnapshotHash,
        );
        expect(resumed.state.sharedSourceFiles.single.referenceRootPath, first);
        expect(_reviewPanel(tester).enabled, isFalse);
        for (var attempt = 0; attempt < 2; attempt++) {
          expect(_button(tester, 'save-review-session').onPressed, isNull);
          await tester.tap(find.byKey(const ValueKey('save-review-session')));
          await tester.pump();
          final before = resumed.state.revision;
          expect(_button(tester, 'prepare-study').onPressed, isNotNull);
          await tester.tap(find.byKey(const ValueKey('prepare-study')));
          await _waitFor(
            tester,
            () =>
                resumed!.state.revision > before &&
                !resumed.state.isBusy &&
                (resumed.state.prepared != null ||
                    find
                        .text(
                          'Le projet source a changé. Relancez son analyse avant de créer le projet Avelune.',
                        )
                        .evaluate()
                        .isNotEmpty),
          );
          expect(resumed.state.prepared, isNull);
          expect(resumed.state.approval, isNull);
          expect(_reviewPanel(tester).enabled, isFalse);
          expect(_button(tester, 'save-review-session').onPressed, isNull);
          final unchanged = (await tester.runAsync(
            () => store.load(stored.reviewSet.sessionId),
          ))!;
          expect(unchanged.canonicalHash, stored.canonicalHash);
          expect(
            unchanged.resumeSettings.sharedSourceFiles.single.referenceRootPath,
            second,
          );
          final retryRevision = resumed.state.revision;
          await tester.tap(
            find.byKey(const ValueKey('reselect-session-source')),
          );
          await _waitFor(
            tester,
            () =>
                picks == attempt + 1 &&
                resumed!.state.revision > retryRevision &&
                !resumed.state.isBusy &&
                find
                    .text('Session conservée · source à retrouver')
                    .evaluate()
                    .isNotEmpty,
          );
          expect(resumed.state.prepared, isNull);
          expect(_reviewPanel(tester).enabled, isFalse);
        }
        selectedSource = '${source.sourcePath}-moved';
        selectedSupplements = ['$first-moved', '$second-moved'];
        await tester.runAsync(() async {
          await Directory(source.sourcePath).rename(selectedSource);
          await Directory(first).rename(selectedSupplements[0]);
          await Directory(second).rename(selectedSupplements[1]);
        });
        for (final key in [
          'reselect-session-source',
          'reselect-session-supplemental-source-0',
          'reselect-session-supplemental-source-1',
        ]) {
          final before = picks;
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pump();
          await _waitFor(
            tester,
            () =>
                picks > before ||
                find.text('Abandonner les changements').evaluate().isNotEmpty,
          );
          if (find.text('Abandonner les changements').evaluate().isNotEmpty) {
            await tester.tap(find.text('Abandonner les changements'));
          }
          await _waitFor(
            tester,
            () =>
                picks > before &&
                !resumed!.state.isBusy &&
                find
                    .text('Session conservée · source à retrouver')
                    .evaluate()
                    .isNotEmpty &&
                find.text('Vérification de la source…').evaluate().isEmpty,
          );
          expect(resumed.state.prepared, isNull);
        }
        expect(resumed.state.source!.rootPath, selectedSource);
        expect(
          resumed.state.source!.supplementalRootPaths,
          selectedSupplements,
        );
        expect(_button(tester, 'prepare-study').onPressed, isNotNull);
        final savedBeforeRecovery = (await tester.runAsync(
          () => store.load(stored.reviewSet.sessionId),
        ))!;
        expect(savedBeforeRecovery.canonicalHash, stored.canonicalHash);
        await tester.runAsync(
          () =>
              File('${selectedSupplements[0]}/$relative')
                  .rename('${selectedSupplements[1]}/$relative'),
        );
        await tester.tap(find.byKey(const ValueKey('prepare-study')));
        await _waitFor(
          tester,
          () => resumed!.state.prepared != null && !resumed.state.isBusy,
        );
        expect(_reviewPanel(tester).enabled, isTrue);
        expect(
          resumed.state.prepared!.reviewSet!.canonicalHash,
          stored.reviewSet.canonicalHash,
        );
        expect(
          resumed.state.sharedSourceFiles.single.referenceRootPath,
          selectedSupplements[1],
        );
        await tester.tap(find.byKey(const ValueKey('save-review-session')));
        await _waitFor(
          tester,
          () => find.text('Session enregistrée').evaluate().isNotEmpty,
        );
        final saved = (await tester.runAsync(
          () => store.load(stored.reviewSet.sessionId),
        ))!;
        expect(
          saved.resumeSettings.sharedSourceFiles.single.referenceRootPath,
          selectedSupplements[1],
        );
        expect(saved.resumeSettings.sourceRootPath, selectedSource);
        expect(saved.resumeSettings.supplementalRootPaths, selectedSupplements);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await resumed?.dispose();
          await source.close();
        });
      }
    },
    skip: !Platform.isMacOS,
  );

  for (final sharedFirst in [false, true]) {
    testWidgets(
      'cold ordered session relocates three roots supplementsFirst=$sharedFirst',
      (tester) async {
        final source = (await tester.runAsync(_OriginalSource.create))!;
        final store = LocalReviewSessionStore(
          rootPath: '${source.root.path}/sessions',
        );
        final sharedPath = '${source.root.path}/shared';
        final movedSource = '${source.root.path}/source-moved';
        final movedShared = '${source.root.path}/shared-moved';
        final secondPath = '${source.root.path}/second';
        final movedSecond = '${source.root.path}/second-moved';
        ConverterWorkflow? resumed;
        _setWindow(tester, const Size(1600, 1000));
        final picks = <ConverterPathKind>[];
        try {
          final stored = (await tester.runAsync(() async {
            await Directory('$sharedPath/PBS').create(recursive: true);
            await File('$sharedPath/PBS/items.txt')
                .writeAsString('1,POTION,Potion,1,300,Heals HP,1,1,0');
            await Directory('$secondPath/Audio/BGM').create(recursive: true);
            await File('$secondPath/Audio/BGM/unused.ogg')
                .writeAsString('original supplemental audio');
            final snapshot = await source.workflow.scanSource(
              ConverterSourceSelection(
                rootPath: source.sourcePath,
                supplementalRootPaths: [sharedPath, secondPath],
                logicalProjectNamespace: ConverterId('cold-shared-session'),
              ),
            );
            source.workflow.updateSettings(
              ConverterStudySettings(
                projectName: 'Cold shared session',
                parentPath: source.output.path,
                folderName: 'cold-shared-session',
                selectedSourceMapIds: [1, 8],
                assetOutputMode: AssetOutputMode.standaloneObjects,
                profileAcknowledgement: SourceStudyAcknowledgement(
                  sourceSnapshotHash: snapshot.canonicalHash,
                  profileEvidenceHash: snapshot.profile.evidenceHash,
                  humanConfirmed: true,
                  reason: 'Controlled original source.',
                ),
              ),
            );
            final prepared = await source.workflow.prepareStudy();
            source.workflow.approvePrepared(
              sessionRevision: prepared.sessionRevision,
              preparationHash: prepared.preparationHash,
              humanConfirmed: true,
            );
            final stored = await store.create(
              reviewSet: prepared.reviewSet!,
              resumeSettings: LocalReviewResumeSettings(
                sourceRootPath: source.sourcePath,
                supplementalRootPaths: [sharedPath, secondPath],
                sharedSourceFiles: source.workflow.state.sharedSourceFiles,
                destinationParentPath: source.output.path,
                projectName: prepared.settings.projectName,
                folderName: prepared.settings.folderName,
                normalizationLimits: prepared.settings.normalizationLimits,
                writeLimits: prepared.settings.writeLimits,
                profileAcknowledgement: LocalReviewProfileAcknowledgement(
                  sourceSnapshotHash: prepared.sourceSnapshotHash,
                  profileEvidenceHash: prepared.profileEvidenceHash,
                  humanConfirmed: true,
                  reason: 'Controlled original source.',
                ),
              ),
            );
            await Directory(source.sourcePath).rename(movedSource);
            await Directory(sharedPath).rename(movedShared);
            await Directory(secondPath).rename(movedSecond);
            return stored;
          }))!;
          var supplementalPick = 0;
          final movedSupplements = sharedFirst
              ? [movedSecond, movedShared]
              : [movedShared, movedSecond];
          resumed = ConverterWorkflow();
          await tester.pumpWidget(
            ConverterApp(
              workflow: resumed,
              sessionStore: store,
              pathPicker: (kind) async {
                picks.add(kind);
                return kind == ConverterPathKind.supplementalFolder
                    ? movedSupplements[supplementalPick++].replaceFirst(
                        '/private/tmp/',
                        '/tmp/',
                      )
                    : movedSource.replaceFirst('/private/tmp/', '/tmp/');
              },
            ),
          );
          await tester.tap(find.byKey(const ValueKey('load-review-session')));
          final sessionKey = ValueKey(
            'load-session-${stored.reviewSet.sessionId.value}',
          );
          await _waitFor(
            tester,
            () => find.byKey(sessionKey).evaluate().isNotEmpty,
          );
          await tester.tap(find.byKey(sessionKey));
          await _waitFor(
            tester,
            () =>
                find
                    .text('Session conservée · source à retrouver')
                    .evaluate()
                    .isNotEmpty &&
                !resumed!.state.isBusy,
          );
          expect(resumed.state.approval, isNull);
          final order = sharedFirst
              ? [
                  'reselect-session-supplemental-source-1',
                  'reselect-session-supplemental-source-0',
                  'reselect-session-source',
                ]
              : [
                  'reselect-session-source',
                  'reselect-session-supplemental-source-0',
                  'reselect-session-supplemental-source-1',
                ];
          for (var i = 0; i < order.length; i++) {
            await tester.ensureVisible(find.byKey(ValueKey(order[i])));
            await tester.tap(find.byKey(ValueKey(order[i])));
            await tester.pump();
            await _waitFor(
              tester,
              () =>
                  picks.length == i + 1 ||
                  find.text('Abandonner les changements').evaluate().isNotEmpty,
              pumpDuration: const Duration(milliseconds: 20),
            );
            if (find.text('Abandonner les changements').evaluate().isNotEmpty) {
              await tester.tap(find.text('Abandonner les changements'));
              await tester.pump();
            }
            await _waitFor(
              tester,
              () =>
                  picks.length == i + 1 &&
                  !resumed!.state.isBusy &&
                  find.text('Vérification de la source…').evaluate().isEmpty,
              pumpDuration: const Duration(milliseconds: 20),
            );
            expect(resumed.state.approval, isNull);
          }
          expect(
            find.text('Session reprise · source vérifiée'),
            findsOneWidget,
          );
          expect(resumed.state.source!.rootPath, movedSource);
          expect(resumed.state.source!.supplementalRootPaths, [
            movedShared,
            movedSecond,
          ]);
          expect(resumed.state.prepared, isNotNull);
          expect(
            tester
                .widget<ConverterAssetReviewPanel>(
                  find.byType(ConverterAssetReviewPanel),
                )
                .enabled,
            isTrue,
          );
          expect(resumed.state.result, isNull);
          expect(
            resumed.state.prepared!.reviewSet!.canonicalHash,
            stored.reviewSet.canonicalHash,
          );
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async {
            await resumed?.dispose();
            await source.close();
          });
        }
      },
      skip: !Platform.isMacOS,
    );
  }
  testWidgets(
    'ordered folders expose priority and a four-folder picker limit',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      final roots = (await tester.runAsync(() async {
        final values = <String>[];
        for (var index = 0; index < 4; index++) {
          values.add(
            (await Directory(
              '${source.root.path}/supplement-$index',
            ).create()).path,
          );
        }
        return values;
      }))!;
      var picks = 0;
      _setWindow(tester, const Size(1600, 1000));
      try {
        await tester.pumpWidget(
          ConverterApp(
            workflow: source.workflow,
            initialSourcePath: source.sourcePath,
            initialParentPath: source.output.path,
            pathPicker: (kind) async {
              expect(kind, ConverterPathKind.supplementalFolder);
              return roots[picks++];
            },
          ),
        );
        for (var index = 0; index < 4; index++) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('add-supplemental-source')),
          );
          await tester.tap(
            find.byKey(const ValueKey('add-supplemental-source')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Priorité ${index + 1}'), findsOneWidget);
        }
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('add-supplemental-source')),
              )
              .onPressed,
          isNull,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('move-supplemental-source-up-1')),
        );
        await tester.tap(
          find.byKey(const ValueKey('move-supplemental-source-up-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('analyse-project')));
        await _waitFor(
          tester,
          () =>
              source.workflow.state.snapshot != null &&
              !source.workflow.state.isBusy,
        );
        expect(source.workflow.state.source!.supplementalRootPaths, [
          roots[1],
          roots[0],
          roots[2],
          roots[3],
        ]);
        expect(picks, 4);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    '616 shared origins keep maps accessible and detail reaches the last file',
    (tester) async {
      final source = (await tester.runAsync(_OriginalSource.create))!;
      final shared = (await tester.runAsync(() async {
        final directory = await Directory(
          '${source.root.path}/many-shared/Graphics/Pictures',
        ).create(recursive: true);
        for (var index = 0; index < 616; index++) {
          await File(
            '${directory.path}/shared_${index.toString().padLeft(4, '0')}.png',
          ).writeAsBytes([index % 256]);
        }
        return directory.parent.parent;
      }))!;
      _setWindow(tester, const Size(1600, 1000));
      try {
        await tester.pumpWidget(
          ConverterApp(
            workflow: source.workflow,
            initialSourcePath: source.sourcePath,
            initialParentPath: source.output.path,
            pathPicker: (_) async => shared.path,
          ),
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('add-supplemental-source')),
        );
        await tester.tap(find.byKey(const ValueKey('add-supplemental-source')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('analyse-project')));
        await _waitFor(
          tester,
          () =>
              source.workflow.state.snapshot != null &&
              !source.workflow.state.isBusy,
        );
        expect(source.workflow.state.sharedSourceFiles, hasLength(616));
        expect(find.byType(SelectableText), findsNWidgets(5));
        expect(
          tester.getTopLeft(find.text('Tout sélectionner')).dy,
          lessThan(1500),
        );
        await tester.ensureVisible(find.text('Tout sélectionner'));
        await tester.tap(find.text('Tout sélectionner'));
        await tester.pump();
        expect(find.text('2 sélectionnée(s)'), findsOneWidget);
        final detail = find.text('Afficher les 616 fichiers');
        await tester.ensureVisible(detail);
        await tester.tap(detail);
        await tester.pumpAndSettle();
        final list = find.byKey(const ValueKey('shared-source-files-detail'));
        expect(tester.getSize(list).height, lessThanOrEqualTo(360));
        expect(
          find.textContaining('Graphics/Pictures/shared_0615.png'),
          findsNothing,
        );
        final scrollable = find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(
          find.textContaining('Graphics/Pictures/shared_0615.png'),
          500,
          scrollable: scrollable,
          maxScrolls: 100,
        );
        expect(
          find.textContaining('Graphics/Pictures/shared_0615.png'),
          findsOneWidget,
        );
        expect(source.workflow.state.sharedSourceFiles, hasLength(616));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(source.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('shared folder picker and clear feed a fresh source selection', (
    tester,
  ) async {
    final source = (await tester.runAsync(_OriginalSource.create))!;
    final shared = (await tester.runAsync(() async {
      final directory = await Directory('${source.root.path}/shared/PBS')
          .create(recursive: true);
      await File('${directory.path}/items.txt')
          .writeAsString('1,POTION,Potion,1,300,Heals HP,1,1,0');
      return directory.parent;
    }))!;
    _setWindow(tester, const Size(1600, 1000));
    final selections = <ConverterPathKind>[];
    try {
      await tester.pumpWidget(
        ConverterApp(
          workflow: source.workflow,
          initialSourcePath: source.sourcePath,
          initialParentPath: source.output.path,
          pathPicker: (kind) async {
            selections.add(kind);
            return shared.path;
          },
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('add-supplemental-source')),
      );
      await tester.tap(find.byKey(const ValueKey('add-supplemental-source')));
      await tester.pumpAndSettle();
      expect(selections, [ConverterPathKind.supplementalFolder]);
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.snapshot != null &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.source!.supplementalRootPaths, [
        shared.path,
      ]);
      expect(
        source.workflow.state.sharedSourceFiles.single.relativePath,
        'PBS/items.txt',
      );
      expect(find.textContaining('Fichiers partagés utilisés'), findsOneWidget);
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
            source.workflow.state.prepared?.canApprove == true &&
            !source.workflow.state.isBusy,
      );
      final prepared = source.workflow.state.prepared!;
      source.workflow.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true,
      );
      expect(source.workflow.state.approval, isNotNull);
      await tester.tap(find.byKey(const ValueKey('step-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('remove-supplemental-source-0')),
      );
      await tester.tap(
        find.byKey(const ValueKey('remove-supplemental-source-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonner les changements'));
      await tester.pumpAndSettle();
      expect(source.workflow.state.prepared, isNull);
      expect(source.workflow.state.approval, isNull);
      await tester.tap(find.byKey(const ValueKey('analyse-project')));
      await _waitFor(
        tester,
        () =>
            source.workflow.state.source?.supplementalRootPaths.isEmpty ==
                true &&
            !source.workflow.state.isBusy,
      );
      expect(source.workflow.state.sharedSourceFiles, isEmpty);
      expect(
        source.workflow.state.snapshot!.entries.any(
          (entry) => entry.relativePath == 'PBS/items.txt',
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);

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

  for (final dynamicTransfer in [false, true]) {
  testWidgets('dependency choices remain visible until explicit preparation dynamic=$dynamicTransfer', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () => _OriginalSource.create(
        maps: [
          LiteralFixtureMap(
            id: 1,
            warpParameters: [
              [dynamicTransfer ? 1 : 0, 8, 0, 0, 0, 0],
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
      if (dynamicTransfer) {
        expect(choices().first.options, isNot(contains('include')));
        expect(choices().first.options['excludeStudy'],
            'Conserver ce transfert inactif');
      }
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
      final decisions = source.workflow.state.settings!.dependencyDecisions;
      expect(decisions.singleWhere((decision) => decision.locator.commandIndex == 0).targetSourceMapId,
          dynamicTransfer ? isNull : 8);
      expect(decisions.singleWhere((decision) => decision.locator.commandIndex == 1).targetSourceMapId, 12);
      expect(source.nativeStages, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.runAsync(source.expectSourceUnchanged);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(source.close);
    }
  }, skip: !Platform.isMacOS);
  }

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
        expect(document['version'], 11);
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
        contentScope: ConverterContentScope.world,
      );
      await _acknowledgeAndPrepare(tester, source);
      final recipe = source.workflow.exportStudyPlanRecipe();
      expect(recipe.settings.contentScope, ConverterContentScope.world);
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
      expect(restored!.state.prepared!.settings.contentScope, ConverterContentScope.world);
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
      await _scanAndPrepare(tester, source, interpretationProfile: fixtureSourceInterpretationProfile);
      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(
        find.text(
          'Événements : 1 adapté(s) automatiquement sans IA ; 1 en quarantaine.',
        ),
        findsOneWidget,
        reason: tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>().join(' | '),
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
      String? inspectedProject;
      String? inspectedRoot;
      final inspection = ConverterPlayableStartInspection(
        revision: 'sha256:native-start-fixture',
        maps: [ConverterPlayableStartMap(id: 'map-start', name: 'Start map',
          spawns: [const ConverterPlayableStartSpawn(id: 'spawn-start', name: 'Start spawn')])],
        avatars: [const ConverterPlayableStartAvatar(id: 'player', name: 'Imported player')],
        species: [
          const ConverterPlayableStartSpecies(id: 'first', name: 'First starter'),
          const ConverterPlayableStartSpecies(id: 'second', name: 'Second starter'),
        ],
      );
      final applyRequests = <Map<String, Object>>[];
      final applyingGate = Completer<void>();
      try {
        await _scanAndPrepare(
          tester,
          source,
          folderOpener: (value) async => openedFolder = value,
          playableStartInspector: ({required projectPath, required allowedRootPath}) async {
            inspectedProject = projectPath;
            inspectedRoot = allowedRootPath;
            return inspection;
          },
          playableStartApplier: ({required projectPath, required allowedRootPath,
            required expectedRevision, required mapId, required spawnId,
            required starterSpeciesIds, required starterLevel}) async {
            applyRequests.add({'projectPath': projectPath, 'allowedRootPath': allowedRootPath,
              'expectedRevision': expectedRevision, 'mapId': mapId, 'spawnId': spawnId,
              'starterSpeciesIds': starterSpeciesIds, 'starterLevel': starterLevel});
            await applyingGate.future;
            throw const ConverterPlayableStartException('playable_start.stale_revision',
              'Le projet a changé. Relisez le départ.');
          },
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
        expect(result.receipt.importUndoHistoryRetained, isFalse);
        expect(source.nativeStages.where((stage) => stage == NativeWriteStage.beforeCreation), hasLength(1));
        expect(source.nativeStages.where((stage) => stage == NativeWriteStage.afterCreation), hasLength(1));
        expect(result.published, isTrue);
        expect(result.playableCertified, isFalse);
        await _waitFor(tester, () => inspectedProject != null);
        await tester.pump();
        expect(inspectedProject, result.projectPath);
        expect(inspectedRoot, source.output.path);
        expect(find.text('Départ Avelune adapté, ne reproduit pas l’introduction source'), findsOneWidget);
        tester.widget<StudioSelect>(find.byKey(const ValueKey('playable-start-map'))).onChanged!('map-start');
        await tester.pump();
        tester.widget<StudioSelect>(find.byKey(const ValueKey('playable-start-spawn'))).onChanged!('spawn-start');
        tester.widget<StudioToggleRow>(find.byKey(const ValueKey('playable-starter-first'))).onChanged!(true);
        tester.widget<StudioToggleRow>(find.byKey(const ValueKey('playable-starter-second'))).onChanged!(true);
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('apply-playable-start')));
        await tester.tap(find.byKey(const ValueKey('apply-playable-start')));
        await tester.pump();
        expect(find.text('Configuration du départ jouable…'), findsOneWidget);
        expect(find.text('Publication du projet vérifié'), findsNothing);
        applyingGate.complete();
        await tester.pumpAndSettle();
        expect(applyRequests, [{'projectPath': result.projectPath, 'allowedRootPath': source.output.path,
          'expectedRevision': inspection.revision, 'mapId': 'map-start', 'spawnId': 'spawn-start',
          'starterSpeciesIds': ['first', 'second'], 'starterLevel': 5}]);
        expect(find.text('Le projet a changé. Relisez le départ.'), findsOneWidget);
        expect(find.textContaining('Les choix de départ sont enregistrés'), findsNothing);
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
        if (!applyingGate.isCompleted) applyingGate.complete();
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
            if (stage == NativeWriteStage.afterCreation && pause) {
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
  ConverterContentScope contentScope = ConverterContentScope.full,
  ConverterPlayableStartInspector? playableStartInspector,
  ConverterPlayableStartApplier? playableStartApplier,
  SourceInterpretationProfile? interpretationProfile,
}) async {
  final profilePath = '${source.root.path}/selected-profile.json';
  if (interpretationProfile != null) {
    await tester.runAsync(() => File(profilePath).writeAsString(jsonEncode(interpretationProfile.toJson())));
  }
  await tester.pumpWidget(
    ConverterApp(
      workflow: source.workflow,
      pathPicker: interpretationProfile == null ? pickConverterPath : (kind) async => kind == ConverterPathKind.interpretationProfileFile ? profilePath : null,
      initialSourcePath: source.sourcePath,
      initialParentPath: source.output.path,
      folderOpener: folderOpener ?? (_) async {},
      planSavePicker: planSavePicker ?? () async => null,
      sessionStore: sessionStore,
      playableStartInspector: playableStartInspector,
      playableStartApplier: playableStartApplier,
    ),
  );
  await tester.tap(find.byKey(const ValueKey('analyse-project')));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        source.workflow.state.snapshot != null && !source.workflow.state.isBusy,
  );
  if (interpretationProfile != null) {
    final choose = find.byKey(const ValueKey('choose-interpretation-profile'));
    await tester.ensureVisible(choose);
    await tester.tap(choose);
    await _waitFor(tester, () => find.text('Profil de scripts sélectionné : ${interpretationProfile.profileId.value}').evaluate().isNotEmpty);
  }
  await tester.ensureVisible(find.text('Tout sélectionner'));
  await tester.tap(find.text('Tout sélectionner'));
  await tester.pump();
  if (contentScope != ConverterContentScope.full) {
    expect(tester.widget<StudioSelect>(find.byKey(const ValueKey('content-scope'))).value, 'full');
    tester.widget<StudioSelect>(find.byKey(const ValueKey('content-scope')))
        .onChanged!(contentScope.name);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('prepare-study')));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        source.workflow.state.prepared != null && !source.workflow.state.isBusy,
  );
  expect(source.workflow.state.prepared!.composition.nativeMaps,
      hasLength(source.fixture.source.maps.length));
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
    ConverterWorkflowCheckpoint? workflowCheckpoint,
    String sourceSuffix = 'source',
    List<LiteralFixtureMap>? maps,
    List<int>? scriptsBytes,
    Map<String, List<int>> extraFiles = const {},
    List<LiteralFixtureTileset>? tilesets,
    bool includeEventSystem = false,
    bool withoutInterpretationProfile = false,
  }) async {
    final root = await Directory('/private/tmp')
        .createTemp('ac09-original-widget-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/$sourceSuffix',
        interpretationProfile: scriptsBytes == null || withoutInterpretationProfile ? null : fixtureSourceInterpretationProfile,
      scriptsBytes: scriptsBytes,
        includeEventSystem: includeEventSystem,
        extraFiles: extraFiles,
        tilesets: tilesets,
        maps: maps ?? [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8)],
      );
      final stages = <NativeWriteStage>[];
      final workflow = ConverterWorkflow(
        checkpoint: workflowCheckpoint,
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
