import 'package:map_core/map_core.dart';

enum NarrativeDocumentKind { scene, presentationCinematic }

enum NarrativeLibraryKind { scenes, cinematics }

enum NarrativeLibrarySort {
  manual,
  nameAscending,
  nameDescending,
  updatedDescending,
}

enum NarrativeLibraryVisibility { active, archived, all }

enum NarrativeSceneInspector { none, node, properties }

sealed class NarrativeDocumentSourceContext {
  const NarrativeDocumentSourceContext();
}

final class NarrativeLibrarySourceContext
    extends NarrativeDocumentSourceContext {
  NarrativeLibrarySourceContext({
    required this.library,
    this.cinematicFamily,
    String? folderId,
    this.searchQuery = '',
    this.sort = NarrativeLibrarySort.manual,
    this.visibility = NarrativeLibraryVisibility.active,
    String? selectedAssetId,
    this.scrollOffset = 0,
  }) : folderId = _optionalText(folderId, 'folderId'),
       selectedAssetId = _optionalText(selectedAssetId, 'selectedAssetId') {
    if (!scrollOffset.isFinite || scrollOffset < 0) {
      throw ArgumentError.value(
        scrollOffset,
        'scrollOffset',
        'must be finite and non-negative',
      );
    }
    if (library == NarrativeLibraryKind.scenes && cinematicFamily != null) {
      throw ArgumentError.value(
        cinematicFamily,
        'cinematicFamily',
        'must be absent for the Scene library',
      );
    }
    if (library == NarrativeLibraryKind.cinematics && cinematicFamily == null) {
      throw ArgumentError.value(
        cinematicFamily,
        'cinematicFamily',
        'is required for the Cinematics library',
      );
    }
  }

  final NarrativeLibraryKind library;
  final CinematicLibraryFamily? cinematicFamily;
  final String? folderId;
  final String searchQuery;
  final NarrativeLibrarySort sort;
  final NarrativeLibraryVisibility visibility;
  final String? selectedAssetId;
  final double scrollOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeLibrarySourceContext &&
          other.library == library &&
          other.cinematicFamily == cinematicFamily &&
          other.folderId == folderId &&
          other.searchQuery == searchQuery &&
          other.sort == sort &&
          other.visibility == visibility &&
          other.selectedAssetId == selectedAssetId &&
          other.scrollOffset == scrollOffset;

  @override
  int get hashCode => Object.hash(
    library,
    cinematicFamily,
    folderId,
    searchQuery,
    sort,
    visibility,
    selectedAssetId,
    scrollOffset,
  );
}

final class NarrativeSceneSourceContext extends NarrativeDocumentSourceContext {
  NarrativeSceneSourceContext({
    required String sceneId,
    required this.viewportX,
    required this.viewportY,
    required this.zoom,
    String? selectedNodeId,
    this.inspector = NarrativeSceneInspector.none,
  }) : sceneId = _requiredText(sceneId, 'sceneId'),
       selectedNodeId = _optionalText(selectedNodeId, 'selectedNodeId') {
    if (!viewportX.isFinite) {
      throw ArgumentError.value(viewportX, 'viewportX', 'must be finite');
    }
    if (!viewportY.isFinite) {
      throw ArgumentError.value(viewportY, 'viewportY', 'must be finite');
    }
    if (!zoom.isFinite || zoom <= 0) {
      throw ArgumentError.value(zoom, 'zoom', 'must be finite and positive');
    }
  }

  final String sceneId;
  final double viewportX;
  final double viewportY;
  final double zoom;
  final String? selectedNodeId;
  final NarrativeSceneInspector inspector;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeSceneSourceContext &&
          other.sceneId == sceneId &&
          other.viewportX == viewportX &&
          other.viewportY == viewportY &&
          other.zoom == zoom &&
          other.selectedNodeId == selectedNodeId &&
          other.inspector == inspector;

  @override
  int get hashCode => Object.hash(
    sceneId,
    viewportX,
    viewportY,
    zoom,
    selectedNodeId,
    inspector,
  );
}

