import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../application/services/narrative_activity_journal.dart';

/// Atomic, project-local persistence for Narrative Studio authoring activity.
final class NarrativeActivityJournalRepository
    implements NarrativeActivityJournalStore {
  NarrativeActivityJournalRepository({required String projectRootPath})
      : _journal = File(
          p.join(
            _requiredPath(projectRootPath),
            '.pokemap',
            'narrative',
            'activity-journal.json',
          ),
        );

  final File _journal;
  Future<void> _writeTail = Future<void>.value();

  String get journalPath => _journal.path;

  @override
  Future<NarrativeActivityJournal> load() async {
    if (!await _journal.exists()) {
      return const NarrativeActivityJournal.empty();
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await _journal.readAsString());
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        'Narrative activity journal cannot be decoded: $error',
      );
    }
    return NarrativeActivityJournal.fromJson(decoded);
  }

  @override
  Future<void> save(NarrativeActivityJournal journal) {
    final next = _writeTail.then<void>(
      (_) => _write(journal),
      onError: (_) => _write(journal),
    );
    _writeTail = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _write(NarrativeActivityJournal journal) async {
    final temp = File('${_journal.path}.tmp');
    await _journal.parent.create(recursive: true);
    final bytes = utf8.encode(jsonEncode(journal.toJson()));
    final handle = await temp.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }

    try {
      final verification = jsonDecode(await temp.readAsString());
      NarrativeActivityJournal.fromJson(verification);
      await temp.rename(_journal.path);
    } on Object {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }
}

String _requiredPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    throw ArgumentError.value(value, 'projectRootPath', 'must not be empty');
  }
  return p.normalize(p.absolute(path));
}
