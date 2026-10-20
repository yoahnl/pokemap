import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_source_species_bindings.dart';

final class SourcePokemonGiftBindings {
  SourcePokemonGiftBindings(Map<String, SourcePokemonGiftBinding> bindings,
      Map<String, String> refusals)
      : byEventIdentity = Map.unmodifiable(bindings),
        refusals = Map.unmodifiable(refusals);
  final Map<String, SourcePokemonGiftBinding> byEventIdentity;
  final Map<String, String> refusals;
}

final class SourcePokemonGiftBinding {
  SourcePokemonGiftBinding._(
      {required this.program,
      required this.nativeSpeciesId,
      required this.nativeFormId,
      required Map<String, Object?> evidence,
      required this.sourceHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.catalog,
      required this.catalogHash,
      required this.eventProof})
      : _evidenceJson = canonicalJsonOf(evidence);
  final SourcePokemonGiftNode program;
  final String nativeSpeciesId, nativeFormId;
  final String _evidenceJson;
  Map<String, Object?> get evidence =>
      (jsonDecode(_evidenceJson) as Map).cast<String, Object?>();
  final Sha256Hash sourceHash, normalizationHash, profileHash, catalogHash;
  final NativePsdkCatalog catalog;
  final String eventProof;

  bool isBoundToEvent(
          {required NormalizedSourceProject source,
          required SourceEventAnalysis analysis,
          required SourceEventDefinition event}) =>
      analysis.profile.isQualified &&
      source.snapshot.canonicalHash == sourceHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      analysis.profile.sourceSnapshotHash == sourceHash &&
      analysis.profile.normalizationHash == normalizationHash &&
      event.identity ==
          source.eventIdentity(event.sourceMapId, event.sourceEventId) &&
      canonicalHashOf(catalog.toJson(),
              limits: nativePsdkCatalogShardJsonLimits) ==
          catalogHash &&
      _stationaryGift(event) != null &&
      _eventProof(event) == eventProof;
}

final class SourcePokemonGiftBindingResolver {
  const SourcePokemonGiftBindingResolver();

