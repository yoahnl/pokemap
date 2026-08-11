import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'enables Studio actions automatically after deferred initialization',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-studio-deferred-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final project = buildShellChromeProject(
        name: 'Deferred Studio',
      ).copyWith(presentation: const ProjectPresentationProfile());
      File(
        '${root.path}/project.json',
      ).writeAsStringSync(jsonEncode(project.toJson()), flush: true);
      final gateway = _DelayedProjectGateway(project);

      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: const Size(1600, 800),
        overrides: [
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectManifest>(
                    documentId: 'personalization-studio-deferred',
                    initialDocument: initialDocument,
                    gateway: gateway,
                    recoveryStore: _MemoryProjectRecoveryStore(),
                  ),
                );
              }),
        ],
      );
      final preset = find.byKey(
        const ValueKey<String>('personalization-preset-cinematic'),
      );

      expect(tester.widget<PokeMapButton>(preset).onPressed, isNull);

      gateway.releaseInitialization();
      await tester.pumpAndSettle();

      expect(tester.widget<PokeMapButton>(preset).onPressed, isNotNull);
      expect(preset.hitTestable(), findsOneWidget);
      await tester.tap(preset.hitTestable());
      await tester.pump();

      expect(
        container
            .read(editorNotifierProvider)
            .project
            ?.effectivePresentation
            .branding
            .layoutVariant,
        'cinematic',
      );
    },
  );

  testWidgets(
    'preview context selection preserves the map, dirty flags and project json',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-preview-context-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final project = buildShellChromeProject(
        name: 'Preview Context Studio',
      ).copyWith(presentation: const ProjectPresentationProfile());
      final projectFile = File('${root.path}/project.json');
      final durableJson = jsonEncode(project.toJson());
      projectFile.writeAsStringSync(durableJson, flush: true);
      const activeMap = MapData(
        id: 'active-map',
        name: 'Carte active',
        size: GridSize(width: 4, height: 4),
      );
      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
          activeMap: activeMap,
          activeMapPath: '${root.path}/maps/active-map.json',
        ),
        surfaceSize: const Size(1600, 900),
        overrides: [
          personalizationPreviewContextSourceProvider.overrideWithValue(
            _PreviewContextSource(_previewContexts),
          ),
        ],
      );
      await tester.pumpAndSettle();
      final before = container.read(editorNotifierProvider);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-studio-scene-dialogue'),
        ),
      );
      await tester.pumpAndSettle();
      final picker = find.byKey(
        const ValueKey<String>('personalization-preview-context-dialogue'),
      );
      expect(picker.hitTestable(), findsOneWidget);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deuxième dialogue').last);
      await tester.pumpAndSettle();

      final after = container.read(editorNotifierProvider);
      expect(after.activeMap, before.activeMap);
      expect(after.activeMapPath, before.activeMapPath);
      expect(after.isDirty, before.isDirty);
      expect(after.isProjectDirty, before.isProjectDirty);
      expect(after.project, before.project);
      expect(projectFile.readAsStringSync(), durableJson);
      expect(
        container
            .read(editorNotifierProvider.notifier)
            .personalizationStudioSessionState
            ?.isDirty,
        isFalse,
      );
      expect(find.text('Texte du deuxième dialogue.'), findsOneWidget);
    },
  );

  testWidgets(
    'runs preflight in Studio and invalidates it after a draft edit',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-preflight-ui-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final project = buildShellChromeProject(
        name: 'Preflight Studio',
      ).copyWith(presentation: const ProjectPresentationProfile());
      File('${root.path}/project.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(project.toJson()),
        flush: true,
      );
      final preflight = _FixedPresentationPreflight();
      final gateway = _MemoryProjectGateway(project);
      var exportCalls = 0;

      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: const Size(1600, 900),
        overrides: [
          projectPresentationPreflightProvider.overrideWithValue(preflight),
          personalizationStudioExportLauncherProvider.overrideWithValue((
            context, {
            required projectRootPath,
            required projectName,
          }) async {
            exportCalls += 1;
            expect(projectRootPath, root.path);
            expect(projectName, 'Preflight Studio');
          }),
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectManifest>(
                    documentId: 'personalization-preflight-ui',
                    initialDocument: initialDocument,
                    gateway: gateway,
                    recoveryStore: _MemoryProjectRecoveryStore(),
                  ),
                );
              }),
        ],
      );
      await container
          .read(editorNotifierProvider.notifier)
          .initializePersonalizationStudioSession();
      await tester.pump();
      final detailScrollable = _detailScrollable('branding');
      final runPreflight = find.byKey(
        const ValueKey<String>('personalization-readiness-run-preflight'),
      );
      expect(detailScrollable, findsOneWidget);

      await _dragUntilHitTestable(
        tester,
        runPreflight,
        detailScrollable,
        dy: -500,
      );
      await tester.tap(runPreflight.hitTestable());
      await tester.pump();
      await tester.pump();

      expect(preflight.calls, 1);
      expect(find.text('Prêt à exporter'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('personalization-readiness-export')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('personalization-readiness-export')),
      );
      await tester.pump();
      expect(exportCalls, 1);

      final cinematicPreset = find.byKey(
        const ValueKey<String>('personalization-preset-cinematic'),
      );
      await _dragUntilHitTestable(
        tester,
        cinematicPreset,
        detailScrollable,
        dy: 500,
      );
      await tester.tap(cinematicPreset.hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await _dragUntilHitTestable(
        tester,
        runPreflight,
        detailScrollable,
        dy: -500,
      );

      expect(find.text('Preflight à relancer'), findsOneWidget);
    },
  );

  testWidgets(
    'applies a preset to a dirty draft without writing project.json',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-studio-draft-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final project = buildShellChromeProject(
        name: 'Editable presentation',
      ).copyWith(presentation: const ProjectPresentationProfile());
      final projectFile = File('${root.path}/project.json');
      final durableJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(project.toJson());
      projectFile.writeAsStringSync(durableJson, flush: true);
      final gateway = _MemoryProjectGateway(project);
      final recoveryStore = _MemoryProjectRecoveryStore();

      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: const Size(1600, 800),
        overrides: [
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectManifest>(
                    documentId: 'personalization-studio',
                    initialDocument: initialDocument,
                    gateway: gateway,
                    recoveryStore: recoveryStore,
                  ),
                );
              }),
        ],
      );
      await container
          .read(editorNotifierProvider.notifier)
          .initializePersonalizationStudioSession();
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('personalization-preset-cinematic')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        container
            .read(editorNotifierProvider)
            .project
            ?.effectivePresentation
            .branding
            .layoutVariant,
        'cinematic',
      );
      expect(container.read(editorNotifierProvider).isProjectDirty, isTrue);
      expect(
        find.byKey(const ValueKey<String>('personalization-studio-dirty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('personalization-comparison-paths')),
        findsOneWidget,
      );
      expect(projectFile.readAsStringSync(), durableJson);
      expect(gateway.saveCount, 0);

      final undoButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('personalization-studio-undo')),
      );
      final redoButtonBeforeUndo = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('personalization-studio-redo')),
      );
      expect(undoButton.onPressed, isNotNull);
      expect(redoButtonBeforeUndo.onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('personalization-studio-undo')),
      );
      await tester.pump();
      expect(
        container
            .read(editorNotifierProvider)
            .project
            ?.effectivePresentation
            .branding
            .layoutVariant,
        'standard',
      );
      final redoButtonAfterUndo = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('personalization-studio-redo')),
      );
      expect(redoButtonAfterUndo.onPressed, isNotNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('personalization-studio-redo')),
      );
      await tester.pump();
      expect(
        container
            .read(editorNotifierProvider)
            .project
            ?.effectivePresentation
            .branding
            .layoutVariant,
        'cinematic',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('personalization-studio-autosave')),
      );
      await tester.pump();
      expect(
        container
            .read(editorNotifierProvider.notifier)
            .personalizationStudioSessionState
            ?.autosaveEnabled,
        isTrue,
      );

      final saveButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('personalization-studio-save')),
      );
      expect(saveButton.onPressed, isNotNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('personalization-studio-save')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(gateway.saveCount, 1);
      expect(
        find.byKey(const ValueKey<String>('personalization-studio-dirty')),
        findsNothing,
      );
    },
  );

  testWidgets('blocks save while a global color breaks contrast', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-studio-contrast-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Contrast Studio').copyWith(
      presentation: const ProjectPresentationProfile(
        theme: safeProjectSemanticTheme,
      ),
    );
    File(
      '${root.path}/project.json',
    ).writeAsStringSync(jsonEncode(project.toJson()), flush: true);
    final gateway = _MemoryProjectGateway(project);
    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 900),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio-contrast',
                initialDocument: initialDocument,
                gateway: gateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
              ),
            );
          },
        ),
      ],
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    await notifier.initializePersonalizationStudioSession();
    await notifier.applyPersonalizationStudioProfile(
      ProjectPresentationProfile(
        theme: safeProjectSemanticTheme.copyWith(
          primary: '#EEEEEE',
          onPrimary: '#FFFFFF',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('personalization-studio-validation-blocked'),
      ),
      findsOneWidget,
    );
    final saveButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey<String>('personalization-studio-save')),
    );
    expect(saveButton.onPressed, isNull);
    expect(await notifier.savePersonalizationStudio(), isFalse);
    expect(gateway.saveCount, 0);
  });

  testWidgets('canvas displays the current project profile in read-only mode', (
    tester,
  ) async {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
    );
    final project = buildShellChromeProject(
      name: 'Personalized project',
    ).copyWith(presentation: profile);

    await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/personalization-studio-project',
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 800),
    );

    expect(
      find.byKey(const Key('personalization-studio-workspace')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-studio-shell')),
      findsOneWidget,
    );
    expect(find.byType(PersonalizationLivePreview), findsOneWidget);

    final editorGuard = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byType(ProjectBrandingEditor),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(editorGuard.ignoring, isTrue);
  });

  testWidgets('branding accent and layout update only the studio draft', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-studio-branding-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Branding Studio').copyWith(
      presentation: const ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          iconPath: 'assets/presentation/branding/icon.png',
        ),
      ),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 1000),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio-branding',
                initialDocument: initialDocument,
                gateway: gateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
              ),
            );
          },
        ),
      ],
    );
    await container
        .read(editorNotifierProvider.notifier)
        .initializePersonalizationStudioSession();
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('branding-edit-accent')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('branding-edit-accent')),
    );
    await tester.pumpAndSettle();
    final input = find.byKey(
      const ValueKey<String>('personalization-theme-token-input'),
    );
    await tester.enterText(input, '#GG');
    await tester.tap(find.text('Appliquer'));
    await tester.pump();
    expect(find.textContaining('six chiffres hexadécimaux'), findsOneWidget);
    await tester.enterText(input, '#224466');
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('branding-layout')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('branding-layout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinématique').last);
    await tester.pumpAndSettle();

    final branding = container
        .read(editorNotifierProvider)
        .project
        ?.effectivePresentation
        .branding;
    expect(branding?.accentColor, '#224466');
    expect(branding?.layoutVariant, 'cinematic');
    expect(branding?.iconPath, 'assets/presentation/branding/icon.png');
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets('title music import, preview, and removal stay in the draft', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-title-music-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(
      name: 'Title Music Studio',
    ).copyWith(presentation: const ProjectPresentationProfile());
    final projectFile = File('${root.path}/project.json');
    final durableJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);
    final picker = _FixedTitleMusicPicker('/source/title.ogg');
    final importer = _FixedTitleMusicImporter();
    final preview = _FixedTitleMusicPreviewController();

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 1000),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio-title-music',
                initialDocument: initialDocument,
                gateway: gateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
              ),
            );
          },
        ),
        personalizationStudioTitleMusicPickerProvider.overrideWithValue(picker),
        projectTitleMusicImportServiceProvider.overrideWithValue(importer),
        projectTitleMusicPreviewControllerFactoryProvider.overrideWithValue(
          () => preview,
        ),
      ],
    );
    await container
        .read(editorNotifierProvider.notifier)
        .initializePersonalizationStudioSession();
    await tester.pump();

    final importButton = find.byKey(
      const ValueKey<String>('branding-import-title-music'),
    );
    await tester.ensureVisible(importButton);
    await tester.pumpAndSettle();
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(importer.calls, 1);
    expect(
      container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .branding
          .titleMusicPath,
      'assets/presentation/branding/title-music-test.ogg',
    );
    expect(projectFile.readAsStringSync(), durableJson);

    final previewButton = find.byKey(
      const ValueKey<String>('branding-preview-title-music'),
    );
    await tester.ensureVisible(previewButton);
    await tester.pumpAndSettle();
    await tester.tap(previewButton);
    await tester.pumpAndSettle();
    expect(preview.toggleCalls, 1);
    expect(
      preview.lastFile?.path,
      '${root.path}/assets/presentation/branding/title-music-test.ogg',
    );
    expect(find.text('Arrêter'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-scene-intro')),
    );
    await tester.pumpAndSettle();
    expect(preview.stopCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-scene-title')),
    );
    await tester.pumpAndSettle();

    final removeButton = find.byKey(
      const ValueKey<String>('branding-remove-title-music'),
    );
    await tester.ensureVisible(removeButton);
    await tester.pumpAndSettle();
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    expect(preview.stopCalls, 2);
    expect(
      container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .branding
          .titleMusicPath,
      isNull,
    );
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets(
    'intro category edits the studio draft without writing project.json',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-studio-intro-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final intro = ProjectIntroVideoProfile.fromLandscape(
        videoPath: 'assets/presentation/intro/intro.mp4',
        posterPath: 'assets/presentation/intro/poster.png',
        captionsPath: 'assets/presentation/intro/captions.vtt',
        durationMilliseconds: 12000,
        width: 1280,
        height: 720,
        bitrateKbps: 2400,
        sizeBytes: 5000000,
        videoCodec: 'h264',
        audioCodec: 'aac',
      );
      final project = buildShellChromeProject(
        name: 'Intro Studio',
      ).copyWith(presentation: ProjectPresentationProfile(intro: intro));
      final projectFile = File('${root.path}/project.json');
      final durableJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(project.toJson());
      projectFile.writeAsStringSync(durableJson, flush: true);
      final gateway = _MemoryProjectGateway(project);

      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: const Size(1600, 800),
        overrides: [
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectManifest>(
                    documentId: 'personalization-studio-intro',
                    initialDocument: initialDocument,
                    gateway: gateway,
                    recoveryStore: _MemoryProjectRecoveryStore(),
                  ),
                );
              }),
        ],
      );
      await container
          .read(editorNotifierProvider.notifier)
          .initializePersonalizationStudioSession();
      await tester.pump();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-studio-scene-intro'),
        ),
      );
      await tester.pump();

      expect(find.byType(ProjectIntroVideoEditor), findsOneWidget);
      final allowReplay = find.text('Autoriser “Rejouer”');
      await _dragUntilHitTestable(
        tester,
        allowReplay,
        _detailScrollable('intro'),
        dy: -500,
      );
      await tester.tap(allowReplay.hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        container
            .read(editorNotifierProvider)
            .project
            ?.effectivePresentation
            .intro
            ?.allowReplay,
        isFalse,
      );
      expect(projectFile.readAsStringSync(), durableJson);
    },
  );

  testWidgets(
    'global typography exposes one common font and resets every role',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-studio-typography-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      const display = ProjectTypographyRoleProfile(
        fontPath: 'assets/presentation/fonts/display.ttf',
        family: 'Display Custom',
        licensePath: 'assets/presentation/fonts/display-license.txt',
        redistributable: true,
        fallbackFamilies: <String>['sans-serif'],
        glyphCoverage: <String>[
          'digits',
          'latin',
          'latinExtended',
          'punctuation',
        ],
      );
      const body = ProjectTypographyRoleProfile(
        fallbackFamilies: <String>['serif'],
      );
      const typography = ProjectTypographyProfile(display: display, body: body);
      final project = buildShellChromeProject(name: 'Typography Studio')
          .copyWith(
            presentation: const ProjectPresentationProfile(
              typography: typography,
            ),
          );
      final projectFile = File('${root.path}/project.json');
      final durableJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(project.toJson());
      projectFile.writeAsStringSync(durableJson, flush: true);
      final gateway = _MemoryProjectGateway(project);

      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: const Size(1600, 800),
        overrides: [
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectManifest>(
                    documentId: 'personalization-studio-typography',
                    initialDocument: initialDocument,
                    gateway: gateway,
                    recoveryStore: _MemoryProjectRecoveryStore(),
                  ),
                );
              }),
        ],
      );
      await container
          .read(editorNotifierProvider.notifier)
          .initializePersonalizationStudioSession();
      await tester.pump();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-studio-scene-globalStyle'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('global-style-tab-typography')),
      );
      await tester.pump();

      expect(find.byType(ProjectTypographyEditor), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('typography-import-common')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('typography-import-display')),
        findsNothing,
      );

      final useSystemDisplay = find.byKey(
        const ValueKey<String>('typography-system-common'),
      );
      await _dragUntilHitTestable(
        tester,
        useSystemDisplay,
        _detailScrollable('typography'),
        dy: -500,
      );
      await tester.tap(useSystemDisplay.hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final draft = container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .typography;
      expect(draft?.display.fontPath, isNull);
      expect(draft?.display.fallbackFamilies, <String>['sans-serif']);
      expect(draft?.body.fontPath, isNull);
      expect(draft?.body.fallbackFamilies, <String>['serif']);
      expect(draft?.dialogue.fontPath, isNull);
      expect(draft?.numbers.fontPath, isNull);
      expect(projectFile.readAsStringSync(), durableJson);
    },
  );

  testWidgets('global style edits the buttons color through a guided dialog', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-studio-theme-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Theme Studio').copyWith(
      presentation: const ProjectPresentationProfile(
        theme: safeProjectSemanticTheme,
      ),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 1400),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio-theme',
                initialDocument: initialDocument,
                gateway: gateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
              ),
            );
          },
        ),
      ],
    );
    await container
        .read(editorNotifierProvider.notifier)
        .initializePersonalizationStudioSession();
    await tester.pump();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-scene-globalStyle'),
      ),
    );
    await tester.pump();

    expect(find.byType(ProjectSemanticThemeEditor), findsOneWidget);
    final editPrimary = find.byKey(
      const ValueKey<String>('global-style-color-buttons'),
    );
    final detailScrollable = _detailScrollable('theme');
    await _dragUntilHitTestable(
      tester,
      editPrimary,
      detailScrollable,
      dy: -500,
    );
    await tester.tap(editPrimary.hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('personalization-theme-token-dialog')),
      findsOneWidget,
    );
    final tokenInput = find.byKey(
      const ValueKey<String>('personalization-theme-token-input'),
    );
    await tester.enterText(tokenInput, '#GG');
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(find.textContaining('six chiffres hexadécimaux'), findsOneWidget);
    expect(
      container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .theme
          ?.primary,
      safeProjectSemanticTheme.primary,
    );

    await tester.enterText(tokenInput, '#123456');
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .theme
          ?.primary,
      '#123456',
    );

    final resetColors = find.byKey(
      const ValueKey<String>('global-style-reset-colors'),
    );
    await _dragUntilHitTestable(tester, resetColors, detailScrollable, dy: 500);
    await tester.tap(resetColors.hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      container.read(editorNotifierProvider).project?.presentation?.theme,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-undo')),
    );
    await tester.pump();
    expect(
      container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .theme
          ?.primary,
      '#123456',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-redo')),
    );
    await tester.pump();
    expect(
      container.read(editorNotifierProvider).project?.presentation?.theme,
      isNull,
    );
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets(
    'guided intro import reports success and updates only the draft',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-studio-import-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final project = buildShellChromeProject(
        name: 'Import Studio',
      ).copyWith(presentation: const ProjectPresentationProfile());
      final projectFile = File('${root.path}/project.json');
      final durableJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(project.toJson());
      projectFile.writeAsStringSync(durableJson, flush: true);
      final gateway = _MemoryProjectGateway(project);
      final assetPicker = _FixedAssetPicker(
        intro: const PersonalizationStudioIntroAssetSelection(
          videoPath: '/source/opening.mp4',
          posterPath: '/source/poster.png',
          captionsPath: '/source/captions.vtt',
        ),
      );
      final introImporter = _FixedIntroImporter();

      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: root.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: const Size(1600, 800),
        overrides: [
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectManifest>(
                    documentId: 'personalization-studio-import',
                    initialDocument: initialDocument,
                    gateway: gateway,
                    recoveryStore: _MemoryProjectRecoveryStore(),
                  ),
                );
              }),
          personalizationStudioAssetPickerProvider.overrideWithValue(
            assetPicker,
          ),
          projectIntroVideoImportServiceProvider.overrideWithValue(
            introImporter,
          ),
        ],
      );
      await container
          .read(editorNotifierProvider.notifier)
          .initializePersonalizationStudioSession();
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey<String>('personalization-studio-scene-intro'),
        ),
      );
      await tester.pump();

      final importButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('personalization-intro-import')),
      );
      expect(importButton.onPressed, isNotNull);
      importButton.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(assetPicker.introCalls, 1);
      expect(introImporter.calls, 1);

      final intro = container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .intro;
      expect(intro, isNotNull);
      expect(intro?.captionsPath, endsWith('.vtt'));
      expect(
        find.text('Vidéo, poster et sous-titres importés dans le brouillon.'),
        findsOneWidget,
      );
      expect(projectFile.readAsStringSync(), durableJson);
    },
  );

  testWidgets('guided font import confirms rights and updates every role', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-studio-font-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(
      name: 'Font Studio',
    ).copyWith(presentation: const ProjectPresentationProfile());
    final projectFile = File('${root.path}/project.json');
    final durableJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);
    final assetPicker = _FixedAssetPicker(
      font: const PersonalizationStudioFontAssetSelection(
        fontPath: '/source/body.otf',
        licensePath: '/source/OFL.txt',
      ),
    );
    final fontImporter = _FixedFontImporter();
    final previewRegistry = _FixedFontPreviewRegistry();

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 1000),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio-font-import',
                initialDocument: initialDocument,
                gateway: gateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
              ),
            );
          },
        ),
        personalizationStudioAssetPickerProvider.overrideWithValue(assetPicker),
        projectFontImportServiceProvider.overrideWithValue(fontImporter),
        projectFontPreviewLoaderProvider.overrideWithValue(previewRegistry),
      ],
    );
    await container
        .read(editorNotifierProvider.notifier)
        .initializePersonalizationStudioSession();
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-scene-globalStyle'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-tab-typography')),
    );
    await tester.pump();

    final importBody = find.byKey(
      const ValueKey<String>('typography-import-common'),
    );
    await _dragUntilHitTestable(
      tester,
      importBody,
      _detailScrollable('typography'),
      dy: -500,
    );
    await tester.tap(importBody.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Droit de redistribution'), findsOneWidget);
    await tester.tap(find.text('Je confirme'));
    await tester.pumpAndSettle();

    expect(assetPicker.fontCalls, 1);
    expect(fontImporter.calls, 1);
    expect(fontImporter.lastRole, ProjectTypographyRole.body);
    expect(previewRegistry.calls, 1);
    final typography = container
        .read(editorNotifierProvider)
        .project
        ?.effectivePresentation
        .typography;
    expect(
      typography?.body.fontPath,
      'assets/presentation/fonts/body-test.otf',
    );
    expect(typography?.display, typography?.body);
    expect(typography?.dialogue, typography?.body);
    expect(typography?.numbers, typography?.body);
    expect(
      find.text('Fonte et licence importées dans le brouillon.'),
      findsOneWidget,
    );
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets('guided import exposes selection errors without changing draft', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-studio-error-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(
      name: 'Import Error Studio',
    ).copyWith(presentation: const ProjectPresentationProfile());
    final gateway = _MemoryProjectGateway(project);
    final assetPicker = _FixedAssetPicker(
      introError: const PersonalizationStudioAssetSelectionException(
        code: 'introSelectionIncomplete',
        message:
            'Sélectionnez exactement une vidéo MP4 et un poster PNG, JPEG ou WebP.',
      ),
    );

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 800),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio-import-error',
                initialDocument: initialDocument,
                gateway: gateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
              ),
            );
          },
        ),
        personalizationStudioAssetPickerProvider.overrideWithValue(assetPicker),
      ],
    );
    await container
        .read(editorNotifierProvider.notifier)
        .initializePersonalizationStudioSession();
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-scene-intro')),
    );
    await tester.pump();

    final importButton = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey<String>('personalization-intro-import')),
    );
    importButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(assetPicker.introCalls, 1);
    expect(
      find.text(
        'Sélectionnez exactement une vidéo MP4 et un poster PNG, JPEG ou WebP.',
      ),
      findsOneWidget,
    );
    expect(
      container
          .read(editorNotifierProvider)
          .project
          ?.effectivePresentation
          .intro,
      isNull,
    );
  });

  testWidgets('routes player surface clicks to the contextual inspector', (
    tester,
  ) async {
    final project = buildShellChromeProject(name: 'Contextual Studio').copyWith(
      presentation: const ProjectPresentationProfile(
        theme: safeProjectSemanticTheme,
      ),
    );
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/personalization-contextual-studio',
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1600, 1000),
      overrides: [
        personalizationPreviewContextSourceProvider.overrideWithValue(
          _PreviewContextSource(_previewContexts),
        ),
      ],
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-scene-pause')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-inspector-target-pauseAppearance',
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-target-editor-pauseAppearance'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('pause.party')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-target-editor-pauseLabels'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-scene-dialogue'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-inspector-target-dialogueTypography',
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('dialogue-tap-zone')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-target-editor-dialogueAppearance',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-studio-scene-battle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-inspector-target-battleAppearance',
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('ATTAQUER').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-target-editor-battleCommands'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a dedicated state when no project is open', (
    tester,
  ) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
    );

    expect(
      find.byKey(const Key('personalization-studio-no-project')),
      findsOneWidget,
    );
    expect(find.text('Aucun projet ouvert'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('personalization-studio-shell')),
      findsNothing,
    );
  });

  testWidgets('shows a loading state while a project path is being restored', (
    tester,
  ) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/project-being-restored',
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
    );

    expect(
      find.byKey(const Key('personalization-studio-loading')),
      findsOneWidget,
    );
    expect(find.text('Chargement du projet…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('personalization-studio-shell')),
      findsNothing,
    );
  });

  testWidgets('shows the project loading error instead of an empty hub', (
    tester,
  ) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
        errorMessage: 'Manifest illisible',
      ),
    );

    expect(
      find.byKey(const Key('personalization-studio-error')),
      findsOneWidget,
    );
    expect(find.text('Manifest illisible'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('personalization-studio-shell')),
      findsNothing,
    );
  });
}

