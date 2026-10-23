import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_source_species_bindings.dart';
import 'native_project_writer.dart';
import 'source_event_sound_binding.dart';

final class SourceDecorativePokemonBinding {
  SourceDecorativePokemonBinding._(
      this.sourceHash,
      this.normalizationHash,
      this.profileHash,
      this.fingerprint,
      this.symbol,
      this.sound,
      Map<String, Object?> speciesEvidence,
      this.witnesses)
      : _speciesEvidence = canonicalJsonOf(speciesEvidence,
            limits: const ContractLimits(
                maxNodes: 2000000, maxTextCodeUnits: 33554432));

  final Sha256Hash sourceHash, normalizationHash, profileHash;
  final String fingerprint, symbol, _speciesEvidence;
  final SourceEventSoundBinding sound;
  final List<SourceFileEntry> witnesses;

  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
          SourceEventDefinition event) =>
      source.snapshot.canonicalHash == sourceHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      analysis.profile.isQualified &&
      sourceDecorativePokemonSymbol(event) == symbol &&
      _fingerprint(event) == fingerprint &&
      sound.sourceSnapshotHash == sourceHash &&
      sound.name == 'Cries/$symbol' &&
      sound.policy == SourceEventSoundPolicy.sourceEngineGain;

  Map<String, Object?> toJson() => {
        'kind': 'sourceDecorativePokemonCry',
        'sourceSnapshotHash': sourceHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceSpeciesSymbol': symbol,
        'programHash': canonicalHashOf(fingerprint).value,
        'sourceForm': 0,
        'sourceVolume': 90,
        'sourcePitch': 100,
        'sourceSpeciesBinding': jsonDecode(_speciesEvidence),
        'sound': sound.evidence,
        'sourceOracle': {
          'Pokemon': '273:99-100',
          'Species_files': '130:183-205'
        },
        'nativeContract': 'sourceCryThenSourceDialogueAndDeclaredFacing',
        'sourceSoundMissing': false,
        'sourceScriptsExecuted': 0,
      };
}

String? sourceDecorativePokemonSymbol(SourceEventDefinition event) {
  if (event.isQuarantined || event.pages.length != 1) {
    return null;
  }
  final page = event.pages.single, graphic = page.graphic;
  if (page.rawDataRef == null ||
      page.triggerCode != 0 ||
      page.condition.kind != SourceEventConditionKind.always ||
      graphic == null ||
      graphic.characterName.isEmpty ||
      graphic.tileId != 0 ||
      graphic.hue != 0 ||
      graphic.opacity != 255 ||
      graphic.blendType != 0 ||
      graphic.moveType != 0 ||
      graphic.stepAnime ||
      graphic.directionFix ||
      graphic.through ||
      graphic.alwaysOnTop ||
      RegExp(r'size\s*\(', caseSensitive: false).hasMatch(event.name)) {
    return null;
  }
  final nodes = page.body.nodes;
  if (nodes.length < 2 ||
      nodes.length > 18 ||
      nodes.first is! SourceSoundEffectNode) {
    return null;
  }
  final cry = nodes.first as SourceSoundEffectNode;
  final match =
      RegExp(r'^Cries/([A-Z][A-Za-z0-9_]{0,63})$').firstMatch(cry.name);
  if (match == null || cry.volume != 90 || cry.pitch != 100) {
    return null;
  }
  final symbol = match[1]!;
  final commands = page.sourcePage.commands;
  if (commands.first.code != 355 ||
      commands.first.indent != 0 ||
      canonicalJsonOf(commands.first.parameters) !=
          canonicalJsonOf(['Pokemon.play_cry(:$symbol)']) ||
      commands.any((command) =>
          command.indent != 0 ||
          !const {355, 101, 401, 209, 509, 0}.contains(command.code)) ||
      commands.where((command) => command.code == 355).length != 1 ||
      commands.last.code != 0 ||
      commands.last.parameters.isNotEmpty) {
    return null;
  }
  var cursor = 1;
  var textGroups = 0;
  while (cursor < commands.length && commands[cursor].code == 101) {
    textGroups++;
    cursor++;
    while (cursor < commands.length && commands[cursor].code == 401) {
      cursor++;
    }
  }
  if (textGroups < 1 || textGroups > 16) return null;
  if (nodes.last is SourceInteractionFacingNode) {
    if (cursor + 2 >= commands.length ||
        commands[cursor].code != 209 ||
        commands[cursor + 1].code != 509) {
      return null;
    }
    cursor += 2;
  }
  if (cursor != commands.length - 1) return null;
  final following = nodes.skip(1).toList();
  if (following.last is SourceInteractionFacingNode) following.removeLast();
  if (following.isEmpty ||
      following.any((node) =>
          node is! SourceTextNode ||
          node.followingChoice != null ||
          node.annotations.isNotEmpty)) {
    return null;
  }
  if (nodes.whereType<SourceInteractionFacingNode>().length > 1) {
    return null;
  }
  return symbol;
}

