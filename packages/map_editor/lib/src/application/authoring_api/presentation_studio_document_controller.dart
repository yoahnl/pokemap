import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import 'presentation_studio_draft_authoring_gateway.dart';

enum PresentationStudioDocumentStatus { opening, saved, dirty, saving, failed }

typedef PresentationStudioRecoveryApplier =
    Future<bool> Function(
      ProjectManifest manifest, {
      required String operationId,
      required String label,
    });

typedef PresentationStudioDocumentAction = Future<bool> Function();

final class PresentationStudioDocumentController extends ChangeNotifier {
  PresentationStudioDocumentController({
    required PresentationStudioDraftAuthoringGateway draftGateway,
    required PresentationStudioRecoveryApplier applyRecovery,
    required PresentationStudioDocumentAction saveDurably,
    required PresentationStudioDocumentAction discardDraft,
  }) : _draftGateway = draftGateway,
       _applyRecovery = applyRecovery,
       _saveDurably = saveDurably,
       _discardDraft = discardDraft;

  final PresentationStudioDraftAuthoringGateway _draftGateway;
  final PresentationStudioRecoveryApplier _applyRecovery;
  final PresentationStudioDocumentAction _saveDurably;
  final PresentationStudioDocumentAction _discardDraft;

  PresentationCinematicDraft? _draft;
  ProjectManifest? _manifest;
  ProjectManifest? _baseline;
  String? _projectRootPath;
  PresentationStudioDocumentStatus _status =
      PresentationStudioDocumentStatus.opening;
  _PendingRecovery? _pendingRecovery;
  Future<bool>? _activeRecovery;
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;

  PresentationStudioDocumentStatus get status => _status;
  ProjectManifest get manifest =>
      _manifest ?? (throw StateError('Presentation draft is not open.'));
  ProjectManifest get durableBaseline =>
      _baseline ?? (throw StateError('Presentation draft is not open.'));
  bool get isOpen => _draft != null;
  bool get isDirty =>
      _status == PresentationStudioDocumentStatus.dirty ||
      _status == PresentationStudioDocumentStatus.failed;
  bool get isSaving => _status == PresentationStudioDocumentStatus.saving;
  bool get recoveryPending =>
      _pendingRecovery != null || _activeRecovery != null;
  String? get errorMessage => _errorMessage;

  Future<bool> open(
    String projectRootPath, {
    required ProjectManifest expectedProject,
  }) async {
    final generation = ++_generation;
    _projectRootPath = projectRootPath;
    _baseline = expectedProject;
    _manifest = expectedProject;
    _draft = null;
    _pendingRecovery = null;
    _errorMessage = null;
    _setStatus(PresentationStudioDocumentStatus.opening);
    try {
      final draft = await _draftGateway.open(
        projectRootPath,
        expectedProject: expectedProject,
      );
      if (!_canAdopt(generation)) return false;
      _draft = draft;
      _manifest = draft.manifest;
      _setStatus(PresentationStudioDocumentStatus.saved);
      return true;
    } on Object catch (error) {
      if (_canAdopt(generation)) {
        _errorMessage = error.toString();
        _setStatus(PresentationStudioDocumentStatus.failed);
      }
      return false;
    }
  }

  bool apply({
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationId,
    required String label,
  }) {
    final draft = _draft;
    if (draft == null || _disposed || isSaving) return false;
    try {
      final projected = draft.apply(
        actionId: actionId,
        parameters: parameters,
        operationId: operationId,
      );
      _manifest = projected;
      _pendingRecovery = _PendingRecovery(
        manifest: projected,
        operationId: operationId,
        label: label,
      );
      _errorMessage = null;
      _setStatus(PresentationStudioDocumentStatus.dirty);
      unawaited(_ensureRecoveryDrain());
      return true;
    } on Object catch (error) {
      _errorMessage = error.toString();
      _setStatus(PresentationStudioDocumentStatus.failed);
      return false;
    }
  }

  Future<bool> flushRecovery() async {
    while (!_disposed) {
      final active = _activeRecovery;
      if (active != null) {
        if (!await active) return false;
        continue;
      }
      if (_pendingRecovery == null) return true;
      if (!await _ensureRecoveryDrain()) return false;
    }
    return false;
  }

