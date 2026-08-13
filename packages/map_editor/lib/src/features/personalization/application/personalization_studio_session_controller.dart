import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../../application/services/narrative_document_session.dart';

/// Personalization-specific projection of the shared crash-safe document
/// session.
@immutable
final class PersonalizationStudioSessionState {
  const PersonalizationStudioSessionState({
    required this.document,
    required this.savedDocument,
    required this.status,
    required this.isInitialized,
    required this.isDirty,
    required this.canUndo,
    required this.canRedo,
    required this.autosaveEnabled,
    this.code,
    this.message,
  });

  factory PersonalizationStudioSessionState.fromDocumentState(
    NarrativeDocumentSessionState<ProjectPresentationProfile> state,
    ProjectManifest project,
  ) {
    return PersonalizationStudioSessionState(
      document: _projectWithProfile(project, state.document),
      savedDocument: _projectWithProfile(project, state.baseline),
      status: state.status,
      isInitialized: state.isInitialized,
      isDirty: state.isDirty,
      canUndo: state.canUndo,
      canRedo: state.canRedo,
      autosaveEnabled: state.autosaveEnabled,
      code: state.code,
      message: state.message,
    );
  }

  final ProjectManifest document;
  final ProjectManifest savedDocument;
  final NarrativeDocumentSessionStatus status;
  final bool isInitialized;
  final bool isDirty;
  final bool canUndo;
  final bool canRedo;
  final bool autosaveEnabled;
  final String? code;
  final String? message;

  ProjectPresentationProfile get draftProfile => document.effectivePresentation;

  ProjectPresentationProfile get savedProfile =>
      savedDocument.effectivePresentation;

  bool get isSaving => status == NarrativeDocumentSessionStatus.saving;
  bool get isRecovered => status == NarrativeDocumentSessionStatus.recovered;
  bool get isConflicted => status == NarrativeDocumentSessionStatus.conflicted;
  bool get hasFailed => status == NarrativeDocumentSessionStatus.failed;
}

/// Owns one Personalization Studio draft for one open project.
///
/// Every accepted edit is journaled by [NarrativeDocumentSession] before it is
/// published. Durable save and history commands are exposed in later Studio
/// lots without duplicating that safety-critical state machine.
final class PersonalizationStudioSessionController extends ChangeNotifier {
  PersonalizationStudioSessionController({
    required NarrativeDocumentSession<ProjectPresentationProfile> session,
    required ProjectManifest initialProject,
    ProjectManifest Function()? projectSnapshot,
  }) : _session = session,
       _project = initialProject,
       _durableProject = initialProject,
       _projectSnapshot = projectSnapshot {
    _session.setPersistenceGuard(_persistenceIssueFor);
    _session.addListener(_onSessionChanged);
  }

  final NarrativeDocumentSession<ProjectPresentationProfile> _session;
  final ProjectManifest Function()? _projectSnapshot;
  ProjectManifest _project;
  ProjectManifest _durableProject;
  bool _disposed = false;
  int _conflictResolutionSequence = 0;

  PersonalizationStudioSessionState get state =>
      PersonalizationStudioSessionState.fromDocumentState(
        _session.state,
        _project,
      );

  Future<void> initialize() async {
    await _session.initialize();
    _synchronizeProject();
    final comparison = _session.comparison;
    if (_session.state.status != NarrativeDocumentSessionStatus.conflicted ||
        comparison == null ||
        comparison.baseline != comparison.external) {
      return;
    }
    await keepDraftOnCurrentProject();
  }

  Future<bool> applyProfile(
    ProjectPresentationProfile profile, {
    required String operationId,
    required String label,
  }) {
    return _session.apply(
      operationId: operationId,
      label: label,
      document: profile,
    );
  }

  Future<bool> save({required String operationId}) {
    return _session.save(operationId: operationId);
  }

  Future<bool> undo() => _session.undo();

  Future<bool> redo() => _session.redo();

  bool get hasPendingProjectChanges =>
      !_sameProjectOutsidePresentation(_project, _durableProject);

  bool adoptProjectSnapshot(ProjectManifest project) {
    if (project.effectivePresentation != state.savedProfile) {
      return false;
    }
    _project = project;
    _session.reevaluatePersistenceGuard();
    return true;
  }

  Future<bool> refreshCurrentProject() => _session.refreshBaseline();

  Future<bool> keepDraftOnCurrentProject() {
    final sequence = ++_conflictResolutionSequence;
    return _session.rebaseConflict(
      merge: (local, external) => local,
      operationId: 'personalization_conflict_keep_$sequence',
      label: 'Restaurer les derniers réglages visuels',
    );
  }

  Future<bool> useCurrentProject() => _session.discard();

  void setAutosaveEnabled(bool enabled) {
    _session.setAutosaveEnabled(enabled);
  }

  static String? _persistenceIssue(ProjectPresentationProfile document) {
    final errors = validateProjectPresentationProfile(document).where(
      (diagnostic) =>
          diagnostic.severity == ProjectPresentationDiagnosticSeverity.error,
    );
    if (errors.isEmpty) return null;
    return 'Sauvegarde bloquée : ${errors.first.message}';
  }

  String? _persistenceIssueFor(ProjectPresentationProfile document) {
    final validationIssue = _persistenceIssue(document);
    if (validationIssue != null) return validationIssue;
    if (hasPendingProjectChanges) {
      return 'Sauvegarde automatique suspendue pendant l’enregistrement des '
          'autres modifications du projet.';
    }
    return null;
  }

  void _onSessionChanged() {
    if (_disposed) return;
    _synchronizeProject();
    notifyListeners();
  }

  void _synchronizeProject() {
    final snapshot = _projectSnapshot;
    if (snapshot != null) {
      final hasLocalProjectChanges = !_sameProjectOutsidePresentation(
        _project,
        _durableProject,
      );
      _durableProject = snapshot();
      if (!hasLocalProjectChanges) {
        _project = _durableProject;
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }
}

ProjectManifest _projectWithProfile(
  ProjectManifest project,
  ProjectPresentationProfile profile,
) {
  if (profile == project.effectivePresentation) return project;
  return project.copyWith(presentation: profile);
}

bool _sameProjectOutsidePresentation(
  ProjectManifest left,
  ProjectManifest right,
) {
  return left.copyWith(presentation: right.presentation) == right;
}
