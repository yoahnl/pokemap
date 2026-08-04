import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../domains/assets/asset_store.dart';
import '../domains/narrative/dialogue_authoring_service.dart';
import '../domains/narrative/dialogue_source_store.dart';
import '../domains/narrative/script_authoring_service.dart';
import '../domains/narrative/scenario_actions.dart';
import '../domains/narrative/storyline_inspection.dart';
import 'project_snapshot.dart';

final class AuthoringQueryException implements Exception {
  const AuthoringQueryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringQueryException($code): $message';
}

/// Deterministic generic reads over one immutable [ProjectSnapshot].
final class ProjectQueryService {
  const ProjectQueryService();

  AuthoringQueryPage query(
    ProjectSnapshot snapshot,
    AuthoringQueryRequest request,
  ) {
    var records = _records(snapshot, request.resourceKind);
    records = _applyOperation(records, request);
    records = records
        .where((record) => _matchesFilters(record.detail, request.filters))
        .toList(growable: false);
    final ordered = records.toList()..sort(_comparator(request.sort));
    final offset = _cursorOffset(snapshot, request);
    if (offset > ordered.length) {
      throw const AuthoringQueryException(
        'query.cursor_invalid',
        'The query cursor offset is invalid.',
      );
    }
    final end = (offset + request.pageSize).clamp(0, ordered.length);
    final pageRecords = ordered.sublist(offset, end);
    final useDetail = request.operation != AuthoringQueryOperation.summary &&
        request.view == AuthoringQueryView.detail;
    final items = [
      for (final record in pageRecords)
        _applyFieldMask(
          useDetail ? record.detail : record.summary,
          request.fieldMask,
        ),
    ];
    final nextCursor = end < ordered.length
        ? _encodeCursor(
            revision: snapshot.revision,
            signature: request.signature,
            offset: end,
          )
        : null;
    return AuthoringQueryPage(
      snapshotRevision: snapshot.revision,
      items: items,
      totalAvailable: ordered.length,
      nextCursor: nextCursor,
    );
  }
}

