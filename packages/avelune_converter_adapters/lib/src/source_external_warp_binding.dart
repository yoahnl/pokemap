import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'native_project_writer.dart';

enum SourceExternalWarpPolicy {
  strictSource,
  nativeTransitionsWithoutEscapeState
}

final class SourceExternalWarpBindingUnavailable implements Exception {
  const SourceExternalWarpBindingUnavailable(this.reason);
  final String reason;
}

final class SourceExternalWarpBinding {
  SourceExternalWarpBinding._(
      {required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.policy,
      required Map<ConverterId, SourceExternalWarpProgram> programs,
      required Map<String, ProjectElementEntry> illustrations,
      required List<SourceFileEntry> files,
      required List<NativeArtifact> artifacts,
      required List<NativeMutation> mutations,
      required Map<String, Object?> evidence})
      : programs = Map.unmodifiable(programs),
        illustrations = Map.unmodifiable(illustrations),
        files = List.unmodifiable(files),
        artifacts = List.unmodifiable(artifacts),
        mutations = List.unmodifiable(mutations),
        _evidence = canonicalJsonOf(evidence);

  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final SourceExternalWarpPolicy policy;
  final Map<ConverterId, SourceExternalWarpProgram> programs;
  final Map<String, ProjectElementEntry> illustrations;
  final List<SourceFileEntry> files;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final String _evidence;
  Map<String, Object?> get evidence => Map<String, Object?>.from(
      (jsonDecode(_evidence) as Map).cast<String, Object?>());

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        !analysis.profile.isQualified ||
        event.identity !=
            source.eventIdentity(event.sourceMapId, event.sourceEventId) ||
        !_externalEventMatchesSource(source, analysis.profile, event) ||
        event.isQuarantined ||
        event.pages.isEmpty ||
        event.pages.first.body.nodes.singleOrNull is! SourceWarpNode) {
      return false;
    }
    final program = programs[event.identity];
    final node = event.pages.first.body.nodes.single as SourceWarpNode;
    if (program == null ||
        !program.matches(node) ||
        !_filesMatch(source) ||
        canonicalJsonOf(node.originalProgram?.toJson()) !=
            canonicalJsonOf(program.toJson())) {
      return false;
    }
    final map = source.maps
        .where((map) => map.map.sourceMapId == event.sourceMapId)
        .singleOrNull;
    final original = map?.map.events
        .where((candidate) => candidate.sourceEventId == event.sourceEventId)
        .singleOrNull;
    if (original == null ||
        original.name != event.name ||
        original.x != event.x ||
        original.y != event.y ||
        original.pages.length != event.pages.length ||
        !program.isBoundToSourceEvent(
            source: source, profile: analysis.profile, event: original)) {
      return false;
    }
    for (final (index, page) in event.pages.indexed) {
      if (canonicalJsonOf(page.sourcePage.toJson()) !=
          canonicalJsonOf(original.pages[index].toJson())) {
        return false;
      }
    }
    return program.illustrationName == null ||
        illustrations.containsKey(program.illustrationName);
  }

  bool _filesMatch(NormalizedSourceProject source) =>
      files.every((file) => source.snapshot.entries.any((entry) =>
          entry.fileId == file.fileId &&
          canonicalJsonOf(entry.toJson()) == canonicalJsonOf(file.toJson())));
}

final class SourceExternalWarpBindingResolver {
  const SourceExternalWarpBindingResolver();

