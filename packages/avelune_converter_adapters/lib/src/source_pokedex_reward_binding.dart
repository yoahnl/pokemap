import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'source_event_item_bindings.dart';
import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_source_species_bindings.dart';

final class SourcePokedexRewardBinding {
  SourcePokedexRewardBinding._(
      {required this.range,
      required this.sourceMapId,
      required this.sourceEventId,
      required this.speciesEvidence,
      required this.item,
      required this.archive,
      required this.itemArchive,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.eventHash,
      required List<SourcePokedexRewardProgramNode> programs})
      : programs = List.unmodifiable(programs);

  final PokedexSpeciesRange range;
  final int sourceMapId, sourceEventId;
  final Map<String, Object?> speciesEvidence;
  final SourceEventItemBinding item;
  final SourceArchive archive, itemArchive;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      eventHash;
  final List<SourcePokedexRewardProgramNode> programs;

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (!analysis.profile.isQualified ||
        source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        event.sourceMapId != sourceMapId ||
        event.sourceEventId != sourceEventId ||
        canonicalHashOf(_eventFingerprint(event)) != eventHash) {
      return false;
    }
    final maps = source.maps.where((map) => map.map.sourceMapId == sourceMapId);
    if (maps.length != 1) {
      return false;
    }
    final originals = maps.single.map.events
        .where((event) => event.sourceEventId == sourceEventId);
    return originals.length == 1 &&
        programs.length == 2 &&
        programs.every((program) => program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: sourceMapId,
            event: originals.single));
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourcePokedexRewardBinding',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'eventHash': eventHash.value,
        'sourceDexIndex': programs.first.sourceDexIndex,
        'nativeScope': range.key,
        'sourceRegionalDexFile': archive.files.values.single.entry.toJson(),
        'speciesIdentityEvidence': speciesEvidence,
        'sourcePrograms': programs.map((program) => program.toJson()).toList(),
        'sourceItemCatalog': item.toJson(),
        'nativeGrantScope': 'nativeAtomicUnitBagGrantWithExplicitFailure',
        'sourceGiftPresentationParityQualified': false,
        'nativeHeldItemEvolutionEffectQualified': false,
        'nativeExecutionQualified': false,
        'fullSourceRewardParityQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourcePokedexRewardBindingResolver {
  const SourcePokedexRewardBindingResolver();
  Future<SourcePokedexRewardBinding?> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      required int sourceMapId,
      required int sourceEventId,
      NativePsdkCatalog? nativeCatalog,
      ScanCancellation? cancellation}) async {
    cancellation?.check();
    if (source.snapshot.state != SourceScanState.complete ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      throw ContractError('events.pokedex_reward.source_binding', r'$',
          'Pokedex reward bindings require the exact complete source analysis.');
    }
    if (!analysis.profile.isQualified) {
      return null;
    }
    final event = analysis.eventAt(sourceMapId, sourceEventId);
    if (event == null ||
        event.isQuarantined ||
        event.pages.length != 2 ||
        event.pages.any((page) =>
            page.body.nodes.length != 1 ||
            page.body.nodes.single is! SourcePokedexRewardProgramNode)) {
      return null;
    }
    final programs = event.pages
        .map((page) => page.body.nodes.single as SourcePokedexRewardProgramNode)
        .toList();
    if (programs.where((p) => p.pickup != null).length != 1 ||
        programs.firstWhere((p) => p.pickup != null).pickup!.quantity != 1) {
      return null;
    }
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyzeEventAt(sourceMapId, sourceEventId);
    if (expected == null ||
        canonicalJsonOf(_eventFingerprint(expected)) !=
            canonicalJsonOf(_eventFingerprint(event))) {
      return null;
    }
    const path = 'Data/regional_dexes.dat';
    final entries = source.snapshot.entries.where((entry) =>
        sourcePathCollisionKey(entry.relativePath) ==
        sourcePathCollisionKey(path));
    if (entries.length != 1 || entries.single.relativePath != path) {
      return null;
    }
    final entry = entries.single;
    const maxBytes = 1048576;
    if (entry.kind != SourceNodeKind.file ||
        entry.sha256 == null ||
        entry.byteLength <= 0 ||
        entry.byteLength > maxBytes) {
      return null;
    }
    final bytes = await files.read(entry.fileId);
    cancellation?.check();
    if (bytes.length != entry.byteLength ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('events.pokedex_reward.source_changed', path,
          'Regional dex bytes differ from the complete source inventory.');
    }
    final archive = SourceArchive(
        limits: const SourceArchiveLimits(
            maxFiles: 1,
            maxFileBytes: maxBytes,
            maxTotalBytes: maxBytes,
            maxTotalNodes: 100000,
            maxTotalEntries: 100000,
            maxEncodedCodeUnits: 4194304,
            maxTotalLocationCodeUnits: 4194304,
            maxReferences: 16));
    final SourceArchivedFile file;
    try {
      file = archive.add(entry, bytes);
    } on ContractError catch (error) {
      if (['quota', 'limit', 'changed', 'hash'].any(error.code.contains)) {
        rethrow;
      }
      return null;
    }
    final document = file.document;
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array ||
        root.elements.length <= programs.first.sourceDexIndex ||
        root.elements.length > 32) {
      return null;
    }
    final region = document.node(root.elements[programs.first.sourceDexIndex]);
    if (region.kind != MarshalKind.array ||
        region.elements.isEmpty ||
        region.elements.length > 2048) {
      return null;
    }
    final symbols = <String>[];
    for (final nodeId in region.elements) {
      final species = document.node(nodeId);
      if (species.kind != MarshalKind.symbol ||
          species.name == null ||
          symbols.contains(species.name)) {
        return null;
      }
      symbols.add(species.name!);
    }
    final catalog = nativeCatalog ?? NativePsdkCatalogManifest.builtin();
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot,
        files: files,
        families: const {SourcePbsFamily.species},
        cancellation: cancellation);
    final NativeSourceSpeciesBindingResult identities;
    try {
      identities = await const NativeSourceSpeciesBindings().bind(
          snapshot: source.snapshot,
          source: pbs,
          files: files,
          nativeCatalog: catalog,
          requestedSourceSymbols: symbols,
          cancellation: cancellation);
    } on ContractError catch (error) {
      if (['quota', 'limit', 'changed', 'hash'].any(error.code.contains)) {
        rethrow;
      }
      return null;
    }
    final dexNumbers = <int>{};
    for (final row in identities.rows) {
      final species = catalog.speciesById[row['nativeSpeciesId']];
      if (species == null ||
          row['nativeForm'] != 0 ||
          species.nationalDex < 1 ||
          !dexNumbers.add(species.nationalDex)) {
        return null;
      }
    }
    final orderedDex = dexNumbers.toList()..sort();
    if (orderedDex.isEmpty ||
        orderedDex.last - orderedDex.first + 1 != orderedDex.length) {
      return null;
    }
    archive.seal();
    final SourceEventItemBindings items;
    try {
      items = await const SourceEventItemBindingResolver().read(
          snapshot: source.snapshot,
          missingItemBindings: source.missingItemBindings,
          files: files,
          symbols: [
            programs.firstWhere((p) => p.pickup != null).pickup!.sourceSymbol
          ],
          eventProfile: analysis.profile,
          cancellation: cancellation);
    } on ContractError catch (error) {
      if (['quota', 'limit', 'changed', 'hash'].any(error.code.contains)) {
        rethrow;
      }
      return null;
    }
    final item = items.bindings[
        programs.firstWhere((p) => p.pickup != null).pickup!.sourceSymbol];
    if (item == null ||
        !item.pickupQualified ||
        item.isKeyItem ||
        (item.isMachine &&
            (item.sourceMachineMove == null ||
                item.definition.machine == null)) ||
        (programs.first.skipGrantWhenOwned && !item.isMachine) ||
        item.sourceSnapshotHash != source.snapshot.canonicalHash) {
      return null;
    }
    final binding = SourcePokedexRewardBinding._(
        range: PokedexSpeciesRange(
            firstNationalDex: orderedDex.first,
            lastNationalDex: orderedDex.last),
        sourceMapId: sourceMapId,
        sourceEventId: sourceEventId,
        speciesEvidence: identities.evidence,
        item: item,
        archive: archive,
        itemArchive: items.archive,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: analysis.profile.canonicalHash,
        eventHash: canonicalHashOf(_eventFingerprint(event)),
        programs: programs);
    return binding.isBoundToEvent(
            source: source, analysis: analysis, event: event)
        ? binding
        : null;
  }
}

Map<String, Object?> _eventFingerprint(SourceEventDefinition event) => {
      'identity': event.identity.value,
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'quarantined': event.isQuarantined,
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'condition': page.condition.toJson(),
            'rawDataRef': page.rawDataRef?.toJson(),
            'body': [
              for (final node in page.body.nodes)
                node is SourcePokedexRewardProgramNode
                    ? node.toJson()
                    : {'kind': node.runtimeType.toString()}
            ],
            'graphic': page.graphic == null
                ? null
                : {
                    'tileId': page.graphic!.tileId,
                    'characterName': page.graphic!.characterName,
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
