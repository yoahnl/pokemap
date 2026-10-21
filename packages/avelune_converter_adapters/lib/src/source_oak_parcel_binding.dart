import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';
import 'source_event_item_bindings.dart';
import 'source_event_sound_binding.dart';
import 'source_oak_parcel_tile_binding.dart';

final class SourceOakParcelBinding {
  SourceOakParcelBinding._({
    required this.program,
    required this.eventHash,
    required this.companionHashes,
    required this.tileActors,
    required this.items,
    required this.audio,
    required this.dexFile,
    required this.dexSpecies,
    required this.dexArchive,
    required this.inheritedThroughEvidence,
    required this.throughCommonEventsFile,
    required this.hasPokedexSourceFactId,
    required this.unlockedDexSourceFactId,
  });

  final SourceOakParcelProgram program;
  final Sha256Hash eventHash;
  final Map<int, Sha256Hash> companionHashes;
  final Map<ConverterId, SourceOakParcelTileBinding> tileActors;
  final Map<String, SourceEventItemBinding> items;
  final Map<String, SourceEventSoundBinding> audio;
  final SourceFileEntry dexFile;
  final List<String> dexSpecies;
  final SourceArchive dexArchive;
  final Map<String, Object?> inheritedThroughEvidence;
  final SourceFileEntry throughCommonEventsFile;
  final String hasPokedexSourceFactId, unlockedDexSourceFactId;

  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
      SourceEventDefinition event) {
    if (!analysis.profile.isQualified ||
        source.snapshot.canonicalHash != program.sourceSnapshotHash ||
        source.canonicalHash != program.normalizationHash ||
        analysis.profile.canonicalHash != program.profileHash ||
        event.sourceMapId != program.sourceMapId ||
        event.sourceEventId != program.sourceEventId ||
        canonicalHashOf(_eventValue(event)) != eventHash ||
        event.pages.take(4).any((page) =>
            page.body.nodes.length != 1 ||
            page.body.nodes.single is! SourceOakParcelProgramNode)) {
      return false;
    }
    for (final companion in companionHashes.entries) {
      final actor = analysis.eventAt(program.sourceMapId, companion.key);
      if (actor == null ||
          canonicalHashOf(_eventValue(actor)) != companion.value) {
        return false;
      }
    }
    return tileActors.length == 2 &&
        tileActors.values.every((actor) => actor.isBoundTo(source, analysis));
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourceOakParcelNativeBinding',
        'program': program.toJson(),
        'eventHash': eventHash.value,
        'companionHashes': {
          for (final entry in companionHashes.entries)
            '${entry.key}': entry.value.value,
        },
        'tileActors': tileActors.values.map((actor) => actor.toJson()).toList(),
        'items': {
          for (final item in items.entries) item.key: item.value.toJson()
        },
        'audio': {
          for (final entry in audio.entries) entry.key: entry.value.evidence
        },
        'regionalDex': {
          'file': dexFile.toJson(),
          'index': 1,
          'sourceSpecies': dexSpecies,
          'sourceStatePreserved': true,
          'nativePresentation': 'avelunePokedexCatalog',
          'regionalCatalogPresentationParity': false,
        },
        'persistentSourceFacts': [
          hasPokedexSourceFactId,
          unlockedDexSourceFactId
        ],
        'actorFacingAdaptation': {
          'sourceActorEventId': program.sourceEventId,
          'nativeCondition':
              'oppositeLivePlayerFacingAfterOwnerInteractionLock',
          'adjacentContactOnly': true,
          'sourceCounterCellsAbsent': true,
          'sourceDirectionFixed': false,
          'sourceOracle': [
            'events.Interpreter:64-70',
            'events.Interpreter_Commands:424-426',
            'walking.Game_Character:165-169,868-875',
          ],
        },
        'nativeMusicAdaptation': {
          'sourceMemorizeMergedWithPlay': true,
          'sourceTemporalAudioParity': false,
          'sourcePlaybackPositionRestored': false,
          'nativeRestoration': 'mapAmbienceIdentityAndVolume',
        },
        'inheritedActorThrough': inheritedThroughEvidence,
        'allSourcePageMasksRequired': true,
        'adaptedPageIndices': SourceOakParcelProgram.adaptedPageIndices,
        'unsupportedPageIndices': SourceOakParcelProgram.unsupportedPageIndices,
        'staticSemanticsQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourceOakParcelBindingResolver {
  const SourceOakParcelBindingResolver();

  Future<SourceOakParcelBinding?> read({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event,
    required SourceFilePort files,
    required Map<String, SourceEventItemBinding> items,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    if (source.snapshot.state != SourceScanState.complete ||
        !analysis.profile.isQualified ||
        event.pages.length != 6) {
      return null;
    }
    final wrappers = event.pages
        .take(4)
        .map((page) => page.body.nodes
            .whereType<SourceOakParcelProgramNode>()
            .singleOrNull)
        .toList();
    if (wrappers.any((node) => node == null)) {
      return null;
    }
    final program = wrappers.first!.program;
    final maps = source.maps
        .where((map) => map.map.sourceMapId == event.sourceMapId)
        .toList();
    final originals = maps.length == 1
        ? maps.single.map.events
            .where((raw) => raw.sourceEventId == event.sourceEventId)
            .toList()
        : <SourceEvent>[];
    if (originals.length != 1 ||
        !program.isBoundTo(
            source: source,
            profile: analysis.profile,
            event: originals.single) ||
        wrappers.indexed.any((entry) =>
            entry.$2!.pageIndex != entry.$1 ||
            entry.$2!.program.programHash != program.programHash)) {
      return null;
    }
    final analyzer =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile);
    final originalAnalysis = analyzer.analyze();
    final freshOwner =
        originalAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    if (freshOwner == null ||
        canonicalJsonOf(_eventValue(freshOwner)) !=
            canonicalJsonOf(_eventValue(event))) {
      return null;
    }
    final ownerGraphic = event.pages.first.graphic;
    if (ownerGraphic == null ||
        ownerGraphic.directionFix ||
        ownerGraphic.moveType != 0 ||
        ownerGraphic.through ||
        event.pages.take(4).any((page) =>
            page.triggerCode != 0 ||
            page.graphic?.directionFix != false ||
            page.graphic?.moveType != 0)) {
      return null;
    }
    final semantic = SourceSemanticResolver.forProject(source);
    for (final (x, y) in [
      (event.x, event.y - 1),
      (event.x, event.y + 1),
      (event.x - 1, event.y),
      (event.x + 1, event.y)
    ]) {
      final cell = semantic.cellAt(event.sourceMapId, x, y);
      if (semantic.resolveCell(cell).counter) {
        return null;
      }
    }
    final companions = <int, Sha256Hash>{};
    for (final id in const [12, 15, 25]) {
      final actor = analysis.eventAt(program.sourceMapId, id);
      final fresh = originalAnalysis.eventAt(program.sourceMapId, id);
      if (actor == null ||
          fresh == null ||
          canonicalJsonOf(_eventValue(actor)) !=
              canonicalJsonOf(_eventValue(fresh))) {
        return null;
      }
      if (id == 25 && !_rivalCompanion(actor, analyzer)) {
        return null;
      }
      companions[id] = canonicalHashOf(_eventValue(actor));
    }
    final through = _oakInheritedActorThrough(source, program.sourceMapId, 25);
    if (through == null) return null;
    final commonEvents = source.archive.files.values
        .singleWhere(
            (entry) => entry.entry.relativePath == 'Data/CommonEvents.rxdata')
        .entry;
    if (commonEvents.byteLength < 1 ||
        commonEvents.byteLength > 1048576 ||
        commonEvents.sha256 == null) {
      return null;
    }
    final commonBytes = await files.read(commonEvents.fileId);
    cancellation?.check();
    if (commonBytes.length != commonEvents.byteLength ||
        crypto.sha256.convert(commonBytes).toString() !=
            commonEvents.sha256!.value) {
      throw const NativeWriteException('events.oak_parcel.concurrency_changed',
          'The source common-event interpreter census differs from its complete inventory.');
    }
    for (final symbol in const ['OAKPARCEL', 'POKEBALL']) {
      final item = items[symbol];
      if (item == null ||
          item.sourceSymbol != symbol ||
          !item.pickupQualified ||
          item.sourceSnapshotHash != source.snapshot.canonicalHash ||
          item.interpretationProfile?.canonicalHash !=
              source.interpretationProfile?.canonicalHash) {
        return null;
      }
    }
    final props = await const SourceOakParcelTileBindingResolver().read(
        source: source,
        analysis: analysis,
        program: program,
        files: files,
        limits: limits);
    final audio = <String, SourceEventSoundBinding>{};
    for (final page in program.pages.take(4)) {
      for (final command in page['list'] as List) {
        final code = command['code'];
        if (code != 241 && code != 249) continue;
        final parameters = command['parameters'] as List;
        if (parameters.length != 1 || parameters.single is! Map) {
          return null;
        }
        final value = parameters.single as Map;
        if (value['pitch'] != 100 ||
            value['volume'] != 100 ||
            value['name'] is! String) {
          return null;
        }
        final kind = code == 249
            ? SourceEventAudioKind.musicEffect
            : SourceEventAudioKind.music;
        final name = value['name'] as String;
        final key = '${code == 249 ? 'me:' : 'bgm:'}$name';
        audio[key] ??= await const SourceEventSoundResolver().read(
            source: source,
            files: files,
            name: name,
            kind: kind,
            policy: code == 249
                ? SourceEventSoundPolicy.nativeAuthoredVolume
                : SourceEventSoundPolicy.sourceEngineGain,
            limits: limits,
            cancellation: cancellation);
      }
    }
    const path = 'Data/regional_dexes.dat';
    final entries = source.snapshot.entries
        .where((entry) =>
            sourcePathCollisionKey(entry.relativePath) ==
            sourcePathCollisionKey(path))
        .toList();
    if (entries.length != 1 || entries.single.relativePath != path) {
      return null;
    }
    final dex = entries.single;
    const maxBytes = 1048576;
    if (dex.kind != SourceNodeKind.file ||
        dex.sha256 == null ||
        dex.byteLength <= 0 ||
        dex.byteLength > maxBytes) {
      return null;
    }
    final bytes = await files.read(dex.fileId);
    cancellation?.check();
    if (bytes.length != dex.byteLength ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != dex.sha256!.value) {
      throw const NativeWriteException('events.oak_parcel.dex_changed',
          'The source regional dex differs from its complete inventory.');
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
    final document = archive.add(dex, bytes).document;
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array ||
        root.elements.length < 2 ||
        root.elements.length > 32) {
      return null;
    }
    final region = document.node(root.elements[1]);
    if (region.kind != MarshalKind.array ||
        region.elements.isEmpty ||
        region.elements.length > 2048) {
      return null;
    }
    final symbols = <String>[];
    for (final id in region.elements) {
      final species = document.node(id);
      if (species.kind != MarshalKind.symbol ||
          species.name == null ||
          symbols.contains(species.name)) {
        return null;
      }
      symbols.add(species.name!);
    }
    final namespace = source.snapshot.logicalProjectNamespace.value;
    final result = SourceOakParcelBinding._(
        program: program,
        eventHash: canonicalHashOf(_eventValue(event)),
        companionHashes: Map.unmodifiable(companions),
        tileActors: Map.unmodifiable(props),
        items: Map.unmodifiable({
          for (final symbol in ['OAKPARCEL', 'POKEBALL']) symbol: items[symbol]!
        }),
        audio: Map.unmodifiable(audio),
        dexFile: dex,
        dexSpecies: List.unmodifiable(symbols),
        dexArchive: archive,
        inheritedThroughEvidence: through,
        throughCommonEventsFile: commonEvents,
        hasPokedexSourceFactId: 'source:$namespace:player:has_pokedex',
        unlockedDexSourceFactId: 'source:$namespace:player:pokedex:unlocked:1');
    return result.isBoundTo(source, analysis, event) ? result : null;
  }
}

