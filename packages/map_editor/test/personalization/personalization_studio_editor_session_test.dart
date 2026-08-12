import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  test('save then reopen restores the exact presentation profile', () async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-reopen-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final projectFile = File('${root.path}/project.json');
    final initial = buildShellChromeProject(name: 'Reopen presentation');
    projectFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(initial.toJson()),
      flush: true,
    );
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(
        accentColor: '#6750A4',
        layoutVariant: 'cinematic',
      ),
      theme: safeProjectSemanticTheme,
    );

    final firstContainer = ProviderContainer();
    final firstSubscription = firstContainer.listen<EditorState>(
      editorNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final firstNotifier = firstContainer.read(editorNotifierProvider.notifier);
    firstNotifier.state = EditorState(
      projectRootPath: root.path,
      project: initial,
      workspaceMode: EditorWorkspaceMode.personalizationStudio,
    );

    expect(
      await firstNotifier.initializePersonalizationStudioSession(),
      isTrue,
    );
    expect(
      await firstNotifier.applyPersonalizationStudioProfile(profile),
      isTrue,
    );
    expect(
      ProjectManifest.fromJson(
        jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>,
      ).presentation,
      isNull,
    );
    expect(await firstNotifier.saveProjectManifest(), isTrue);
    expect(firstNotifier.state.isProjectDirty, isFalse);
    final durable = ProjectManifest.fromJson(
      jsonDecode(projectFile.readAsStringSync()) as Map<String, dynamic>,
    );
    expect(durable.presentation, profile);
    firstSubscription.close();
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    final secondSubscription = secondContainer.listen<EditorState>(
      editorNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(secondSubscription.close);
    final secondNotifier = secondContainer.read(
      editorNotifierProvider.notifier,
    );
    secondNotifier.state = EditorState(
      projectRootPath: root.path,
      project: durable,
      workspaceMode: EditorWorkspaceMode.personalizationStudio,
    );

    expect(
      await secondNotifier.initializePersonalizationStudioSession(),
      isTrue,
    );
    expect(
      secondNotifier.personalizationStudioSessionState?.draftProfile,
      profile,
    );
    expect(
      secondNotifier.personalizationStudioSessionState?.savedProfile,
      profile,
    );
    expect(secondNotifier.state.isProjectDirty, isFalse);
  });

  test('autosave resynchronizes the shared project document session', () async {
    final root = Directory.systemTemp.createTempSync(
      'personalization-autosave-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Autosave integration');
    File('${root.path}/project.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
    final personalizationGateway = _MemoryProfileGateway(project);
    final scheduler = _ManualAutosaveScheduler();
    var narrativeFactoryCalls = 0;
    final container = ProviderContainer(
      overrides: [
        personalizationStudioSessionControllerFactoryProvider.overrideWithValue(
          ({
            required String projectPath,
            required ProjectManifest initialDocument,
          }) {
            return PersonalizationStudioSessionController(
              session: NarrativeDocumentSession<ProjectPresentationProfile>(
                documentId: 'personalization-studio',
                initialDocument: initialDocument.effectivePresentation,
                gateway: personalizationGateway,
                recoveryStore: _MemoryProfileRecoveryStore(),
                autosaveScheduler: scheduler.schedule,
              ),
              initialProject: initialDocument,
              projectSnapshot: () => personalizationGateway.currentProject,
            );
          },
        ),
        narrativeProjectDocumentSessionFactoryProvider.overrideWithValue(({
          required String projectPath,
          required ProjectManifest initialDocument,
        }) {
          narrativeFactoryCalls += 1;
          return NarrativeDocumentSession<ProjectManifest>(
            documentId: 'cinematics',
            initialDocument: initialDocument,
            gateway: _MemoryProjectGateway(initialDocument),
            recoveryStore: _MemoryProjectRecoveryStore(),
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen<EditorState>(
      editorNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: project,
      workspaceMode: EditorWorkspaceMode.personalizationStudio,
    );
    expect(await notifier.initializeNarrativeDocumentSession(), isTrue);
    expect(await notifier.initializePersonalizationStudioSession(), isTrue);
    await notifier.setPersonalizationStudioAutosaveEnabled(true);
    await notifier.applyPersonalizationStudioProfile(
      const ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#56789A'),
      ),
    );

    await scheduler.runLatest();
    await Future<void>.delayed(Duration.zero);

    expect(personalizationGateway.saveCount, 1);
    expect(narrativeFactoryCalls, 2);
    expect(notifier.state.isProjectDirty, isFalse);
  });

  test(
    'serializes rapid presentation commits before writing recovery',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'personalization-serialized-commits-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final project = buildShellChromeProject(name: 'Serialized commits');
      File(
        '${root.path}/project.json',
      ).writeAsStringSync(jsonEncode(project.toJson()), flush: true);
      final recovery = _BlockingProfileRecoveryStore();
      final gateway = _MemoryProfileGateway(project);
      final container = ProviderContainer(
        overrides: [
          personalizationStudioSessionControllerFactoryProvider
              .overrideWithValue(({
                required String projectPath,
                required ProjectManifest initialDocument,
              }) {
                return PersonalizationStudioSessionController(
                  session: NarrativeDocumentSession<ProjectPresentationProfile>(
                    documentId: 'personalization-serialized-commits',
                    initialDocument: initialDocument.effectivePresentation,
                    gateway: gateway,
                    recoveryStore: recovery,
                  ),
                  initialProject: initialDocument,
                  projectSnapshot: () => gateway.currentProject,
                );
              }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      );
      expect(await notifier.initializePersonalizationStudioSession(), isTrue);

      const firstProfile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#123456'),
      );
      const secondProfile = ProjectPresentationProfile(
        title: ProjectTitlePresentationProfile(title: 'Dernière valeur'),
      );
      final first = notifier.applyPersonalizationStudioProfile(firstProfile);
      await recovery.firstWriteStarted.future;
      final second = notifier.updatePersonalizationStudioProfile(
        (current) => current.copyWith(title: secondProfile.title),
      );
      final autosave = notifier.setPersonalizationStudioAutosaveEnabled(true);
      await Future<void>.delayed(Duration.zero);

      expect(recovery.writeCount, 1);
      expect(recovery.maxConcurrentWrites, 1);
      expect(
        notifier.personalizationStudioSessionState?.autosaveEnabled,
        isFalse,
      );

      recovery.releaseFirstWrite();
      expect(await first, isTrue);
      expect(await second, isTrue);
      await autosave;
      expect(recovery.writeCount, 2);
      expect(recovery.maxConcurrentWrites, 1);
      expect(
        notifier.personalizationStudioSessionState?.autosaveEnabled,
        isTrue,
      );
      expect(
        notifier.personalizationStudioSessionState?.draftProfile,
        const ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#123456'),
          title: ProjectTitlePresentationProfile(title: 'Dernière valeur'),
        ),
      );
    },
  );
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
        document: after,
      ),
    );
  }
}

