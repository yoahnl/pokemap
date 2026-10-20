import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:path/path.dart' as p;

Future<Map<String, Object?>> runRealProjectPlayerCatalogProbe({
  required String projectDirectory,
  required String outputPath,
  List<String>? mapIds,
  int maximumOutputBytes = 30 * 1024,
}) async {
  if (maximumOutputBytes < 1024 || maximumOutputBytes > 30 * 1024) {
    throw ArgumentError.value(maximumOutputBytes, 'maximumOutputBytes');
  }
  if (mapIds != null &&
      (mapIds.length != 3 ||
          mapIds.toSet().length != 3 ||
          mapIds.any((id) => id.isEmpty || id.length > 512))) {
    throw ArgumentError('Select exactly three distinct map identities.');
  }
  final root = await Directory(projectDirectory).resolveSymbolicLinks();
  final sourceFile = File(p.join(root, 'project.json'));
  final canonicalSource = await sourceFile.resolveSymbolicLinks();
  if (!p.isWithin(root, canonicalSource)) {
    throw ArgumentError('The project document escapes its source directory.');
  }
  final output = File(p.absolute(outputPath));
  final outputParent = await output.parent.resolveSymbolicLinks();
  if (outputParent == root || p.isWithin(root, outputParent)) {
    throw ArgumentError('The output must be outside the source project.');
  }
  if (await FileSystemEntity.type(output.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw ArgumentError('The output must not already exist.');
  }
  final sourceBefore = await _fingerprint(sourceFile);
  final memory = _MemorySampler()..start();
  final phases = <Map<String, Object?>>[];
  final mapSources = <String, Map<String, Object?>>{};
  final budget = RuntimeResourceBudget();
  RuntimeProjectCatalog? catalog;
  RuntimeMapBundle? currentBundle;
  ProjectManifest? metadata;
  final route = <String>[];
  var bundleLoadCount = 0;
  var catalogOpenCount = 0;
  var activePhase = 'catalogOpen';
  Map<String, Object?>? failure;
  var ownerReleased = false;
  var sourceUnchanged = false;
  var mapsUnchanged = true;
  Map<String, Object?>? sourceAfter;

  Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    String? mapId,
  }) async {
    activePhase = name;
    final phase = <String, Object?>{
      'phase': name,
      'mapId': ?mapId,
      'rssBeforeBytes': ProcessInfo.currentRss,
      'status': 'completed',
    };
    memory.beginPhase(phase['rssBeforeBytes']! as int);
    final watch = Stopwatch()..start();
    try {
      return await operation();
    } catch (_) {
      phase['status'] = 'failed';
      rethrow;
    } finally {
      watch.stop();
      memory.observe();
      phase.addAll({
        'elapsedMicroseconds': watch.elapsedMicroseconds,
        'rssAfterBytes': ProcessInfo.currentRss,
        'rssSampledPeakBytes': memory.phasePeak,
        'rssSamplesDuringPhase': memory.phaseSamples,
        'processMaxRssBytes': ProcessInfo.maxRss,
      });
      phases.add(phase);
    }
  }

  try {
    catalogOpenCount++;
    final opened = await measure(
      'catalogOpen',
      () => RuntimeProjectCatalog.open(canonicalSource),
    );
    catalog = opened;
    metadata = opened.projectMetadata;
    final selected = mapIds ?? _selectMaps(metadata);
    for (final id in selected) {
      if (metadata.maps.where((entry) => entry.id == id).length != 1) {
        throw FormatException('Map identity is missing or ambiguous: $id');
      }
      final entry = metadata.maps.singleWhere((entry) => entry.id == id);
      final file = File(p.normalize(p.join(root, entry.relativePath)));
      if (!p.isWithin(root, file.path) ||
          !p.isWithin(root, await file.resolveSymbolicLinks())) {
        throw FormatException('Map document escapes its source directory: $id');
      }
      mapSources[id] = {
        'mapId': id,
        'path': file.path,
        'before': await _fingerprint(file),
      };
    }
    route.addAll([...selected, selected.first]);
    for (var index = 0; index < route.length; index++) {
      final name = switch (index) {
        0 => 'firstMap',
        3 => 'revisit',
        _ => 'visit',
      };
      RuntimeMapBundleLoadProfile? loadProfile;
      final bundle = await measure(
        name,
        () => loadRuntimeMapBundle(
          projectFilePath: canonicalSource,
          mapId: route[index],
          projectCatalog: catalog,
          resourceBudget: budget,
          profileSink: (value) => loadProfile = value,
        ),
        mapId: route[index],
      );
      bundleLoadCount++;
      currentBundle = bundle;
      final phase = phases.last;
      phase.addAll({
        'catalogShared': identical(bundle.projectCatalog, catalog),
        'resourceBudgetShared': identical(bundle.resourceBudget, budget),
        'mapSize': {
          'width': bundle.map.size.width,
          'height': bundle.map.size.height,
          'layers': bundle.map.layers.length,
          'entities': bundle.map.entities.length,
        },
        'dependencies': _dependencies(bundle.manifest),
        'imagePaths': _identities(bundle.runtimeImageAbsolutePathsById.keys),
        'loaderProfile': _profile(loadProfile!),
        'resourceBudget': _budget(budget),
      });
    }
  } catch (error, stack) {
    failure = {
      'phase': activePhase,
      'type': error.runtimeType.toString(),
      'message': _boundedText(error.toString(), 1536),
      'stack': _boundedText(stack.toString(), 2048),
    };
  } finally {
    await measure('dispose', () async {
      currentBundle = null;
      catalog?.dispose();
      budget.dispose();
      ownerReleased =
          metadata == null || RuntimeProjectCatalog.ownerOf(metadata) == null;
    });
    memory.stop();
    try {
      sourceAfter = await _fingerprint(sourceFile);
      sourceUnchanged = _sameFingerprint(sourceBefore, sourceAfter);
      for (final source in mapSources.values) {
        final after = await _fingerprint(File(source['path']! as String));
        source['after'] = after;
        source['unchanged'] = _sameFingerprint(
          source['before']! as Map<String, Object?>,
          after,
        );
        mapsUnchanged = mapsUnchanged && source['unchanged'] == true;
      }
    } catch (error) {
      failure ??= {
        'phase': 'sourceVerification',
        'type': error.runtimeType.toString(),
        'message': _boundedText(error.toString(), 1536),
      };
    }
  }
  final receipt = <String, Object?>{
    'schemaVersion': 1,
    'benchmark': 'real_project_player_catalog_load',
    'status': failure != null
        ? 'failed'
        : sourceUnchanged && mapsUnchanged
        ? 'completed'
        : 'sourceChanged',
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'execution': {
      'sdk': Platform.version,
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'pid': pid,
      'mode': 'flutter-test',
      'filesystemCache': 'uncontrolled; source files hashed before timing',
      'scope': 'catalog and map bundles; no rendered frame or image-cache load',
      'hostScope': 'loader subset; not a complete Hub session startup',
      'sourceVerificationScope': 'project.json and selected maps only; other source files stay mutable',
      'dependencyTiming': 'included in each bundle mapLoad phase',
      'rssScope': 'whole process; sampled RSS is not heap or GPU memory',
      'rssSamplingLimit':
          'the timer cannot sample during synchronous decode; '
          'maxRss is cumulative and cannot attribute that peak to a phase',
      'disposeScope':
          'drops the current bundle and disposes catalog/budget; '
          'does not force GC or require immediate RSS reclamation',
    },
    'source': {
      'path': canonicalSource,
      'before': sourceBefore,
      'after': sourceAfter,
      'unchanged': sourceUnchanged,
    },
    'catalogIdentity': catalog?.identity,
    'metadataCounts': metadata == null ? null : _metadataCounts(metadata),
    'route': route,
    'mapSources': mapSources.values.toList(),
    'catalogOpenCount': catalogOpenCount,
    'bundleLoadCount': bundleLoadCount,
    'retainedProbeBundleCount': currentBundle == null ? 0 : 1,
    'catalogOwnerReleased': ownerReleased,
    'phases': phases,
    'memory': memory.toJson(),
    'resourceBudgetAfterDispose': _budget(budget),
    'error': ?failure,
  };
  final bytes = utf8.encode('${jsonEncode(receipt)}\n');
  if (bytes.length > maximumOutputBytes) {
    throw StateError('Probe receipt exceeds $maximumOutputBytes bytes.');
  }
  await output.writeAsBytes(bytes, flush: true);
  return receipt;
}