  Future<bool> save() async {
    if (_disposed || !isOpen || isSaving) return false;
    if (!await flushRecovery()) return false;
    _setStatus(PresentationStudioDocumentStatus.saving);
    try {
      final saved = await _saveDurably();
      if (_disposed) return false;
      if (!saved) {
        _errorMessage = 'La sauvegarde durable a échoué.';
        _setStatus(PresentationStudioDocumentStatus.failed);
        return false;
      }
      _baseline = _manifest;
      _errorMessage = null;
      _setStatus(PresentationStudioDocumentStatus.saved);
      return true;
    } on Object catch (error) {
      if (!_disposed) {
        _errorMessage = error.toString();
        _setStatus(PresentationStudioDocumentStatus.failed);
      }
      return false;
    }
  }

  Future<bool> discard() async {
    if (_disposed || !isOpen || isSaving) return false;
    ++_generation;
    _pendingRecovery = null;
    final discarded = await _discardDraft();
    if (_disposed || !discarded) return false;
    final baseline = _baseline;
    final projectRootPath = _projectRootPath;
    if (baseline == null || projectRootPath == null) return false;
    return open(projectRootPath, expectedProject: baseline);
  }

  bool adoptSessionManifest(ProjectManifest manifest, {required bool isDirty}) {
    final draft = _draft;
    if (draft == null || _disposed || isSaving) return false;
    try {
      _manifest = draft.adopt(manifest);
      _pendingRecovery = null;
      _errorMessage = null;
      _setStatus(
        isDirty
            ? PresentationStudioDocumentStatus.dirty
            : PresentationStudioDocumentStatus.saved,
      );
      return true;
    } on Object catch (error) {
      _errorMessage = error.toString();
      _setStatus(PresentationStudioDocumentStatus.failed);
      return false;
    }
  }

  Future<bool> refreshResources() async {
    final projectRootPath = _projectRootPath;
    final currentManifest = _manifest;
    if (_disposed ||
        _draft == null ||
        projectRootPath == null ||
        currentManifest == null ||
        isSaving ||
        !await flushRecovery()) {
      return false;
    }
    final generation = _generation;
    final previousStatus = _status;
    try {
      final refreshed = await _draftGateway.open(
        projectRootPath,
        expectedProject: currentManifest,
      );
      if (!_canAdopt(generation)) return false;
      _draft = refreshed;
      _manifest = refreshed.manifest;
      _errorMessage = null;
      _setStatus(
        previousStatus == PresentationStudioDocumentStatus.failed
            ? PresentationStudioDocumentStatus.dirty
            : previousStatus,
      );
      return true;
    } on Object catch (error) {
      if (_canAdopt(generation)) {
        _errorMessage = error.toString();
        _setStatus(PresentationStudioDocumentStatus.failed);
      }
      return false;
    }
  }

  Future<bool> _ensureRecoveryDrain() {
    final active = _activeRecovery;
    if (active != null) return active;
    final generation = _generation;
    final operation = _drainRecovery(generation);
    _activeRecovery = operation;
    operation.whenComplete(() {
      if (identical(_activeRecovery, operation)) {
        _activeRecovery = null;
      }
    });
    return operation;
  }

  Future<bool> _drainRecovery(int generation) async {
    while (_canAdopt(generation)) {
      final pending = _pendingRecovery;
      if (pending == null) return true;
      _pendingRecovery = null;
      bool applied;
      try {
        applied = await _applyRecovery(
          pending.manifest,
          operationId: pending.operationId,
          label: pending.label,
        );
      } on Object catch (error) {
        if (_canAdopt(generation)) {
          _pendingRecovery ??= pending;
          _errorMessage = error.toString();
          _setStatus(PresentationStudioDocumentStatus.failed);
        }
        return false;
      }
      if (!_canAdopt(generation)) return false;
      if (!applied) {
        _pendingRecovery ??= pending;
        _errorMessage = 'Le brouillon local n’a pas pu être sécurisé.';
        _setStatus(PresentationStudioDocumentStatus.failed);
        return false;
      }
    }
    return false;
  }

  bool _canAdopt(int generation) => !_disposed && generation == _generation;

  void _setStatus(PresentationStudioDocumentStatus status) {
    _status = status;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _pendingRecovery = null;
    super.dispose();
  }
}

final class _PendingRecovery {
  const _PendingRecovery({
    required this.manifest,
    required this.operationId,
    required this.label,
  });

  final ProjectManifest manifest;
  final String operationId;
  final String label;
}
