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
    NarrativeDocumentSessionState<ProjectManifest> state,
  ) {
    return PersonalizationStudioSessionState(
      document: state.document,
      savedDocument: state.baseline,
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
    required NarrativeDocumentSession<ProjectManifest> session,
  }) : _session = session {
    _session.setPersistenceGuard(_persistenceIssue);
    _session.addListener(_onSessionChanged);
  }

  final NarrativeDocumentSession<ProjectManifest> _session;
  bool _disposed = false;

  PersonalizationStudioSessionState get state =>
      PersonalizationStudioSessionState.fromDocumentState(_session.state);

  Future<void> initialize() => _session.initialize();

  Future<bool> applyProfile(
    ProjectPresentationProfile profile, {
    required String operationId,
    required String label,
  }) {
    return _session.apply(
      operationId: operationId,
      label: label,
      document: _session.state.document.copyWith(presentation: profile),
    );
  }

  Future<bool> save({required String operationId}) {
    return _session.save(operationId: operationId);
  }

  Future<bool> undo() => _session.undo();

  Future<bool> redo() => _session.redo();

  void setAutosaveEnabled(bool enabled) {
    _session.setAutosaveEnabled(enabled);
  }

  static String? _persistenceIssue(ProjectManifest document) {
    final errors =
        validateProjectPresentationProfile(
          document.effectivePresentation,
        ).where(
          (diagnostic) =>
              diagnostic.severity ==
              ProjectPresentationDiagnosticSeverity.error,
        );
    if (errors.isEmpty) return null;
    return 'Sauvegarde bloquée : ${errors.first.message}';
  }

  void _onSessionChanged() {
    if (!_disposed) notifyListeners();
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
