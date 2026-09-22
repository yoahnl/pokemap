import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';

typedef MapEntityRef = ({String mapId, String entityId});

class MapDraftReferenceSources {
  const MapDraftReferenceSources({
    this.eventDrafts = const [],
    this.ruleTargets = const [],
    this.interactionDrafts = const [],
  });
  final List<NarrativeEventRecord> eventDrafts;
  final List<MapEntityRef> ruleTargets;
  final List<MapEntityRef> interactionDrafts;

  List<Object?> get signature => [
    for (final record in eventDrafts) '${record.id}/${_sourceKey(record)}',
    for (final target in ruleTargets) '${target.mapId}/${target.entityId}',
    for (final draft in interactionDrafts) '${draft.mapId}/${draft.entityId}',
  ];

  Iterable<MapEntityRef> get targets sync* {
    for (final record in eventDrafts) {
      final source = record.draftOrNull?.source;
      if (source == null) continue;
      final target = _entityTarget(source.toJson());
      if (target != null) yield target;
    }
    yield* ruleTargets;
    yield* interactionDrafts;
  }
}

String _sourceKey(NarrativeEventRecord record) {
  final source = record.draftOrNull?.source;
  if (source == null) return 'none';
  final json = source.toJson();
  return '${json['mapId']}/${json['entityId']}/${json['triggerId']}';
}

MapEntityRef? _entityTarget(Map<String, dynamic> json) {
  final mapId = json['mapId'] as String?;
  final entityId = json['entityId'] as String?;
  return mapId == null || mapId.isEmpty || entityId == null || entityId.isEmpty
      ? null
      : (mapId: mapId, entityId: entityId);
}

String _key(String mapId, String entityId) => '$mapId$entityId';

/// Answers whether an unsaved draft still points at a map entity. The set is
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
      for (final target in sources.targets) _key(target.mapId, target.entityId),
    };
  }

  bool _sameSignature(List<Object?> next) {
    if (next.length != _signature.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != _signature[i]) return false;
    }
    return true;
  }

  String? problemFor({required String mapId, required String entityId}) {
    _refresh();
    return _blocked.contains(_key(mapId, entityId))
        ? 'Un brouillon en cours utilise cet élément. Enregistrez-le ou '
              'retirez sa liaison avant de le supprimer.'
        : null;
  }

  MapReferenceGuard get guard => problemFor;
}
