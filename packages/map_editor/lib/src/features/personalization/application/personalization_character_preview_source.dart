import 'package:map_authoring/map_authoring.dart';

import '../../../application/authoring_api/authoring_query_adapter.dart';

final class PersonalizationCharacterPreviewAsset {
  const PersonalizationCharacterPreviewAsset({
    required this.path,
    required this.bytes,
  });

  final String? path;
  final List<int>? bytes;
}

final class PersonalizationCharacterPreviewOption {
  const PersonalizationCharacterPreviewOption({
    required this.id,
    required this.characterId,
    required this.displayName,
    required this.portraitPath,
    required this.expressionId,
    required this.expressionLabel,
    required this.workspaceRevision,
    this.portraitBytes,
    this.diagnosticCodes = const <String>[],
  });

  final String id;
  final String characterId;
  final String displayName;
  final String? portraitPath;
  final String? expressionId;
  final String expressionLabel;
  final String workspaceRevision;
  final List<int>? portraitBytes;
  final List<String> diagnosticCodes;

  bool get isReady => diagnosticCodes.isEmpty;

  String get pickerLabel => '$displayName · $expressionLabel';
}

abstract interface class PersonalizationCharacterPreviewSource {
  Future<List<PersonalizationCharacterPreviewOption>> load(String projectRoot);
}

final class AuthoringPersonalizationCharacterPreviewSource
    implements PersonalizationCharacterPreviewSource {
  AuthoringPersonalizationCharacterPreviewSource({
    required AuthoringQueryAdapter queries,
  }) : _queries = queries;

  final AuthoringQueryAdapter _queries;
  final Map<String, _CharacterPreviewCacheEntry> _cache =
      <String, _CharacterPreviewCacheEntry>{};

  @override
  Future<List<PersonalizationCharacterPreviewOption>> load(
    String projectRoot,
  ) async {
    final session = await _queries.open(projectRoot);
    final revision = session.snapshotRevision;
    final cached = _cache[projectRoot];
    if (cached?.revision == revision) return cached!.options;

    final catalogPage = session.query(
      AuthoringQueryRequest(
        resourceKind: 'characterStudioCatalog',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: <String>['catalog'],
      ),
    );
    final rawCatalogItems = catalogPage['items'];
    final catalog = rawCatalogItems is List && rawCatalogItems.isNotEmpty
        ? Map<String, Object?>.from(rawCatalogItems.single! as Map)
        : const <String, Object?>{};
    final rawStates = catalog['portraitStates'];
    final states = rawStates is List
        ? <Map<String, Object?>>[
            for (final raw in rawStates) Map<String, Object?>.from(raw! as Map),
          ]
        : const <Map<String, Object?>>[];

    final characters = <Map<String, Object?>>[];
    String? cursor;
    do {
      final page = session.query(
        AuthoringQueryRequest(
          resourceKind: 'characterStudioCharacter',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 100,
          cursor: cursor,
          sort: const <AuthoringQuerySort>[
            AuthoringQuerySort(field: 'sortOrder'),
          ],
        ),
      );
      final rawItems = page['items'];
      if (rawItems is! List) {
        throw const FormatException('Invalid Character Studio page.');
      }
      characters.addAll(
        rawItems.map((raw) => Map<String, Object?>.from(raw! as Map)),
      );
      cursor = page['nextCursor'] as String?;
    } while (cursor != null);

    final assetIds = <String>{
      for (final character in characters)
        for (final portrait in _portraitMaps(character['portraits']))
          if (portrait['assetId'] case final String assetId) assetId,
    };
    final assets = <String, PersonalizationCharacterPreviewAsset>{};
    for (final assetId in assetIds) {
      try {
        final page = session.query(
          AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: <String>[assetId],
          ),
        );
        final items = page['items'];
        final item = items is List && items.isNotEmpty
            ? Map<String, Object?>.from(items.single! as Map)
            : const <String, Object?>{};
        assets[assetId] = PersonalizationCharacterPreviewAsset(
          path: item['logicalPath'] as String? ?? item['name'] as String?,
          bytes: session.assetBytes(assetId),
        );
      } on Object {
        assets[assetId] = const PersonalizationCharacterPreviewAsset(
          path: null,
          bytes: null,
        );
      }
    }

    final options = PersonalizationCharacterPreviewCatalogProjection.project(
      workspaceRevision: revision,
      portraitStates: states,
      characters: characters,
      assets: assets,
    );
    _cache[projectRoot] = _CharacterPreviewCacheEntry(
      revision: revision,
      options: options,
    );
    return options;
  }
}

abstract final class PersonalizationCharacterPreviewCatalogProjection {
  static List<PersonalizationCharacterPreviewOption> project({
    required String workspaceRevision,
    required List<Map<String, Object?>> portraitStates,
    required List<Map<String, Object?>> characters,
    required Map<String, PersonalizationCharacterPreviewAsset> assets,
  }) {
    final states = <String, String>{
      for (final state in portraitStates)
        if (state['id'] case final String id)
          id: state['displayName'] as String? ?? id,
    };
    final options = <PersonalizationCharacterPreviewOption>[];
    for (final character in characters) {
      final characterId = character['id'];
      final displayName = character['name'];
      if (characterId is! String || displayName is! String) continue;
      final portraits = _portraitMaps(character['portraits']);
      final portraitsByState = <String, Map<String, Object?>>{
        for (final portrait in portraits)
          if (portrait['portraitStateId'] case final String stateId)
            stateId: portrait,
      };
      final projectedStateIds = <String>[
        ...states.keys,
        ...portraitsByState.keys.where(
          (stateId) => !states.containsKey(stateId),
        ),
      ];
      if (projectedStateIds.isEmpty) {
        options.add(
          PersonalizationCharacterPreviewOption(
            id: '$characterId:none',
            characterId: characterId,
            displayName: displayName,
            portraitPath: null,
            expressionId: null,
            expressionLabel: 'Aucun état de portrait',
            workspaceRevision: workspaceRevision,
            diagnosticCodes: const <String>['portraitStateMissing'],
          ),
        );
        continue;
      }
      for (final stateId in projectedStateIds) {
        final portrait = portraitsByState[stateId];
        final assetId = portrait?['assetId'] as String?;
        final asset = assetId == null ? null : assets[assetId];
        final diagnostics = <String>[
          if (!states.containsKey(stateId)) 'portraitStateDeleted',
          if (portrait == null) 'portraitMissing',
          if (portrait != null &&
              (asset == null || asset.path == null || asset.bytes == null))
            'portraitAssetMissing',
        ];
        options.add(
          PersonalizationCharacterPreviewOption(
            id: '$characterId:$stateId',
            characterId: characterId,
            displayName: displayName,
            portraitPath: asset?.path,
            expressionId: stateId,
            expressionLabel: states[stateId] ?? stateId,
            workspaceRevision: workspaceRevision,
            portraitBytes: asset?.bytes,
            diagnosticCodes: List.unmodifiable(diagnostics),
          ),
        );
      }
    }
    return List.unmodifiable(options);
  }
}

List<Map<String, Object?>> _portraitMaps(Object? source) => switch (source) {
  final List values => <Map<String, Object?>>[
    for (final value in values) Map<String, Object?>.from(value! as Map),
  ],
  _ => const <Map<String, Object?>>[],
};

final class _CharacterPreviewCacheEntry {
  const _CharacterPreviewCacheEntry({
    required this.revision,
    required this.options,
  });

  final String revision;
  final List<PersonalizationCharacterPreviewOption> options;
}
