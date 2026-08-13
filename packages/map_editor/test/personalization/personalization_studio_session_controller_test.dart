import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('PersonalizationStudioSessionController', () {
    test('keeps the session and recovery history profile-only', () async {
      final project = buildShellChromeProject(name: 'Profile-only session');
      final gateway = _MemoryProfileGateway(project);
      final recovery = _MemoryProfileRecoveryStore();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: gateway,
          recoveryStore: recovery,
        ),
        initialProject: project,
        projectSnapshot: () => gateway.currentProject,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#123456'),
      );

      expect(
        await controller.applyProfile(
          profile,
          operationId: 'profile-only-edit',
          label: 'Modifier le profil',
        ),
        isTrue,
      );

      expect(recovery.record?.baseline, project.effectivePresentation);
      expect(recovery.record?.document, profile);
      expect(
        recovery.record?.undoEntries.single.before,
        project.effectivePresentation,
      );
      expect(recovery.record?.undoEntries.single.after, profile);
      expect(controller.state.document.name, 'Profile-only session');
      expect(controller.state.draftProfile, profile);
    });

    test(
      'publishes a presentation draft without persisting project.json',
      () async {
        final project = buildShellChromeProject(name: 'Studio session');
        final gateway = _MemoryProfileGateway(project);
        final recovery = _MemoryProfileRecoveryStore();
        final controller = PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: project.effectivePresentation,
            gateway: gateway,
            recoveryStore: recovery,
          ),
          initialProject: project,
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
        expect(recovery.record?.document, profile);
        expect(gateway.saveCount, 0);
        expect(gateway.durableDocument, project);
      },
    );

    test('treats an identical profile as a no-op', () async {
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(layoutVariant: 'centered'),
      );
      final project = buildShellChromeProject(
        name: 'Unchanged profile',
      ).copyWith(presentation: profile);
      final gateway = _MemoryProfileGateway(project);
      final recovery = _MemoryProfileRecoveryStore();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: gateway,
          recoveryStore: recovery,
        ),
        initialProject: project,
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

    test('refreshes the durable revision without losing the local draft', () async {
      final project = buildShellChromeProject(name: 'Refresh baseline');
      final gateway = _MemoryProfileGateway(project);
      final recovery = _MemoryProfileRecoveryStore();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-refresh-baseline',
          initialDocument: project.effectivePresentation,
          gateway: gateway,
          recoveryStore: recovery,
        ),
        initialProject: project,
        projectSnapshot: () => gateway.currentProject,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      const profile = ProjectPresentationProfile(
        title: ProjectTitlePresentationProfile(title: 'Le train UwU'),
      );
      await controller.applyProfile(
        profile,
        operationId: 'refresh-title',
        label: 'Modifier le titre',
      );
      gateway
        ..durableDocument = project.copyWith(name: 'Refresh baseline updated')
        ..revision = 'revision-2';

      expect(await controller.refreshCurrentProject(), isTrue);

      expect(controller.state.draftProfile, profile);
      expect(controller.state.savedProfile, project.effectivePresentation);
      expect(controller.state.isDirty, isTrue);
      expect(recovery.record?.baseRevision, 'revision-2');
    });

    test('saves the exact draft and adopts it as the new baseline', () async {
      final project = buildShellChromeProject(name: 'Saved profile');
      final gateway = _MemoryProfileGateway(project);
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: gateway,
          recoveryStore: _MemoryProfileRecoveryStore(),
        ),
        initialProject: project,
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

    test(
      'undo and redo move the presentation draft through its history',
      () async {
        final project = buildShellChromeProject(name: 'History profile');
        final controller = PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: project.effectivePresentation,
            gateway: _MemoryProfileGateway(project),
            recoveryStore: _MemoryProfileRecoveryStore(),
          ),
          initialProject: project,
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
      },
    );

    test('undo and redo restore the exact V10 battle draft', () async {
      final project = buildShellChromeProject(name: 'Battle history');
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: _MemoryProfileGateway(project),
          recoveryStore: _MemoryProfileRecoveryStore(),
        ),
        initialProject: project,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      const battle = ProjectBattlePresentationProfile(
        commandLayout: ProjectBattleCommandLayout.radial,
        moves: ProjectBattlePanelPresentationProfile(
          shape: ProjectWindowShape.cutCorner,
        ),
      );
      final profile = project.effectivePresentation.copyWith(battle: battle);

      await controller.applyProfile(
        profile,
        operationId: 'battle-history-profile',
        label: 'Personnaliser le combat',
      );

      expect(controller.state.draftProfile.battle, battle);
      expect(await controller.undo(), isTrue);
      expect(controller.state.draftProfile.battle, isNull);
      expect(await controller.redo(), isTrue);
      expect(controller.state.draftProfile.battle, battle);
    });

    test('records one completed layout gesture as one undo entry', () async {
      final project = buildShellChromeProject(name: 'Gesture history');
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: _MemoryProfileGateway(project),
          recoveryStore: _MemoryProfileRecoveryStore(),
        ),
        initialProject: project,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final layouts = suggestedProjectPresentationLayouts('standard');
      final moved = layouts.copyWith(
        pauseMenu: layouts.pauseMenu.copyWith(
          regular: layouts.pauseMenu.regular.copyWith(
            slot: ProjectPresentationLayoutSlot.right,
          ),
        ),
      );

      expect(
        await controller.applyProfile(
          project.effectivePresentation.copyWith(layouts: moved),
          operationId: 'gesture-1',
          label: 'Déplacer le menu Pause',
        ),
        isTrue,
      );
      expect(await controller.undo(), isTrue);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.draftProfile, project.effectivePresentation);
    });

    test('records a scene preset as one atomic undo entry', () async {
      final project = buildShellChromeProject(name: 'Preset history');
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: _MemoryProfileGateway(project),
          recoveryStore: _MemoryProfileRecoveryStore(),
        ),
        initialProject: project,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final preset = personalizationScenePresetsFor(
        PersonalizationStudioScene.dialogue,
      ).last;

      expect(
        await controller.applyProfile(
          preset.preview(project.effectivePresentation).profile,
          operationId: 'preset-1',
          label: 'Appliquer le preset dialogue',
        ),
        isTrue,
      );
      expect(await controller.undo(), isTrue);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.draftProfile, project.effectivePresentation);
    });

    test(
      'repeats undo and redo across gestures and presets deterministically',
      () async {
        final project = buildShellChromeProject(name: 'Repeated history');
        final controller = PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: project.effectivePresentation,
            gateway: _MemoryProfileGateway(project),
            recoveryStore: _MemoryProfileRecoveryStore(),
          ),
          initialProject: project,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        final layouts = suggestedProjectPresentationLayouts('standard');
        final moved = project.effectivePresentation.copyWith(
          layouts: layouts.copyWith(
            pauseMenu: layouts.pauseMenu.copyWith(
              expanded: layouts.pauseMenu.expanded.copyWith(
                slot: ProjectPresentationLayoutSlot.right,
              ),
            ),
          ),
        );
        final preset = personalizationScenePresetsFor(
          PersonalizationStudioScene.dialogue,
        ).last;
        final withPreset = preset.apply(moved);

        await controller.applyProfile(
          moved,
          operationId: 'gesture-repeat',
          label: 'Déplacer Pause',
        );
        await controller.applyProfile(
          withPreset,
          operationId: 'preset-repeat',
          label: 'Appliquer Dialogue',
        );

        expect(await controller.undo(), isTrue);
        expect(controller.state.draftProfile, moved);
        expect(await controller.undo(), isTrue);
        expect(controller.state.draftProfile, project.effectivePresentation);
        expect(await controller.redo(), isTrue);
        expect(controller.state.draftProfile, moved);
        expect(await controller.redo(), isTrue);
        expect(controller.state.draftProfile, withPreset);
      },
    );

    test(
      'does not announce success when durable confirmation mismatches',
      () async {
        final project = buildShellChromeProject(name: 'Mismatch save');
        final controller = PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: project.effectivePresentation,
            gateway: _MismatchingProfileGateway(project),
            recoveryStore: _MemoryProfileRecoveryStore(),
          ),
          initialProject: project,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        await controller.applyProfile(
          const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(accentColor: '#345678'),
          ),
          operationId: 'mismatch-edit',
          label: 'Modifier le profil',
        );

        expect(await controller.save(operationId: 'mismatch-save'), isFalse);
        expect(controller.state.hasFailed, isTrue);
        expect(controller.state.code, 'savedDocumentMismatch');
        expect(controller.state.isDirty, isTrue);
      },
    );

    test('autosave persists the latest scheduled presentation draft', () async {
      final project = buildShellChromeProject(name: 'Autosave profile');
      final gateway = _MemoryProfileGateway(project);
      final scheduler = _ManualAutosaveScheduler();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: gateway,
          recoveryStore: _MemoryProfileRecoveryStore(),
          autosaveScheduler: scheduler.schedule,
        ),
        initialProject: project,
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

    test('blocks persistence while presentation contrast is invalid', () async {
      final project = buildShellChromeProject(name: 'Invalid contrast');
      final gateway = _MemoryProfileGateway(project);
      final scheduler = _ManualAutosaveScheduler();
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: project.effectivePresentation,
          gateway: gateway,
          recoveryStore: _MemoryProfileRecoveryStore(),
          autosaveScheduler: scheduler.schedule,
        ),
        initialProject: project,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final profile = ProjectPresentationProfile(
        theme: safeProjectSemanticTheme.copyWith(
          primary: '#EEEEEE',
          onPrimary: '#FFFFFF',
        ),
      );

      expect(
        await controller.applyProfile(
          profile,
          operationId: 'invalid-contrast',
          label: 'Modifier le contraste',
        ),
        isTrue,
      );
      controller.setAutosaveEnabled(true);

      expect(controller.state.isDirty, isTrue);
      expect(scheduler.activeTasks, isEmpty);
      expect(await controller.save(operationId: 'blocked-save'), isFalse);
      expect(controller.state.code, 'persistenceValidationFailed');
      expect(gateway.saveCount, 0);
    });

    test(
      'keeps the recovered presentation on top of the current project',
      () async {
        const recoveredProfile = ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#456789'),
        );
        const currentProfile = ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#987654'),
        );
        final previousProject = buildShellChromeProject(
          name: 'Previous project',
        );
        final currentProject = buildShellChromeProject(
          name: 'Current project',
        ).copyWith(presentation: currentProfile);
        final recovery = _MemoryProfileRecoveryStore()
          ..record =
              NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>(
                documentId: 'personalization-studio',
                baseRevision: 'revision-previous',
                baseline: previousProject.effectivePresentation,
                document: recoveredProfile,
              );
        final gateway = _MemoryProfileGateway(currentProject)
          ..revision = 'revision-current';
        final controller = PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: previousProject.effectivePresentation,
            gateway: gateway,
            recoveryStore: recovery,
          ),
          initialProject: previousProject,
          projectSnapshot: () => gateway.currentProject,
        );
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.state.isConflicted, isTrue);

        expect(await controller.keepDraftOnCurrentProject(), isTrue);

        expect(controller.state.isConflicted, isFalse);
        expect(controller.state.isDirty, isTrue);
        expect(controller.state.document.name, 'Current project');
        expect(controller.state.draftProfile, recoveredProfile);
        expect(recovery.record?.baseline, currentProfile);
        expect(recovery.record?.document, recoveredProfile);

        expect(
          await controller.save(operationId: 'save-recovered-profile'),
          isTrue,
        );
        expect(gateway.durableDocument.name, 'Current project');
        expect(gateway.durableDocument.presentation, recoveredProfile);
      },
    );

    test(
      'automatically rebases a recovered profile when only the project changed',
      () async {
        const recoveredProfile = ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: '#456789'),
        );
        final previousProject = buildShellChromeProject(
          name: 'Previous project',
        );
        final currentProject = previousProject.copyWith(
          name: 'Current project',
        );
        final recovery = _MemoryProfileRecoveryStore()
          ..record =
              NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>(
                documentId: 'personalization-studio',
                baseRevision: 'revision-previous',
                baseline: previousProject.effectivePresentation,
                document: recoveredProfile,
              );
        final gateway = _MemoryProfileGateway(currentProject)
          ..revision = 'revision-current';
        final controller = PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: currentProject.effectivePresentation,
            gateway: gateway,
            recoveryStore: recovery,
          ),
          initialProject: currentProject,
          projectSnapshot: () => gateway.currentProject,
        );
        addTearDown(controller.dispose);

        await controller.initialize();

        expect(controller.state.isConflicted, isFalse);
        expect(controller.state.isDirty, isTrue);
        expect(controller.state.document.name, 'Current project');
        expect(controller.state.draftProfile, recoveredProfile);
        expect(recovery.record?.baseRevision, 'revision-current');
      },
    );

    test('uses the current project and clears the recovered draft', () async {
      const recoveredProfile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#456789'),
      );
      const currentProfile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#987654'),
      );
      final previousProject = buildShellChromeProject(name: 'Previous project');
      final currentProject = buildShellChromeProject(
        name: 'Current project',
      ).copyWith(presentation: currentProfile);
      final recovery = _MemoryProfileRecoveryStore()
        ..record = NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          baseRevision: 'revision-previous',
          baseline: previousProject.effectivePresentation,
          document: recoveredProfile,
        );
      final gateway = _MemoryProfileGateway(currentProject)
        ..revision = 'revision-current';
      final controller = PersonalizationStudioSessionController(
        session: NarrativeDocumentSession<ProjectPresentationProfile>(
          documentId: 'personalization-studio',
          initialDocument: previousProject.effectivePresentation,
          gateway: gateway,
          recoveryStore: recovery,
        ),
        initialProject: previousProject,
        projectSnapshot: () => gateway.currentProject,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.state.isConflicted, isTrue);

      expect(await controller.useCurrentProject(), isTrue);

      expect(controller.state.isConflicted, isFalse);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.document, currentProject);
      expect(controller.state.draftProfile, currentProfile);
      expect(recovery.record, isNull);
    });
  });
}

