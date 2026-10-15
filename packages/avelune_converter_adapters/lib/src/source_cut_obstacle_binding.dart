import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'native_project_writer.dart';

final class SourceCutObstacleBindingUnavailable implements Exception {
  const SourceCutObstacleBindingUnavailable(this.reason);
  final String reason;
}

final class SourceCutObstacleBinding {
  SourceCutObstacleBinding._({
    required this.eventIdentity,
    required this.sourceMapId,
    required this.sourceEventId,
    required this.x,
    required this.y,
    required this.program,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.nativeBadge,
    required this.nativeElement,
  });

  final ConverterId eventIdentity;
  final int sourceMapId, sourceEventId, x, y;
  final SourceCutObstacleProgramNode program;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final BadgeDefinition nativeBadge;
  final ProjectElementEntry nativeElement;

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (!analysis.profile.isQualified ||
        source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        event.identity != eventIdentity ||
        event.sourceMapId != sourceMapId ||
        event.sourceEventId != sourceEventId ||
        event.x != x ||
        event.y != y ||
        event.isQuarantined ||
        event.pages.length != 1 ||
        event.pages.single.body.nodes.length != 1 ||
        event.pages.single.body.nodes.single is! SourceCutObstacleProgramNode ||
        canonicalJsonOf((event.pages.single.body.nodes.single
                    as SourceCutObstacleProgramNode)
                .toJson()) !=
            canonicalJsonOf(program.toJson())) {
      return false;
    }
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyze()
            .eventAt(sourceMapId, sourceEventId);
    if (expected == null ||
        canonicalJsonOf(_sourceCutEventShape(event)) !=
            canonicalJsonOf(_sourceCutEventShape(expected))) {
      return false;
    }
    final maps =
        source.maps.where((map) => map.map.sourceMapId == sourceMapId).toList();
    if (maps.length != 1) {
      return false;
    }
    final events = maps.single.map.events
        .where((e) => e.sourceEventId == sourceEventId)
        .toList();
    return events.length == 1 &&
        program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: sourceMapId,
            event: events.single);
  }

  MapEntity createNativeEntity(String entityId) => MapEntity(
      id: entityId,
      name: 'Arbre à couper',
      kind: MapEntityKind.custom,
      pos: GridPos(x: x, y: y),
      blocksMovement: true,
      fieldObstacle: const MapEntityFieldObstacleData(),
      editorVisual: MapEntityEditorVisual(elementId: nativeElement.id));

  Map<String, Object?> toJson() => {
        'kind': 'sourceCutObstacleBinding',
        'version': 1,
        'sourceEventIdentity': eventIdentity.value,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'program': program.toJson(),
        'nativeBadge': nativeBadge.toJson(),
        'nativeElementId': nativeElement.id,
        'initialPlayerBadgeGranted': false,
        'initialPlayerAbilityUnlocked': false,
        'sourceBadgeIndex': 12,
        'sourceBadgeAward': {
          'path': 'Data/Map026.rxdata',
          'eventId': 5,
          'pageIndex': 0,
          'commandIndices': [10, 11, 12],
          'sha256': _sourceCutGymHash,
          'exactScript': r'$player.badges[12]=true',
          'exactMessage': r'\PN received the Cascade Badge from Misty!'
        },
        'nativeRequiresNonFaintedPokemon': true,
        'nativeResetPolicy': 'mapInstance',
        'fullSourceCutParityQualified': false,
        'audioSourceParity': false,
        'nativeSound': '063-Swing02',
        'nativeSoundAsset':
            'packages/map_runtime/assets/audio/battle/se/063-swing02.ogg',
        'sourceSoundName': 'Cut',
        'sourceSoundSelection': 'unqualifiedMultipleExtensions',
        'sourceScriptsExecuted': 0,
      };
}

Map<String, Object?> _sourceCutEventShape(SourceEventDefinition event) => {
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
            'raw': page.rawDataRef?.toJson(),
            'graphic': page.graphic == null
                ? null
                : {
                    'tileId': page.graphic!.tileId,
                    'name': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blendType': page.graphic!.blendType,
                    'moveType': page.graphic!.moveType,
                    'moveSpeed': page.graphic!.moveSpeed,
                    'moveFrequency': page.graphic!.moveFrequency,
                    'walkAnime': page.graphic!.walkAnime,
                    'stepAnime': page.graphic!.stepAnime,
                    'directionFix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'alwaysOnTop': page.graphic!.alwaysOnTop,
                    'moveRouteNodeId': page.graphic!.moveRouteNodeId,
                  },
          }
      ],
    };