final class _MemoryProjectRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectManifest> {
  NarrativeDocumentRecoveryRecord<ProjectManifest>? record;

  @override
  Future<void> clear() async => record = null;

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectManifest>?> read() async =>
      record;

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<ProjectManifest> record,
  ) async {
    this.record = record;
  }
}

final class _MemoryProfileGateway
    implements NarrativeDocumentGateway<ProjectPresentationProfile> {
  _MemoryProfileGateway(this.currentProject);

  ProjectManifest currentProject;
  var revision = 'revision-1';
  var saveCount = 0;

  @override
  Future<NarrativeDocumentVersion<ProjectPresentationProfile>> read() async {
    return NarrativeDocumentVersion<ProjectPresentationProfile>(
      revision: revision,
      document: currentProject.effectivePresentation,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectPresentationProfile>> save({
    required String expectedRevision,
    required ProjectPresentationProfile before,
    required ProjectPresentationProfile after,
    required String operationId,
  }) async {
    saveCount += 1;
    currentProject = currentProject.copyWith(presentation: after);
    revision = 'revision-${saveCount + 1}';
    return NarrativeDocumentSaveResult<ProjectPresentationProfile>.saved(
      NarrativeDocumentVersion<ProjectPresentationProfile>(
        revision: revision,
        document: after,
      ),
    );
  }
}

final class _MemoryProfileRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectPresentationProfile> {
  NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>? record;

  @override
  Future<void> clear() async => record = null;

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>?>
  read() async => record;

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<ProjectPresentationProfile> record,
  ) async {
    this.record = record;
  }
}

final class _BlockingProfileRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectPresentationProfile> {
  final Completer<void> firstWriteStarted = Completer<void>();
  final Completer<void> _firstWriteRelease = Completer<void>();
  var writeCount = 0;
  var concurrentWrites = 0;
  var maxConcurrentWrites = 0;

  void releaseFirstWrite() => _firstWriteRelease.complete();

  @override
  Future<void> clear() async {}

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>?>
  read() async => null;

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<ProjectPresentationProfile> record,
  ) async {
    writeCount += 1;
    concurrentWrites += 1;
    if (concurrentWrites > maxConcurrentWrites) {
      maxConcurrentWrites = concurrentWrites;
    }
    if (writeCount == 1) {
      firstWriteStarted.complete();
      await _firstWriteRelease.future;
    }
    concurrentWrites -= 1;
  }
}

final class _ManualAutosaveScheduler {
  final List<_ManualAutosaveTask> _tasks = <_ManualAutosaveTask>[];

  NarrativeDocumentAutosaveHandle schedule(
    Duration delay,
    Future<void> Function() callback,
  ) {
    final task = _ManualAutosaveTask(callback);
    _tasks.add(task);
    return task;
  }

  Future<void> runLatest() => _tasks.lastWhere((task) => !task.cancelled).run();
}

final class _ManualAutosaveTask implements NarrativeDocumentAutosaveHandle {
  _ManualAutosaveTask(this._callback);

  final Future<void> Function() _callback;
  bool cancelled = false;

  Future<void> run() async {
    if (!cancelled) await _callback();
  }

  @override
  void cancel() {
    cancelled = true;
  }
}
