import 'package:map_authoring/map_authoring.dart';

import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/authoring_session_lifecycle.dart';

enum PersonalizationPreviewContextKind {
  map,
  dialogue,
  characterPortrait,
  encounter,
}

final class PersonalizationPreviewContextOption {
  PersonalizationPreviewContextOption({
    required this.id,
    required this.kind,
    required this.sourceId,
    required this.label,
    required this.availability,
    required Iterable<String> diagnosticCodes,
    required Map<String, Object?> detail,
  }) : diagnosticCodes = List.unmodifiable(diagnosticCodes),
       detail = Map.unmodifiable(detail);

  factory PersonalizationPreviewContextOption.fromJson(
    Map<String, Object?> json,
  ) {
    final kindName = json['contextKind'];
    final kind = PersonalizationPreviewContextKind.values
        .where((candidate) => candidate.name == kindName)
        .firstOrNull;
    final id = json['id'];
    final sourceId = json['sourceId'];
    final label = json['name'];
    final availability = json['availability'];
    final diagnosticCodes = json['diagnosticCodes'];
    if (kind == null ||
        id is! String ||
        sourceId is! String ||
        label is! String ||
        availability is! String ||
        diagnosticCodes is! List) {
      throw const FormatException(
        'Invalid presentation preview context resource.',
      );
    }
    return PersonalizationPreviewContextOption(
      id: id,
      kind: kind,
      sourceId: sourceId,
      label: label,
      availability: availability,
      diagnosticCodes: diagnosticCodes.cast<String>(),
      detail: json,
    );
  }

  final String id;
  final PersonalizationPreviewContextKind kind;
  final String sourceId;
  final String label;
  final String availability;
  final List<String> diagnosticCodes;
  final Map<String, Object?> detail;

  bool get isReady => availability == 'ready';
}

abstract interface class PersonalizationPreviewContextSource {
  Future<List<PersonalizationPreviewContextOption>> load(String projectRoot);
}

final class AuthoringPersonalizationPreviewContextSource
    implements PersonalizationPreviewContextSource {
  const AuthoringPersonalizationPreviewContextSource({
    required AuthoringQueryAdapter queries,
  }) : _queries = queries;

  final AuthoringQueryAdapter _queries;

  @override
  Future<List<PersonalizationPreviewContextOption>> load(
    String projectRoot,
  ) async {
    final session = await _queries.open(projectRoot);
    final contexts = <PersonalizationPreviewContextOption>[];
    String? cursor;
    String? revision;
    do {
      final page = session.query(
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 100,
          cursor: cursor,
        ),
      );
      final pageRevision = page['snapshotRevision'];
      final rawItems = page['items'];
      if (pageRevision is! String || rawItems is! List) {
        throw const FormatException(
          'Invalid presentation preview context page.',
        );
      }
      revision ??= pageRevision;
      if (revision != pageRevision) {
        throw EditorAuthoringStaleSessionException();
      }
      contexts.addAll(
        rawItems.map(
          (raw) => PersonalizationPreviewContextOption.fromJson(
            Map<String, Object?>.from(raw! as Map),
          ),
        ),
      );
      cursor = page['nextCursor'] as String?;
    } while (cursor != null);
    return List.unmodifiable(contexts);
  }
}