  Future<SourceExternalWarpBinding?> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      SourceExternalWarpPolicy policy = SourceExternalWarpPolicy.strictSource,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    cancellation?.check();
    limits.validate();
    if (!source.canPlan ||
        source.snapshot.state != SourceScanState.complete ||
        analysis.profile.canonicalHash !=
            SourceEventProfile.forProject(source).canonicalHash) {
      throw const SourceExternalWarpBindingUnavailable('source_unqualified');
    }
    final programs = <ConverterId, SourceExternalWarpProgram>{};
    for (final event in analysis.events) {
      if (event.isQuarantined || event.pages.isEmpty) continue;
      final node = event.pages.first.body.nodes.singleOrNull;
      if (node is! SourceWarpNode || node.originalProgram == null) continue;
      final map = source.maps
          .where((map) => map.map.sourceMapId == event.sourceMapId)
          .singleOrNull;
      final original = map?.map.events
          .where((candidate) => candidate.sourceEventId == event.sourceEventId)
          .singleOrNull;
      final program = node.originalProgram!;
      if (original == null ||
          programs.containsKey(event.identity) ||
          !_externalEventMatchesSource(source, analysis.profile, event) ||
          !program.matches(node) ||
          !program.isBoundToSourceEvent(
              source: source, profile: analysis.profile, event: original)) {
        throw const SourceExternalWarpBindingUnavailable(
            'program_binding_invalid');
      }
      if ((program.presentation ==
                  SourceExternalWarpPresentation.caveEntrance ||
              program.presentation ==
                  SourceExternalWarpPresentation.caveExit) &&
          policy == SourceExternalWarpPolicy.strictSource) {
        throw const SourceExternalWarpBindingUnavailable(
            'native_escape_state_decision_required');
      }
      programs[event.identity] = program;
    }
    if (programs.isEmpty) return null;
    final names = programs.values
        .map((program) => program.illustrationName)
        .nonNulls
        .toSet()
        .toList()
      ..sort();
    final mutationCount = names.isEmpty ? 0 : names.length * 2 + 1;
    if (names.length > limits.maxArtifacts ||
        mutationCount > limits.maxMutations ||
        (names.isNotEmpty && 512 * 384 > limits.maxImagePixels) ||
        names.length * 512 * 384 > limits.maxTotalImagePixels) {
      throw const NativeWriteException('events.external_warp.quota',
          'Transition artwork exceeds the native resource budget.');
    }
    const hashes = {
      'dpic_powerplant':
          '59363afc47d23f051b18ae471e9d6670790316f0ad0140a3fa16c1e1d8646c13',
      'dpic_rocktunnel':
          '0348feae8e4da3cd8f9e7948c029c84198df1e59931a6f27cad9657f4148cdc8',
    };
    final admitted = <SourceFileEntry>[];
    var bytesBudget = 0;
    for (final name in names) {
      final path = 'Graphics/Pictures/$name.png';
      final matches = source.snapshot.entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256?.value != hashes[name]) {
        throw const SourceExternalWarpBindingUnavailable(
            'source_illustration_unqualified');
      }
      bytesBudget += matches.single.byteLength;
      if (matches.single.byteLength > limits.maxArtifactBytes ||
          bytesBudget > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException('events.external_warp.quota',
            'Transition artwork exceeds the byte budget.');
      }
      admitted.add(matches.single);
    }
    final artifacts = <NativeArtifact>[];
    for (final file in admitted) {
      cancellation?.check();
      final bytes = await files.read(file.fileId);
      cancellation?.check();
      if (bytes.length != file.byteLength ||
          crypto.sha256.convert(bytes).toString() != file.sha256!.value) {
        throw const NativeWriteException('events.external_warp.image_changed',
            'Transition artwork differs from the sealed source.');
      }
      final dimensions =
          decodeRasterImageDimensions(bytes, mediaType: 'image/png');
      if (dimensions?.width != 512 || dimensions?.height != 384) {
        throw const SourceExternalWarpBindingUnavailable(
            'source_illustration_dimensions');
      }
      artifacts.add(NativeArtifact(
          bytes: bytes, expectedSha256: file.sha256, limits: limits));
    }
    final namespace = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'kind': 'sourceExternalWarpArtwork'
    }).value.substring(0, 24);
    final category = ProjectElementCategory(
        id: 'source_warp_locations_$namespace', name: 'Illustrations de lieux');
    final elements = <String, ProjectElementEntry>{
      for (final name in names)
        name: ProjectElementEntry(
            id: 'source_warp_image_${name}_$namespace',
            name: name == 'dpic_powerplant' ? 'Centrale' : 'Grotte',
            tilesetId: 'source_warp_${name}_$namespace',
            categoryId: category.id,
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
            ]),
    };
    NativeMutation mutate(String role, String action, List<String> targetIds,
            Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('source_warp_${role}_$namespace'),
            actionId: action,
            sourceEntityIds: [
              ...programs.keys,
              ...admitted.map((file) => file.fileId)
            ],
            targetEntityIds: targetIds.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    final binding = SourceExternalWarpBinding._(
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: analysis.profile.canonicalHash,
        policy: policy,
        programs: programs,
        illustrations: elements,
        files: admitted,
        artifacts: artifacts,
        mutations: [
          for (final (index, name) in names.indexed)
            mutate(name, 'tileset.import_image', [
              elements[name]!.tilesetId,
              'image_${elements[name]!.tilesetId}'
            ], {
              'artifactHandle': artifacts[index].handle,
              'tilesetId': elements[name]!.tilesetId,
              'name': elements[name]!.name,
              'tileWidth': 512,
              'tileHeight': 384
            }),
          if (names.isNotEmpty)
            mutate('category', 'element_category.upsert', [category.id],
                {'category': category.toJson()}),
          for (final name in names)
            mutate('element_$name', 'element.upsert', [elements[name]!.id],
                {'element': elements[name]!.toJson()}),
        ],
        evidence: {
          'kind': 'sourceExternalWarpBinding',
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': analysis.profile.canonicalHash.value,
          'policy': policy.name,
          'programs': [for (final program in programs.values) program.toJson()],
          'illustrations': [for (final file in admitted) file.toJson()],
          'nativeElements': [
            for (final element in elements.values) element.toJson()
          ],
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
          'sourcePixelsTransformed': false,
          'fullSourceParityQualified': false,
          'nativeExecutionQualified': false,
          'sourceEscapePoint': 'notImported',
          'sourceDarkMapMask': 'notImported',
          'nativeCavePresentation':
              'typedNativeTransitionAndOrdinaryNativeMapLighting'
        });
    for (final event in analysis.events
        .where((event) => programs.containsKey(event.identity))) {
      if (!binding.isBoundToEvent(
          source: source, analysis: analysis, event: event)) {
        throw const SourceExternalWarpBindingUnavailable(
            'event_binding_invalid');
      }
    }
    return binding;
  }
}

