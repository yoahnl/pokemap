import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';

enum MapDraftReferenceKind { entity, trigger }

typedef MapDraftReference = ({
  String mapId,
  MapDraftReferenceKind kind,
  String id,
});

class MapDraftReferenceSources {
  const MapDraftReferenceSources({this.ruleTargets = const []});

  final List<MapDraftReference> ruleTargets;

  List<Object?> get signature => [
    for (final target in ruleTargets)
      '${target.mapId}/${target.kind.name}/${target.id}',
  ];

  Iterable<MapDraftReference> get references => ruleTargets;
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
