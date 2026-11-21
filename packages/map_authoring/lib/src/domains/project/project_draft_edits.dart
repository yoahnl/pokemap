import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';
import '../../transactions/plan_store.dart';

final class ProjectDraftEdits {
  ProjectDraftEdits._(this.name, this.documents);

  static const actionId = 'project.publish_draft';
  static const documentFields = {
    'facts',
    'worldRules',
    'scenes',
    'storylines',
    'shops',
    'environmentPresets',
  };

  final ({String before, String after})? name;
  final Map<String, Map<String, ProjectDraftDocumentEdit>> documents;

  bool get isEmpty => name == null && documents.isEmpty;

  Set<String> get fields => {
        if (name != null) 'name',
        ...documents.keys,
      };

  factory ProjectDraftEdits.fromParameters(Map<String, Object?> parameters) {
    if (parameters.keys.any((key) => key != 'name' && key != 'documents')) {
      throw const FormatException('Unexpected project draft parameter.');
    }
    final rawName = parameters['name'];
    ({String before, String after})? name;
    if (parameters.containsKey('name')) {
      if (rawName is! Map || rawName.length != 2 ||
          rawName['before'] is! String || rawName['after'] is! String) {
        throw const FormatException('Invalid project draft name.');
      }
      final after = rawName['after'] as String;
      if (after.trim().isEmpty || after != after.trim() ||
          RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(after)) {
        throw const FormatException('Invalid project draft name.');
      }
      name = (before: rawName['before'] as String, after: after);
    }
    final documents = <String, Map<String, ProjectDraftDocumentEdit>>{};
    final rawDocuments = parameters['documents'];
    if (parameters.containsKey('documents')) {
      if (rawDocuments is! Map) {
        throw const FormatException('Invalid project draft documents.');
      }
      for (final entry in rawDocuments.entries) {
        final field = entry.key;
        final values = entry.value;
        if (field is! String ||
            !(documentFields.contains(field) || field == 'borderCatalog') ||
            values is! Map || values.isEmpty) {
          throw const FormatException('Invalid project draft document section.');
        }
        documents[field] = {
          for (final edit in values.entries)
            _documentId(edit.key): ProjectDraftDocumentEdit.fromJson(
              _documentId(edit.key),
              edit.value,
            ),
        };
      }
    }
    final edits = ProjectDraftEdits._(name, documents);
    if (edits.isEmpty) throw const FormatException('The project draft is empty.');
    return edits;
  }

  factory ProjectDraftEdits.between(
    ProjectManifest previous,
    ProjectManifest draft,
  ) {
    final scoped = previous.copyWith(
      name: draft.name,
      facts: draft.facts,
      worldRules: draft.worldRules,
      scenes: draft.scenes,
      storylines: draft.storylines,
      shops: draft.shops,
      environmentPresets: draft.environmentPresets,
      borderCatalog: draft.borderCatalog,
    );
    if (scoped != draft) {
      throw const FormatException('The project draft changes a protected section.');
    }
    final documents = <String, Map<String, ProjectDraftDocumentEdit>>{};
    void collect<T>(String field, List<T> before, List<T> after,
        String Function(T) identity, Map<String, dynamic> Function(T) encode) {
      if (identical(before, after)) return;
      final old = {for (final value in before) identity(value): value};
      final next = {for (final value in after) identity(value): value};
      final edits = <String, ProjectDraftDocumentEdit>{};
      for (final id in {...old.keys, ...next.keys}) {
        final previous = old[id];
        final current = next[id];
        if (previous != current) {
          edits[id] = ProjectDraftDocumentEdit._(
              previous == null ? null : encode(previous),
              current == null ? null : encode(current));
        }
      }
      if (edits.isNotEmpty) documents[field] = edits;
    }

    collect('facts', previous.facts, draft.facts, (v) => v.id, (v) => v.toJson());
    collect('worldRules', previous.worldRules, draft.worldRules, (v) => v.id,
        (v) => v.toJson());
    collect('scenes', previous.scenes, draft.scenes, (v) => v.id, (v) => v.toJson());
    collect('storylines', previous.storylines, draft.storylines, (v) => v.id,
        (v) => v.toJson());
    collect('shops', previous.shops, draft.shops, (v) => v.id, (v) => v.toJson());
    collect('environmentPresets', previous.environmentPresets,
        draft.environmentPresets, (v) => v.id, (v) => v.toJson());
    if (previous.borderCatalog != draft.borderCatalog) {
      final old = previous.borderCatalog;
      final next = draft.borderCatalog;
      if (old.formatVersion != next.formatVersion ||
          old.visualSnapshots != next.visualSnapshots) {
        throw const FormatException('The project draft changes published Borders.');
      }
      collect('borderCatalog', old.records, next.records, (v) => v.id,
          (v) => encodeBorderBlueprintRecordJson(v, formatVersion: old.formatVersion));
    }
    return ProjectDraftEdits._(
      previous.name == draft.name ? null : (before: previous.name, after: draft.name),
      documents,
    );
  }