  Future<SourcePokemonGiftBindings> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      NativePsdkCatalog? nativeCatalog,
      ScanCancellation? cancellation}) async {
    final bindings = <String, SourcePokemonGiftBinding>{};
    final refusals = <String, String>{};
    final candidates = analysis.events
        .where(
            (event) => event.pages.any((page) => _gifts(page.body).isNotEmpty))
        .toList();
    if (candidates.isEmpty) {
      return SourcePokemonGiftBindings(bindings, refusals);
    }
    if (!analysis.profile.isQualified ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      for (final event in candidates) {
        refusals[event.identity.value] = 'sourcePokemonGiftProfileUnqualified';
      }
      return SourcePokemonGiftBindings(bindings, refusals);
    }
    final scripts = source.snapshot.entries
        .where((e) => e.relativePath == 'Data/Scripts.rxdata')
        .toList();
    var helperQualified = false;
    if (scripts.length == 1 &&
        scripts.single.sha256?.value ==
            source.interpretationProfile?.scriptsArchiveHash.value) {
      cancellation?.check();
      try {
        final bytes = await files.read(scripts.single.fileId);
        helperQualified = bytes.length == scripts.single.byteLength &&
            crypto.sha256.convert(bytes).toString() ==
                scripts.single.sha256!.value;
      } on FileSystemException {
        helperQualified = false;
      }
    }
    if (!helperQualified || nativeCatalog == null) {
      for (final event in candidates) {
        refusals[event.identity.value] = helperQualified
            ? 'sourcePokemonGiftCatalogueUnavailable'
            : 'sourcePokemonGiftHelperUnqualified';
      }
      return SourcePokemonGiftBindings(bindings, refusals);
    }
    final original =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile);
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot, files: files, cancellation: cancellation);
    final catalogHash = canonicalHashOf(nativeCatalog.toJson(),
        limits: nativePsdkCatalogShardJsonLimits);
    for (final event in candidates) {
      cancellation?.check();
      final id = event.identity.value;
      final program = _stationaryGift(event);
      final expected = original.analyzeEventAt(event.sourceMapId, event.sourceEventId);
      if (program == null ||
          expected == null ||
          _stationaryGift(expected) == null ||
          _eventProof(event) != _eventProof(expected) ||
          program.sourceSnapshotHash != source.snapshot.canonicalHash ||
          program.normalizationHash != source.canonicalHash ||
          program.profileHash != analysis.profile.canonicalHash) {
        refusals[id] = 'sourcePokemonGiftWholeEventUnqualified';
        continue;
      }
      try {
        final identities = await const NativeSourceSpeciesBindings().bind(
            snapshot: source.snapshot,
            source: pbs,
            files: files,
            nativeCatalog: nativeCatalog,
            requestedSourceSymbols: [program.sourceSpeciesSymbol],
            cancellation: cancellation);
        final identity = identities.rows.single;
        final speciesId = identity['nativeSpeciesId'] as String;
        final species = nativeCatalog.speciesById[speciesId];
        final learnset = nativeCatalog.learnsetsBySpeciesId[speciesId];
        if (species == null ||
            learnset == null ||
            species.id != speciesId ||
            species.forms.formId != '${identity['nativeForm']}' ||
            nativeCatalog.mediaBySpeciesId[speciesId] == null) {
          refusals[id] = 'sourcePokemonGiftNativeClosureUnqualified';
          continue;
        }
        final moves = nativeTrainerDefaultMoveIds(learnset, program.level);
        if (moves.isEmpty ||
            moves.length > 4 ||
            moves.any((moveId) =>
                nativeCatalog.movesById[moveId] == null ||
                nativeCatalog.movesById[moveId]!.pp <= 0)) {
          refusals[id] = 'sourcePokemonGiftNativeMovesUnqualified';
          continue;
        }
        final evidence = <String, Object?>{
          'kind': 'literalPokemonGiftNativeBinding',
          'program': program.toJson(),
          'sourceSpeciesBinding': identity,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': analysis.profile.canonicalHash.value,
          'catalogHash': catalogHash.value,
          'nativeSpeciesId': speciesId,
          'nativeFormId': species.forms.formId,
          'nativeDefaultMoveIds': moves,
          'nicknameMaxGraphemes': 10,
          'helperOracle': {
            'archiveSha256': source.interpretationProfile?.scriptsArchiveHash.value,
            'module': 'Utilities_Pokemon',
            'moduleIndex': 363,
            'moduleSha256':
                'f94d2cb7fe5a5dea5aff34095642cacf4bd7d57b2a9251a39f735743348dc369',
            'pbAddPokemonLine': 48,
            'pbNicknameLine': 8,
            'sourceReturnValueUsed': false
          },
          'presentationAdaptation': {
            'kind': 'explicitNativePresentationAdaptation',
            'receipt': 'avelunePokemonGift',
            'nicknamePolicy': 'offer',
            'sourceNicknamePreferenceMapped': false,
            'sourceDefaultGiveNicknames': 0,
            'pokedexPolicy': 'whenNewAndPokedexVisible',
            'sourceDexFlagsMapped': false,
            'nativeAvailability':
                'pauseMenuState.pokedexVisibilityWithProjectDefaults',
            'sourceAvailability': ['has_pokedex', 'species_in_unlocked_dex'],
            'sourcePresentationParity': false
          },
          'sourceFiles': [
            for (final entry in source.snapshot.entries)
              if (entry.relativePath == 'Data/Scripts.rxdata' ||
                  entry.relativePath == 'Data/species.dat' ||
                  entry.relativePath ==
                      (identity['sourceLocator'] as Map)['file'] ||
                  entry.relativePath ==
                      (identity['sourceBaseLocator'] as Map)['file'])
                entry.toJson()
          ],
          'sourceSuffixPolicy': 'allBusinessPortsContinueSourceSuccessor',
          'sourceScriptsExecuted': 0,
        };
        bindings[id] = SourcePokemonGiftBinding._(
            program: program,
            nativeSpeciesId: speciesId,
            nativeFormId: species.forms.formId,
            evidence: evidence,
            sourceHash: source.snapshot.canonicalHash,
            normalizationHash: source.canonicalHash,
            profileHash: analysis.profile.canonicalHash,
            catalog: nativeCatalog,
            catalogHash: catalogHash,
            eventProof: _eventProof(event));
      } on ContractError catch (error) {
        refusals[id] = 'sourcePokemonGiftCatalogueUnqualified:${error.code}';
      }
    }
    return SourcePokemonGiftBindings(bindings, refusals);
  }
}

Iterable<SourcePokemonGiftNode> _gifts(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    if (node is SourcePokemonGiftNode) {
      yield node;
    }
    if (node is SourceConditionalNode) {
      yield* _gifts(node.whenTrue);
      yield* _gifts(node.whenFalse);
    }
    final choice = node is SourceChoiceNode
        ? node
        : node is SourceTextNode
            ? node.followingChoice
            : null;
    if (choice != null) {
      for (final branch in choice.branches) {
        yield* _gifts(branch.body);
      }
      if (choice.cancelBranch case final branch?) {
        yield* _gifts(branch);
      }
    }
  }
}