List<_QueryRecord> _records(ProjectSnapshot snapshot, String resourceKind) {
  switch (resourceKind) {
    case 'project':
      return [
        _QueryRecord(
          summary: _projectSummary(snapshot),
          detail: _projectDetail(snapshot),
        ),
      ];
    case 'map':
      return [
        for (final map in snapshot.maps)
          _QueryRecord(
            summary: _mapSummary(map),
            detail: _mapDetail(map),
          ),
      ];
    case 'asset':
      final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
      if (bytes == null) return const [];
      final catalog = _decodeAssetCatalog(bytes);
      return [
        for (final asset in catalog.records)
          _QueryRecord(
            summary: _assetSummary(asset),
            detail: _assetDetail(asset),
          ),
      ];
    case 'tilesetFolder':
      return [
        for (final folder in snapshot.manifest.tilesetFolders)
          _QueryRecord(
            summary: _tilesetFolderRecord(folder),
            detail: _tilesetFolderRecord(folder),
          ),
      ];
    case 'elementCategory':
      return [
        for (final category in snapshot.manifest.elementCategories)
          _QueryRecord(
            summary: _elementCategoryRecord(category),
            detail: _elementCategoryRecord(category),
          ),
      ];
    case 'smartTileAtlas':
      return <_QueryRecord>[
        for (final atlas in snapshot.manifest.smartTileCatalog.atlases)
          _QueryRecord(
            summary: _smartTileAtlasSummary(atlas),
            detail: <String, Object?>{
              ...atlas.toJson(),
              'resourceKind': 'smartTileAtlas',
            },
          ),
      ];
    case 'smartTileMaterial':
      return <_QueryRecord>[
        for (final material in snapshot.manifest.smartTileCatalog.materials)
          _QueryRecord(
            summary: _smartTileMaterialSummary(material),
            detail: <String, Object?>{
              ...material.toJson(),
              'resourceKind': 'smartTileMaterial',
            },
          ),
      ];
    case 'smartTilePattern':
      return <_QueryRecord>[
        for (final pattern in snapshot.manifest.smartTileCatalog.patterns)
          _QueryRecord(
            summary: _smartTilePatternSummary(pattern),
            detail: <String, Object?>{
              ...pattern.toJson(),
              'resourceKind': 'smartTilePattern',
            },
          ),
      ];
    case 'smartTileAnimation':
      return <_QueryRecord>[
        for (final animation in snapshot.manifest.smartTileCatalog.animations)
          _QueryRecord(
            summary: _smartTileAnimationSummary(animation),
            detail: <String, Object?>{
              ...animation.toJson(),
              'resourceKind': 'smartTileAnimation',
            },
          ),
      ];
    case 'smartTileDraft':
      return <_QueryRecord>[
        for (final draft in snapshot.manifest.smartTileCatalog.drafts)
          _QueryRecord(
            summary: _smartTileDraftSummary(draft),
            detail: <String, Object?>{
              ...draft.toJson(),
              'resourceKind': 'smartTileDraft',
            },
          ),
      ];
    case 'smartTilePreset':
      final catalog = snapshot.manifest.smartTileCatalog;
      return <_QueryRecord>[
        for (final preset in catalog.presets)
          _QueryRecord(
            summary: _smartTilePresetSummary(preset),
            detail: <String, Object?>{
              ...preset.toJson(),
              'resourceKind': 'smartTilePreset',
              'coverage': _smartTileCoverageDetail(
                analyzeSmartTileCoverage(
                  preset: preset,
                  materials: catalog.materials,
                  atlases: catalog.atlases,
                  animations: catalog.animations,
                ),
              ),
            },
          ),
      ];
    case 'smartTileLayer':
      return <_QueryRecord>[
        for (final map in snapshot.maps)
          for (final layer in map.layers.whereType<SmartTileLayer>())
            _QueryRecord(
              summary: _smartTileLayerSummary(map, layer),
              detail: <String, Object?>{
                ...layer.toJson(),
                'id': '${map.id}:${layer.id}',
                'name': layer.name,
                'resourceKind': 'smartTileLayer',
                'mapId': map.id,
                'layerId': layer.id,
                'authoredValueCount': smartTileAuthoredValueCount(layer),
              },
            ),
      ];
    case 'dialogue':
      return [
        for (final dialogue in snapshot.manifest.dialogues)
          _QueryRecord(
            summary: _dialogueSummary(dialogue),
            detail: _dialogueDetail(snapshot, dialogue),
          ),
      ];
    case 'script':
      return [
        for (final script in snapshot.manifest.scripts)
          _QueryRecord(
            summary: _scriptSummary(script),
            detail: _scriptDetail(script),
          ),
      ];
    case 'scene':
      return [
        for (final scene in snapshot.manifest.scenes)
          _QueryRecord(
            summary: _sceneSummary(scene),
            detail: _sceneDetail(snapshot, scene),
          ),
      ];
    case 'eventV2':
      return [
        for (final record in snapshot.manifest.eventRegistry?.records ??
            const <NarrativeEventRecord>[])
          _QueryRecord(
            summary: _eventV2Summary(record),
            detail: _eventV2Detail(snapshot, record),
          ),
      ];
    case 'fact':
      return [
        for (final fact in snapshot.manifest.facts)
          _QueryRecord(
            summary: _factSummary(fact),
            detail: {...fact.toJson(), 'resourceKind': 'fact'},
          ),
      ];
    case 'worldRule':
      return [
        for (final rule in snapshot.manifest.worldRules)
          _QueryRecord(
            summary: _worldRuleSummary(rule),
            detail: {...rule.toJson(), 'resourceKind': 'worldRule'},
          ),
      ];
    case 'storyline':
      final inspection = const StorylineInspector().inspect(snapshot.manifest);
      return [
        for (final storyline in snapshot.manifest.storylines)
          _QueryRecord(
            summary: _storylineSummary(storyline),
            detail: {
              ...storyline.toJson(),
              'resourceKind': 'storyline',
              'progression': inspection.progression[storyline.id],
              'diagnostics': [
                for (final item in inspection.diagnostics)
                  if (item.storylineId == storyline.id) item.toJson(),
              ],
            },
          ),
      ];
    case 'scenario':
      const actions = ScenarioActions();
      final migration = actions.migrationPreviewJson(snapshot.manifest);
      return [
        for (final scenario in snapshot.manifest.scenarios)
          _QueryRecord(
            summary: _scenarioSummary(scenario),
            detail: {
              ...scenario.toJson(),
              'resourceKind': 'scenario',
              'simulation': actions.simulate(scenario).toJson(),
              'migration': migration,
            },
          ),
      ];
    default:
      throw const AuthoringQueryException(
        'query.resource_kind_unsupported',
        'The requested resource kind is not readable in this phase.',
      );
  }
}

