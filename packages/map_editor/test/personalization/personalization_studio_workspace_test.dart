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
  testWidgets('applies a preset to a dirty draft without writing project.json',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('personalization-studio-draft-');
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Editable presentation')
        .copyWith(presentation: const ProjectPresentationProfile());
    final projectFile = File('${root.path}/project.json');
    final durableJson =
        const JsonEncoder.withIndent('  ').convert(project.toJson());
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
      surfaceSize: const Size(1200, 800),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
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
        const ValueKey<String>('personalization-preset-cinematic'),
      ),
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
      find.byKey(
        const ValueKey<String>('personalization-studio-dirty'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-comparison-paths'),
      ),
      findsOneWidget,
    );
    expect(projectFile.readAsStringSync(), durableJson);
    expect(gateway.saveCount, 0);

    final undoButton = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-studio-undo'),
      ),
    );
    final redoButtonBeforeUndo = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-studio-redo'),
      ),
    );
    expect(undoButton.onPressed, isNotNull);
    expect(redoButtonBeforeUndo.onPressed, isNull);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-undo'),
      ),
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
      find.byKey(
        const ValueKey<String>('personalization-studio-redo'),
      ),
    );
    expect(redoButtonAfterUndo.onPressed, isNotNull);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-redo'),
      ),
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
      find.byKey(
        const ValueKey<String>('personalization-studio-autosave'),
      ),
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
      find.byKey(
        const ValueKey<String>('personalization-studio-save'),
      ),
    );
    expect(saveButton.onPressed, isNotNull);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-save'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(gateway.saveCount, 1);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-studio-dirty'),
      ),
      findsNothing,
    );
  });

  testWidgets('canvas displays the current project profile in read-only mode',
      (tester) async {
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
      surfaceSize: const Size(1200, 800),
    );

    expect(
      find.byKey(const Key('personalization-studio-workspace')),
      findsOneWidget,
    );
    expect(find.byType(PersonalizationHubShell), findsOneWidget);
    expect(
      find.text('Use a hexadecimal color such as #6750A4.'),
      findsOneWidget,
    );

    final reset = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-reset-branding'),
      ),
    );
    expect(reset.onPressed, isNull);
  });

  testWidgets(
      'intro category edits the studio draft without writing project.json',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('personalization-studio-intro-');
    addTearDown(() => root.deleteSync(recursive: true));
    const intro = ProjectIntroVideoProfile(
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
    final project = buildShellChromeProject(name: 'Intro Studio').copyWith(
      presentation: const ProjectPresentationProfile(intro: intro),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson =
        const JsonEncoder.withIndent('  ').convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1200, 800),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
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
        const ValueKey<String>('personalization-category-intro'),
      ),
    );
    await tester.pump();

    expect(find.byType(ProjectIntroVideoEditor), findsOneWidget);
    await tester.tap(find.text('Autoriser “Rejouer”'));
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
  });

  testWidgets('typography category edits one role without changing the others',
      (tester) async {
    final root = Directory.systemTemp
        .createTempSync('personalization-studio-typography-');
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
    const typography = ProjectTypographyProfile(
      display: display,
      body: body,
    );
    final project = buildShellChromeProject(name: 'Typography Studio').copyWith(
      presentation: const ProjectPresentationProfile(
        typography: typography,
      ),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson =
        const JsonEncoder.withIndent('  ').convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1200, 800),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
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
        const ValueKey<String>('personalization-category-typography'),
      ),
    );
    await tester.pump();

    expect(find.byType(ProjectTypographyEditor), findsOneWidget);
    for (final role in ProjectTypographyRole.values) {
      expect(
        find.byKey(ValueKey<String>('typography-import-${role.name}')),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.byKey(
        const ValueKey<String>('typography-system-display'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final draft = container
        .read(editorNotifierProvider)
        .project
        ?.effectivePresentation
        .typography;
    expect(draft?.display.fontPath, isNull);
    expect(draft?.display.fallbackFamilies, <String>['sans-serif']);
    expect(draft?.body, body);
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets('theme category edits a semantic token through a guided dialog',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('personalization-studio-theme-');
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Theme Studio').copyWith(
      presentation: const ProjectPresentationProfile(
        theme: safeProjectSemanticTheme,
      ),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson =
        const JsonEncoder.withIndent('  ').convert(project.toJson());
    projectFile.writeAsStringSync(durableJson, flush: true);
    final gateway = _MemoryProjectGateway(project);

    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1200, 1400),
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
        const ValueKey<String>('personalization-category-theme'),
      ),
    );
    await tester.pump();

    expect(find.byType(ProjectSemanticThemeEditor), findsOneWidget);
    final editPrimary =
        find.byKey(const ValueKey<String>('theme-edit-primary'));
    await tester.ensureVisible(editPrimary);
    await tester.tap(editPrimary);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('personalization-theme-token-dialog'),
      ),
      findsOneWidget,
    );
    final tokenInput = find.byKey(
      const ValueKey<String>('personalization-theme-token-input'),
    );
    await tester.enterText(tokenInput, '#GG');
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(
      find.textContaining('six chiffres hexadécimaux'),
      findsOneWidget,
    );
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
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets('guided intro import reports success and updates only the draft',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('personalization-studio-import-');
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Import Studio').copyWith(
      presentation: const ProjectPresentationProfile(),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson =
        const JsonEncoder.withIndent('  ').convert(project.toJson());
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
      surfaceSize: const Size(1200, 800),
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
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
          },
        ),
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
        const ValueKey<String>('personalization-category-intro'),
      ),
    );
    await tester.pump();

    final importButton = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-intro-import'),
      ),
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
  });

  testWidgets('guided font import confirms rights and updates only one role',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('personalization-studio-font-');
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Font Studio').copyWith(
      presentation: const ProjectPresentationProfile(),
    );
    final projectFile = File('${root.path}/project.json');
    final durableJson =
        const JsonEncoder.withIndent('  ').convert(project.toJson());
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
      surfaceSize: const Size(1200, 1000),
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
        personalizationStudioAssetPickerProvider.overrideWithValue(
          assetPicker,
        ),
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
        const ValueKey<String>('personalization-category-typography'),
      ),
    );
    await tester.pump();

    final importBody = find.byKey(
      const ValueKey<String>('typography-import-body'),
    );
    await tester.ensureVisible(importBody);
    await tester.tap(importBody);
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
    expect(typography?.display.fontPath, isNull);
    expect(
      find.text('Fonte et licence importées dans le brouillon.'),
      findsOneWidget,
    );
    expect(projectFile.readAsStringSync(), durableJson);
  });

  testWidgets('guided import exposes selection errors without changing draft',
      (tester) async {
    final root =
        Directory.systemTemp.createTempSync('personalization-studio-error-');
    addTearDown(() => root.deleteSync(recursive: true));
    final project =
        buildShellChromeProject(name: 'Import Error Studio').copyWith(
      presentation: const ProjectPresentationProfile(),
    );
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
      surfaceSize: const Size(1200, 800),
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
        personalizationStudioAssetPickerProvider.overrideWithValue(
          assetPicker,
        ),
      ],
    );
    await container
        .read(editorNotifierProvider.notifier)
        .initializePersonalizationStudioSession();
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-category-intro'),
      ),
    );
    await tester.pump();

    final importButton = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-intro-import'),
      ),
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

  testWidgets('shows a dedicated state when no project is open',
      (tester) async {
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
    expect(find.byType(PersonalizationHubShell), findsNothing);
  });

  testWidgets('shows a loading state while a project path is being restored',
      (tester) async {
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
    expect(find.byType(PersonalizationHubShell), findsNothing);
  });

  testWidgets('shows the project loading error instead of an empty hub',
      (tester) async {
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
    expect(find.byType(PersonalizationHubShell), findsNothing);
  });
}

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
  _FixedAssetPicker({
    this.intro,
    this.font,
    this.introError,
  });

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
    return ProjectIntroVideoProfile(
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
