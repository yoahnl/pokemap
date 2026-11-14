import '../domain/map_directory.dart';

MapDirectoryPage mapDirectoryPage(Map<String, Object?> item) =>
    MapDirectoryPage(
      mapId: item['mapId'] as String,
      name: item['name'] as String,
      elements: [
        for (final raw in item['elements'] as List? ?? const [])
          if (raw is Map)
            if (MapDirectoryElementKind.values
                    .where((kind) => kind.name == raw['kind'])
                    .firstOrNull
                case final kind?)
              MapDirectoryElement(
                id: raw['id'] as String,
                kind: kind,
                name: raw['name'] is String && raw['name'] != raw['id']
                    ? raw['name'] as String
                    : null,
                characterId: raw['characterId'] as String?,
                entityId: raw['entityId'] as String?,
              ),
      ],
    );
