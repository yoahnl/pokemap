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
    final root =
        Directory.systemTemp.createTempSync('personalization-reopen-test-');
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
        await firstNotifier.initializePersonalizationStudioSession(), isTrue);
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
    final secondNotifier =
        secondContainer.read(editorNotifierProvider.notifier);
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
    final root =
        Directory.systemTemp.createTempSync('personalization-autosave-test-');
    addTearDown(() => root.deleteSync(recursive: true));
    final project = buildShellChromeProject(name: 'Autosave integration');
    File('${root.path}/project.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
    final personalizationGateway = _MemoryProjectGateway(project);
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
              session: NarrativeDocumentSession<ProjectManifest>(
                documentId: 'personalization-studio',
                initialDocument: initialDocument,
                gateway: personalizationGateway,
                recoveryStore: _MemoryProjectRecoveryStore(),
                autosaveScheduler: scheduler.schedule,
              ),
            );
          },
        ),
        narrativeProjectDocumentSessionFactoryProvider.overrideWithValue(
          ({
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
          },
        ),
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
