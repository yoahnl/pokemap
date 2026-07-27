import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('PersonalizationStudioSessionController', () {
    test('publishes a presentation draft without persisting project.json',
        () async {
      final project = buildShellChromeProject(name: 'Studio session');
      final gateway = _MemoryProjectGateway(project);
      final recovery = _MemoryProjectRecoveryStore();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectManifest>(
          documentId: 'personalization-studio',
          initialDocument: project,
          gateway: gateway,
          recoveryStore: recovery,
        ),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#123456'),
      );

      final applied = await controller.applyProfile(
        profile,
        operationId: 'accent-1',
        label: 'Changer la couleur d’accent',
      );

      expect(applied, isTrue);
      expect(controller.state.draftProfile, profile);
      expect(controller.state.savedProfile, project.effectivePresentation);
      expect(controller.state.document.name, 'Studio session');
      expect(controller.state.isDirty, isTrue);
      expect(recovery.record?.document.presentation, profile);
      expect(gateway.saveCount, 0);
      expect(gateway.durableDocument, project);
    });

    test('treats an identical profile as a no-op', () async {
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(layoutVariant: 'centered'),
      );
      final project = buildShellChromeProject(
        name: 'Unchanged profile',
      ).copyWith(presentation: profile);
      final gateway = _MemoryProjectGateway(project);
      final recovery = _MemoryProjectRecoveryStore();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectManifest>(
          documentId: 'personalization-studio',
          initialDocument: project,
          gateway: gateway,
          recoveryStore: recovery,
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      final applied = await controller.applyProfile(
        profile,
        operationId: 'same-profile',
        label: 'Conserver le profil',
      );

      expect(applied, isTrue);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
      expect(recovery.writeCount, 0);
      expect(gateway.saveCount, 0);
    });

    test('saves the exact draft and adopts it as the new baseline', () async {
      final project = buildShellChromeProject(name: 'Saved profile');
      final gateway = _MemoryProjectGateway(project);
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectManifest>(
          documentId: 'personalization-studio',
          initialDocument: project,
          gateway: gateway,
          recoveryStore: _MemoryProjectRecoveryStore(),
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#345678'),
      );
      await controller.applyProfile(
        profile,
        operationId: 'accent-before-save',
        label: 'Changer la couleur',
      );

      final saved = await controller.save(operationId: 'save-profile');

      expect(saved, isTrue);
      expect(gateway.saveCount, 1);
      expect(gateway.durableDocument.presentation, profile);
      expect(controller.state.savedProfile, profile);
      expect(controller.state.draftProfile, profile);
      expect(controller.state.isDirty, isFalse);
    });

    test('undo and redo move the presentation draft through its history',
        () async {
      final project = buildShellChromeProject(name: 'History profile');
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectManifest>(
          documentId: 'personalization-studio',
          initialDocument: project,
          gateway: _MemoryProjectGateway(project),
          recoveryStore: _MemoryProjectRecoveryStore(),
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
      );
      await controller.applyProfile(
        profile,
        operationId: 'history-profile',
        label: 'Appliquer le profil',
      );

      expect(await controller.undo(), isTrue);
      expect(controller.state.draftProfile, project.effectivePresentation);
      expect(controller.state.canRedo, isTrue);
      expect(await controller.redo(), isTrue);
      expect(controller.state.draftProfile, profile);
      expect(controller.state.canUndo, isTrue);
    });

    test('autosave persists the latest scheduled presentation draft', () async {
      final project = buildShellChromeProject(name: 'Autosave profile');
      final gateway = _MemoryProjectGateway(project);
      final scheduler = _ManualAutosaveScheduler();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectManifest>(
          documentId: 'personalization-studio',
          initialDocument: project,
          gateway: gateway,
          recoveryStore: _MemoryProjectRecoveryStore(),
          autosaveScheduler: scheduler.schedule,
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#456789'),
      );
      await controller.applyProfile(
        profile,
        operationId: 'autosave-profile',
        label: 'Modifier le profil',
      );

      controller.setAutosaveEnabled(true);
      expect(controller.state.autosaveEnabled, isTrue);
      expect(scheduler.activeTasks, hasLength(1));
      await scheduler.runLatest();

      expect(gateway.saveCount, 1);
      expect(gateway.durableDocument.presentation, profile);
      expect(controller.state.isDirty, isFalse);
    });
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
  var writeCount = 0;

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
    writeCount += 1;
    this.record = record;
  }
}

final class _ManualAutosaveScheduler {
  final List<_ManualAutosaveTask> _tasks = <_ManualAutosaveTask>[];

  List<_ManualAutosaveTask> get activeTasks =>
      _tasks.where((task) => !task.cancelled).toList(growable: false);

  NarrativeDocumentAutosaveHandle schedule(
    Duration delay,
    Future<void> Function() callback,
  ) {
    final task = _ManualAutosaveTask(callback);
    _tasks.add(task);
    return task;
  }

  Future<void> runLatest() => activeTasks.last.run();
}

final class _ManualAutosaveTask implements NarrativeDocumentAutosaveHandle {
  _ManualAutosaveTask(this._callback);

  final Future<void> Function() _callback;
  bool cancelled = false;

  Future<void> run() async {
    if (!cancelled) {
      await _callback();
    }
  }

  @override
  void cancel() {
    cancelled = true;
  }
}