class _MemoryProfileGateway
    implements NarrativeDocumentGateway<ProjectPresentationProfile> {
  _MemoryProfileGateway(this.durableDocument);

  ProjectManifest durableDocument;
  var revision = 'revision-1';
  var saveCount = 0;

  ProjectManifest get currentProject => durableDocument;

  @override
  Future<NarrativeDocumentVersion<ProjectPresentationProfile>> read() async {
    return NarrativeDocumentVersion<ProjectPresentationProfile>(
      revision: revision,
      document: durableDocument.effectivePresentation,
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
    durableDocument = durableDocument.copyWith(presentation: after);
    revision = 'revision-${saveCount + 1}';
    return NarrativeDocumentSaveResult<ProjectPresentationProfile>.saved(
      NarrativeDocumentVersion<ProjectPresentationProfile>(
        revision: revision,
        document: after,
      ),
    );
  }
}

final class _MismatchingProfileGateway extends _MemoryProfileGateway {
  _MismatchingProfileGateway(super.durableDocument);

  @override
  Future<NarrativeDocumentSaveResult<ProjectPresentationProfile>> save({
    required String expectedRevision,
    required ProjectPresentationProfile before,
    required ProjectPresentationProfile after,
    required String operationId,
  }) async => NarrativeDocumentSaveResult<ProjectPresentationProfile>.saved(
    NarrativeDocumentVersion<ProjectPresentationProfile>(
      revision: 'revision-mismatch',
      document: before,
    ),
  );
}

final class _MemoryProfileRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectPresentationProfile> {
  NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>? record;
  var writeCount = 0;

  @override
  Future<void> clear() async {
    record = null;
  }

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>?>
  read() async {
    return record;
  }

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<ProjectPresentationProfile> record,
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
