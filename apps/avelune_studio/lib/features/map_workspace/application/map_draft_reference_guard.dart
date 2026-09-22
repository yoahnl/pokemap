import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';

enum MapDraftReferenceKind { entity, trigger }

typedef MapDraftReference = ({
  String mapId,
  MapDraftReferenceKind kind,
  String id,
});

class MapDraftReferenceSources {
  const MapDraftReferenceSources({
    this.eventDrafts = const [],
    this.ruleTargets = const [],
    this.interactionDrafts = const [],
  });

  /// Records with unsaved work, whatever their business shape: a configured
  /// record keeps its source in the definition, a draft one in the draft.
  final List<NarrativeEventRecord> eventDrafts;
  final List<MapDraftReference> ruleTargets;
  final List<MapDraftReference> interactionDrafts;

  List<Object?> get signature => [
    for (final record in eventDrafts) '${record.id}/${_sourceKey(record)}',
    for (final target in ruleTargets)
      '${target.mapId}/${target.kind.name}/${target.id}',
    for (final draft in interactionDrafts)
      '${draft.mapId}/${draft.kind.name}/${draft.id}',
  ];

  Iterable<MapDraftReference> get references sync* {
    for (final record in eventDrafts) {
      final reference = _referenceOf(recordSource(record));
      if (reference != null) yield reference;
    }
    yield* ruleTargets;
    yield* interactionDrafts;
  }
}

/// The source of a record, wherever its current shape keeps it.
NarrativeEventSourceRef? recordSource(NarrativeEventRecord record) =>
    record.draftOrNull?.source ?? record.definitionOrNull?.source;

String _sourceKey(NarrativeEventRecord record) {
  final source = recordSource(record);
  if (source == null) return 'none';
  final json = source.toJson();
  return '${json['mapId']}/${json['entityId']}/${json['triggerId']}';
}

MapDraftReference? _referenceOf(NarrativeEventSourceRef? source) {
  if (source == null) return null;
  final json = source.toJson();
  final mapId = json['mapId'] as String?;
  if (mapId == null || mapId.isEmpty) return null;
  final entityId = json['entityId'] as String?;
  if (entityId != null && entityId.isNotEmpty) {
    return (mapId: mapId, kind: MapDraftReferenceKind.entity, id: entityId);
  }
  final triggerId = json['triggerId'] as String?;
  return triggerId == null || triggerId.isEmpty
      ? null
      : (mapId: mapId, kind: MapDraftReferenceKind.trigger, id: triggerId);
}

String _key(String mapId, MapDraftReferenceKind kind, String id) =>
    '$mapId${kind.name}$id';

/// Answers whether an unsaved draft still points at a map element. The set is
/// rebuilt only when the drafts themselves change, never on every build.
class MapDraftReferenceIndex {
  MapDraftReferenceIndex(this._read);
  final MapDraftReferenceSources Function() _read;
  List<Object?> _signature = const [];
  Set<String> _blocked = const {};
  bool _primed = false;

  void _refresh() {
    final sources = _read();
    final signature = sources.signature;
    if (_primed && _sameSignature(signature)) return;
    _primed = true;
    _signature = signature;
    _blocked = {
      for (final reference in sources.references)
        _key(reference.mapId, reference.kind, reference.id),
    };
  }

  bool _sameSignature(List<Object?> next) {
    if (next.length != _signature.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != _signature[i]) return false;
    }
    return true;
  }

  String? problemFor({
    required String mapId,
    required String entityId,
    MapDraftReferenceKind kind = MapDraftReferenceKind.entity,
  }) {
    _refresh();
    return _blocked.contains(_key(mapId, kind, entityId))
        ? 'Un brouillon en cours utilise cet élément. Enregistrez-le ou '
              'retirez sa liaison avant de le supprimer.'
        : null;
  }

  MapReferenceGuard get guard => problemFor;
}
