import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_source_species_bindings.dart';

final class SourceStarterChoiceBinding {
  SourceStarterChoiceBinding._(
      {required this.program,
      required this.nativeSpeciesId,
      required this.nativeFormId,
      required this.catalog,
      required this.catalogHash,
      required Map<String, Object?> evidence})
      : _evidenceJson = canonicalJsonOf(evidence);
  final SourceStarterChoiceProgram program;
  final String nativeSpeciesId, nativeFormId;
  final NativePsdkCatalog catalog;
  final Sha256Hash catalogHash;
  final String _evidenceJson;
  Map<String, Object?> get evidence =>
      (jsonDecode(_evidenceJson) as Map).cast<String, Object?>();

  bool isBoundTo(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    final original = source.maps
        .where((map) => map.map.sourceMapId == event.sourceMapId)
        .singleOrNull
        ?.map
        .events
        .where((value) => value.sourceEventId == event.sourceEventId)
        .singleOrNull;
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyzeEventAt(event.sourceMapId, event.sourceEventId);
    return original != null &&
        expected != null &&
        _starterEventProof(expected) == _starterEventProof(event) &&
        program.isBoundTo(
            source: source, profile: analysis.profile, event: original) &&
        canonicalHashOf(catalog.toJson(),
                limits: nativePsdkCatalogShardJsonLimits) ==
            catalogHash;
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedStarterChoiceNativeBinding',
        'program': program.toJson(),
        'sourceSnapshotHash': program.sourceSnapshotHash.value,
        'normalizationHash': program.normalizationHash.value,
        'profileHash': program.profileHash.value,
        'nativeSpeciesId': nativeSpeciesId,
        'nativeFormId': nativeFormId,
        'catalogHash': catalogHash.value,
        ...evidence
      };
}

