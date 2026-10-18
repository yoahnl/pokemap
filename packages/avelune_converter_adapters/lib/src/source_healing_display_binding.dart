import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_distribution/map_distribution.dart';

import 'native_project_writer.dart';

final class SourceHealingDisplayBindingUnavailable implements Exception {
  const SourceHealingDisplayBindingUnavailable(this.reason);
  final String reason;
}

final class SourceHealingDisplayBinding {
  SourceHealingDisplayBinding._({
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.eventIdentity,
    required this.program,
    required List<ProjectElementEntry> elements,
    required List<NativeArtifact> artifacts,
    required List<NativeMutation> mutations,
    required Map<String, Object?> evidence,
    required List<SourceFileEntry> files,
  })  : elements = List.unmodifiable(elements),
        artifacts = List.unmodifiable(artifacts),
        mutations = List.unmodifiable(mutations),
        evidence = _freezeHealing(evidence) as Map<String, Object?>,
        _files = List.unmodifiable(files);
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final ConverterId eventIdentity;
  final SourceHealingDisplayProgram program;
  final List<ProjectElementEntry> elements;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final Map<String, Object?> evidence;
  final List<SourceFileEntry> _files;

  MapEntity createNativeEntity(String id) => MapEntity(
      id: id,
      name: 'Boules de soin',
      kind: MapEntityKind.custom,
      pos: GridPos(x: program.x, y: program.y),
      blocksMovement: false,
      healingDisplay: MapEntityHealingDisplayData(
          variantElementIds: elements.map((element) => element.id).toList()));

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (!source.canPlan ||
        source.snapshot.state != SourceScanState.complete ||
        !analysis.profile.isQualified ||
        source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        event.identity != eventIdentity ||
        event.sourceMapId != program.sourceMapId ||
        event.sourceEventId != program.sourceEventId ||
        analysis.events
                .where((candidate) =>
                    candidate.sourceMapId == program.sourceMapId &&
                    candidate.sourceEventId == program.sourceEventId)
                .length !=
            1 ||
        analysis.events
                .where((candidate) => candidate.identity == event.identity)
                .length !=
            1 ||
        !_files.every((file) => source.snapshot.entries.any((entry) =>
            entry.fileId == file.fileId &&
            entry.relativePath == file.relativePath &&
            entry.kind == SourceNodeKind.file &&
            entry.sha256 == file.sha256 &&
            entry.byteLength == file.byteLength))) {
      return false;
    }
    final maps = source.maps
        .where((map) => map.map.sourceMapId == program.sourceMapId)
        .toList();
    if (maps.length != 1) {
      return false;
    }
    final events = maps.single.map.events
        .where((event) => event.sourceEventId == program.sourceEventId)
        .toList();
    if (events.length != 1 ||
        !program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: program.sourceMapId,
            event: events.single)) {
      return false;
    }
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyze()
            .eventAt(program.sourceMapId, program.sourceEventId);
    return expected != null &&
        event.pages.every(
            (page) => page.body.nodes.isEmpty && page.diagnostics.isEmpty) &&
        canonicalJsonOf(_healingEventShape(event)) ==
            canonicalJsonOf(_healingEventShape(expected));
  }
}

