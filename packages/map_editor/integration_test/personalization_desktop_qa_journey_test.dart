import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/debug/marionette_personalization_qa_seed.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_player_surface_adapter.dart';
import 'package:map_editor/src/infrastructure/riverpod_retry_policy.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_player_ui/personalization_preview.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads every real Personalization surface without persistence', (
    tester,
  ) async {
    final fixture = await _PersonalizationQaFixture.create('read-only');
    final durableBefore = fixture.projectFile.readAsBytesSync();
    final harness = await _pumpStudio(tester, fixture.projectRoot);
    addTearDown(() async {
      await harness.dispose();
      await tester.binding.setSurfaceSize(null);
      fixture.dispose();
    });

    const sceneCompositions = <String, String>{
      'globalStyle': 'personalization-global-style-composition',
      'title': 'personalization-title-composition',
      'intro': 'personalization-intro-composition',
      'pause': 'personalization-pause-composition',
      'dialogue': 'personalization-dialogue-composition',
      'battle': 'personalization-battle-composition',
    };
    for (final entry in sceneCompositions.entries) {
      await _tapVisible(
        tester,
        find.byKey(
          ValueKey<String>('personalization-studio-scene-${entry.key}'),
        ),
      );
      await _waitForFinder(tester, find.byKey(ValueKey<String>(entry.value)));
      expect(find.byKey(ValueKey<String>(entry.value)), findsOneWidget);
      expect(find.byType(PersonalizationPlayerSurfaceAdapter), findsWidgets);
    }

    await _tapVisible(
      tester,
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
    );
    await _tapVisible(
      tester,
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-200'),
      ),
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-viewport-frame-portrait',
        ),
      ),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(
        const ValueKey<String>('personalization-studio-scene-dialogue'),
      ),
    );
    await _scrollInspectorTo(
      tester,
      find.byKey(const ValueKey<String>('dialogue-preview-portrait')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('dialogue-preview-portrait')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('dialogue-preview-choices')),
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-composition'),
      ),
      findsOneWidget,
    );
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('personalization-studio-scene-battle')),
    );
    for (final section in <String>['commands', 'moves', 'target', 'message']) {
      await _tapVisible(
        tester,
        find.byKey(ValueKey<String>('battle-section-$section')),
      );
      expect(
        find.byKey(
          const ValueKey<String>('personalization-battle-composition'),
        ),
        findsOneWidget,
      );
    }

    expect(fixture.projectFile.readAsBytesSync(), durableBefore);
    expect(
      harness.notifier.personalizationStudioSessionState?.isDirty,
      isFalse,
    );
  });

  testWidgets('mutates saves restarts and exports one desktop QA project', (
    tester,
  ) async {
    final fixture = await _PersonalizationQaFixture.create('write-export');
    _StudioHarness? activeHarness;
    addTearDown(() async {
      await activeHarness?.dispose();
      await tester.binding.setSurfaceSize(null);
      fixture.dispose();
    });
    activeHarness = await _pumpStudio(tester, fixture.projectRoot);
    final firstHarness = activeHarness;

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('personalization-studio-scene-pause')),
    );
    final pokedexLabel = find.byKey(
      const ValueKey<String>('pause-action-label-pokedex'),
    );
    await _scrollInspectorTo(tester, pokedexLabel);
    await tester.enterText(pokedexLabel, 'Bestiaire QA');
    await tester.pump(const Duration(milliseconds: 50));

    await _tapVisible(
      tester,
      find.byKey(
        const ValueKey<String>('personalization-studio-scene-dialogue'),
      ),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('dialogue-layout-top')),
    );
    await _scrollInspectorTo(
      tester,
      find.byKey(const ValueKey<String>('dialogue-portrait-side-end')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('dialogue-portrait-side-end')),
    );
    final shape = find.byKey(const ValueKey<String>('dialogue-geometry-shape'));
    await _scrollInspectorTo(tester, shape);
    tester
        .widget<PokeMapDropdownField<ProjectWindowShape>>(shape)
        .onChanged(ProjectWindowShape.cutCorner);
    await tester.pump(const Duration(milliseconds: 50));

    await _scrollInspectorTo(
      tester,
      find.byKey(const ValueKey<String>('dialogue-color-surface')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('dialogue-color-surface')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('personalization-theme-token-input')),
      '#F0F0F0',
    );
    await tester.tap(find.text('Appliquer').hitTestable());
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('personalization-studio-save')),
    );
    await _waitFor(
      tester,
      () =>
          firstHarness.notifier.personalizationStudioSessionState?.isDirty ==
          false,
    );
    await firstHarness.dispose();
    activeHarness = null;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    activeHarness = await _pumpStudio(tester, fixture.projectRoot);
    final restartedHarness = activeHarness;
    final reloaded = restartedHarness.notifier.state.project!.presentation!;
    expect(
      reloaded.pause?.actions
          ?.singleWhere((action) => action.id == ProjectPauseActionId.pokedex)
          .label,
      'Bestiaire QA',
    );
    expect(reloaded.dialogue?.placement, ProjectDialoguePlacement.top);
    expect(reloaded.dialogue?.portraitSide, ProjectDialoguePortraitSide.end);
    expect(reloaded.dialogue?.shape, ProjectWindowShape.cutCorner);
    expect(reloaded.dialogue?.surfaceColor, '#F0F0F0');

    final output = File(
      p.join(
        fixture.projectRoot.path,
        'build',
        'personalization-qa.avelunegame',
      ),
    );
    final exportController = GamePackageExportController(
      projectRoot: fixture.projectRoot,
      projectName: 'QA Personalization Studio',
      profileStore: GamePackageExportProfileStore(
        projectRoot: fixture.projectRoot,
      ),
      localGameIdGenerator: () => 'games.local.personalizationqa',
    );
    addTearDown(exportController.dispose);
    await tester.runAsync(exportController.initialize);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: GamePackageExportDialog(
            controller: exportController,
            chooseOutputFile: (_) async => output,
            chooseProjectFile: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pump();
    final exportButton = tester.widget<PokeMapButton>(
      find.widgetWithText(PokeMapButton, 'Exporter pour tester'),
    );
    await tester.runAsync(() async {
      exportButton.onPressed!.call();
      for (var attempt = 0; attempt < 300; attempt += 1) {
        if (exportController.snapshot.status ==
                GamePackageExportStatus.succeeded ||
            exportController.snapshot.status == GamePackageExportStatus.error) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    final exportSnapshot = exportController.snapshot;
    expect(
      exportSnapshot.status,
      GamePackageExportStatus.succeeded,
      reason:
          '${exportSnapshot.errorCode}: ${exportSnapshot.safeErrorMessage}\n'
          '${exportSnapshot.technicalErrorDetails}',
    );
    expect(output.existsSync(), isTrue);
    expect(output.lengthSync(), greaterThan(0));
    expect(
      exportController
          .snapshot
          .artifact
          ?.manifest
          .presentation
          ?.dialogue
          ?.placement,
      ProjectDialoguePlacement.top.name,
    );
  });
}

final class _PersonalizationQaFixture {
  const _PersonalizationQaFixture({
    required this.sandbox,
    required this.projectRoot,
  });

  final Directory sandbox;
  final Directory projectRoot;

  File get projectFile => File(p.join(projectRoot.path, 'project.json'));

  static Future<_PersonalizationQaFixture> create(String suffix) async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap-personalization-$suffix-',
    );
    final projectRoot = await MarionettePersonalizationQaSeed.create(
      sandboxRoot: sandbox,
      runId: suffix,
      loadAsset: (path) async {
        final data = await rootBundle.load(path);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      },
    );
    return _PersonalizationQaFixture(
      sandbox: sandbox,
      projectRoot: projectRoot,
    );
  }

  void dispose() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  }
}