final class SourceStarterChoiceBindingResolver {
  const SourceStarterChoiceBindingResolver();
  Future<Map<ConverterId, SourceStarterChoiceBinding>> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      required NativePsdkCatalog? nativeCatalog,
      ScanCancellation? cancellation}) async {
    cancellation?.check();
    final candidates = <ConverterId, SourceStarterChoiceProgram>{};
    for (final event in analysis.events) {
      cancellation?.check();
      if (event.pages.length != 4 ||
          !event.pages[1].sourcePage.commands.any((command) =>
              command.code == 355 &&
              command.parameters.length == 1 &&
              command.parameters.single is String &&
              RegExp(r'^\s*pbAddPokemon\b')
                  .hasMatch(command.parameters.single as String))) {
        continue;
      }
      final original = source.maps
          .where((map) => map.map.sourceMapId == event.sourceMapId)
          .singleOrNull
          ?.map
          .events
          .where((value) => value.sourceEventId == event.sourceEventId)
          .singleOrNull;
      if (original == null) continue;
      final program = SourceStarterChoiceProgram.read(
          source: source,
          profile: analysis.profile,
          sourceMapId: event.sourceMapId,
          event: original);
      if (program != null) candidates[event.identity] = program;
    }
    if (candidates.isEmpty || nativeCatalog == null) return const {};
    final scripts = source.snapshot.entries
        .where((entry) => entry.relativePath == 'Data/Scripts.rxdata')
        .singleOrNull;
    if (scripts == null ||
        scripts.sha256 != source.interpretationProfile?.scriptsArchiveHash) {
      return const {};
    }
    cancellation?.check();
    final bytes = await files.read(scripts.fileId);
    if (bytes.length != scripts.byteLength ||
        crypto.sha256.convert(bytes).toString() != scripts.sha256!.value) {
      return const {};
    }
    final pbs = await const SourcePbsParser().read(
        snapshot: source.snapshot,
        files: files,
        families: const {SourcePbsFamily.species, SourcePbsFamily.forms},
        cancellation: cancellation);
    final result = <ConverterId, SourceStarterChoiceBinding>{};
    final catalogHash = canonicalHashOf(nativeCatalog.toJson(),
        limits: nativePsdkCatalogShardJsonLimits);
    for (final entry in candidates.entries) {
      cancellation?.check();
      try {
        final identities = await const NativeSourceSpeciesBindings().bind(
            snapshot: source.snapshot,
            source: pbs,
            files: files,
            nativeCatalog: nativeCatalog,
            requestedSourceSymbols: [entry.value.sourceSpeciesSymbol],
            cancellation: cancellation);
        final identity = identities.rows.single;
        final speciesId = identity['nativeSpeciesId'] as String;
        final species = nativeCatalog.speciesById[speciesId];
        final learnset = nativeCatalog.learnsetsBySpeciesId[speciesId];
        if (species == null ||
            learnset == null ||
            species.forms.formId != '${identity['nativeForm']}' ||
            nativeCatalog.mediaBySpeciesId[speciesId] == null) {
          continue;
        }
        final moves = nativeTrainerDefaultMoveIds(learnset, entry.value.level);
        if (moves.isEmpty ||
            moves.length > 4 ||
            moves.any((id) =>
                nativeCatalog.movesById[id] == null ||
                nativeCatalog.movesById[id]!.pp <= 0)) {
          continue;
        }
        result[entry.key] = SourceStarterChoiceBinding._(
            program: entry.value,
            nativeSpeciesId: speciesId,
            nativeFormId: species.forms.formId,
            catalog: nativeCatalog,
            catalogHash: catalogHash,
            evidence: {
              'sourceSpeciesBinding': identity,
              'nativeDefaultMoveIds': moves,
              'sourceFiles': [
                for (final file in source.snapshot.entries)
                  if (file.relativePath == 'Data/Scripts.rxdata' ||
                      file.relativePath == 'Data/species.dat' ||
                      pbs.documents.any(
                          (document) => document.file.fileId == file.fileId) ||
                      file.relativePath ==
                          (identity['sourceLocator'] as Map)['file'] ||
                      file.relativePath ==
                          (identity['sourceBaseLocator'] as Map)['file'])
                    file.toJson()
              ],
              'gift': 'nativeReceivePokemonFromCatalogWithAveluneMoves',
              'presentationAdaptation': [
                'sourcePicturesAndCryReplacedByNativeGiftPresentation',
                'followingPokemonNotStarted',
                'rivalReceiptFanfareReplacedByNativeGiftPresentation',
                'ownBallHidesAfterSuccessfulNativeGrant',
                'nativeGiftFailureDoesNotAdvanceStarterChoice'
              ],
              'sourcePresentationParity': false,
              'sourceScriptsExecuted': 0,
            });
      } on ContractError catch (error) {
        if (error.code == 'source.cancelled' ||
            error.code.contains('quota') ||
            error.code.contains('limit') ||
            error.code.contains('changed') ||
            error.code.contains('hash')) {
          rethrow;
        }
        continue;
      }
    }
    return Map.unmodifiable(result);
  }
}

String _starterEventProof(SourceEventDefinition event) => canonicalJsonOf({
      'identity': event.identity.value,
      'sourceFileId': event.sourceFileId.value,
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'condition': page.condition.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'locator': page.locator.toJson(),
            'trigger': page.triggerCode,
            'graphic': page.graphic == null
                ? null
                : {
                    'character': page.graphic!.characterName,
                    'tile': page.graphic!.tileId,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'hue': page.graphic!.hue,
                    'opacity': page.graphic!.opacity,
                    'blend': page.graphic!.blendType,
                    'moveType': page.graphic!.moveType,
                    'moveSpeed': page.graphic!.moveSpeed,
                    'moveFrequency': page.graphic!.moveFrequency,
                    'walkAnime': page.graphic!.walkAnime,
                    'stepAnime': page.graphic!.stepAnime,
                    'directionFix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'alwaysOnTop': page.graphic!.alwaysOnTop,
                    'route': page.graphic!.moveRouteNodeId,
                  }
          }
      ],
    });

bool sourceStarterActorIsBound(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event}) {
  final expected =
      SourceEventAnalyzer.forProject(source, profile: analysis.profile)
          .analyzeEventAt(event.sourceMapId, event.sourceEventId);
  return expected != null &&
      _starterEventProof(expected) == _starterEventProof(event);
}