final class SourceHealingDisplayBindingResolver {
  const SourceHealingDisplayBindingResolver();
  Future<SourceHealingDisplayBinding?> read({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required int sourceMapId,
    required int sourceEventId,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final events = analysis.events
        .where((event) =>
            event.sourceMapId == sourceMapId &&
            event.sourceEventId == sourceEventId)
        .toList();
    if (events.isEmpty) {
      return null;
    }
    if (!source.canPlan ||
        source.snapshot.state != SourceScanState.complete ||
        !analysis.profile.isQualified ||
        analysis.profile.canonicalHash !=
            SourceEventProfile.forProject(source).canonicalHash ||
        events.length != 1) {
      throw const SourceHealingDisplayBindingUnavailable('source_unqualified');
    }
    final maps =
        source.maps.where((map) => map.map.sourceMapId == sourceMapId).toList();
    final originals = maps.length == 1
        ? maps.single.map.events
            .where((event) => event.sourceEventId == sourceEventId)
            .toList()
        : <SourceEvent>[];
    final program = originals.length == 1
        ? resolveSourceHealingDisplayProgram(
            source: source,
            profile: analysis.profile,
            sourceMapId: sourceMapId,
            event: originals.single)
        : null;
    if (program == null) {
      throw const SourceHealingDisplayBindingUnavailable(
          'source_program_unqualified');
    }
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyze()
            .eventAt(sourceMapId, sourceEventId);
    if (expected == null ||
        events.single.pages.any((page) =>
            page.body.nodes.isNotEmpty || page.diagnostics.isNotEmpty) ||
        canonicalJsonOf(_healingEventShape(events.single)) !=
            canonicalJsonOf(_healingEventShape(expected))) {
      throw const SourceHealingDisplayBindingUnavailable(
          'event_binding_unqualified');
    }
    final presentation =
        source.interpretationProfile?.presentationBindings?.healingDisplay;
    if (presentation == null) {
      throw const SourceHealingDisplayBindingUnavailable(
          'presentation_bindings_missing');
    }
    final sheets = presentation.sheets;
    final totalPixels = sheets.fold<int>(
        0, (total, sheet) => total + sheet.pixelWidth * sheet.pixelHeight);
    if (limits.maxArtifacts < sheets.length ||
        limits.maxMutations < sheets.length + 7 ||
        sheets.any((sheet) =>
            sheet.pixelWidth * sheet.pixelHeight > limits.maxImagePixels) ||
        totalPixels > limits.maxTotalImagePixels) {
      throw const NativeWriteException('events.healing_display.quota',
          'Healing display native assets exceed the configured budget.');
    }
    final admitted = <SourceFileEntry>[];
    var total = 0;
    for (final sheet in sheets) {
      final path = sheet.asset.relativePath;
      final matches = source.snapshot.entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(path))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 != sheet.asset.sha256) {
        throw const SourceHealingDisplayBindingUnavailable(
            'source_image_unqualified');
      }
      total += matches.single.byteLength;
      if (matches.single.byteLength > limits.maxArtifactBytes ||
          total > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException('events.healing_display.quota',
            'Healing display source images exceed the configured byte budget.');
      }
      admitted.add(matches.single);
    }
    final artifacts = <NativeArtifact>[];
    for (var index = 0; index < admitted.length; index++) {
      final file = admitted[index], sheet = sheets[index];
      cancellation?.check();
      final bytes = await files.read(file.fileId);
      cancellation?.check();
      if (bytes.length != file.byteLength ||
          crypto.sha256.convert(bytes).toString() != file.sha256!.value) {
        throw ContractError(
            'source.healing_display.image_changed',
            file.relativePath,
            'Healing display image differs from its source inventory.');
      }
      final dimensions =
          decodeRasterImageDimensions(bytes, mediaType: 'image/png');
      if (dimensions == null ||
          dimensions.width != sheet.pixelWidth ||
          dimensions.height != sheet.pixelHeight) {
        throw const SourceHealingDisplayBindingUnavailable(
            'source_image_unqualified');
      }
      artifacts.add(NativeArtifact(
          bytes: bytes, expectedSha256: file.sha256, limits: limits));
    }
    final namespace = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'kind': 'sourceHealingDisplay',
      'sourceIdentity': events.single.identity.value
    }).value.substring(0, 24);
    final tilesets = [
      for (var sheet = 1; sheet <= sheets.length; sheet++)
        'source_healing_sheet_${sheet}_$namespace'
    ];
    final category = ProjectElementCategory(
        id: 'source_healing_display_$namespace', name: 'Boules de soin');
    final elements = [
      for (final variant in presentation.variants)
        ProjectElementEntry(
            id: 'source_healing_${variant.count}_$namespace',
            name: 'Soin (${variant.count} membres)',
            tilesetId: tilesets[variant.sheetIndex],
            categoryId: category.id,
            frames: [
              for (final frame in variant.frames)
                TilesetVisualFrame(
                    source: TilesetSourceRect(
                        x: frame.x,
                        y: frame.y,
                        width: frame.width,
                        height: frame.height),
                    durationMs: frame.durationMs)
            ])
    ];
    NativeMutation mutation(String id, String action, List<String> targets,
            Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('source_healing_${id}_$namespace'),
            actionId: action,
            sourceEntityIds: [
              events.single.identity,
              for (final file in admitted) file.fileId
            ],
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    final result = SourceHealingDisplayBinding._(
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: analysis.profile.canonicalHash,
        eventIdentity: events.single.identity,
        program: program,
        elements: elements,
        artifacts: artifacts,
        files: admitted,
        mutations: [
          for (var sheet = 0; sheet < sheets.length; sheet++)
            mutation('sheet_${sheet + 1}', 'tileset.import_image', [
              tilesets[sheet],
              'image_${tilesets[sheet]}'
            ], {
              'artifactHandle': artifacts[sheet].handle,
              'tilesetId': tilesets[sheet],
              'name': 'Boules de soin ${sheet + 1}',
              'tileWidth': sheets[sheet].tileWidth,
              'tileHeight': sheets[sheet].tileHeight
            }),
          mutation('category', 'element_category.upsert', [category.id],
              {'category': category.toJson()}),
          for (var count = 0; count < 6; count++)
            mutation('variant_${count + 1}', 'element.upsert',
                [elements[count].id], {'element': elements[count].toJson()})
        ],
        evidence: {
          'kind': 'sourceHealingDisplayBinding',
          'version': 1,
          'sourceEventIdentity': events.single.identity.value,
          'sourceMapId': sourceMapId,
          'sourceEventId': sourceEventId,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': analysis.profile.canonicalHash.value,
          'program': program.toJson(),
          'sourceImages': [for (final file in admitted) file.toJson()],
          'nativeElements': [for (final element in elements) element.toJson()],
          'sourceScriptsExecuted': 0,
          'fullSourceParityQualified': false,
          'nativeDisplayCount': 'actualPartyMembersIncludingFainted',
          'nativeDisplayLifetime':
              'acceptedApplyingBeforeAtomicPartyHealAndCheckpoint',
          'sourcePresentationMilliseconds': program.sourceWaitMilliseconds,
          'nativePresentationPolicy': 'runtimeHealService',
          'declaredPresentation': presentation.toJson(),
          'nativeAnchor': 'bottomCenterOfOriginalSourceCell',
          'sourceVariableExecuted': false,
          'sourcePixelsResampled': false,
          'sourcePlacementBallShakeSoundsImported': false,
          'nativeRecoveryMusic': 'existingCompletionSceneOnce',
          'requiredNativeMachineCollision': true,
          'requiredAdmittedNurse': true,
          'sourceHealingBeforePresentationNativeHealingAfterPresentation': true,
          'nativeHasEggState': false
        });
    if (!result.isBoundToEvent(
        source: source, analysis: analysis, event: events.single)) {
      throw const SourceHealingDisplayBindingUnavailable(
          'event_binding_unqualified');
    }
    return result;
  }
}

Object? _freezeHealing(Object? value) => switch (value) {
      Map() => Map<String, Object?>.unmodifiable({
          for (final entry in value.entries)
            entry.key as String: _freezeHealing(entry.value)
        }),
      List() => List<Object?>.unmodifiable(value.map(_freezeHealing)),
      _ => value,
    };

Map<String, Object?> _healingEventShape(SourceEventDefinition event) => {
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
                : [
                    page.graphic!.tileId,
                    page.graphic!.characterName,
                    page.graphic!.hue,
                    page.graphic!.direction,
                    page.graphic!.pattern,
                    page.graphic!.opacity,
                    page.graphic!.blendType,
                    page.graphic!.moveType,
                    page.graphic!.moveSpeed,
                    page.graphic!.moveFrequency,
                    page.graphic!.walkAnime,
                    page.graphic!.stepAnime,
                    page.graphic!.directionFix,
                    page.graphic!.through,
                    page.graphic!.alwaysOnTop,
                    page.graphic!.moveRouteNodeId
                  ]
          }
      ]
    };