  Map<String, Object?> toParameters() => {
        if (name case final change?)
          'name': {'before': change.before, 'after': change.after},
        if (documents.isNotEmpty)
          'documents': {
            for (final section in documents.entries)
              section.key: {
                for (final edit in section.value.entries)
                  edit.key: edit.value.toJson(),
              },
          },
      };

  ProjectManifest apply(ProjectManifest previous) {
    final json = previous.toJson();
    if (name case final change?) {
      if (previous.name != change.before) _stale();
      json['name'] = change.after;
    }
    for (final section in documents.entries) {
      final field = section.key;
      if (field == 'borderCatalog') {
        final raw = Map<String, dynamic>.from(json[field] as Map? ?? const {});
        raw['records'] = _edit(field, raw['records'], section.value);
        json[field] = raw;
      } else {
        json[field] = _edit(field, json[field], section.value);
      }
    }
    return ProjectManifest.fromJson(json);
  }

  List<Object?> _edit(String field, Object? input,
      Map<String, ProjectDraftDocumentEdit> edits) {
    final result = <Object?>[];
    final seen = <String>{};
    for (final value in input as List? ?? const []) {
      final id = (value as Map)['id'];
      final edit = edits[id];
      if (edit == null) {
        result.add(value);
        continue;
      }
      if (!seen.add(id as String) || !_same(value, edit.before)) _stale();
      if (field == 'borderCatalog' &&
          !_same(value['latestPublished'], edit.after?['latestPublished'])) {
        throw const FormatException('The project draft changes published Borders.');
      }
      if (edit.after != null) result.add(edit.after);
    }
    for (final entry in edits.entries) {
      if (seen.contains(entry.key)) continue;
      if (entry.value.before != null) _stale();
      if (field == 'borderCatalog' && entry.value.after?['latestPublished'] != null) {
        throw const FormatException('The project draft changes published Borders.');
      }
      if (entry.value.after != null) result.add(entry.value.after);
    }
    return result;
  }

  static Never _stale() => throw const AuthoringPlanException(
        code: 'plan.stale',
        message: 'Le projet a été modifié depuis la création du brouillon.',
      );
}

final class ProjectDraftDocumentEdit {
  const ProjectDraftDocumentEdit._(this.before, this.after);

  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  factory ProjectDraftDocumentEdit.fromJson(String id, Object? value) {
    if (value is! Map || value.length != 2 ||
        !value.containsKey('before') || !value.containsKey('after')) {
      throw const FormatException('Invalid project draft document edit.');
    }
    Map<String, dynamic>? document(Object? raw) {
      if (raw == null) return null;
      if (raw is! Map || raw['id'] != id) {
        throw const FormatException('Invalid project draft document identity.');
      }
      return Map<String, dynamic>.from(raw);
    }
    final before = document(value['before']);
    final after = document(value['after']);
    if (_same(before, after)) {
      throw const FormatException('A project draft edit must change a document.');
    }
    return ProjectDraftDocumentEdit._(before, after);
  }

  Map<String, Object?> toJson() => {'before': before, 'after': after};
}

bool _same(Object? a, Object? b) =>
    canonicalAuthoringJson(a) == canonicalAuthoringJson(b);

String _documentId(Object? id) => id is String && id.isNotEmpty && id.trim() == id
    ? id
    : (throw const FormatException('Invalid project draft document identity.'));