List<_QueryRecord> _applyOperation(
  List<_QueryRecord> records,
  AuthoringQueryRequest request,
) {
  switch (request.operation) {
    case AuthoringQueryOperation.list:
    case AuthoringQueryOperation.summary:
      return records;
    case AuthoringQueryOperation.get:
      final matches = records
          .where((record) => record.id == request.ids.single)
          .toList(growable: false);
      if (matches.isEmpty) {
        throw const AuthoringQueryException(
          'query.resource_not_found',
          'The requested resource was not found.',
        );
      }
      return matches;
    case AuthoringQueryOperation.batchGet:
      final ids = request.ids.toSet();
      return records
          .where((record) => ids.contains(record.id))
          .toList(growable: false);
    case AuthoringQueryOperation.search:
      final term = request.searchTerm!.toLowerCase();
      return records
          .where(
            (record) =>
                record.id.toLowerCase().contains(term) ||
                record.name.toLowerCase().contains(term),
          )
          .toList(growable: false);
  }
}

Map<String, Object?> _projectSummary(ProjectSnapshot snapshot) => {
      'id': 'project',
      'name': snapshot.manifest.name,
      'resourceKind': 'project',
      'version': snapshot.manifest.version.name,
      'mapCount': snapshot.maps.length,
      'groupCount': snapshot.manifest.groups.length,
      'tilesetCount': snapshot.manifest.tilesets.length,
    };

Map<String, Object?> _projectDetail(ProjectSnapshot snapshot) {
  final detail = _jsonObject(snapshot.manifest.toJson());
  final settings = detail['settings'];
  if (settings is Map<String, Object?>) {
    final sanitizedSettings = Map<String, Object?>.from(settings)
      ..remove('mistralApiKey');
    detail['settings'] = sanitizedSettings;
  }
  final maps = detail['maps'];
  if (maps is List) {
    detail['maps'] = [
      for (final rawMap in maps)
        if (rawMap is Map)
          Map<String, Object?>.from(rawMap)..remove('relativePath'),
    ];
  }
  detail
    ..['id'] = 'project'
    ..['resourceKind'] = 'project';
  return detail;
}

Map<String, Object?> _mapSummary(MapData map) => {
      'id': map.id,
      'name': map.name,
      'resourceKind': 'map',
      'version': map.version.name,
      'size': {
        'width': map.size.width,
        'height': map.size.height,
      },
      'layerCount': map.layers.length,
      'entityCount': map.entities.length,
      'placedElementCount': map.placedElements.length,
      'eventCount': map.events.length,
    };

Map<String, Object?> _mapDetail(MapData map) =>
    _jsonObject(map.toJson())..['resourceKind'] = 'map';

Map<String, Object?> _assetSummary(AssetRecord asset) => {
      'id': asset.id,
      'name': asset.logicalPath,
      'resourceKind': 'asset',
      'mediaType': asset.artifact.mediaType,
      'byteLength': asset.artifact.byteLength,
      'unused': asset.usages.isEmpty,
    };