Finder _detailScrollable(String _) => find
    .descendant(
      of: find.byKey(
        const ValueKey<String>('personalization-studio-inspector-scroll'),
      ),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _dragUntilHitTestable(
  WidgetTester tester,
  Finder target,
  Finder scrollable, {
  required double dy,
}) async {
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (target.hitTestable().evaluate().isNotEmpty) return;
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      if (target.hitTestable().evaluate().isNotEmpty) return;
    }
    final position = tester.state<ScrollableState>(scrollable).position;
    final direction = dy.isNegative ? 1 : -1;
    final next = (position.pixels + direction * dy.abs())
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (next == position.pixels) break;
    position.jumpTo(next);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

final class _PreviewContextSource
    implements PersonalizationPreviewContextSource {
  const _PreviewContextSource(this.contexts);

  final List<PersonalizationPreviewContextOption> contexts;

  @override
  Future<List<PersonalizationPreviewContextOption>> load(
    String projectRoot,
  ) async => contexts;
}

final _previewContexts = <PersonalizationPreviewContextOption>[
  PersonalizationPreviewContextOption(
    id: 'map:preview-map',
    kind: PersonalizationPreviewContextKind.map,
    sourceId: 'preview-map',
    label: 'Carte de l’aperçu',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'map': <String, Object?>{
        'id': 'preview-map',
        'name': 'Carte de l’aperçu',
        'size': <String, Object?>{'width': 8, 'height': 6},
        'version': 'v6',
      },
    },
  ),
  _dialogueContext(
    id: 'dialogue:first',
    label: 'Premier dialogue',
    text: 'Texte du premier dialogue.',
  ),
  _dialogueContext(
    id: 'dialogue:second',
    label: 'Deuxième dialogue',
    text: 'Texte du deuxième dialogue.',
  ),
  PersonalizationPreviewContextOption(
    id: 'characterPortrait:leo:happy',
    kind: PersonalizationPreviewContextKind.characterPortrait,
    sourceId: 'leo',
    label: 'Léo · Heureux',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'characterName': 'Léo',
      'portraitStateId': 'happy',
    },
  ),
  PersonalizationPreviewContextOption(
    id: 'encounter:preview',
    kind: PersonalizationPreviewContextKind.encounter,
    sourceId: 'preview',
    label: 'Rencontre de l’aperçu',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'entries': <Object?>[
        <String, Object?>{
          'speciesId': 'roucool',
          'minLevel': 7,
          'maxLevel': 7,
          'weight': 1,
        },
      ],
      'playerPokemon': <String, Object?>{
        'speciesId': 'brindibou',
        'level': 8,
        'currentHp': 24,
        'knownMoveIds': <String>['charge'],
      },
    },
  ),
];

