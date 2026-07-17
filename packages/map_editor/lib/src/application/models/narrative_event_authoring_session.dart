import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';

final class NarrativeEventAuthoringSession {
  NarrativeEventAuthoringSession._({
    required this.projectPath,
    required this.projectRevision,
    required this.manifest,
    required List<MapData> maps,
    required this.registryFingerprint,
    required this.manifestSemanticHash,
    required Map<String, String> mapManifestPaths,
    required Map<String, String> mapPaths,
    required Map<String, String> mapByteHashes,
    required this.catalogFingerprint,
    required this.sourceIndexFingerprint,
    required this.totalMapBytes,
    required this.context,
  })  : maps = List.unmodifiable(maps),
        mapManifestPaths = Map.unmodifiable(mapManifestPaths),
        mapPaths = Map.unmodifiable(mapPaths),
        mapByteHashes = Map.unmodifiable(mapByteHashes);

  static Future<NarrativeEventAuthoringSession> prepare(
    String projectPath,
  ) async {
    try {
      final projectFile = File(projectPath);
      if (!await projectFile.exists()) {
        throw const NarrativeEventAuthoringSessionException(
          'Le manifest du projet est introuvable.',
        );
      }
      final canonicalProjectPath = p.normalize(
        await projectFile.resolveSymbolicLinks(),
      );
      final canonicalProjectFile = File(canonicalProjectPath);
      final projectBytes = await canonicalProjectFile.readAsBytes();
      final project = decodeValidatedNarrativeEventAuthoringProject(
        projectBytes,
      );
      final manifest = project.manifest;
      final projectRoot = p.dirname(canonicalProjectPath);
      final mapManifestPaths = <String, String>{};
      final mapPaths = <String, String>{};
      final mapByteHashes = <String, String>{};
      final maps = <MapData>[];
      var totalMapBytes = 0;
      final manifestMapIds = <String>{};
      final loadedMapIds = <String>{};
      for (final entry in manifest.maps) {
        if (!manifestMapIds.add(entry.id)) {
          throw NarrativeEventAuthoringSessionException(
            'La map ${entry.id} est déclarée plusieurs fois.',
          );
        }
        if (p.isAbsolute(entry.relativePath)) {
          throw NarrativeEventAuthoringSessionException(
            'Le chemin de la map ${entry.id} doit rester relatif au projet.',
          );
        }
        final candidate = File(p.normalize(p.join(
          projectRoot,
          entry.relativePath,
        )));
        if (!await candidate.exists()) {
          throw NarrativeEventAuthoringSessionException(
            'La map ${entry.id} est introuvable.',
          );
        }
        final canonicalMapPath = p.normalize(
          await candidate.resolveSymbolicLinks(),
        );
        if (!p.isWithin(projectRoot, canonicalMapPath)) {
          throw NarrativeEventAuthoringSessionException(
            'Le chemin de la map ${entry.id} sort du projet.',
          );
        }
        final mapBytes = await File(canonicalMapPath).readAsBytes();
        final map = decodeValidatedNarrativeEventAuthoringMap(
          mapBytes,
          canonicalMapPath,
        );
        if (map.id != entry.id) {
          throw NarrativeEventAuthoringSessionException(
            'La map ${entry.id} contient l’identité ${map.id}.',
          );
        }
        if (!loadedMapIds.add(map.id)) {
          throw NarrativeEventAuthoringSessionException(
            'La map ${map.id} est chargée plusieurs fois.',
          );
        }
        mapManifestPaths[map.id] = p.normalize(candidate.path);
        mapPaths[map.id] = canonicalMapPath;
        mapByteHashes[map.id] = narrativeEventBytesFingerprint(mapBytes);
        totalMapBytes += mapBytes.length;
        maps.add(map);
      }
      final catalog = buildNarrativeEventProjectCatalog(
        project: manifest,
        maps: maps,
      );
      final registry = project.registryState.registryOrNull;
      final sourceIndex = buildNarrativeEventSourceIndex(
        registry?.records ?? const <NarrativeEventRecord>[],
      );
      final projectRevision = narrativeEventBytesFingerprint(projectBytes);
      final context = NarrativeEventAuthoringContext(
        registryState: project.registryState,
        revision: projectRevision,
        catalog: catalog,
        sourceIndex: sourceIndex,
        manifestHash: catalog.manifestHash,
        mapHashes: catalog.mapHashes,
      );
      final contextIssue = context.inspect(projectRevision);
      if (contextIssue != null) {
        throw NarrativeEventAuthoringSessionException(contextIssue.message);
      }
      return NarrativeEventAuthoringSession._(
        projectPath: canonicalProjectPath,
        projectRevision: projectRevision,
        manifest: manifest,
        maps: maps,
        registryFingerprint: narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(registry?.toJson()),
        ),
        manifestSemanticHash: catalog.manifestHash,
        mapManifestPaths: mapManifestPaths,
        mapPaths: mapPaths,
        mapByteHashes: mapByteHashes,
        catalogFingerprint: narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(catalog.toDebugJson()),
        ),
        sourceIndexFingerprint: _sourceIndexFingerprint(sourceIndex),
        totalMapBytes: totalMapBytes,
        context: context,
      );
    } on NarrativeEventAuthoringSessionException {
      rethrow;
    } on Object catch (error) {
      throw NarrativeEventAuthoringSessionException(
        'La session Event ne peut pas être préparée: $error',
      );
    }
  }

  final String projectPath;
  final String projectRevision;

  /// Exact validated project snapshot used to attest this session.
  ///
  /// Event Builder V2 consumes it together with [maps] to build its canonical
  /// project-level read model without re-reading only the active map.
  final ProjectManifest manifest;

  /// Every validated map from the same attested project snapshot.
  final List<MapData> maps;

  final String registryFingerprint;
  final String manifestSemanticHash;
  final Map<String, String> mapManifestPaths;
  final Map<String, String> mapPaths;
  final Map<String, String> mapByteHashes;
  final String catalogFingerprint;
  final String sourceIndexFingerprint;
  final int totalMapBytes;
  final NarrativeEventAuthoringContext context;

  bool hasSameAttestation(NarrativeEventAuthoringSession other) {
    return projectPath == other.projectPath &&
        projectRevision == other.projectRevision &&
        registryFingerprint == other.registryFingerprint &&
        manifestSemanticHash == other.manifestSemanticHash &&
        _stringMapsEqual(mapManifestPaths, other.mapManifestPaths) &&
        _stringMapsEqual(mapPaths, other.mapPaths) &&
        _stringMapsEqual(mapByteHashes, other.mapByteHashes) &&
        catalogFingerprint == other.catalogFingerprint &&
        sourceIndexFingerprint == other.sourceIndexFingerprint;
  }
}

