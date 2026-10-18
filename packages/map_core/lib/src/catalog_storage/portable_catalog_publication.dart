import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../models/project_manifest.dart';
import '../models/resource_library_catalog.dart';
import '../models/resource_pack.dart';
import '../models/resource_pack_catalog.dart';
import '../models/resource_pack_installation_catalog.dart';
import '../operations/resource_pack_dependency_graph.dart';
import 'catalog_dynamic_dependency.dart';
import 'catalog_storage.dart';

final class PortableCatalogPublicationBuild {
  PortableCatalogPublicationBuild._(this.descriptor, this.storage);
  final Map<String, Object?> descriptor;
  final CatalogStorageBuild storage;
}

final class PortableProjectCatalog {
  PortableProjectCatalog._(this.snapshot, this.projectMetadata, this._shell);

  final CatalogSnapshot snapshot;
  final ProjectManifest projectMetadata;
  final CatalogDefinitionUnit _shell;

  static Future<PortableProjectCatalog> open(
    Map<String, Object?> descriptor, {
    required CatalogObjectReader readObject,
    CatalogStorageLimits? limits,
  }) async {
    if (descriptor.length != 4 ||
        descriptor['format'] != 'avelune.portable-catalog' ||
        descriptor['version'] != 2 ||
        descriptor['version'] is! int ||
        descriptor['kind'] != 'project') {
      throw const FormatException('catalog.publication: unsupported project');
    }
    final snapshot = await CatalogSnapshot.open(
      root: CatalogObjectReference.fromJson(_map(descriptor['root'])),
      readObject: readObject,
      limits: limits,
    );
    final shell = await snapshot.lookup(_shellKey);
    if (shell == null || shell.payload['section'] != r'$shell') {
      throw const FormatException('catalog.publication: missing project shell');
    }
    final metadata = <CatalogDefinitionUnit>[shell];
    String? cursor;
    do {
      final page = await snapshot.page(
        kind: CatalogDefinitionKind.catalogMetadata,
        limit: snapshot.limits.indexPageSize,
        cursor: cursor,
      );
      for (final entry in page.items) {
        if (entry.key == _shellKey) continue;
        final identity = entry.key.id;
        if (!identity.startsWith('["projectDefinition",') &&
            !identity.startsWith('["projectAggregateHeader",') &&
            !identity.startsWith('["projectAggregateChunk",') &&
            !identity.startsWith('["dynamic",')) {
          continue;
        }
        final unit = await snapshot.lookup(entry.key);
        if (unit == null) {
          throw const FormatException('catalog.project: missing metadata');
        }
        metadata.add(unit);
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    final decoded = ProjectManifest.fromJson(_reconstruct(metadata));
    final project = decoded.copyWith(
      globalProperties: _immutableProjectProperty(
        decoded.globalProperties,
        0,
      ) as Map<String, dynamic>,
    );
    final projection = ProjectManifest(
      name: project.name,
      version: project.version,
      maps: const [],
      tilesets: const [],
    ).toJson();
    final originalShell = _map(shell.payload['value']);
    for (final section in [
      'smartTileCatalog',
      'borderCatalog',
      'resourceLibraryCatalog',
      'characterStudioCatalog',
    ]) {
      if (originalShell[section] != null) {
        projection[section] = _copy(_map(originalShell[section]));
      }
    }
    return PortableProjectCatalog._(
      snapshot,
      project,
      _unit(_shellKey, r'$shell', 0, projection),
    );
  }

  Future<CatalogDefinitionUnit?> lookup(CatalogDefinitionKey key) =>
      snapshot.lookup(key);

  ProjectManifest definitions(Iterable<CatalogDefinitionUnit> definitions) {
    final grouped = <String, List<CatalogDefinitionUnit>>{};
    for (final unit in definitions) {
      final section = unit.payload['section'];
      if (section is! String ||
          !_sections.containsKey(section) ||
          _sections[section] != unit.key.kind ||
          unit.payload['id'] != unit.key.id ||
          _id(section, unit.payload['value']) != unit.key.id) {
        throw const FormatException('catalog.project: invalid definition');
      }
      (grouped[section] ??= []).add(unit);
    }
    return ProjectManifest.fromJson(
      _reconstruct([
        _shell,
        for (final units in grouped.values)
          ...((units..sort(
                (a, b) => (a.payload['position']! as int).compareTo(
                  b.payload['position']! as int,
                ),
              ))
              .indexed
              .map(
                (entry) => CatalogDefinitionUnit(
                  key: entry.$2.key,
                  payload: {...entry.$2.payload, 'position': entry.$1},
                  references: entry.$2.references,
                ),
              )),
      ]),
    );
  }

  ProjectManifest projectWithDefinitions(
    Iterable<CatalogDefinitionUnit> definitions,
  ) {
    final selected = this.definitions(definitions);
    return projectMetadata.copyWith(
      tilesets: selected.tilesets,
      elements: selected.elements,
      models3d: selected.models3d,
      characters: selected.characters,
      environmentPresets: selected.environmentPresets,
      smartTileCatalog: selected.smartTileCatalog,
      borderCatalog: selected.borderCatalog,
      elementCategories: selected.elementCategories,
      tilesetFolders: selected.tilesetFolders,
      characterStudioCatalog: selected.characterStudioCatalog,
      resourceLibraryCatalog: selected.resourceLibraryCatalog,
    );
  }
}

Object? _immutableProjectProperty(Object? value, int depth) {
  if (depth > 128) {
    throw const FormatException('catalog.project: property depth limit');
  }
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _immutableProjectProperty(entry.value, depth + 1),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable([
      for (final child in value) _immutableProjectProperty(child, depth + 1),
    ]);
  }
  return value;
}

final class PortableCatalogPublication {
  static const projectDynamicDependenciesKey =
      'aveluneCatalogDynamicDependencies';