bool _rivalCompanion(
        SourceEventDefinition event, SourceEventAnalyzer analyzer) =>
    event.pages.length == 2 &&
    event.pages.every((page) =>
        page.triggerCode == 0 &&
        page.body.nodes.every((node) => node is SourceAnnotationNode) &&
        page.graphic?.tileId == 0 &&
        page.graphic?.moveType == 0 &&
        page.graphic?.stepAnime == false &&
        page.graphic?.directionFix == false &&
        page.graphic?.through == true &&
        page.graphic?.opacity == 255 &&
        page.graphic?.blendType == 0) &&
    event.pages.first.graphic!.characterName.isEmpty &&
    event.pages.first.condition.kind == SourceEventConditionKind.always &&
    event.pages.last.graphic!.characterName.isNotEmpty &&
    event.pages.last.condition.kind == SourceEventConditionKind.all &&
    event.pages.last.condition.children.length == 1 &&
    event.pages.last.condition.children.single.kind ==
        SourceEventConditionKind.selfSwitch &&
    event.pages.last.condition.children.single.factId ==
        analyzer.selfFactId(event.sourceMapId, event.sourceEventId, 'A');

Map<String, Object?> _eventValue(SourceEventDefinition event) => {
      'identity': event.identity.value,
      'map': event.sourceMapId,
      'event': event.sourceEventId,
      'file': event.sourceFileId.value,
      'locator': event.locator.toJson(),
      'x': event.x,
      'y': event.y,
      'name': event.name,
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'rawDataRef': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
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
            'nodes': [
              for (final node in page.body.nodes)
                node is SourceOakParcelProgramNode
                    ? node.toJson()
                    : {
                        'type': node.runtimeType.toString(),
                        'span': node.span.toJson(),
                      }
            ],
          }
      ],
    };

