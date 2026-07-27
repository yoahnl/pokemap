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