final class ValidatedNarrativeEventAuthoringProject {
  const ValidatedNarrativeEventAuthoringProject({
    required this.manifest,
    required this.registryState,
  });

  final ProjectManifest manifest;
  final EventRegistryDecodeResult registryState;
}

ValidatedNarrativeEventAuthoringProject
    decodeValidatedNarrativeEventAuthoringProject(List<int> bytes) {
  final preflight = preflightProjectManifestJson(bytes);
  if (!preflight.writable) {
    throw NarrativeEventAuthoringSessionException(
      preflight.diagnostics.isEmpty
          ? 'Le manifest ne peut pas préparer une session Event.'
          : preflight.diagnostics.join(' '),
    );
  }
  final decoded = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  if (decoded is! Map) {
    throw const NarrativeEventAuthoringSessionException(
      'Le manifest doit être un objet JSON.',
    );
  }
  final json = <String, dynamic>{};
  for (final entry in decoded.entries) {
    if (entry.key is! String) {
      throw const NarrativeEventAuthoringSessionException(
        'Le manifest contient une clé invalide.',
      );
    }
    json[entry.key as String] = entry.value;
  }
  final manifest = normalizeLoadedProjectManifest(
    ProjectManifest.fromJson(migrateProjectManifestJson(json)),
  );
  ProjectValidator.validate(manifest);
  return ValidatedNarrativeEventAuthoringProject(
    manifest: manifest,
    registryState: preflight.eventRegistry,
  );
}

MapData decodeValidatedNarrativeEventAuthoringMap(
  List<int> bytes,
  String path,
) {
  final decoded = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  if (decoded is! Map) {
    throw NarrativeEventAuthoringSessionException(
      'La map $path doit être un objet JSON.',
    );
  }
  final json = <String, dynamic>{};
  for (final entry in decoded.entries) {
    if (entry.key is! String) {
      throw NarrativeEventAuthoringSessionException(
        'La map $path contient une clé invalide.',
      );
    }
    json[entry.key as String] = entry.value;
  }
  final map = MapData.fromJson(migrateMapDataJson(json));
  MapValidator.validate(map);
  return map;
}

ProjectManifest normalizeLoadedProjectManifest(ProjectManifest manifest) {
  return manifest.copyWith(
    elements: [
      for (final element in manifest.elements)
        _normalizeProjectElementCollisionProfile(element, manifest.settings),
    ],
  );
}

ProjectElementEntry _normalizeProjectElementCollisionProfile(
  ProjectElementEntry element,
  ProjectSettings settings,
) {
  final profile = element.collisionProfile;
  if (profile == null) return element;
  return element.copyWith(
    collisionProfile: normalizeElementCollisionProfile(
      profile,
      tileSize: _collisionProfileTileSize(settings, profile),
    ),
  );
}

int _collisionProfileTileSize(
  ProjectSettings settings,
  ElementCollisionProfile profile,
) {
  if (profile.collisionMask != null &&
      settings.tileWidth != settings.tileHeight) {
    throw ValidationException(
      'Cannot normalize collision masks for non-square project tiles: '
      '${settings.tileWidth}x${settings.tileHeight}',
    );
  }
  return settings.tileWidth;
}

String _sourceIndexFingerprint(NarrativeEventSourceIndexBuildResult value) {
  final sources = value.index.sources.toList()
    ..sort((left, right) => canonicalizeNarrativeEventJson(left.toJson())
        .compareTo(canonicalizeNarrativeEventJson(right.toJson())));
  return narrativeEventBytesFingerprint(canonicalizeNarrativeEventJsonUtf8({
    'sources': [
      for (final source in sources)
        {
          'source': source.toJson(),
          'records': [
            for (final record in value.index.recordsFor(source))
              record.toJson(),
          ],
        },
    ],
    'conflicts': [
      for (final conflict in value.conflicts)
        {
          'source': conflict.source.toJson(),
          'priority': conflict.priority,
          'order': conflict.order,
          'eventIds': [for (final record in conflict.records) record.id],
        },
    ],
  }));
}

bool _stringMapsEqual(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