Future<Map<String, Object?>> _fingerprint(File file) async {
  final before = await file.stat();
  final digest = await sha256.bind(file.openRead()).first;
  final after = await file.stat();
  if (before.size != after.size || before.modified != after.modified) {
    throw FileSystemException('Source changed while hashing', file.path);
  }
  return {
    'bytes': after.size,
    'modifiedUtc': after.modified.toUtc().toIso8601String(),
    'sha256': digest.toString(),
  };
}

bool _sameFingerprint(
  Map<String, Object?> before,
  Map<String, Object?> after,
) =>
    before['sha256'] == after['sha256'] &&
    before['bytes'] == after['bytes'] &&
    before['modifiedUtc'] == after['modifiedUtc'];

List<String> _selectMaps(ProjectManifest metadata) {
  final first =
      metadata.newGame.enabled && metadata.newGame.startMapId.isNotEmpty
      ? metadata.newGame.startMapId
      : metadata.maps.firstOrNull?.id;
  final selected = [
    ?first,
    ...metadata.maps
        .map((entry) => entry.id)
        .where((id) => id != first)
        .take(2),
  ];
  if (selected.length != 3 || selected.toSet().length != 3) {
    throw const FormatException('The probe requires three distinct maps.');
  }
  return selected;
}

Map<String, Object?> _identities(Iterable<String> source) {
  final ids = source.toSet().toList()..sort();
  return {
    'count': ids.length,
    'sha256': sha256.convert(utf8.encode(jsonEncode(ids))).toString(),
    'sample': ids.take(3).map((id) => _boundedText(id, 96)).toList(),
    'omitted': ids.length > 3 ? ids.length - 3 : 0,
  };
}