  static void validateProjectMetadataJson(String source) {
    _metadataSourceMetrics(source);
  }

  static int validateCatalogObjectBytes(
    CatalogObjectReference reference,
    List<int> bytes, {
    CatalogStorageLimits? limits,
  }) {
    final effective = limits ?? CatalogStorageLimits();
    if (reference.byteLength > effective.maxUnitBytes ||
        bytes.length != reference.byteLength ||
        crypto.sha256.convert(bytes).toString() != reference.sha256) {
      throw const FormatException('catalog.object: invalid size or digest');
    }
    final metrics = _metadataSourceMetrics(utf8.decode(bytes));
    if (metrics.values > effective.maxJsonValues ||
        metrics.depth > effective.maxJsonDepth) {
      throw const FormatException('catalog.object: logical JSON limit');
    }
    return metrics.values;
  }

  static String objectPath(CatalogObjectReference reference) =>
      'catalog/objects/${reference.sha256}.json';

  static List<CatalogDynamicDependency> projectDynamicDependencies(
    ProjectManifest project,
  ) {
    final value = project.globalProperties[projectDynamicDependenciesKey];
    if (value == null &&
        !project.globalProperties.containsKey(projectDynamicDependenciesKey)) {
      return const [];
    }
    if (value is! List) {
      throw const FormatException(
        'catalog.dynamic: project declarations must be a list',
      );
    }
    return List.unmodifiable(
      value.map((entry) => CatalogDynamicDependency.fromJson(_map(entry))),
    );
  }

  static ProjectManifest withProjectDynamicDependencies(
    ProjectManifest project,
    Iterable<CatalogDynamicDependency> declarations,
  ) => project.copyWith(
    globalProperties: {
      ...project.globalProperties,
      projectDynamicDependenciesKey: declarations
          .map((declaration) => declaration.toJson())
          .toList(),
    },
  );

  static PortableCatalogPublicationBuild encodeCatalog(
    ResourcePackCatalog catalog, {
    CatalogStorageLimits? limits,
  }) {
    return _build('resourcePack', definitionUnits(catalog), limits);
  }

  static List<CatalogDefinitionUnit> definitionUnits(
    ResourcePackCatalog catalog,
  ) {
    ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
    return List.unmodifiable(_catalogUnits(catalog));
  }

  static PortableCatalogPublicationBuild encodeProject(
    ProjectManifest project, {
    CatalogStorageLimits? limits,
  }) => _build('project', _projectUnits(project), limits);

  static PortableCatalogPublicationBuild _build(
    String kind,
    List<CatalogDefinitionUnit> units,
    CatalogStorageLimits? limits,
  ) {
    final storage = CatalogStorageBuilder(limits: limits).build(units);
    return PortableCatalogPublicationBuild._(
      Map.unmodifiable({
        'format': 'avelune.portable-catalog',
        'version': 2,
        'kind': kind,
        'root': storage.root.toJson(),
      }),
      storage,
    );
  }

  static CatalogStorageRead readSync(
    Map<String, Object?> descriptor, {
    required CatalogObjectReaderSync readObject,
    CatalogStorageLimits? limits,
  }) {
    if (descriptor.length != 4 ||
        descriptor['format'] != 'avelune.portable-catalog' ||
        descriptor['version'] is! int ||
        descriptor['version'] != 2 ||
        !{'resourcePack', 'project'}.contains(descriptor['kind']) ||
        !descriptor.containsKey('root')) {
      throw const FormatException(
        'catalog.publication: unsupported descriptor',
      );
    }
    return CatalogSnapshot.readAllSync(
      root: CatalogObjectReference.fromJson(_map(descriptor['root'])),
      readObject: readObject,
      limits: limits,
    );
  }

  static ResourcePackCatalog decodeCatalogSync(
    Map<String, Object?> descriptor, {
    required CatalogObjectReaderSync readObject,
    CatalogStorageLimits? limits,
  }) {
    if (descriptor['kind'] != 'resourcePack') {
      throw const FormatException(
        'catalog.publication: expected resource pack',
      );
    }
    final read = readSync(descriptor, readObject: readObject, limits: limits);
    final catalog = ResourcePackCatalog.fromJson(_reconstruct(read.units));
    ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
    _verifyUnits(read.units, _catalogUnits(catalog));
    return catalog;
  }

  static ProjectManifest decodeProjectSync(
    Map<String, Object?> descriptor, {
    required CatalogObjectReaderSync readObject,
    CatalogStorageLimits? limits,
  }) {
    if (descriptor['kind'] != 'project') {
      throw const FormatException('catalog.publication: expected project');
    }
    final read = readSync(descriptor, readObject: readObject, limits: limits);
    final project = ProjectManifest.fromJson(_reconstruct(read.units));
    _verifyUnits(read.units, _projectUnits(project));
    return project;
  }