final class SourceDecorativePokemonBindingResolver {
  const SourceDecorativePokemonBindingResolver();

  Future<SourceDecorativePokemonBinding> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event,
      required SourceFilePort files,
      SourcePbsProject? pbs,
      NativePsdkCatalog? nativeCatalog,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    Never refuse() => throw const NativeWriteException(
        'events.decorative_pokemon.binding',
        'Decorative cries require their complete literal event, compiled species and exact source sound.');
    cancellation?.check();
    limits.validate();
    final profile = SourceEventProfile.forProject(source);
    final symbol = sourceDecorativePokemonSymbol(event);
    if (symbol == null ||
        !profile.isQualified ||
        profile.canonicalHash != analysis.profile.canonicalHash ||
        profile.scriptsArchiveHash?.value !=
            '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d') {
      refuse();
    }
    final original = SourceEventAnalyzer.forProject(source, profile: profile)
        .analyzeEventAt(event.sourceMapId, event.sourceEventId);
    if (original == null || _fingerprint(original) != _fingerprint(event)) {
      refuse();
    }
    final catalogSource = pbs ??
        await const SourcePbsParser().read(
            snapshot: source.snapshot,
            files: files,
            cancellation: cancellation);
    final species = await const NativeSourceSpeciesBindings().bind(
        snapshot: source.snapshot,
        source: catalogSource,
        files: files,
        nativeCatalog: nativeCatalog ?? NativePsdkCatalogManifest.builtin(),
        requestedSourceSymbols: [symbol],
        cancellation: cancellation);
    if (species.rows.length != 1 ||
        species.rows.single['sourceForm'] != 0 ||
        species.rows.single['sourceSymbol'] != symbol ||
        species.rows.single['sourceBaseSymbol'] != symbol) {
      refuse();
    }
    final sound = await const SourceEventSoundResolver().read(
        source: source,
        files: files,
        name: 'Cries/$symbol',
        limits: limits,
        policy: SourceEventSoundPolicy.sourceEngineGain,
        cancellation: cancellation);
    if (!const {'ogg', 'wav'}.any((extension) =>
        sound.audioFile.relativePath == 'Audio/SE/Cries/$symbol.$extension')) {
      refuse();
    }
    final witnesses = source.snapshot.entries
        .where((entry) =>
            entry.relativePath == 'Data/species.dat' ||
            entry.relativePath == 'Data/Scripts.rxdata' ||
            entry.relativePath == 'Game.exe' ||
            entry.relativePath == 'Game.ini' ||
            entry.relativePath == 'mkxp.json' ||
            catalogSource.documents
                .any((document) => document.file.fileId == entry.fileId))
        .toList();
    return SourceDecorativePokemonBinding._(
        source.snapshot.canonicalHash,
        source.canonicalHash,
        profile.canonicalHash,
        _fingerprint(event),
        symbol,
        sound,
        species.evidence,
        List.unmodifiable(witnesses));
  }
}

String _fingerprint(SourceEventDefinition event) => canonicalJsonOf({
      'identity': event.identity.value,
      'file': event.sourceFileId.value,
      'map': event.sourceMapId,
      'event': event.sourceEventId,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'raw': page.sourcePage.toJson(),
            'ref': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'locator': page.locator.toJson(),
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
                  ],
            'body': [
              for (final node in page.body.nodes)
                {
                  'span': node.span.toJson(),
                  'value': switch (node) {
                    SourceSoundEffectNode() => node.toJson(),
                    SourceTextNode() => {
                        'text': node.text,
                        'annotations': node.annotations,
                        'choice':
                            node.followingChoice == null ? null : 'refused'
                      },
                    SourceInteractionFacingNode() => {
                        'kind': 'interactionFacing',
                        'refs':
                            node.rawDataRefs.map((ref) => ref.toJson()).toList()
                      },
                    _ => 'refused',
                  }
                }
            ]
          }
      ]
    });
