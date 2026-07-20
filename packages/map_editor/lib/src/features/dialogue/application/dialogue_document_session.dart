import '../../../application/services/narrative_document_session.dart';
import 'dialogue_editor_model.dart';
import 'dialogue_yarn_codec.dart';

typedef DialogueSourceLoader = Future<String> Function();
typedef DialogueSourcePersister = Future<void> Function(String yarn);

/// Dialogue-specific facade over the shared NSC-13 document session.
///
/// The session deliberately stores Yarn snapshots rather than mutable editor
/// nodes. This gives undo/redo, recovery and compare-and-swap stable value
/// semantics while the UI continues to manipulate a structured document.
final class DialogueDocumentSession {
  DialogueDocumentSession({
    required String dialogueId,
    required String initialYarn,
    required DialogueSourceLoader load,
    required DialogueSourcePersister persist,
    NarrativeDocumentRecoveryStore<String>? recoveryStore,
    bool autosaveEnabled = false,
    Duration autosaveDelay = const Duration(seconds: 3),
    NarrativeDocumentAutosaveScheduler? autosaveScheduler,
  }) : _session = NarrativeDocumentSession<String>(
          documentId: dialogueId,
          initialDocument: initialYarn,
          gateway: DialogueSourceGateway(load: load, persist: persist),
          recoveryStore: recoveryStore ?? InMemoryDialogueRecoveryStore(),
          autosaveEnabled: autosaveEnabled,
          autosaveDelay: autosaveDelay,
          autosaveScheduler: autosaveScheduler,
        );

  final NarrativeDocumentSession<String> _session;

  NarrativeDocumentSessionState<String> get state => _session.state;
  DialogueEditorDocument get document => parseYarnToDocument(state.document);

  void addListener(void Function() listener) => _session.addListener(listener);
  void removeListener(void Function() listener) =>
      _session.removeListener(listener);

  Future<void> initialize() => _session.initialize();

  Future<bool> apply({
    required String operationId,
    required String label,
    required DialogueEditorDocument document,
  }) {
    return _session.apply(
      operationId: operationId,
      label: label,
      document: emitDocumentToYarn(document),
    );
  }

  Future<bool> undo() => _session.undo();
  Future<bool> redo() => _session.redo();
  Future<bool> save({required String operationId}) =>
      _session.save(operationId: operationId);
  void setAutosaveEnabled(bool enabled) => _session.setAutosaveEnabled(enabled);
  void dispose() => _session.dispose();
}

/// Compare-and-swap adapter for the actual `.yarn` source.
final class DialogueSourceGateway implements NarrativeDocumentGateway<String> {
  DialogueSourceGateway({required this.load, required this.persist});

  final DialogueSourceLoader load;
  final DialogueSourcePersister persist;

  @override
  Future<NarrativeDocumentVersion<String>> read() async {
    final source = await load();
    return NarrativeDocumentVersion<String>(
      revision: _dialogueRevision(source),
      document: source,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<String>> save({
    required String expectedRevision,
    required String before,
    required String after,
    required String operationId,
  }) async {
    final external = await read();
    if (external.revision != expectedRevision || external.document != before) {
      return NarrativeDocumentSaveResult<String>.conflicted(
        code: 'dialogueExternalRevisionConflict',
        message: 'Le fichier Yarn a changé depuis son ouverture.',
        external: external,
      );
    }
    try {
      await persist(after);
      final durable = await read();
      if (durable.document != after) {
        return const NarrativeDocumentSaveResult<String>.failed(
          code: 'dialogueDurableWriteMismatch',
          message: 'Le fichier relu ne correspond pas au dialogue demandé.',
        );
      }
      return NarrativeDocumentSaveResult<String>.saved(durable);
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<String>.failed(
        code: 'dialogueWriteFailed',
        message: 'Échec de l’écriture Yarn : $error',
      );
    }
  }
}

/// Session-lifetime recovery store used by the workspace.
///
/// The shared session contract remains injectable, so a durable sidecar can be
/// supplied by a host without changing Dialogue Studio.
final class InMemoryDialogueRecoveryStore
    implements NarrativeDocumentRecoveryStore<String> {
  NarrativeDocumentRecoveryRecord<String>? _record;

  @override
  Future<void> clear() async => _record = null;

  @override
  Future<NarrativeDocumentRecoveryRecord<String>?> read() async => _record;

  @override
  Future<void> write(
    NarrativeDocumentRecoveryRecord<String> record,
  ) async {
    _record = record;
  }
}

String _dialogueRevision(String source) {
  var hash = 0xcbf29ce484222325;
  for (final unit in source.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return 'yarn-${source.length}-${hash.toRadixString(16)}';
}