  static Map<String, Object?> projectShellSync(
    Map<String, Object?> descriptor, {
    required CatalogObjectReaderSync readObject,
    CatalogStorageLimits? limits,
  }) {
    if (descriptor['kind'] != 'project') {
      throw const FormatException('catalog.publication: expected project');
    }
    final read = readSync(descriptor, readObject: readObject, limits: limits);
    final shell = read.units.where((unit) => unit.key == _shellKey).single;
    return _copy(_map(shell.payload['value']));
  }
}

final _shellKey = CatalogDefinitionKey(
  CatalogDefinitionKind.catalogMetadata,
  'publication-shell',
);

final _sections = <String, CatalogDefinitionKind>{
  'tilesets': CatalogDefinitionKind.tileset,
  'elements': CatalogDefinitionKind.element,
  'models3d': CatalogDefinitionKind.model3d,
  'characters': CatalogDefinitionKind.character,
  'environmentPresets': CatalogDefinitionKind.environmentPreset,
  'elementCategories': CatalogDefinitionKind.elementCategory,
  'tilesetFolders': CatalogDefinitionKind.tilesetFolder,
  'smartTileCatalog.categories': CatalogDefinitionKind.smartTileCategory,
  'smartTileCatalog.atlases': CatalogDefinitionKind.smartTileAtlas,
  'smartTileCatalog.materials': CatalogDefinitionKind.smartTileMaterial,
  'smartTileCatalog.patterns': CatalogDefinitionKind.smartTilePattern,
  'smartTileCatalog.animations': CatalogDefinitionKind.smartTileAnimation,
  'smartTileCatalog.presets': CatalogDefinitionKind.smartTilePreset,
  'smartTileCatalog.drafts': CatalogDefinitionKind.catalogMetadata,
  'borderCatalog.records': CatalogDefinitionKind.borderRecord,
  'borderCatalog.visualSnapshots': CatalogDefinitionKind.borderVisualSnapshot,
  'resourceLibraryCatalog.families': CatalogDefinitionKind.resourceFamily,
  'resourceLibraryCatalog.entries': CatalogDefinitionKind.resourceLibraryEntry,
  'characterStudioCatalog.portraitStates':
      CatalogDefinitionKind.characterStudioDefinition,
  'characterStudioCatalog.customAnimationDefinitions':
      CatalogDefinitionKind.characterStudioDefinition,
  'files': CatalogDefinitionKind.fileBinding,
  'provenance': CatalogDefinitionKind.provenance,
  'extras.smartTilePatternIds': CatalogDefinitionKind.catalogMetadata,
  'dynamicDependencies': CatalogDefinitionKind.catalogMetadata,
  'globalProperties.${PortableCatalogPublication.projectDynamicDependenciesKey}':
      CatalogDefinitionKind.catalogMetadata,
};

Map<String, Object?> _map(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('catalog.publication: expected object');
  }
  return value;
}

Map<String, Object?> _copy(Map<String, Object?> value) =>
    _map(jsonDecode(jsonEncode(value)));

Map<String, Object?>? _parent(Map<String, Object?> root, String path) {
  final segments = path.split('.');
  var value = root;
  for (final segment in segments.take(segments.length - 1)) {
    final child = value[segment];
    if (child == null) return null;
    value = _map(child);
  }
  return value;
}

Map<String, Object?>? _partitionParent(Map<String, Object?> root, String path) {
  var parent = root;
  final segments = path.split('.');
  for (final segment in segments.take(segments.length - 1)) {
    final value = parent[segment];
    if (value == null) return null;
    final copy = <String, Object?>{..._map(value)};
    parent[segment] = copy;
    parent = copy;
  }
  return parent;
}

String _id(String section, Object? value) {
  if (section == 'extras.smartTilePatternIds') {
    return jsonEncode(['patternSelection', value]);
  }
  final json = _map(value);
  if (section == 'dynamicDependencies' ||
      section.endsWith(
        PortableCatalogPublication.projectDynamicDependenciesKey,
      )) {
    final declaration = CatalogDynamicDependency.fromJson(json);
    return jsonEncode([
      'dynamic',
      declaration.owner.kind.name,
      declaration.owner.id,
    ]);
  }
  if (section == 'resourceLibraryCatalog.entries') {
    return '${json['resourceKind']}:${json['resourceId']}';
  }
  if (section.startsWith('characterStudioCatalog.')) {
    final kind = section.endsWith('portraitStates')
        ? ResourcePackSupportKind.characterPortraitState
        : ResourcePackSupportKind.characterAnimationDefinition;
    return jsonEncode([kind.name, json['id']]);
  }
  if (section == 'smartTileCatalog.drafts') {
    return jsonEncode(['smartTileDraft', json['id']]);
  }
  if (json['id'] is! String) {
    throw const FormatException('catalog.publication: definition id required');
  }
  return json['id']! as String;
}

CatalogDefinitionUnit _unit(
  CatalogDefinitionKey key,
  String section,
  int position,
  Object? value, [
  Iterable<CatalogDefinitionKey> references = const [],
]) => CatalogDefinitionUnit(
  key: key,
  payload: {
    'id': key.id,
    'section': section,
    'position': position,
    'value': value,
  },
  references: references,
);