Map<String, Object?> _assetDetail(AssetRecord asset) => {
      ...asset.toJson(),
      'name': asset.logicalPath,
      'resourceKind': 'asset',
      'unused': asset.usages.isEmpty,
      'preview': {
        'artifactHandle': asset.artifact.handle,
        'mediaType': asset.artifact.mediaType,
      },
    };

Map<String, Object?> _tilesetFolderRecord(ProjectTilesetFolder folder) => {
      ...folder.toJson(),
      'resourceKind': 'tilesetFolder',
    };

Map<String, Object?> _elementCategoryRecord(ProjectElementCategory category) =>
    {
      ...category.toJson(),
      'resourceKind': 'elementCategory',
    };

Map<String, Object?> _smartTileAtlasSummary(ProjectSmartTileAtlas atlas) =>
    <String, Object?>{
      'id': atlas.id,
      'name': atlas.name,
      'resourceKind': 'smartTileAtlas',
      'tilesetId': atlas.tilesetId,
      'columns': atlas.columns,
      'rows': atlas.rows,
      'cellWidth': atlas.cellWidth,
      'cellHeight': atlas.cellHeight,
    };

Map<String, Object?> _smartTileMaterialSummary(
  ProjectSmartTileMaterial material,
) =>
    <String, Object?>{
      'id': material.id,
      'name': material.name,
      'resourceKind': 'smartTileMaterial',
      'connectionGroupId': material.connectionGroupId,
      'isEmpty': material.isEmpty,
    };

Map<String, Object?> _smartTilePatternSummary(
  ProjectSmartTilePattern pattern,
) =>
    <String, Object?>{
      'id': pattern.id,
      'name': pattern.name,
      'resourceKind': 'smartTilePattern',
      'usage': pattern.usage.name,
      'width': pattern.width,
      'height': pattern.height,
      'repeatMode': pattern.repeatMode.name,
      'cellCount': pattern.cells.length,
    };

Map<String, Object?> _smartTileAnimationSummary(
  ProjectSmartTileAnimation animation,
) =>
    <String, Object?>{
      'id': animation.id,
      'name': animation.name,
      'resourceKind': 'smartTileAnimation',
      'frameCount': animation.frames.length,
      'sync': animation.sync.name,
      'loop': animation.loop.name,
    };

Map<String, Object?> _smartTileDraftSummary(
  ProjectSmartTileAuthoringDraft draft,
) =>
    <String, Object?>{
      'id': draft.id,
      'name': draft.name,
      'resourceKind': 'smartTileDraft',
      'targetPresetId': draft.targetPresetId,
      'usage': draft.usage.name,
      'lastStage': draft.lastStage.name,
      'atlasCount': draft.atlases.length,
      'materialCount': draft.materials.length,
      'ruleCount': draft.rules.length,
    };

Map<String, Object?> _smartTilePresetSummary(ProjectSmartTilePreset preset) =>
    <String, Object?>{
      'id': preset.id,
      'name': preset.name,
      'resourceKind': 'smartTilePreset',
      'usage': preset.usage.name,
      'topology': preset.topology.name,
      'templateHint': preset.templateHint.name,
      'status': preset.status.name,
      'ruleCount': preset.rules.length,
    };

Map<String, Object?> _smartTileLayerSummary(
  MapData map,
  SmartTileLayer layer,
) =>
    <String, Object?>{
      'id': '${map.id}:${layer.id}',
      'name': layer.name,
      'resourceKind': 'smartTileLayer',
      'mapId': map.id,
      'layerId': layer.id,
      'presetId': layer.presetId,
      'usage': layer.usage.name,
      'authoredValueCount': smartTileAuthoredValueCount(layer),
    };