final class NarrativeDocumentRoute {
  NarrativeDocumentRoute._({
    required this.kind,
    required String documentId,
    required this.source,
  }) : documentId = _requiredText(documentId, 'documentId') {
    switch (kind) {
      case NarrativeDocumentKind.scene:
        if (source case NarrativeLibrarySourceContext(:final library)) {
          if (library != NarrativeLibraryKind.scenes) {
            throw ArgumentError.value(
              source,
              'source',
              'a Scene document must return to the Scene library',
            );
          }
        } else {
          throw ArgumentError.value(
            source,
            'source',
            'a Scene document requires a typed Scene library context',
          );
        }
      case NarrativeDocumentKind.presentationCinematic:
        if (source case NarrativeLibrarySourceContext(
          library: NarrativeLibraryKind.cinematics,
          cinematicFamily: final family,
        )) {
          if (family != CinematicLibraryFamily.presentation) {
            throw ArgumentError.value(
              source,
              'source',
              'a Presentation must return to the Presentation library',
            );
          }
        } else if (source is! NarrativeSceneSourceContext) {
          throw ArgumentError.value(
            source,
            'source',
            'a Presentation requires a Library or Scene source context',
          );
        }
    }
  }

  factory NarrativeDocumentRoute.scene({
    required String sceneId,
    required NarrativeLibrarySourceContext source,
  }) => NarrativeDocumentRoute._(
    kind: NarrativeDocumentKind.scene,
    documentId: sceneId,
    source: source,
  );

  factory NarrativeDocumentRoute.presentation({
    required String cinematicId,
    required NarrativeDocumentSourceContext source,
  }) => NarrativeDocumentRoute._(
    kind: NarrativeDocumentKind.presentationCinematic,
    documentId: cinematicId,
    source: source,
  );

  final NarrativeDocumentKind kind;
  final String documentId;
  final NarrativeDocumentSourceContext source;

  String get sessionDocumentId => switch (kind) {
    NarrativeDocumentKind.scene => 'scene:$documentId',
    NarrativeDocumentKind.presentationCinematic =>
      'presentationCinematic:$documentId',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeDocumentRoute &&
          other.kind == kind &&
          other.documentId == documentId &&
          other.source == source;

  @override
  int get hashCode => Object.hash(kind, documentId, source);
}

abstract interface class NarrativeDocumentRouteStore {
  Future<NarrativeDocumentRoute?> read();
  Future<void> write(NarrativeDocumentRoute route);
  Future<void> clear();
}

final class NarrativeDocumentRouteCodec {
  const NarrativeDocumentRouteCodec();

  Uri encode(NarrativeDocumentRoute route) {
    final query = switch (route.source) {
      NarrativeLibrarySourceContext source => <String, String>{
        'source': 'library',
        'library': source.library.name,
        if (source.cinematicFamily case final family?)
          'family': family.toJson(),
        'folder': ?source.folderId,
        if (source.searchQuery.isNotEmpty) 'query': source.searchQuery,
        'sort': source.sort.name,
        'visibility': source.visibility.name,
        'selected': ?source.selectedAssetId,
        'scroll': source.scrollOffset.toString(),
      },
      NarrativeSceneSourceContext source => <String, String>{
        'source': 'scene',
        'scene': source.sceneId,
        'x': source.viewportX.toString(),
        'y': source.viewportY.toString(),
        'zoom': source.zoom.toString(),
        'node': ?source.selectedNodeId,
        'inspector': source.inspector.name,
      },
    };
    return Uri(
      scheme: 'pokemap',
      host: 'editor',
      pathSegments: <String>[
        'narrative',
        switch (route.kind) {
          NarrativeDocumentKind.scene => 'scene',
          NarrativeDocumentKind.presentationCinematic => 'presentation',
        },
        route.documentId,
      ],
      queryParameters: query,
    );
  }

  NarrativeDocumentRoute decode(Uri uri) {
    if (uri.scheme != 'pokemap' ||
        uri.host != 'editor' ||
        uri.pathSegments.length != 3 ||
        uri.pathSegments.first != 'narrative') {
      throw const FormatException('Unsupported Narrative document route.');
    }
    final kind = switch (uri.pathSegments[1]) {
      'scene' => NarrativeDocumentKind.scene,
      'presentation' => NarrativeDocumentKind.presentationCinematic,
      _ => throw FormatException(
        'Unsupported Narrative document kind: ${uri.pathSegments[1]}.',
      ),
    };
    final source = _decodeSource(uri.queryParameters);
    return switch (kind) {
      NarrativeDocumentKind.scene => NarrativeDocumentRoute.scene(
        sceneId: uri.pathSegments[2],
        source: source is NarrativeLibrarySourceContext
            ? source
            : throw const FormatException(
                'A Scene route requires a library source.',
              ),
      ),
      NarrativeDocumentKind.presentationCinematic =>
        NarrativeDocumentRoute.presentation(
          cinematicId: uri.pathSegments[2],
          source: source,
        ),
    };
  }