List<CatalogDefinitionUnit> _partition(
  Map<String, Object?> source, {
  Map<String, String> snapshotAliases = const {},
  bool project = false,
}) {
  final shell = <String, Object?>{...source};
  final result = <CatalogDefinitionUnit>[];
  for (final section in _sections.entries) {
    final parent = _partitionParent(shell, section.key);
    final field = section.key.split('.').last;
    if (parent == null || !parent.containsKey(field)) continue;
    final values = parent[field];
    if (values is! List) {
      throw FormatException(
        'catalog.publication: ${section.key} must be a list',
      );
    }
    for (var i = 0; i < values.length; i++) {
      var id = _id(section.key, values[i]);
      if (section.key == 'borderCatalog.visualSnapshots') {
        id = snapshotAliases[id] ?? id;
      }
      if (section.key == 'provenance') {
        final origin = _copy(_map(values[i]));
        final memberships = origin.remove('resources') ?? const <Object?>[];
        if (memberships is! List) {
          throw const FormatException('catalog.provenance: expected resources');
        }
        final header = _unit(
          CatalogDefinitionKey(section.value, id),
          section.key,
          i,
          origin,
        );
        result.add(
          CatalogDefinitionUnit(
            key: header.key,
            payload: {...header.payload, 'memberCount': memberships.length},
          ),
        );
        for (var index = 0; index < memberships.length; index++) {
          result.add(
            _unit(_membershipKey(id, index), r'$provenanceMembership', index, {
              'provenanceId': id,
              'resource': memberships[index],
            }),
          );
        }
      } else {
        result.add(
          _unit(
            CatalogDefinitionKey(section.value, id),
            section.key,
            i,
            values[i],
          ),
        );
      }
    }
    parent[field] = <Object?>[];
  }
  if (project) _partitionProjectMetadata(shell, result);
  result.add(_unit(_shellKey, r'$shell', 0, shell));
  return result;
}

const _projectMetadataValues = 1000000;
const _projectMetadataDepth = 128;

Map<String, Object?> _projectMetadataProjection(Map<String, Object?> source) {
  final result = <String, Object?>{...source};
  for (final section in _sections.keys) {
    final segments = section.split('.');
    var parent = result;
    var present = true;
    for (final segment in segments.take(segments.length - 1)) {
      final value = parent[segment];
      if (value == null) {
        present = false;
        break;
      }
      final copy = <String, Object?>{..._map(value)};
      parent[segment] = copy;
      parent = copy;
    }
    if (present && parent.containsKey(segments.last)) {
      parent[segments.last] = <Object?>[];
    }
  }
  return result;
}

void _validateMetadataValue(Object? value) {
  var count = 0;
  void visit(Object? current, int depth) {
    if (++count > _projectMetadataValues) {
      throw const FormatException('catalog.project: logical value limit');
    }
    if (depth > _projectMetadataDepth) {
      throw const FormatException('catalog.project: logical depth limit');
    }
    if (current is Map<String, Object?>) {
      for (final child in current.values) {
        visit(child, depth + 1);
      }
    } else if (current is List) {
      for (final child in current) {
        visit(child, depth + 1);
      }
    } else if (!(current == null ||
        current is String ||
        current is bool ||
        current is int ||
        current is double && current.isFinite)) {
      throw const FormatException('catalog.project: non JSON metadata value');
    }
  }

  visit(value, 0);
}

final class _MetadataSourceMetrics {
  _MetadataSourceMetrics(this.bytes, this.values, this.depth);
  final int bytes;
  final int values;
  final int depth;
}

final class _MetadataJsonFrame {
  _MetadataJsonFrame(this.object);
  final bool object;
  int state = 0;
}

final _metadataNumber = RegExp(
  r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
);