bool _externalEventMatchesSource(NormalizedSourceProject source,
    SourceEventProfile profile, SourceEventDefinition event) {
  final expected = SourceEventAnalyzer.forProject(source, profile: profile)
      .analyze()
      .eventAt(event.sourceMapId, event.sourceEventId);
  if (expected == null ||
      expected.isQuarantined ||
      event.pages.any((page) => _externalBlockShape(page.body) == null)) {
    return false;
  }
  return canonicalJsonOf(_externalEventShape(event)) ==
      canonicalJsonOf(_externalEventShape(expected));
}

Map<String, Object?> _externalEventShape(SourceEventDefinition event) => {
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'identity': event.identity.value,
      'sourceFileId': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'condition': page.condition.toJson(),
            'rawDataRef': page.rawDataRef?.toJson(),
            'body': _externalBlockShape(page.body),
            'graphic': page.graphic == null
                ? null
                : _externalGraphicShape(page.graphic!),
          }
      ],
    };

Map<String, Object?> _externalGraphicShape(SourceEventGraphic graphic) => {
      'tileId': graphic.tileId,
      'characterName': graphic.characterName,
      'hue': graphic.hue,
      'direction': graphic.direction,
      'pattern': graphic.pattern,
      'opacity': graphic.opacity,
      'blendType': graphic.blendType,
      'moveType': graphic.moveType,
      'moveSpeed': graphic.moveSpeed,
      'moveFrequency': graphic.moveFrequency,
      'walkAnime': graphic.walkAnime,
      'stepAnime': graphic.stepAnime,
      'directionFix': graphic.directionFix,
      'through': graphic.through,
      'alwaysOnTop': graphic.alwaysOnTop,
      'moveRouteNodeId': graphic.moveRouteNodeId,
    };

Object? _externalBlockShape(SourceEventBlock block) {
  final result = <Object?>[];
  for (final node in block.nodes) {
    final Object? shape = switch (node) {
      SourceWarpNode() when node.originalProgram != null => {
          'kind': 'warp',
          'span': node.span.toJson(),
          'targetSourceMapId': node.targetSourceMapId,
          'x': node.x,
          'y': node.y,
          'direction': node.direction,
          'fade': node.fade,
          'program': node.originalProgram!.toJson(),
        },
      SourceForcedMoveRouteNode() => node.toJson(),
      SourceMoveRouteBarrierNode() => node.toJson(),
      SourceTempSwitchNode() => node.toJson(),
      SourceConditionalNode() => {
          'kind': 'conditional',
          'span': node.span.toJson(),
          'condition': node.condition.toJson(),
          'whenTrue': _externalBlockShape(node.whenTrue),
          'whenFalse': _externalBlockShape(node.whenFalse),
        },
      _ => null,
    };
    if (shape == null ||
        node is SourceConditionalNode &&
            (_externalBlockShape(node.whenTrue) == null ||
                _externalBlockShape(node.whenFalse) == null)) {
      return null;
    }
    result.add(shape);
  }
  return {'span': block.span.toJson(), 'nodes': result};
}