Map<String, Object?> _smartTileCoverageDetail(
  SmartTileCoverageReport report,
) =>
    <String, Object?>{
      'caseCount': report.cases.length,
      'exactCount': report.exactCount,
      'transformedCount': report.transformedCount,
      'fallbackCount': report.fallbackCount,
      'missingCount': report.missingCount,
      'ambiguousCount': report.ambiguousCount,
      'noCandidateCount': report.noCandidateCount,
      'missingVisualSourceCount': report.missingVisualSourceCount,
      'outOfAtlasGridCount': report.outOfAtlasGridCount,
      'isExact': report.isExact,
      'diagnostics': <Map<String, Object?>>[
        for (final diagnostic in report.diagnostics)
          <String, Object?>{
            'code': diagnostic.code,
            'message': diagnostic.message,
            if (diagnostic.scenarioId != null)
              'scenarioId': diagnostic.scenarioId,
          },
      ],
      'cases': <Map<String, Object?>>[
        for (final coverageCase in report.cases)
          <String, Object?>{
            'id': coverageCase.id,
            'status': coverageCase.status.name,
            'ruleIds': coverageCase.ruleIds,
          },
      ],
    };

Map<String, Object?> _dialogueSummary(ProjectDialogueEntry dialogue) => {
      'id': dialogue.id,
      'name': dialogue.name,
      'resourceKind': 'dialogue',
      'tagCount': dialogue.tags.length,
      'declaredOutcomeCount': dialogue.declaredOutcomes.length,
      'defaultStartNode': dialogue.defaultStartNode,
    };

Map<String, Object?> _dialogueDetail(
  ProjectSnapshot snapshot,
  ProjectDialogueEntry dialogue,
) {
  final bytes = snapshot.findResourceBytes(
    dialogueSourceResourceIdentity(dialogue.id),
  );
  String? source;
  if (bytes != null) {
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on Object {
      source = null;
    }
  }
  DialogueAuthoringCompileResult? compile;
  if (source != null && dialogue.relativePath.toLowerCase().endsWith('.yarn')) {
    compile = const DialogueAuthoringCompiler().compile(
      entry: dialogue,
      source: source,
    );
  }
  return {
    ...dialogue.toJson(),
    'resourceKind': 'dialogue',
    'source': {
      'available': source != null,
      'byteLength': bytes?.length,
      if (source != null) 'text': source,
    },
    if (compile != null) 'compile': compile.toJson(),
  };
}

Map<String, Object?> _scriptSummary(ProjectScriptEntry script) => {
      'id': script.id,
      'name': script.name,
      'resourceKind': 'script',
      'tagCount': script.tags.length,
      'nodeCount': script.asset.nodes.length,
      'defaultStartNode': script.asset.defaultStartNode,
    };

Map<String, Object?> _scriptDetail(ProjectScriptEntry script) => {
      ...script.toJson(),
      'resourceKind': 'script',
      'simulation':
          const ScriptAuthoringSimulator().simulate(script.asset).toJson(),
    };

Map<String, Object?> _sceneSummary(SceneAsset scene) => {
      'id': scene.id,
      'name': scene.name,
      'resourceKind': 'scene',
      'nodeCount': scene.graph.nodes.length,
      'edgeCount': scene.graph.edges.length,
    };

Map<String, Object?> _sceneDetail(ProjectSnapshot snapshot, SceneAsset scene) {
  final report = diagnoseSceneAgainstProject(
    scene,
    snapshot.manifest,
    mapsById: {for (final map in snapshot.maps) map.id: map},
  );
  return {
    ...scene.toJson(),
    'resourceKind': 'scene',
    'runtimeBuildable': buildSceneRuntimePlan(scene).canBuild,
    'diagnostics': [
      for (final item in report.diagnostics)
        {
          'code': item.code.name,
          'severity': item.severity.name,
          'message': item.message,
          if (item.nodeId != null) 'nodeId': item.nodeId,
          if (item.edgeId != null) 'edgeId': item.edgeId,
        },
    ],
  };
}

