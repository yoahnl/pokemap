import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_studio/avelune_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../../../packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart';

void main() {
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
    final rect = tester.getRect(find.byKey(const ValueKey('action-bar')));
    expect(rect.bottom, lessThanOrEqualTo(800));
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
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
        expect(result.published, isFalse);
        expect(result.playableCertified, isFalse);
        expect(find.text('Projet d’étude créé et relu'), findsOneWidget);
        await tester.runAsync(() async {
          expect(await Directory(result.receipt.projectPath).exists(), isTrue);
          expect(
            await Directory('${source.output.path}/avelune-study').exists(),
            isFalse,
          );
          await source.expectSourceUnchanged();
        });
        await tester.ensureVisible(
          find.byKey(const ValueKey('show-result-folder')),
        );
        await tester.tap(find.byKey(const ValueKey('show-result-folder')));
        await tester.pump();
        expect(openedFolder, result.receipt.projectPath);
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
          find.textContaining('Aucun projet final publié'),
          findsOneWidget,
        );
        expect(find.text('Projet d’étude créé et relu'), findsNothing);
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
      expect(find.text('Projet d’étude créé et relu'), findsNothing);
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

Future<void> _waitFor(WidgetTester tester, bool Function() done) async {
  for (var attempt = 0; attempt < 1500 && !done(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
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
}) async {
  await tester.pumpWidget(
    ConverterApp(
      workflow: source.workflow,
      initialSourcePath: source.sourcePath,
      initialParentPath: source.output.path,
      folderOpener: folderOpener ?? (_) async {},
    ),
  );
  await tester.tap(find.byKey(const ValueKey('analyse-project')));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        source.workflow.state.prepared != null && !source.workflow.state.isBusy,
  );
  expect(source.workflow.state.prepared!.composition.nativeMaps, hasLength(2));
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
  }) async {
    final root = await Directory.systemTemp.createTemp('ac09-original-widget-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/$sourceSuffix',
        scriptsBytes: scriptsBytes,
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
