import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

const _mapExecutionAuditHashes = {
  21: '2c410c2da4334afa802a6eb2351ee8f76df1c9006396339ce8ca511bf4794dc4',
  83: '024b7c4179bc2b13e4bcd20ca1660c028a444477cf3b4051cf549c349d51f6b0',
  98: 'b6761d596c30bf7fc7119cbc422ac9a01e910a77c0a4a3da597eb8e4be59b620',
  100: '3a101f07319e797c0021212ce5e6adc5344128eaff4b1ea2c4712219289c47a0',
  102: '85bf6e82ae6c6271b30546297f6d9bbd2f472b32f1e0e2ac383a3c6248315ce7',
};

String _mapSourcePath(int id) =>
    'Data/Map${id.toString().padLeft(3, '0')}.rxdata';

final class SourceEventExecutionContext {
  SourceEventExecutionContext._({
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.sourceProfileHash,
    required this.baseDraftHash,
    required Map<int, String> mapIds,
    required Map<int, Sha256Hash> mapHashes,
    required List<String> refusals,
    required Map<String, Object?> proof,
  })  : mapIds = Map.unmodifiable(mapIds),
        _mapHashes = Map.unmodifiable(mapHashes),
        refusals = List.unmodifiable(refusals),
        _proof = canonicalJsonOf(proof);

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizationHash;
  final Sha256Hash sourceProfileHash;
  final Sha256Hash? baseDraftHash;
  final Map<int, String> mapIds;
  final List<String> refusals;
  final Map<int, Sha256Hash> _mapHashes;
  final String _proof;

  bool get isQualified => refusals.isEmpty;

  bool supportsRouteBarrierOnSourceMap(int sourceMapId) =>
      isQualified &&
      const {100, 102}.contains(sourceMapId) &&
      mapIds.containsKey(sourceMapId);

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile,
          Map<int, MapData> maps) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      profile.canonicalHash == sourceProfileHash &&
      maps.length == mapIds.length &&
      mapIds.entries.every((entry) =>
          maps[entry.key]?.id == entry.value &&
          canonicalHashOf(maps[entry.key]!.toJson()) == _mapHashes[entry.key]);

  Map<String, Object?> toJson() => {
        'kind': 'sourceEventExecutionContext',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'sourceProfileHash': sourceProfileHash.value,
        'baseDraftHash': baseDraftHash?.value,
        'mapIds': {
          for (final entry in mapIds.entries) '${entry.key}': entry.value
        },
        'mapHashes': {
          for (final entry in _mapHashes.entries)
            '${entry.key}': entry.value.value
        },
        'qualified': isQualified,
        'refusals': refusals,
        'proof': jsonDecode(_proof),
      };
}

final class SourceEventExecutionContextResolver {
  const SourceEventExecutionContextResolver();