Map<String, Object?> _eventV2Summary(NarrativeEventRecord record) => {
      'id': record.id,
      'name': record.when(
        draft: (draft) => draft.name,
        configured: (definition, _) => definition.name,
      ),
      'resourceKind': 'eventV2',
      'state': record.draftOrNull == null ? 'configured' : 'draft',
      if (record.enabledOrNull != null) 'enabled': record.enabledOrNull,
    };

Map<String, Object?> _eventV2Detail(
  ProjectSnapshot snapshot,
  NarrativeEventRecord record,
) {
  final registry = snapshot.manifest.eventRegistry!;
  final catalog = buildNarrativeEventProjectCatalog(
    project: snapshot.manifest,
    maps: snapshot.maps,
  );
  final validation = buildNarrativeEventValidationReportSubset(
    registry: registry,
    catalog: catalog,
    eventIds: {record.id},
  );
  return {
    ...record.toJson(),
    'id': record.id,
    'name': record.when(
      draft: (draft) => draft.name,
      configured: (definition, _) => definition.name,
    ),
    'resourceKind': 'eventV2',
    'validation': validation.toDebugJson(),
  };
}

Map<String, Object?> _factSummary(NarrativeFactDefinition fact) => {
      'id': fact.id,
      'name': fact.label,
      'resourceKind': 'fact',
      'valueKind': fact.valueKind.wireName,
      'category': fact.category,
    };

Map<String, Object?> _worldRuleSummary(WorldRuleDefinition rule) => {
      'id': rule.id,
      'name': rule.label,
      'resourceKind': 'worldRule',
      'enabled': rule.enabled,
      'sourceKind': rule.source.kind.name,
      'targetKind': rule.target.kind.name,
      'effectKind': rule.effect.kind.name,
    };

Map<String, Object?> _storylineSummary(StorylineAsset storyline) => {
      'id': storyline.id,
      'name': storyline.title,
      'resourceKind': 'storyline',
      'type': storyline.type.name,
      'status': storyline.status.name,
      'chapterCount': storyline.chapters.length,
      'stepCount': storyline.chapters
          .fold<int>(0, (count, chapter) => count + chapter.steps.length),
    };

Map<String, Object?> _scenarioSummary(ScenarioAsset scenario) => {
      'id': scenario.id,
      'name': scenario.name,
      'resourceKind': 'scenario',
      'scope': scenario.scope.name,
      'nodeCount': scenario.nodes.length,
      'edgeCount': scenario.edges.length,
    };

AssetCatalog _decodeAssetCatalog(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw const AuthoringQueryException(
      'query.asset_catalog_invalid',
      'The project asset catalog cannot be queried safely.',
    );
  }
}

Map<String, Object?> _jsonObject(Map<String, dynamic> value) =>
    Map<String, Object?>.from(value);

bool _matchesFilters(
  Map<String, Object?> source,
  Map<String, Object?> filters,
) {
  for (final entry in filters.entries) {
    final resolved = _readPath(source, entry.key);
    if (identical(resolved, _missingValue) ||
        !_jsonValuesEqual(resolved, entry.value)) {
      return false;
    }
  }
  return true;
}