_MetadataSourceMetrics _metadataSourceMetrics(String source) {
  var bytes = 0;
  for (final rune in source.runes) {
    bytes += rune <= 127
        ? 1
        : rune <= 2047
        ? 2
        : rune <= 65535
        ? 3
        : 4;
    if (bytes > _projectMetadataBytes) {
      throw const FormatException(
        'catalog.project: non asset metadata byte limit',
      );
    }
  }
  final frames = <_MetadataJsonFrame>[];
  var consumedRoot = false;
  var values = 0;
  var deepest = 0;
  Never invalid() =>
      throw const FormatException('catalog.project: invalid logical JSON');
  void value() {
    if (frames.isEmpty) {
      if (consumedRoot) invalid();
      consumedRoot = true;
    } else {
      final frame = frames.last;
      if (frame.object
          ? frame.state != 2
          : frame.state != 0 && frame.state != 2) {
        invalid();
      }
      frame.state = frame.object ? 3 : 1;
    }
    if (++values > _projectMetadataValues) {
      throw const FormatException('catalog.project: logical value limit');
    }
    final depth = frames.length;
    if (depth > _projectMetadataDepth) {
      throw const FormatException('catalog.project: logical depth limit');
    }
    if (depth > deepest) deepest = depth;
  }

  var index = 0;
  while (index < source.length) {
    final code = source.codeUnitAt(index);
    if (code == 32 || code == 9 || code == 10 || code == 13) {
      index++;
      continue;
    }
    if (code == 34) {
      final key =
          frames.isNotEmpty &&
          frames.last.object &&
          (frames.last.state == 0 || frames.last.state == 4);
      if (key) {
        frames.last.state = 1;
      } else {
        value();
      }
      index++;
      var closed = false;
      while (index < source.length) {
        final character = source.codeUnitAt(index++);
        if (character == 34) {
          closed = true;
          break;
        }
        if (character < 32) invalid();
        if (character == 92) {
          if (index >= source.length) invalid();
          final escaped = source.codeUnitAt(index++);
          if (escaped == 117) {
            if (index + 4 > source.length) invalid();
            for (var digit = 0; digit < 4; digit++) {
              final hex = source.codeUnitAt(index++);
              if (!(hex >= 48 && hex <= 57 ||
                  hex >= 65 && hex <= 70 ||
                  hex >= 97 && hex <= 102)) {
                invalid();
              }
            }
          } else if (!{34, 47, 92, 98, 102, 110, 114, 116}.contains(escaped)) {
            invalid();
          }
        }
      }
      if (!closed) invalid();
      continue;
    }
    if (code == 123 || code == 91) {
      value();
      frames.add(_MetadataJsonFrame(code == 123));
      index++;
      continue;
    }
    if (code == 125 || code == 93) {
      if (frames.isEmpty) invalid();
      final frame = frames.last;
      if (frame.object != (code == 125) ||
          (frame.object
              ? frame.state != 0 && frame.state != 3
              : frame.state != 0 && frame.state != 1)) {
        invalid();
      }
      frames.removeLast();
      index++;
      continue;
    }
    if (code == 58) {
      if (frames.isEmpty || !frames.last.object || frames.last.state != 1) {
        invalid();
      }
      frames.last.state = 2;
      index++;
      continue;
    }
    if (code == 44) {
      if (frames.isEmpty) invalid();
      final frame = frames.last;
      if (frame.object ? frame.state != 3 : frame.state != 1) invalid();
      frame.state = frame.object ? 4 : 2;
      index++;
      continue;
    }
    final number = code == 45 || code >= 48 && code <= 57
        ? _metadataNumber.matchAsPrefix(source, index)
        : null;
    if (number != null) {
      value();
      index = number.end;
      continue;
    }
    String? keyword;
    for (final candidate in ['true', 'false', 'null']) {
      if (source.startsWith(candidate, index)) {
        keyword = candidate;
        break;
      }
    }
    if (keyword == null) invalid();
    value();
    index += keyword.length;
  }
  if (!consumedRoot || frames.isNotEmpty) invalid();
  return _MetadataSourceMetrics(bytes, values, deepest);
}

CatalogDefinitionKey _membershipKey(String origin, int position) =>
    CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata,
      jsonEncode(['provenanceMembership', origin, position]),
    );

const _projectMetadataBytes = 33554432;
const _aggregateChunkBytes = 65536;
const _projectDefinitionFields = {
  'maps',
  'groups',
  'encounterTables',
  'dialogueFolders',
  'dialogues',
  'scripts',
  'scenarios',
  'cinematics',
  'presentationCinematics',
  'cinematicMediaAssets',
  'facts',
  'worldRules',
  'narrativeDiagnosticSuppressions',
  'scenes',
  'storylines',
  'shops',
  'badges',
  'trainers',
  'presentationPresets',
};
const _projectAggregateFields = {
  'resourcePackInstallations',
  'cinematicLibraryCatalog',
  'runtimeSmokeProfile',
  'eventRegistry',
  'railJourneyCatalog',
  'settings',
  'battleAudio',
  'battleTransitions',
  'pokemon',
  'newGame',
  'presentation',
  'regionalMap',
  'globalProperties',
};

CatalogDefinitionKey _projectMetadataKey(
  String type,
  String field, [
  int? position,
]) => CatalogDefinitionKey(
  CatalogDefinitionKind.catalogMetadata,
  jsonEncode([type, field, ?position]),
);

void _partitionProjectMetadata(
  Map<String, Object?> shell,
  List<CatalogDefinitionUnit> result,
) {
  _metadataSourceMetrics(jsonEncode(shell));
  for (final field in _projectDefinitionFields) {
    if (!shell.containsKey(field)) continue;
    final definitions = shell[field];
    if (definitions is! List) {
      throw const FormatException('catalog.project: expected definition list');
    }
    for (var position = 0; position < definitions.length; position++) {
      result.add(
        _unit(
          _projectMetadataKey('projectDefinition', field, position),
          r'$projectDefinition',
          position,
          {'field': field, 'definition': definitions[position]},
        ),
      );
    }
    shell[field] = <Object?>[];
  }
  for (final field in _projectAggregateFields) {
    final aggregate = shell[field];
    if (aggregate == null) continue;
    final value = _map(aggregate);
    if (value.isEmpty) continue;
    final source = jsonEncode(value);
    final metrics = _metadataSourceMetrics(source);
    final bytes = utf8.encode(source);
    if (bytes.length <= 8192 && metrics.depth <= 60) {
      continue;
    }
    final chunkCount =
        (bytes.length + _aggregateChunkBytes - 1) ~/ _aggregateChunkBytes;
    result.add(
      _unit(
        _projectMetadataKey('projectAggregateHeader', field),
        r'$projectAggregateHeader',
        0,
        {
          'field': field,
          'sha256': crypto.sha256.convert(bytes).toString(),
          'byteLength': bytes.length,
          'chunkCount': chunkCount,
        },
      ),
    );
    for (var position = 0; position < chunkCount; position++) {
      final start = position * _aggregateChunkBytes;
      final end = (start + _aggregateChunkBytes).clamp(0, bytes.length);
      result.add(
        _unit(
          _projectMetadataKey('projectAggregateChunk', field, position),
          r'$projectAggregateChunk',
          position,
          {'field': field, 'data': base64.encode(bytes.sublist(start, end))},
        ),
      );
    }
    shell[field] = <String, Object?>{};
  }
}