SourcePokemonGiftNode? _stationaryGift(SourceEventDefinition event) {
  if (event.isQuarantined ||
      event.pages.length != 2 ||
      event.pages.first.condition.kind != SourceEventConditionKind.always) {
    return null;
  }
  final first = event.pages.first, last = event.pages.last;
  final condition = last.condition.kind == SourceEventConditionKind.all &&
          last.condition.children.length == 1
      ? last.condition.children.single
      : last.condition;
  if (condition.kind != SourceEventConditionKind.selfSwitch ||
      !condition.expectedValue) {
    return null;
  }
  for (final page in event.pages) {
    final g = page.graphic;
    if (page.rawDataRef == null ||
        page.triggerCode != 0 ||
        g == null ||
        g.moveType != 0 ||
        g.characterName.isEmpty ||
        g.directionFix ||
        g.through ||
        g.tileId != 0 ||
        g.hue != 0 ||
        g.opacity != 255 ||
        g.blendType != 0 ||
        g.stepAnime ||
        g.alwaysOnTop) {
      return null;
    }
  }
  if (last.body.nodes
          .any((n) => n is! SourceTextNode && n is! SourceAnnotationNode) ||
      last.body.nodes
          .whereType<SourceTextNode>()
          .any((n) => n.followingChoice != null)) {
    return null;
  }
  final gifts = first.body.nodes.whereType<SourcePokemonGiftNode>().toList();
  if (gifts.length != 1) {
    return null;
  }
  final gift = gifts.single, index = first.body.nodes.indexOf(gifts.single);
  if (first.body.nodes
          .take(index)
          .any((n) => n is! SourceTextNode && n is! SourceAnnotationNode) ||
      first.body.nodes
          .whereType<SourceTextNode>()
          .any((n) => n.followingChoice != null)) {
    return null;
  }
  final suffix = first.body.nodes.skip(index + 1).toList();
  if (suffix.any((n) =>
          n is! SourceTextNode &&
          n is! SourceSelfSwitchNode &&
          n is! SourceInteractionFacingNode &&
          n is! SourceAnnotationNode) ||
      suffix.whereType<SourceSelfSwitchNode>().length != 1) {
    return null;
  }
  final write = suffix.whereType<SourceSelfSwitchNode>().single;
  return write.value && write.factId == condition.factId ? gift : null;
}

String _eventProof(SourceEventDefinition event) => canonicalJsonOf({
      'identity': event.identity.value,
      'sourceFileId': event.sourceFileId.value,
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final p in event.pages)
          {
            'sourcePage': p.sourcePage.toJson(),
            'condition': p.condition.toJson(),
            'rawDataRef': p.rawDataRef?.toJson(),
            'locator': p.locator.toJson(),
            'graphic': p.graphic == null
                ? null
                : {
                    'character': p.graphic!.characterName,
                    'tileId': p.graphic!.tileId,
                    'direction': p.graphic!.direction,
                    'pattern': p.graphic!.pattern,
                    'hue': p.graphic!.hue,
                    'opacity': p.graphic!.opacity,
                    'blendType': p.graphic!.blendType,
                    'moveType': p.graphic!.moveType,
                    'moveSpeed': p.graphic!.moveSpeed,
                    'moveFrequency': p.graphic!.moveFrequency,
                    'walkAnime': p.graphic!.walkAnime,
                    'stepAnime': p.graphic!.stepAnime,
                    'directionFix': p.graphic!.directionFix,
                    'through': p.graphic!.through,
                    'alwaysOnTop': p.graphic!.alwaysOnTop,
                    'moveRouteNodeId': p.graphic!.moveRouteNodeId
                  },
            'nodes': [
              for (final n in p.body.nodes)
                {
                  'type': n.runtimeType.toString(),
                  'span': n.span.toJson(),
                  if (n is SourcePokemonGiftNode) 'gift': n.toJson(),
                  if (n is SourceTextNode) 'text': n.text,
                  if (n is SourceTextNode)
                    'annotations': [for (final a in n.annotations) a.toJson()],
                  if (n is SourceAnnotationNode) 'annotation': n.toJson(),
                  if (n is SourceSelfSwitchNode)
                    'self': {
                      'factId': n.factId,
                      'value': n.value,
                      'letter': n.letter
                    },
                  if (n is SourceInteractionFacingNode)
                    'raw': [for (final r in n.rawDataRefs) r.toJson()],
                }
            ],
          }
      ],
    });