bool _jsonValuesEqual(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_jsonValuesEqual(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !_jsonValuesEqual(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}

Comparator<_QueryRecord> _comparator(List<AuthoringQuerySort> sort) {
  final effectiveSort = sort.isEmpty
      ? const [AuthoringQuerySort(field: 'id')]
      : [...sort, const AuthoringQuerySort(field: 'id')];
  return (left, right) {
    for (final field in effectiveSort) {
      final leftValue = _readPath(left.detail, field.field);
      final rightValue = _readPath(right.detail, field.field);
      var order = _compareJsonValues(leftValue, rightValue);
      if (field.descending) order = -order;
      if (order != 0) return order;
    }
    return 0;
  };
}

int _compareJsonValues(Object? left, Object? right) {
  if (identical(left, right)) return 0;
  if (identical(left, _missingValue)) return 1;
  if (identical(right, _missingValue)) return -1;
  if (left == null) return -1;
  if (right == null) return 1;
  if (left is num && right is num) return left.compareTo(right);
  if (left is bool && right is bool) {
    return (left ? 1 : 0).compareTo(right ? 1 : 0);
  }
  return left.toString().compareTo(right.toString());
}

Map<String, Object?> _applyFieldMask(
  Map<String, Object?> source,
  List<String> fieldMask,
) {
  if (fieldMask.isEmpty) {
    return freezeContractJsonObject(source, field: 'query.item');
  }
  final selected = <String, Object?>{
    'id': source['id'],
    'name': source['name'],
    'resourceKind': source['resourceKind'],
  };
  for (final path in fieldMask) {
    final value = _readPath(source, path);
    if (identical(value, _missingValue)) {
      throw const AuthoringQueryException(
        'query.field_mask_unknown',
        'A requested field mask does not exist on this resource.',
      );
    }
    _writePath(selected, path, value);
  }
  return freezeContractJsonObject(selected, field: 'query.item');
}

Object? _readPath(Map<String, Object?> source, String path) {
  Object? current = source;
  for (final segment in path.split('.')) {
    if (current is! Map || !current.containsKey(segment)) {
      return _missingValue;
    }
    current = current[segment];
  }
  return current;
}

void _writePath(
  Map<String, Object?> target,
  String path,
  Object? value,
) {
  final segments = path.split('.');
  var current = target;
  for (var index = 0; index < segments.length - 1; index++) {
    final segment = segments[index];
    final child = current[segment];
    if (child is Map<String, Object?>) {
      current = child;
    } else {
      final created = <String, Object?>{};
      current[segment] = created;
      current = created;
    }
  }
  current[segments.last] = freezeContractJsonValue(
    value,
    field: 'fieldMask.$path',
  );
}

int _cursorOffset(
  ProjectSnapshot snapshot,
  AuthoringQueryRequest request,
) {
  final cursor = request.cursor;
  if (cursor == null) return 0;
  final decoded = _decodeCursor(cursor);
  if (decoded.revision != snapshot.revision) {
    throw const AuthoringQueryException(
      'query.cursor_stale',
      'The query cursor belongs to another project revision.',
    );
  }
  if (decoded.signature != request.signature) {
    throw const AuthoringQueryException(
      'query.cursor_mismatch',
      'The query cursor belongs to another normalized query.',
    );
  }
  return decoded.offset;
}

String _encodeCursor({
  required String revision,
  required String signature,
  required int offset,
}) {
  final bytes = utf8.encode(
    jsonEncode({
      'version': 1,
      'revision': revision,
      'signature': signature,
      'offset': offset,
    }),
  );
  return base64Url.encode(bytes).replaceAll('=', '');
}

_QueryCursor _decodeCursor(String value) {
  try {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(value))),
    );
    if (decoded is! Map ||
        decoded['version'] != 1 ||
        decoded['revision'] is! String ||
        decoded['signature'] is! String ||
        decoded['offset'] is! int ||
        (decoded['offset']! as int) < 0) {
      throw const FormatException('Invalid cursor payload.');
    }
    return _QueryCursor(
      revision: decoded['revision']! as String,
      signature: decoded['signature']! as String,
      offset: decoded['offset']! as int,
    );
  } on Object {
    throw const AuthoringQueryException(
      'query.cursor_invalid',
      'The query cursor is malformed.',
    );
  }
}

final class _QueryRecord {
  const _QueryRecord({
    required this.summary,
    required this.detail,
  });

  final Map<String, Object?> summary;
  final Map<String, Object?> detail;

  String get id => detail['id']! as String;
  String get name => detail['name']! as String;
}

final class _QueryCursor {
  const _QueryCursor({
    required this.revision,
    required this.signature,
    required this.offset,
  });

  final String revision;
  final String signature;
  final int offset;
}

const Object _missingValue = Object();