List<CatalogDefinitionUnit> _positions(Iterable<CatalogDefinitionUnit> values) {
  final entries = values.toList();
  if (entries.any((unit) => unit.payload['position'] is! int)) {
    throw const FormatException('catalog.publication: invalid position');
  }
  entries.sort(
    (a, b) => (a.payload['position']! as int).compareTo(
      b.payload['position']! as int,
    ),
  );
  for (var position = 0; position < entries.length; position++) {
    if (entries[position].payload['position'] != position) {
      throw const FormatException(
        'catalog.publication: non contiguous positions',
      );
    }
  }
  return entries;
}

void _restoreProjectMetadata(
  Map<String, Object?> root,
  List<CatalogDefinitionUnit> units,
) {
  final headers = <String, CatalogDefinitionUnit>{};
  final chunks = <String, List<CatalogDefinitionUnit>>{};
  final definitions = <String, List<CatalogDefinitionUnit>>{};
  for (final unit in units) {
    final section = unit.payload['section'];
    if (!{
      r'$projectDefinition',
      r'$projectAggregateHeader',
      r'$projectAggregateChunk',
    }.contains(section)) {
      continue;
    }
    final field = _map(unit.payload['value'])['field'];
    if (field is! String) {
      throw const FormatException('catalog.project: invalid field');
    }
    if (section == r'$projectDefinition') {
      if (!_projectDefinitionFields.contains(field)) {
        throw const FormatException(
          'catalog.project: unknown definition field',
        );
      }
      (definitions[field] ??= []).add(unit);
    } else {
      if (!_projectAggregateFields.contains(field)) {
        throw const FormatException('catalog.project: unknown aggregate field');
      }
      if (section == r'$projectAggregateHeader') {
        if (headers.containsKey(field)) {
          throw const FormatException(
            'catalog.project: duplicate aggregate header',
          );
        }
        headers[field] = unit;
      } else {
        (chunks[field] ??= []).add(unit);
      }
    }
  }
  if (chunks.keys.any((field) => !headers.containsKey(field))) {
    throw const FormatException('catalog.project: missing aggregate header');
  }
  for (final field in definitions.entries) {
    final existing = root[field.key];
    if (existing is! List || existing.isNotEmpty) {
      throw const FormatException(
        'catalog.project: invalid definitions placeholder',
      );
    }
    root[field.key] = [
      for (final unit in _positions(field.value))
        _map(unit.payload['value'])['definition'],
    ];
  }
  if (headers.isEmpty && definitions.isEmpty) return;
  final baseline = _metadataSourceMetrics(
    jsonEncode(_projectMetadataProjection(root)),
  );
  var totalBytes = baseline.bytes;
  var totalValues = baseline.values;
  final sources = <String, String>{};
  for (final header in headers.entries) {
    final value = _map(header.value.payload['value']);
    final length = value['byteLength'];
    final count = value['chunkCount'];
    if (length is! int ||
        length < 1 ||
        length > _projectMetadataBytes ||
        count is! int ||
        count != (length + _aggregateChunkBytes - 1) ~/ _aggregateChunkBytes ||
        value['sha256'] is! String) {
      throw const FormatException('catalog.project: invalid aggregate bounds');
    }
    final parts = _positions(chunks[header.key] ?? const []);
    if (parts.length != count) {
      throw const FormatException(
        'catalog.project: aggregate chunk count mismatch',
      );
    }
    final bytes = <int>[];
    for (var position = 0; position < parts.length; position++) {
      final data = _map(parts[position].payload['value'])['data'];
      if (data is! String) {
        throw const FormatException('catalog.project: invalid aggregate data');
      }
      final chunk = base64.decode(data);
      final expectedLength = position == count - 1
          ? length - position * _aggregateChunkBytes
          : _aggregateChunkBytes;
      if (base64.encode(chunk) != data || chunk.length != expectedLength) {
        throw const FormatException('catalog.project: invalid aggregate chunk');
      }
      bytes.addAll(chunk);
    }
    if (bytes.length != length ||
        crypto.sha256.convert(bytes).toString() != value['sha256']) {
      throw const FormatException('catalog.project: aggregate digest mismatch');
    }
    final existing = root[header.key];
    if (existing is! Map || existing.isNotEmpty) {
      throw const FormatException(
        'catalog.project: invalid aggregate placeholder',
      );
    }
    final source = utf8.decode(bytes);
    final metrics = _metadataSourceMetrics(source);
    if (metrics.depth + 1 > _projectMetadataDepth) {
      throw const FormatException('catalog.project: logical depth limit');
    }
    totalBytes += metrics.bytes - 2;
    totalValues += metrics.values - 1;
    if (totalBytes > _projectMetadataBytes ||
        totalValues > _projectMetadataValues) {
      throw const FormatException('catalog.project: logical metadata budget');
    }
    sources[header.key] = source;
  }
  for (final source in sources.entries) {
    root[source.key] = _map(jsonDecode(source.value));
  }
}

