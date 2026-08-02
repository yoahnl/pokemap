import 'dart:async';

import '../../editor_updates/domain/editor_exit_readiness.dart';

enum EditorUnsavedWorkSaveOutcome {
  saved,
  cancelled,
  failed,
  unsupported,
}

abstract interface class EditorUnsavedWorkParticipant {
  String get id;
  EditorExitBlockerKind get kind;
  bool get isDirty;

  Future<EditorUnsavedWorkSaveOutcome> save();
}

final class EditorUnsavedWorkRegistry {
  final Map<String, EditorUnsavedWorkParticipant> _participants = {};
  final StreamController<void> _changes =
      StreamController<void>.broadcast(sync: true);

  Stream<void> get changes => _changes.stream;

  List<EditorUnsavedWorkParticipant> get participants =>
      List.unmodifiable(_participants.values);

  EditorExitReadiness get readiness => resolveReadiness();

  void register(EditorUnsavedWorkParticipant participant) {
    if (_participants.containsKey(participant.id)) {
      throw StateError(
        'An unsaved-work participant with id "${participant.id}" is already registered.',
      );
    }
    _participants[participant.id] = participant;
    _notify();
  }

  void unregister(String participantId) {
    final participant = _participants[participantId];
    if (participant == null) {
      return;
    }
    if (participant.isDirty) {
      throw StateError(
        'Dirty participant "$participantId" must be saved or discarded before unregistering.',
      );
    }
    _participants.remove(participantId);
    _notify();
  }

  void notifyChanged() {
    _notify();
  }

  EditorExitReadiness resolveReadiness({
    Iterable<EditorExitBlocker> globalBlockers = const [],
  }) {
    final blockers = <EditorExitBlocker>[
      ...globalBlockers,
      for (final participant in _participants.values)
        if (participant.isDirty)
          EditorExitBlocker(
            id: participant.id,
            kind: participant.kind,
          ),
    ];
    return EditorExitReadiness.fromBlockers(blockers);
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