  NarrativeDocumentSourceContext _decodeSource(Map<String, String> query) {
    return switch (query['source']) {
      'library' => _decodeLibrarySource(query),
      'scene' => _decodeSceneSource(query),
      final source => throw FormatException(
        'Unsupported Narrative route source: $source.',
      ),
    };
  }

  NarrativeLibrarySourceContext _decodeLibrarySource(
    Map<String, String> query,
  ) {
    _rejectUnknownQuery(query, const {
      'source',
      'library',
      'family',
      'folder',
      'query',
      'sort',
      'visibility',
      'selected',
      'scroll',
    });
    final library = switch (query['library']) {
      'scenes' => NarrativeLibraryKind.scenes,
      'cinematics' => NarrativeLibraryKind.cinematics,
      final value => throw FormatException(
        'Unsupported Narrative library: $value.',
      ),
    };
    final family = query['family'] == null
        ? null
        : CinematicLibraryFamily.fromJson(query['family']);
    final sort = switch (query['sort']) {
      null || 'manual' => NarrativeLibrarySort.manual,
      'nameAscending' => NarrativeLibrarySort.nameAscending,
      'nameDescending' => NarrativeLibrarySort.nameDescending,
      'updatedDescending' => NarrativeLibrarySort.updatedDescending,
      final value => throw FormatException(
        'Unsupported Narrative library sort: $value.',
      ),
    };
    final visibility = switch (query['visibility']) {
      null || 'active' => NarrativeLibraryVisibility.active,
      'archived' => NarrativeLibraryVisibility.archived,
      'all' => NarrativeLibraryVisibility.all,
      final value => throw FormatException(
        'Unsupported Narrative library visibility: $value.',
      ),
    };
    return NarrativeLibrarySourceContext(
      library: library,
      cinematicFamily: family,
      folderId: query['folder'],
      searchQuery: query['query'] ?? '',
      sort: sort,
      visibility: visibility,
      selectedAssetId: query['selected'],
      scrollOffset: _double(query['scroll'] ?? '0', 'scroll'),
    );
  }

  NarrativeSceneSourceContext _decodeSceneSource(Map<String, String> query) {
    _rejectUnknownQuery(query, const {
      'source',
      'scene',
      'x',
      'y',
      'zoom',
      'node',
      'inspector',
    });
    final inspector = switch (query['inspector']) {
      null || 'none' => NarrativeSceneInspector.none,
      'node' => NarrativeSceneInspector.node,
      'properties' => NarrativeSceneInspector.properties,
      final value => throw FormatException(
        'Unsupported Scene inspector: $value.',
      ),
    };
    return NarrativeSceneSourceContext(
      sceneId: _requiredQuery(query, 'scene'),
      viewportX: _double(_requiredQuery(query, 'x'), 'x'),
      viewportY: _double(_requiredQuery(query, 'y'), 'y'),
      zoom: _double(_requiredQuery(query, 'zoom'), 'zoom'),
      selectedNodeId: query['node'],
      inspector: inspector,
    );
  }
}

void _rejectUnknownQuery(Map<String, String> query, Set<String> allowed) {
  final unknown = query.keys.toSet().difference(allowed);
  if (unknown.isNotEmpty) {
    throw FormatException(
      'Unsupported Narrative route parameter: ${unknown.first}.',
    );
  }
}

String _requiredQuery(Map<String, String> query, String key) {
  final value = query[key];
  if (value == null) {
    throw FormatException('Missing Narrative route parameter: $key.');
  }
  return _requiredText(value, key);
}

double _double(String value, String field) {
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite) {
    throw FormatException('$field must be a finite number.');
  }
  return parsed;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return normalized;
}

String? _optionalText(String? value, String field) {
  if (value == null) return null;
  return _requiredText(value, field);
}