final class SourceCutObstacleBindings {
  SourceCutObstacleBindings._(
      {required Map<ConverterId, SourceCutObstacleBinding> bindings,
      required this.badge,
      required this.element,
      required this.artifact,
      required List<NativeMutation> mutations,
      required Map<String, Object?> evidence})
      : byEventIdentity = Map.unmodifiable(bindings),
        mutations = List.unmodifiable(mutations),
        evidence = Map.unmodifiable(evidence);
  final Map<ConverterId, SourceCutObstacleBinding> byEventIdentity;
  final BadgeDefinition badge;
  final ProjectElementEntry element;
  final NativeArtifact artifact;
  final List<NativeMutation> mutations;
  final Map<String, Object?> evidence;
}

const _sourceCutGymHash =
    '358e0f2d520d8f49f9d747a1e87b55421bb027c40c1e026791b251da23ae0e0c';
const _sourceCutMetadataHash =
    '57aceb344d8c23ac84fc1c3a86951b17a6bb67c908c89cf60951071810941db1';
const _sourceCutVisualHash =
    '68271cc5662b112111bec29ea8122466712535a4fd2381262a20a65064e974cb';

final class SourceCutObstacleBindingResolver {
  const SourceCutObstacleBindingResolver();

  Future<SourceCutObstacleBindings?> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    cancellation?.check();
    limits.validate();
    final events = analysis.events
        .where((event) =>
            !event.isQuarantined &&
            event.pages.length == 1 &&
            event.pages.single.body.nodes.length == 1 &&
            event.pages.single.body.nodes.single
                is SourceCutObstacleProgramNode)
        .toList();
    if (events.isEmpty) {
      return null;
    }
    if (!analysis.profile.isQualified ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash ||
        source.snapshot.state != SourceScanState.complete) {
      throw const SourceCutObstacleBindingUnavailable('profile_unqualified');
    }
    var readBytes = 0;
    final witnesses = <String, SourceFileEntry>{};
    Future<List<int>> exact(String path, String hash) async {
      final matches = source.snapshot.entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256?.value != hash) {
        throw const SourceCutObstacleBindingUnavailable('source_unattested');
      }
      final entry = matches.single;
      if (entry.byteLength > limits.maxArtifactBytes ||
          entry.byteLength > limits.maxTotalArtifactBytes - readBytes) {
        throw const NativeWriteException('events.cut.quota',
            'Cut source witnesses exceed the native read budget.');
      }
      readBytes += entry.byteLength;
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          bytes.any((v) => v < 0 || v > 255) ||
          crypto.sha256.convert(bytes).toString() != hash) {
        throw ContractError('source.cut.source_changed', path,
            'Cut source bytes differ from their admitted snapshot.');
      }
      witnesses[path] = entry;
      return bytes;
    }

    await exact(
        'Data/Scripts.rxdata', SourceEventProfile.kantoScriptsArchiveSha256);
    final gym = await exact('Data/Map026.rxdata', _sourceCutGymHash);
    final metadata = utf8
        .decode(await exact('PBS/map_metadata.txt', _sourceCutMetadataHash));
    final image = await exact(
        'Graphics/Characters/OBJ_FRLG_Cut Tree.png', _sourceCutVisualHash);
    final gymDocument =
        const MarshalDecoder().decode(gym, sourcePath: 'Data/Map026.rxdata');
    int field(int id, String key) {
      final object = gymDocument.node(id);
      final matches = object.instanceVariables
          .where((p) => gymDocument.node(p.key).name == key)
          .toList();
      if (matches.length != 1) {
        throw const SourceCutObstacleBindingUnavailable(
            'badge_fragment_unqualified');
      }
      return matches.single.value;
    }

    final map = gymDocument.node(gymDocument.rootId);
    if (map.className != 'RPG::Map') {
      throw const SourceCutObstacleBindingUnavailable(
          'badge_fragment_unqualified');
    }
    final eventMap = gymDocument.node(field(gymDocument.rootId, '@events'));
    final misty = eventMap.pairs
        .where(
            (pair) => gymDocument.node(pair.key).integerValue == BigInt.from(5))
        .toList();
    if (misty.length != 1) {
      throw const SourceCutObstacleBindingUnavailable(
          'badge_fragment_unqualified');
    }
    final pages =
        gymDocument.node(field(misty.single.value, '@pages')).elements;
    final commands = gymDocument.node(field(pages.first, '@list')).elements;
    List<Object?> command(int index) {
      final id = commands[index];
      final parameters = gymDocument.node(field(id, '@parameters')).elements;
      return [
        gymDocument.node(field(id, '@code')).integerValue?.toInt(),
        gymDocument.node(field(id, '@indent')).integerValue?.toInt(),
        for (final parameter in parameters)
          switch (gymDocument.node(parameter).kind) {
            MarshalKind.integer =>
              gymDocument.node(parameter).integerValue?.toInt(),
            MarshalKind.string => gymDocument.node(parameter).text().text,
            _ => null,
          }
      ];
    }

    if (canonicalJsonOf(command(10)) !=
            canonicalJsonOf([
              111,
              0,
              12,
              'TrainerBattle.start(:FRLG_LEADER_Misty, "Misty")'
            ]) ||
        canonicalJsonOf(command(11)) !=
            canonicalJsonOf([355, 1, r'$player.badges[12]=true']) ||
        canonicalJsonOf(command(12)) !=
            canonicalJsonOf(
                [101, 1, r'\PN received the Cascade Badge from Misty!'])) {
      throw const SourceCutObstacleBindingUnavailable(
          'badge_fragment_unqualified');
    }
    final regions = <int, int>{};
    var sectionId = -1;
    for (final line in const LineSplitter().convert(metadata)) {
      final heading = RegExp(r'^\[(\d+)\]').firstMatch(line);
      if (heading != null) {
        sectionId = int.parse(heading.group(1)!);
      } else if (line.startsWith('MapPosition = ')) {
        regions[sectionId] = int.tryParse(line
                .substring('MapPosition = '.length)
                .split(',')
                .first
                .trim()) ??
            -1;
      }
    }
    if (events.any((event) => regions[event.sourceMapId] != 1)) {
      throw const SourceCutObstacleBindingUnavailable('region_unqualified');
    }
    final dimensions =
        decodeRasterImageDimensions(image, mediaType: 'image/png');
    if (dimensions == null ||
        dimensions.width != 128 ||
        dimensions.height != 128) {
      throw const SourceCutObstacleBindingUnavailable('visual_unqualified');
    }
    if (128 * 128 > limits.maxImagePixels) {
      throw const NativeWriteException('events.cut.quota',
          'Cut visual exceeds the native image pixel budget.');
    }
    final artifact = NativeArtifact(
        bytes: image,
        expectedSha256: Sha256Hash(_sourceCutVisualHash),
        limits: limits);
    final namespace = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'kind': 'sourceCutObstacle'
    }).value.substring(0, 24);
    final badge = BadgeDefinition(
        id: 'source_cascade_badge_$namespace',
        label: 'Cascade Badge',
        fieldAbilityUnlock: FieldAbility.cut);
    final tilesetId = 'source_cut_tree_$namespace';
    final category = ProjectElementCategory(
        id: 'source_cut_obstacles_$namespace', name: 'Arbres à couper');
    final element = ProjectElementEntry(
        id: 'source_cut_tree_element_$namespace',
        name: 'Arbre à couper',
        tilesetId: tilesetId,
        categoryId: category.id,
        frames: [
          TilesetVisualFrame(source: const TilesetSourceRect(x: 0, y: 0))
        ],
        collisionProfile:
            const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]));
    NativeMutation mutation(String id, String action, List<String> targets,
            Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('source_cut_$id$namespace'),
            actionId: action,
            sourceEntityIds: [for (final file in witnesses.values) file.fileId],
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    final bindings = <ConverterId, SourceCutObstacleBinding>{};
    for (final event in events) {
      final binding = SourceCutObstacleBinding._(
          eventIdentity: event.identity,
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          x: event.x,
          y: event.y,
          program: event.pages.single.body.nodes.single
              as SourceCutObstacleProgramNode,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          profileHash: analysis.profile.canonicalHash,
          nativeBadge: badge,
          nativeElement: element);
      if (!binding.isBoundToEvent(
          source: source, analysis: analysis, event: event)) {
        throw const SourceCutObstacleBindingUnavailable(
            'event_binding_unqualified');
      }
      bindings[event.identity] = binding;
    }
    return SourceCutObstacleBindings._(
        bindings: bindings,
        badge: badge,
        element: element,
        artifact: artifact,
        mutations: [
          mutation('badge_', 'campaign.badge.upsert', [badge.id],
              {'value': badge.toJson()}),
          mutation('visual_', 'tileset.import_image', [
            tilesetId,
            'image_$tilesetId'
          ], {
            'artifactHandle': artifact.handle,
            'tilesetId': tilesetId,
            'name': 'Arbre à couper',
            'tileWidth': 32,
            'tileHeight': 32
          }),
          mutation('category_', 'element_category.upsert', [category.id],
              {'category': category.toJson()}),
          mutation('element_', 'element.upsert', [element.id],
              {'element': element.toJson()}),
        ],
        evidence: {
          'kind': 'sourceCutObstacleBindings',
          'version': 1,
          'sourceFiles': [for (final file in witnesses.values) file.toJson()],
          'events': [for (final binding in bindings.values) binding.toJson()],
          'nativeBadge': badge.toJson(),
          'initialPlayerStateMutated': false,
          'sourceFrame': {
            'sheetWidth': 128,
            'sheetHeight': 128,
            'x': 0,
            'y': 0,
            'width': 32,
            'height': 32
          },
          'nativeImageRawSha256': artifact.rawSha256.value,
          'sourcePixelsResampled': false,
          'audioSourceParity': false,
          'sourceScriptsExecuted': 0,
        });
  }
}