PersonalizationPreviewContextOption _dialogueContext({
  required String id,
  required String label,
  required String text,
}) => PersonalizationPreviewContextOption(
  id: id,
  kind: PersonalizationPreviewContextKind.dialogue,
  sourceId: id.split(':').last,
  label: label,
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: <String, Object?>{
    'dialogue': <String, Object?>{
      'source': <String, Object?>{
        'text': 'title: Start\n---\n<<portrait leo happy>>\n$text\n===',
      },
    },
  },
);

final class _MemoryProjectGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  _MemoryProjectGateway(this.durableDocument);

  ProjectManifest durableDocument;
  var revision = 'revision-1';
  var saveCount = 0;

  @override
  Future<NarrativeDocumentVersion<ProjectManifest>> read() async {
    return NarrativeDocumentVersion<ProjectManifest>(
      revision: revision,
      document: durableDocument,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectManifest>> save({
    required String expectedRevision,
    required ProjectManifest before,
    required ProjectManifest after,
    required String operationId,
  }) async {
    saveCount += 1;
    durableDocument = after;
    revision = 'revision-${saveCount + 1}';
    return NarrativeDocumentSaveResult<ProjectManifest>.saved(
      NarrativeDocumentVersion<ProjectManifest>(
        revision: revision,
        document: durableDocument,
      ),
    );
  }
}

final class _DelayedProjectGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  _DelayedProjectGateway(this.document);

  final ProjectManifest document;
  final Completer<void> _initialization = Completer<void>();

  void releaseInitialization() => _initialization.complete();

  @override
  Future<NarrativeDocumentVersion<ProjectManifest>> read() async {
    await _initialization.future;
    return NarrativeDocumentVersion<ProjectManifest>(
      revision: 'revision-1',
      document: document,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectManifest>> save({
    required String expectedRevision,
    required ProjectManifest before,
    required ProjectManifest after,
    required String operationId,
  }) async => NarrativeDocumentSaveResult<ProjectManifest>.saved(
    NarrativeDocumentVersion<ProjectManifest>(
      revision: 'revision-2',
      document: after,
    ),
  );
}

final class _FixedPresentationPreflight
    implements ProjectPresentationPreflight {
  int calls = 0;

  @override
  Future<ProjectPresentationPreflightResult> inspect({
    required Directory projectRoot,
    required ProjectPresentationProfile profile,
  }) async {
    calls += 1;
    return ProjectPresentationPreflightResult(
      report: PersonalizationPublishReadiness.fromProfile(profile),
      checkedAssetCount: 0,
    );
  }
}

final class _MemoryProjectRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectManifest> {
  NarrativeDocumentRecoveryRecord<ProjectManifest>? record;

  @override
  Future<void> clear() async {
    record = null;
  }

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectManifest>?> read() async {
    return record;
  }

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<ProjectManifest> record,
  ) async {
    this.record = record;
  }
}

final class _FixedAssetPicker implements PersonalizationStudioAssetPicker {
  _FixedAssetPicker({this.intro, this.font, this.introError});

  final PersonalizationStudioIntroAssetSelection? intro;
  final PersonalizationStudioFontAssetSelection? font;
  final PersonalizationStudioAssetSelectionException? introError;
  int introCalls = 0;
  int fontCalls = 0;

  @override
  Future<PersonalizationStudioFontAssetSelection?> pickFontAssets() async {
    fontCalls += 1;
    return font;
  }

  @override
  Future<PersonalizationStudioIntroAssetSelection?> pickIntroAssets() async {
    introCalls += 1;
    if (introError case final error?) throw error;
    return intro;
  }

  @override
  Future<PersonalizationStudioIntroAssetSelection?> pickTitleMotionAssets() =>
      pickIntroAssets();
}

final class _FixedIntroImporter implements ProjectIntroVideoImporter {
  int calls = 0;

  @override
  Future<ProjectIntroVideoProfile> importIntoProject({
    required Directory projectRoot,
    required File videoFile,
    required File posterFile,
    File? captionsFile,
    String reducedMotionBehavior = 'poster',
    bool allowReplay = true,
  }) async {
    calls += 1;
    return ProjectIntroVideoProfile.fromLandscape(
      videoPath: 'assets/presentation/intro/opening.mp4',
      posterPath: 'assets/presentation/intro/poster.png',
      captionsPath: captionsFile == null
          ? null
          : 'assets/presentation/intro/captions.vtt',
      durationMilliseconds: 1000,
      width: 1280,
      height: 720,
      bitrateKbps: 2400,
      sizeBytes: 1000,
      videoCodec: 'h264',
      audioCodec: 'aac',
      reducedMotionBehavior: reducedMotionBehavior,
      allowReplay: allowReplay,
    );
  }
}

final class _FixedFontImporter implements ProjectFontImporter {
  int calls = 0;
  ProjectTypographyRole? lastRole;

  @override
  Future<ProjectTypographyRoleProfile> importIntoProject({
    required Directory projectRoot,
    required ProjectTypographyRole role,
    required File fontFile,
    required File licenseFile,
    required bool redistributionConfirmed,
    required List<String> fallbackFamilies,
  }) async {
    calls += 1;
    lastRole = role;
    return ProjectTypographyRoleProfile(
      fontPath: 'assets/presentation/fonts/${role.name}-test.otf',
      family: 'Studio Test',
      licensePath: 'assets/presentation/fonts/${role.name}-test-license.txt',
      redistributable: true,
      fallbackFamilies: fallbackFamilies,
      glyphCoverage: requiredProjectFontGlyphCoverage.toList(growable: false),
    );
  }
}

final class _FixedFontPreviewRegistry implements ProjectFontPreviewRegistry {
  int calls = 0;

  @override
  Future<String> load({
    required File fontFile,
    required ProjectTypographyRole role,
  }) async {
    calls += 1;
    return 'PokeMapPreview-${role.name}';
  }
}

final class _FixedTitleMusicPicker
    implements PersonalizationStudioTitleMusicPicker {
  _FixedTitleMusicPicker(this.path);

  final String? path;
  int calls = 0;

  @override
  Future<String?> pickTitleMusic() async {
    calls += 1;
    return path;
  }
}

final class _FixedTitleMusicImporter implements ProjectTitleMusicImporter {
  int calls = 0;

  @override
  Future<ProjectTitleMusicImportResult> importIntoProject({
    required Directory projectRoot,
    required File sourceFile,
  }) async {
    calls += 1;
    return const ProjectTitleMusicImportResult(
      relativePath: 'assets/presentation/branding/title-music-test.ogg',
      sizeBytes: 1024,
    );
  }
}

final class _FixedTitleMusicPreviewController
    implements ProjectTitleMusicPreviewController {
  final StreamController<bool> _playing = StreamController<bool>.broadcast(
    sync: true,
  );
  bool _isPlaying = false;
  int toggleCalls = 0;
  int stopCalls = 0;
  int closeCalls = 0;
  File? lastFile;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  Future<bool> toggle(File file) async {
    toggleCalls += 1;
    lastFile = file;
    _isPlaying = !_isPlaying;
    _playing.add(_isPlaying);
    return _isPlaying;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (!_isPlaying) return;
    _isPlaying = false;
    _playing.add(false);
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
    await _playing.close();
  }
}
