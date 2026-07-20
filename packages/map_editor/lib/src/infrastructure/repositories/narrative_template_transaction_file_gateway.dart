import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/services/narrative_template_catalog.dart';
import 'project_manifest_write_lock.dart';

/// Durable, compare-and-swap storage for an Event + Scene template mutation.
///
/// The journal is deliberately adjacent to `project.json`: recovery remains
/// possible before any editor state has been reconstructed.
final class NarrativeTemplateTransactionFileGateway
    implements NarrativeTemplateTransactionGateway {
  NarrativeTemplateTransactionFileGateway({required String projectPath})
      : projectPath = p.normalize(p.absolute(projectPath));

  final String projectPath;
  String? _expectedProjectRevision;

  String get journalPath => '$projectPath.narrative-template-journal.json';

  @override
  Future<ProjectManifest> readProject() async {
    final bytes = await File(projectPath).readAsBytes();
    _expectedProjectRevision = narrativeEventBytesFingerprint(bytes);
    return decodeValidatedNarrativeEventAuthoringProject(bytes).manifest;
  }

  @override
  Future<void> writeProject(ProjectManifest project) {
    return withProjectManifestWriteLock(projectPath, () async {
      final target = File(projectPath);
      final beforeBytes = await target.readAsBytes();
      final liveRevision = narrativeEventBytesFingerprint(beforeBytes);
      final expected = _expectedProjectRevision;
      if (expected != null && liveRevision != expected) {
        throw StateError(
          'Template write refused because project.json changed independently.',
        );
      }

      final currentRoot = _jsonObject(utf8.decode(beforeBytes));
      final serialized = _jsonObject(jsonEncode(project.toJson()));
      final nextRoot = Map<String, dynamic>.from(currentRoot)
        ..addAll(serialized);
      if (project.eventRegistry == null) nextRoot.remove('eventRegistry');
      final afterBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(nextRoot),
      );
      final projected =
          decodeValidatedNarrativeEventAuthoringProject(afterBytes).manifest;
      if (projected != project) {
        throw StateError('The durable template projection is not identical.');
      }

      final temp = File(
          '$projectPath.template-${DateTime.now().microsecondsSinceEpoch}.tmp');
      try {
        final handle = await temp.open(mode: FileMode.write);
        try {
          await handle.writeFrom(afterBytes);
          await handle.flush();
        } finally {
          await handle.close();
        }
        await temp.rename(projectPath);
      } finally {
        if (await temp.exists()) await temp.delete();
      }
      _expectedProjectRevision = narrativeEventBytesFingerprint(afterBytes);
    });
  }

  @override
  Future<NarrativeTemplateTransactionRecord?> readJournal() async {
    final file = File(journalPath);
    if (!await file.exists()) return null;
    return NarrativeTemplateTransactionRecord.fromJson(
      _jsonObject(await file.readAsString()),
    );
  }

  @override
  Future<void> writeJournal(
    NarrativeTemplateTransactionRecord record,
  ) async {
    final file = File(journalPath);
    await file.parent.create(recursive: true);
    final temp = File('$journalPath.tmp');
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(record.toJson()),
    );
    try {
      final handle = await temp.open(mode: FileMode.write);
      try {
        await handle.writeFrom(bytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      await temp.rename(file.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  @override
  Future<void> clearJournal() async {
    final file = File(journalPath);
    if (await file.exists()) await file.delete();
  }
}

Map<String, dynamic> _jsonObject(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) throw const FormatException('Expected a JSON object.');
  return Map<String, dynamic>.from(decoded);
}