Map<String, Object?> _dependencies(ProjectManifest project) => {
  'tilesets': _identities(project.tilesets.map((entry) => entry.id)),
  'elements': _identities(project.elements.map((entry) => entry.id)),
  'characters': _identities(project.characters.map((entry) => entry.id)),
  'models3d': _identities(project.models3d.map((entry) => entry.id)),
  'borderRecords': _identities(
    project.borderCatalog.records.map((entry) => entry.id),
  ),
  'borderSnapshots': _identities(
    project.borderCatalog.visualSnapshots.map((entry) => entry.id),
  ),
  'smartTileMaterials': _identities(
    project.smartTileCatalog.materials.map((entry) => entry.id),
  ),
  'smartTilePatterns': _identities(
    project.smartTileCatalog.patterns.map((entry) => entry.id),
  ),
};

Map<String, Object?> _metadataCounts(ProjectManifest project) => {
  'maps': project.maps.length,
  'scenes': project.scenes.length,
  'dialogues': project.dialogues.length,
  'scenarios': project.scenarios.length,
  'trainers': project.trainers.length,
  'eventRecords': project.eventRegistry?.records.length ?? 0,
  'visualDefinitions': _dependencies(project),
};

Map<String, Object?> _profile(RuntimeMapBundleLoadProfile value) => {
  'totalMicroseconds': value.totalMicroseconds,
  'manifestLoadMicroseconds': value.manifestLoadMicroseconds,
  'mapLoadIncludingDependenciesMicroseconds': value.mapLoadMicroseconds,
  'assetCatalogLoadMicroseconds': value.assetCatalogLoadMicroseconds,
  'tilesetResolutionMicroseconds': value.tilesetResolutionMicroseconds,
  'borderPreparationMicroseconds': value.borderPreparationMicroseconds,
};

Map<String, Object?> _budget(RuntimeResourceBudget budget) => {
  'residentBytes': budget.residentBytes,
  'transientBytes': budget.transientBytes,
  'peakBytes': budget.peakBytes,
  'activeDecodes': budget.activeDecodes,
  'pendingDecodes': budget.pendingDecodes,
  'disposed': budget.isDisposed,
};

String _boundedText(String value, int maximum) =>
    value.length <= maximum ? value : '${value.substring(0, maximum - 3)}...';

final class _MemorySampler {
  Timer? _timer;
  final baselineRss = ProcessInfo.currentRss;
  final baselineProcessMaxRss = ProcessInfo.maxRss;
  var peak = ProcessInfo.currentRss;
  var samples = 0;
  var phasePeak = 0;
  var phaseSamples = 0;
  int? _rssAtStop;
  int? _processMaxRssAtStop;

  void start() {
    observe();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => observe(),
    );
  }

  void beginPhase(int rssBefore) {
    phasePeak = rssBefore;
    phaseSamples = 0;
  }

  void observe() {
    final rss = ProcessInfo.currentRss;
    samples++;
    phaseSamples++;
    if (rss > peak) peak = rss;
    if (rss > phasePeak) phasePeak = rss;
  }

  void stop() {
    observe();
    _rssAtStop = ProcessInfo.currentRss;
    _processMaxRssAtStop = ProcessInfo.maxRss;
    _timer?.cancel();
  }

  Map<String, Object?> toJson() => {
    'sampleIntervalMs': 100,
    'sampleCount': samples,
    'baselineRssBytes': baselineRss,
    'sampledPeakRssBytes': peak,
    'rssAfterDisposeBytes': _rssAtStop,
    'processMaxRssBeforeBytes': baselineProcessMaxRss,
    'processMaxRssAfterBytes': _processMaxRssAtStop,
    'processMaxRssScope':
        'cumulative since process launch; never reset per phase',
  };
}