void _restoreProvenanceMemberships(
  Map<String, Object?> root,
  List<CatalogDefinitionUnit> units,
) {
  final members = <String, List<CatalogDefinitionUnit>>{};
  for (final unit in units.where(
    (unit) => unit.payload['section'] == r'$provenanceMembership',
  )) {
    final origin = _map(unit.payload['value'])['provenanceId'];
    if (origin is! String) {
      throw const FormatException(
        'catalog.provenance: invalid membership owner',
      );
    }
    (members[origin] ??= []).add(unit);
  }
  final headers = {
    for (final unit in units.where(
      (unit) => unit.key.kind == CatalogDefinitionKind.provenance,
    ))
      unit.key.id: unit,
  };
  if (members.keys.any((origin) => !headers.containsKey(origin))) {
    throw const FormatException('catalog.provenance: missing membership owner');
  }
  final origins = root['provenance'];
  if (headers.isEmpty && origins == null) return;
  if (origins is! List || origins.length != headers.length) {
    throw const FormatException('catalog.provenance: invalid origins');
  }
  for (var position = 0; position < origins.length; position++) {
    final origin = _copy(_map(origins[position]));
    origins[position] = origin;
    final header = headers[origin['id']];
    final count = header?.payload['memberCount'];
    if (count is! int ||
        count < 0 ||
        count > 1000000 ||
        origin.containsKey('resources')) {
      throw const FormatException(
        'catalog.provenance: invalid membership header',
      );
    }
    final values = _positions(members[origin['id']] ?? const []);
    if (values.length != count) {
      throw const FormatException(
        'catalog.provenance: membership count mismatch',
      );
    }
    if (count > 0) {
      origin['resources'] = [
        for (final unit in values) _map(unit.payload['value'])['resource'],
      ];
    }
  }
}

CatalogDefinitionKey _nodeKey(ResourcePackNodeRef node) {
  if (node.fileId != null) {
    return CatalogDefinitionKey(
      CatalogDefinitionKind.fileBinding,
      node.fileId!,
    );
  }
  final resource = node.resource;
  if (resource != null) {
    return CatalogDefinitionKey(
      resource.kind == ResourcePackKind.borderBlueprint
          ? CatalogDefinitionKind.borderRecord
          : CatalogDefinitionKind.values.byName(resource.kind.name),
      resource.id,
    );
  }
  final support = node.support!;
  return switch (support.kind) {
    ResourcePackSupportKind.tilesetElementGroup => CatalogDefinitionKey(
      CatalogDefinitionKind.tileset,
      support.owner!.id,
    ),
    ResourcePackSupportKind.borderSnapshot => CatalogDefinitionKey(
      CatalogDefinitionKind.borderVisualSnapshot,
      support.id,
    ),
    ResourcePackSupportKind.characterPortraitState ||
    ResourcePackSupportKind.characterAnimationDefinition =>
      CatalogDefinitionKey(
        CatalogDefinitionKind.characterStudioDefinition,
        jsonEncode([support.kind.name, support.id]),
      ),
    ResourcePackSupportKind.smartTileConnectionGroup => CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata,
      jsonEncode(['smartTileConnectionGroup', support.id]),
    ),
    _ => CatalogDefinitionKey(
      CatalogDefinitionKind.values.byName(support.kind.name),
      support.id,
    ),
  };
}

List<CatalogDefinitionUnit> _catalogUnits(ResourcePackCatalog catalog) {
  final units = _partition(
    catalog.toJson(),
    snapshotAliases: {
      for (final snapshot in catalog.borderCatalog.visualSnapshots)
        snapshot.id: resourcePackBorderSnapshotAlias(
          snapshot.contentFingerprint,
        ),
    },
  );
  final dependencies = <CatalogDefinitionKey, Set<CatalogDefinitionKey>>{};
  final actual = units.map((unit) => unit.key).toSet();
  for (final family in ResourceLibraryCatalog.predefinedFamilies) {
    final key = CatalogDefinitionKey(
      CatalogDefinitionKind.resourceFamily,
      family.id,
    );
    if (!actual.contains(key)) {
      units.add(_unit(key, r'$virtual', 0, family.toJson()));
      actual.add(key);
    }
  }
  for (final node in ResourcePackReferenceVisitor(catalog).nodes()) {
    final key = _nodeKey(node.reference);
    if (!actual.contains(key) &&
        node.reference.support?.kind ==
            ResourcePackSupportKind.smartTileConnectionGroup) {
      units.add(
        _unit(key, r'$virtual', 0, {
          'connectionGroupId': node.reference.support!.id,
        }),
      );
      actual.add(key);
    }
    final refs = dependencies.putIfAbsent(key, () => {});
    for (final dependency in node.dependencies) {
      final target = _nodeKey(dependency);
      if (target != key) refs.add(target);
    }
  }
  for (final entry in catalog.resourceLibraryCatalog.entries) {
    final key = CatalogDefinitionKey(
      CatalogDefinitionKind.resourceLibraryEntry,
      entry.identity,
    );
    dependencies[key] = {
      _nodeKey(
        ResourcePackNodeRef.resource(
          ResourcePackRef(
            kind: ResourcePackKind.values.byName(entry.resourceKind),
            id: entry.resourceId,
          ),
        ),
      ),
      if (entry.familyId != null)
        CatalogDefinitionKey(
          CatalogDefinitionKind.resourceFamily,
          entry.familyId!,
        ),
    };
  }
  for (final file in catalog.files) {
    (dependencies[CatalogDefinitionKey(
              CatalogDefinitionKind.fileBinding,
              file.id,
            )] ??=
            {})
        .add(
          CatalogDefinitionKey(
            CatalogDefinitionKind.provenance,
            file.provenanceId,
          ),
        );
  }
  for (final provenance in catalog.provenance) {
    for (var index = 0; index < provenance.resources.length; index++) {
      dependencies[_membershipKey(provenance.id, index)] = {
        CatalogDefinitionKey(CatalogDefinitionKind.provenance, provenance.id),
        _nodeKey(ResourcePackNodeRef.resource(provenance.resources[index])),
      };
    }
  }
  for (final id in catalog.smartTilePatternIds) {
    dependencies[CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata,
      jsonEncode(['patternSelection', id]),
    )] = {
      CatalogDefinitionKey(CatalogDefinitionKind.smartTilePattern, id),
    };
  }
  return _applyDependencies(units, dependencies, catalog.dynamicDependencies);
}