  Future<SourceEventExecutionContext> read({
    required NormalizedSourceProject source,
    required NativeProjectDraft? base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final profile = SourceEventProfile.kantoForProject(source);
    final refusals = <String>{};
    final proof = <String, Object?>{};
    final snapshotHash = source.snapshot.canonicalHash;
    final normalizationHash = source.canonicalHash;
    final pluginInventory = {
      'entries': [
        for (final entry in source.snapshot.entries
            .where((entry) => _isPluginPath(entry.relativePath)))
          {
            'relativePath': entry.relativePath,
            'kind': entry.kind.name,
            'byteLength': entry.byteLength,
            'sha256': entry.sha256?.value,
          }
      ],
      'excludedPaths':
          source.snapshot.excludedPaths.where(_isPluginPath).toList(),
    };
    final pluginInventoryHash = canonicalHashOf(pluginInventory);
    if (pluginInventoryHash.value !=
        '40dd5e2e763f4f1ea6ed5a2a8eab7f57501e6c26ed85573b41914fc0380515b0') {
      refusals.add('sourcePluginInventoryUnsupported');
    }
    if (base == null) {
      refusals.add('sourceExecutionContextUnknown');
    } else {
      base.validateResourceBudget(limits: limits);
      if (base.source.canonicalHash != normalizationHash ||
          canonicalJsonOf({
                for (final entry in nativeMaps.entries)
                  '${entry.key}': entry.value.id
              }) !=
              canonicalJsonOf({
                for (final entry in base.mapIds.entries)
                  '${entry.key}': entry.value
              })) {
        refusals.add('sourceExecutionBaseBindingInvalid');
      }
      final composition = base.compositionEvidence['composition'];
      if (base.compositionEvidence.keys.any((key) =>
              const {'kind', 'version', 'compositionHash'}.contains(key)) &&
          (base.compositionEvidence['kind'] != 'literalTileComposition' ||
              base.compositionEvidence['version'] != 1 ||
              composition is! Map ||
              base.compositionEvidence['compositionHash'] !=
                  canonicalHashOf(composition, limits: limits.jsonLimits)
                      .value)) {
        refusals.add('sourceExecutionBaseUnsupported');
      }
      if (base.compositionEvidence.containsKey('sourceCheckpoint') ||
          base.mutations.any((entry) =>
              entry.actionId.startsWith('game_save.') ||
              entry.actionId.startsWith('checkpoint.'))) {
        refusals.add('sourceCheckpointImportUnsupported');
      }
      if (base.compositionEvidence.keys.any((key) => !const {
                'composition',
                'kind',
                'version',
                'compositionHash',
                'sourceSemantics',
                'sourceCheckpoint'
              }.contains(key)) ||
          base.mutations.any((entry) => !const {
                'tileset.import_image',
                'tileset.upsert',
                'map.create',
                'map.save',
                'connection.create_bidirectional_apply',
                'border.blueprint.draft.upsert',
                'border.blueprint.publish',
                'border_layer.feature_create',
                'border_layer.feature_set_replacement',
                'border_layer.materialize_apply',
                'element_category.upsert',
                'element.upsert',
                'characterStudio.character.create',
                'characterStudio.character.update',
                'characterStudio.animationClip.upsert',
                'characterStudio.character.setDefault',
              }.contains(entry.actionId))) {
        refusals.add('sourceExecutionBaseUnsupported');
      }
    }
    if (!profile.isQualified ||
        !source.canPlan ||
        source.snapshot.state != SourceScanState.complete) {
      refusals.add('sourceExecutionProfileUnqualified');
    }
    if (!nativeMaps.keys.toSet().containsAll(const {100, 102}) ||
        nativeMaps.values
            .any((map) => map.spatialScene != null || map.events.isNotEmpty)) {
      refusals.add('sourceExecutionMapsUnavailable');
    }
    final activeMapIds = source.maps.map((map) => map.map.sourceMapId).toSet();
    if (canonicalJsonOf(activeMapIds.toList()..sort()) !=
        canonicalJsonOf(nativeMaps.keys.toList()..sort())) {
      refusals.add('sourceExecutionMapsUnavailable');
    }
    final retainedMapIds = <int>{
      for (final connection in source.connections) ...[
        if (activeMapIds.contains(connection.sourceMapId))
          connection.targetSourceMapId,
        if (activeMapIds.contains(connection.targetSourceMapId))
          connection.sourceMapId,
      ]
    }..removeAll(activeMapIds);
    final attestedMapIds = {...activeMapIds, ...retainedMapIds};
    if (!source.connectionsExtracted) {
      refusals.add('sourceExecutionConnectionsUnavailable');
    }
    if (attestedMapIds.any((id) => !_mapExecutionAuditHashes.containsKey(id))) {
      refusals.add('sourceMapAutonomyContextUnsupported');
    }
    final connectionsEntry = source.snapshot.entries
        .where((entry) => entry.relativePath == 'Data/map_connections.dat')
        .firstOrNull;
    final witnesses = <Map<String, Object?>>[];
    for (final expected in {
      'Data/Scripts.rxdata': SourceEventProfile.kantoScriptsArchiveSha256,
      'Data/PluginScripts.rxdata':
          'f390bd7fb8c034267c8341500f257b8ab1aaaef204c4c88477c81b39806ce9bb',
      'Data/Map100.rxdata':
          '3a101f07319e797c0021212ce5e6adc5344128eaff4b1ea2c4712219289c47a0',
      'Data/Map102.rxdata':
          '85bf6e82ae6c6271b30546297f6d9bbd2f472b32f1e0e2ac383a3c6248315ce7',
      'Data/CommonEvents.rxdata':
          'bce4047ee1779de25f2e8fd087ea4f90dae513eecb8ead734743d1b37ee78cda',
      'Data/map_connections.dat': connectionsEntry?.sha256?.value ?? '',
      for (final id in attestedMapIds.toList()..sort())
        _mapSourcePath(id): _mapExecutionAuditHashes[id] ?? '',
    }.entries) {
      cancellation?.check();
      final matches = source.snapshot.entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(expected.key))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != expected.key ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 == null) {
        refusals.add('sourceExecutionWitnessUnavailable');
        continue;
      }
      final entry = matches.single;
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
        throw const NativeWriteException('events.execution.witness.changed',
            'Execution context witnesses differ from the sealed source snapshot');
      }
      if (entry.sha256!.value != expected.value) {
        refusals.add(expected.key == 'Data/PluginScripts.rxdata'
            ? 'sourcePluginRouteContextUnsupported'
            : 'sourceExecutionWitnessUnqualified');
      }
      if (expected.key == 'Data/CommonEvents.rxdata' &&
          !_commonEventsAreManual(bytes)) {
        refusals.add('sourceAutomaticCommonEventUnsupported');
      }
      witnesses.add({
        'fileId': entry.fileId.value,
        'relativePath': entry.relativePath,
        'byteLength': entry.byteLength,
        'sha256': entry.sha256!.value
      });
    }
    NormalizedSourceProject? retainedSource;
    if (retainedMapIds.isNotEmpty &&
        retainedMapIds.every((id) =>
            _mapExecutionAuditHashes.containsKey(id) &&
            witnesses
                .any((entry) => entry['relativePath'] == _mapSourcePath(id)))) {
      retainedSource = await const RmxpSourceNormalizer().normalize(
          snapshot: source.snapshot,
          files: files,
          selectedMapIds: retainedMapIds,
          includeEventSystem: true,
          cancellation: cancellation);
      if (!retainedSource.canPlan ||
          canonicalJsonOf(
                  retainedSource.maps.map((map) => map.map.sourceMapId).toList()
                    ..sort()) !=
              canonicalJsonOf(retainedMapIds.toList()..sort())) {
        refusals.add('sourceRetainedMapContextUnsupported');
      }
    } else if (retainedMapIds.isNotEmpty) {
      refusals.add('sourceRetainedMapContextUnsupported');
    }
    final pages = [
      for (final map in [...source.maps, ...?retainedSource?.maps])
        for (final event in map.map.events) ...event.pages
    ];
    if (pages.any((page) => page.triggerCode == 4)) {
      refusals.add('sourceParallelEventUnsupported');
    }
    if (pages.any((page) => page.triggerCode < 0 || page.triggerCode > 4)) {
      refusals.add('sourceMapAutonomyContextUnsupported');
    }
    if (refusals.isEmpty) {
      proof.addAll({
        'origin': 'freshNativeProject',
        'nativeCreationContract': {
          'template': 'empty',
          'dimension': 'twoD',
          'stateImports': 'notSupported'
        },
        'sourceCheckpoint': 'notImported',
        'followers': 'newGameDeclaredEmpty',
        'scope': {
          'sourceMapIds': [100, 102],
          'pages': ['100/8/0', '100/8/1', '102/1/0']
        },
        'sourceContextProfile': 'kanto-original-door-fresh-v1',
        'sourcePluginContext': 'exactCompiledPluginsWithFreshEmptyFollowers',
        'pluginInventoryHash': pluginInventoryHash.value,
        'commonEvents': 'manualOnly',
        'parallelEvents': 'noneOnRepresentedMaps',
        'sourceMapExecutionScope': {
          'activeSourceMapIds': activeMapIds.toList()..sort(),
          'retainedOnlySourceMapIds': retainedMapIds.toList()..sort(),
          'attestedSourceMapIds': attestedMapIds.toList()..sort(),
          'retention': 'directNeighboursOfActiveMapsFromFreshSourceHistory',
        },
        'mapAutonomyAudit': {
          'profile': 'kanto-five-map-fresh-door-autonomy-v1',
          'observationSha256':
              '1f704997de836250169e7d01f1b19fb212f38caa05330916465eb1a0cc41bc38',
          'mapHashes': {
            for (final id in attestedMapIds.toList()..sort())
              '$id': _mapExecutionAuditHashes[id]
          },
          'customPatrolScript45Count': 0,
          'customPatrolCodes': [0, 1, 2, 3, 4, 17, 19, 24],
          'unrepresentedAutoruns':
              'serialMainInterpreterWithKnownFreshConditionalGuards',
        },
        'witnesses': witnesses,
        'oracle': {
          'freshState': '027:76-80;031:39-57',
          'followers': '049:55-57,79-83',
          'barrier': '033:106-114',
          'followingTransfer': 'FollowingPokemonEX/MapTransfer:4-9,29-44,50-78',
          'mapActivation': '033:54-72;043:114-139,361-375;045:129-130,170-179'
        },
      });
    }
    return SourceEventExecutionContext._(
        sourceSnapshotHash: snapshotHash,
        normalizationHash: normalizationHash,
        sourceProfileHash: profile.canonicalHash,
        baseDraftHash: base?.canonicalHash,
        mapIds: {
          for (final entry in nativeMaps.entries) entry.key: entry.value.id
        },
        mapHashes: {
          for (final entry in nativeMaps.entries)
            entry.key: canonicalHashOf(entry.value.toJson())
        },
        refusals: refusals.toList()..sort(),
        proof: proof);
  }
}

bool _isPluginPath(String path) {
  final key = sourcePathCollisionKey(path);
  return key == 'plugins' || key.startsWith('plugins/');
}

bool _commonEventsAreManual(List<int> bytes) {
  try {
    final document = const MarshalDecoder()
        .decode(bytes, sourcePath: 'Data/CommonEvents.rxdata');
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array ||
        root.extensions.isNotEmpty ||
        root.userClass != null ||
        root.instanceVariables.isNotEmpty) {
      return false;
    }
    return root.elements.every((id) {
      final record = document.node(id);
      if (record.kind == MarshalKind.nil) {
        return true;
      }
      if (record.kind != MarshalKind.object ||
          record.className != 'RPG::CommonEvent' ||
          record.extensions.isNotEmpty ||
          record.userClass != null) {
        return false;
      }
      final triggers = record.instanceVariables
          .where((pair) => document.node(pair.key).name == '@trigger')
          .toList();
      return triggers.length == 1 &&
          document.node(triggers.single.value).kind == MarshalKind.integer &&
          document.node(triggers.single.value).integerValue == BigInt.zero;
    });
  } on BinaryDecodeError {
    return false;
  }
}
