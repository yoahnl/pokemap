import 'package:map_core/map_core.dart';

import '../../application/services/narrative_document_session.dart';
import '../../application/services/narrative_undo_stack.dart';

final class PersonalizationProjectRecoveryStore
    implements NarrativeDocumentRecoveryStore<ProjectManifest> {
  PersonalizationProjectRecoveryStore({
    required ProjectManifest currentProject,
    required NarrativeDocumentRecoveryStore<ProjectPresentationProfile>
    profileStore,
  }) : _currentProject = currentProject,
       _profileStore = profileStore;

  final ProjectManifest _currentProject;
  final NarrativeDocumentRecoveryStore<ProjectPresentationProfile>
  _profileStore;

  @override
  Future<NarrativeDocumentRecoveryRecord<ProjectManifest>?> read() async {
    final record = await _profileStore.read();
    if (record == null) return null;
    return NarrativeDocumentRecoveryRecord<ProjectManifest>(
      schemaVersion: record.schemaVersion,
      documentId: record.documentId,
      baseRevision: record.baseRevision,
      baseline: _withProfile(record.baseline),
      document: _withProfile(record.document),
      undoEntries: record.undoEntries.map(_toProjectEntry).toList(),
      redoEntries: record.redoEntries.map(_toProjectEntry).toList(),
    );
  }

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<ProjectManifest> record) {
    return _profileStore.write(
      NarrativeDocumentRecoveryRecord<ProjectPresentationProfile>(
        schemaVersion: record.schemaVersion,
        documentId: record.documentId,
        baseRevision: record.baseRevision,
        baseline: record.baseline.effectivePresentation,
        document: record.document.effectivePresentation,
        undoEntries: record.undoEntries.map(_toProfileEntry).toList(),
        redoEntries: record.redoEntries.map(_toProfileEntry).toList(),
      ),
    );
  }

  @override
  Future<void> clear() => _profileStore.clear();

  ProjectManifest _withProfile(ProjectPresentationProfile profile) {
    return _currentProject.copyWith(presentation: profile);
  }

  NarrativeUndoEntry<ProjectManifest> _toProjectEntry(
    NarrativeUndoEntry<ProjectPresentationProfile> entry,
  ) {
    return NarrativeUndoEntry<ProjectManifest>(
      operationId: entry.operationId,
      label: entry.label,
      before: _withProfile(entry.before),
      after: _withProfile(entry.after),
    );
  }

  NarrativeUndoEntry<ProjectPresentationProfile> _toProfileEntry(
    NarrativeUndoEntry<ProjectManifest> entry,
  ) {
    return NarrativeUndoEntry<ProjectPresentationProfile>(
      operationId: entry.operationId,
      label: entry.label,
      before: entry.before.effectivePresentation,
      after: entry.after.effectivePresentation,
    );
  }
}