final class _StudioHarness {
  const _StudioHarness({required this.container, required this.notifier});

  final ProviderContainer container;
  final EditorNotifier notifier;

  Future<void> dispose() async {
    await container.read(editorAuthoringSessionLifecycleProvider).closeAll();
    container.dispose();
  }
}

Future<_StudioHarness> _pumpStudio(
  WidgetTester tester,
  Directory projectRoot,
) async {
  await tester.binding.setSurfaceSize(const Size(1920, 1080));
  final manifest = ProjectManifest.fromJson(
    jsonDecode(
          File(p.join(projectRoot.path, 'project.json')).readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final container = ProviderContainer(retry: disableAutomaticProviderRetry);
  final notifier = container.read(editorNotifierProvider.notifier);
  notifier.state = EditorState(
    projectRootPath: projectRoot.path,
    project: manifest,
    workspaceMode: EditorWorkspaceMode.personalizationStudio,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MapEditorApp(),
    ),
  );
  await notifier.initializePersonalizationStudioSession();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  expect(
    find.byKey(const ValueKey<String>('personalization-studio-workspace')),
    findsOneWidget,
  );
  return _StudioHarness(container: container, notifier: notifier);
}

Future<void> _scrollInspectorTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byKey(
    const ValueKey<String>('personalization-studio-inspector-scroll'),
  );
  final scrollableState = find
      .descendant(of: scrollable, matching: find.byType(Scrollable))
      .first;
  await _waitForFinder(tester, scrollableState);
  final position = tester.state<ScrollableState>(scrollableState).position;
  position.jumpTo(position.minScrollExtent);
  await tester.pumpAndSettle();
  for (var attempt = 0; attempt < 40; attempt += 1) {
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      if (finder.hitTestable().evaluate().isNotEmpty) return;
    }
    final next = (position.pixels + 380)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (next == position.pixels) break;
    position.jumpTo(next);
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsOneWidget);
}

Future<void> _waitForFinder(WidgetTester tester, Finder finder) async {
  for (
    var attempt = 0;
    attempt < 300 && finder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder.hitTestable());
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 300 && !condition(); attempt += 1) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}