List<CatalogDefinitionUnit> _projectUnits(ProjectManifest project) {
  final source = project.toJson();
  final metadata = _projectMetadataProjection(source);
  _validateMetadataValue(metadata);
  _metadataSourceMetrics(jsonEncode(metadata));
  return _applyDependencies(
    _partition(source, project: true),
    {},
    PortableCatalogPublication.projectDynamicDependencies(project),
  );
}

List<CatalogDefinitionUnit> _applyDependencies(
  List<CatalogDefinitionUnit> units,
  Map<CatalogDefinitionKey, Set<CatalogDefinitionKey>> dependencies,
  List<CatalogDynamicDependency> declarations,
) {
  final keys = units.map((unit) => unit.key).toSet();
  final owners = <CatalogDefinitionKey>{};
  final declaredTargets = <CatalogDefinitionKey, List<CatalogDefinitionKey>>{};
  for (final declaration in declarations) {
    if (!owners.add(declaration.owner) ||
        !keys.contains(declaration.owner) ||
        declaration.targets.any((target) => !keys.contains(target))) {
      throw const FormatException(
        'catalog.dynamic: duplicate declaration, missing owner or target',
      );
    }
    declaredTargets[declaration.owner] = declaration.targets;
    (dependencies[declaration.owner] ??= {}).addAll(declaration.targets);
    dependencies[CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata,
      jsonEncode([
        'dynamic',
        declaration.owner.kind.name,
        declaration.owner.id,
      ]),
    )] = {
      declaration.owner,
    };
  }
  final incoming = {for (final owner in owners) owner: 0};
  for (final targets in declaredTargets.values) {
    for (final target in targets) {
      if (owners.contains(target)) incoming[target] = incoming[target]! + 1;
    }
  }
  final ready = [
    for (final owner in owners)
      if (incoming[owner] == 0) owner,
  ];
  for (var position = 0; position < ready.length; position++) {
    for (final target in declaredTargets[ready[position]]!) {
      if (!owners.contains(target)) continue;
      incoming[target] = incoming[target]! - 1;
      if (incoming[target] == 0) ready.add(target);
    }
  }
  if (ready.length != owners.length) {
    throw const FormatException('catalog.dynamic: dependency cycle');
  }
  return [
    for (final unit in units)
      CatalogDefinitionUnit(
        key: unit.key,
        payload: unit.payload,
        references: dependencies[unit.key] ?? const [],
      ),
  ];
}

Map<String, Object?> _reconstruct(List<CatalogDefinitionUnit> units) {
  final shells = units.where((unit) => unit.key == _shellKey).toList();
  if (shells.length != 1) {
    throw const FormatException('catalog.publication: missing shell');
  }
  final root = _copy(_map(shells.single.payload['value']));
  _restoreProjectMetadata(root, units);
  final grouped = <String, List<CatalogDefinitionUnit>>{};
  for (final unit in units) {
    final section = unit.payload['section'];
    if ({
      r'$shell',
      r'$virtual',
      r'$provenanceMembership',
      r'$projectDefinition',
      r'$projectAggregateHeader',
      r'$projectAggregateChunk',
    }.contains(section)) {
      continue;
    }
    if (section is! String || !_sections.containsKey(section)) {
      throw const FormatException('catalog.publication: unknown section');
    }
    (grouped[section] ??= []).add(unit);
  }
  for (final group in grouped.entries) {
    final entries = group.value;
    if (entries.any((unit) => unit.payload['position'] is! int)) {
      throw const FormatException('catalog.publication: invalid position');
    }
    entries.sort(
      (a, b) => (a.payload['position']! as int).compareTo(
        b.payload['position']! as int,
      ),
    );
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].payload['position'] != i) {
        throw const FormatException(
          'catalog.publication: non contiguous positions',
        );
      }
    }
    final parent = _parent(root, group.key);
    final field = group.key.split('.').last;
    if (parent == null ||
        parent[field] is! List ||
        (parent[field]! as List).isNotEmpty) {
      throw const FormatException('catalog.publication: invalid shell section');
    }
    parent[field] = [for (final entry in entries) entry.payload['value']];
  }
  _restoreProvenanceMemberships(root, units);
  return root;
}

void _verifyUnits(
  List<CatalogDefinitionUnit> received,
  List<CatalogDefinitionUnit> expected,
) {
  final byKey = {for (final unit in expected) unit.key: unit};
  if (received.length != expected.length) {
    throw const FormatException(
      'catalog.publication: unexpected definition count',
    );
  }
  for (final unit in received) {
    final canonical = byKey[unit.key];
    if (canonical == null ||
        jsonEncode(unit.toJson()) != jsonEncode(canonical.toJson())) {
      throw const FormatException(
        'catalog.publication: payload or typed references mismatch',
      );
    }
  }
}
