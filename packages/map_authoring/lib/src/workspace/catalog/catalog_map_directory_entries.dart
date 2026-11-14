import 'dart:convert';

typedef CatalogMapDirectoryElement = Map<String, Object?>;

final class CatalogMapDirectoryEntries {
  const CatalogMapDirectoryEntries(this.mapId, this.name, this.elements);

  final String mapId;
  final String name;
  final List<CatalogMapDirectoryElement> elements;

  static CatalogMapDirectoryEntries fromMapBytes(List<int> bytes) {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map || value['id'] is! String) {
      throw const FormatException('catalog.map_directory.map_invalid');
    }
    final mapId = value['id'] as String;
    final name = value['name'];
    return CatalogMapDirectoryEntries(
        mapId,
        name is String && name.isNotEmpty ? name : mapId,
        List.unmodifiable([
          for (final entity in _maps(value['entities'])) _entity(entity),
          for (final trigger in _maps(value['triggers']))
            _element('trigger', trigger, trigger['name'],
                (trigger['area'] as Map?)?['pos']),
          for (final event in _maps(value['events']))
            _element('mapEvent', event, event['name'], event['pos']),
          for (final instance
              in _maps((value['spatialScene'] as Map?)?['instances']))
            if (instance['entityId'] is String)
              {
                ..._element('modelInstance', instance, null, null),
                'modelId': instance['modelId'],
                'entityId': instance['entityId'],
              },
        ]));
  }

  static CatalogMapDirectoryElement _entity(Map entity) {
    final npc = entity['npc'];
    final displayName = npc is Map ? npc['displayName'] : null;
    return {
      ..._element(
          'entity',
          entity,
          displayName is String && displayName.isNotEmpty
              ? displayName
              : entity['name'],
          entity['pos']),
      if (entity['kind'] case final String kind) 'entityKind': kind,
      if (npc is Map && npc['characterId'] is String) ...{
        if ((npc['characterId'] as String).isNotEmpty)
          'characterId': npc['characterId'],
      },
      if (npc is Map && npc['trainerId'] is String) ...{
        if ((npc['trainerId'] as String).isNotEmpty)
          'trainerId': npc['trainerId'],
      },
    };
  }

  static CatalogMapDirectoryElement _element(
      String kind, Map source, Object? name, Object? position) {
    final id = source['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('catalog.map_directory.element_invalid');
    }
    return {
      'id': id,
      'kind': kind,
      'name': name is String && name.isNotEmpty ? name : id,
      if (position case {'x': final int x, 'y': final int y}) 'cell': [x, y],
    };
  }

  static Iterable<Map> _maps(Object? value) =>
      value is List ? value.whereType<Map>() : const [];
}