Map<String, Object?>? _oakInheritedActorThrough(
    NormalizedSourceProject source, int mapId, int actorId) {
  try {
    final map =
        source.maps.singleWhere((entry) => entry.map.sourceMapId == mapId);
    final common = source.archive.files.values.singleWhere(
        (entry) => entry.entry.relativePath == 'Data/CommonEvents.rxdata');
    int field(MarshalDocument document, MarshalNode object, String name) {
      final value = object.instanceVariables
          .where((pair) => document.node(pair.key).name == name)
          .singleOrNull;
      if (value == null) throw const FormatException();
      return value.value;
    }

    int integer(MarshalDocument document, int id) {
      final node = document.node(id);
      if (node.kind != MarshalKind.integer || node.integerValue == null) {
        throw const FormatException();
      }
      return node.integerValue!.toInt();
    }

    final commonRoot = common.document.node(common.document.rootId);
    if (commonRoot.kind != MarshalKind.array ||
        commonRoot.elements.length > 256) {
      return null;
    }
    for (final id in commonRoot.elements) {
      final event = common.document.node(id);
      if (event.kind == MarshalKind.nil) continue;
      if (event.kind != MarshalKind.object ||
          event.className != 'RPG::CommonEvent' ||
          integer(common.document, field(common.document, event, '@trigger')) !=
              0) {
        return null;
      }
    }
    final routes = <Map<String, Object?>>[];
    var inspectedCommands = 0;
    for (final event in map.map.events) {
      for (final page in event.pages) {
        if (page.triggerCode == 4) return null;
        for (final command in page.commands) {
          if (++inspectedCommands > 32768) return null;
          if (const {355, 655}.contains(command.code) &&
              command.parameters
                  .whereType<String>()
                  .any((text) => text.toLowerCase().contains('through'))) {
            return null;
          }
          if (command.code != 209 ||
              command.parameters.length != 2 ||
              !(command.parameters.first == actorId ||
                  event.sourceEventId == actorId &&
                      command.parameters.first == 0)) {
            continue;
          }
          final value = command.parameters[1];
          if (value is! Map ||
              value.length != 1 ||
              value['preservedDataRef'] is! String) {
            return null;
          }
          final reference = source.archive
              .references[ConverterId(value['preservedDataRef'] as String)];
          if (reference == null) return null;
          final document = source.archive.files[reference.fileId]?.document;
          if (document == null) return null;
          final route = document.node(reference.nodeId);
          if (route.kind != MarshalKind.object ||
              route.className != 'RPG::MoveRoute' ||
              document.node(field(document, route, '@repeat')).booleanValue !=
                  false) {
            return null;
          }
          final steps = document.node(field(document, route, '@list'));
          if (steps.kind != MarshalKind.array || steps.elements.length > 256) {
            return null;
          }
          final codes = <int>[];
          for (final id in steps.elements) {
            final step = document.node(id);
            if (step.kind != MarshalKind.object ||
                step.className != 'RPG::MoveCommand') {
              return null;
            }
            final code = integer(document, field(document, step, '@code'));
            if (!const {0, 1, 2, 3, 4, 15, 16, 17, 18, 19, 42}.contains(code)) {
              return null;
            }
            codes.add(code);
          }
          routes.add(Map.unmodifiable({
            'locator': command.sourceLocator.toJson(),
            'rawDataRef': reference.toJson(),
            'codes': List<int>.unmodifiable(codes),
          }));
        }
      }
    }
    if (routes.isEmpty) return null;
    return Map.unmodifiable({
      'sourceActorEventId': actorId,
      'sourcePageThrough': true,
      'sourceMapId': mapId,
      'sourceMapHash':
          source.archive.files[map.map.sourceFileId]!.contentHash.value,
      'sourceCommonEventsFile': common.entry.toJson(),
      'parallelMapPages': 0,
      'backgroundCommonEvents': 0,
      'sourceThroughToggleCommands': 0,
      'sourceActorRouteCensus': List.unmodifiable(routes),
      'nativeRoutePrefix': 'through(true)',
      'scope': 'closedCompanionRoutesOnly',
      'sourceScriptsExecuted': 0,
    });
  } on FormatException {
    return null;
  } on StateError {
    return null;
  }
}
