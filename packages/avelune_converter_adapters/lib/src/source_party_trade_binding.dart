import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_psdk_trainer_bundle.dart';
import 'source_character_presentation_binding.dart';

final class SourcePartyTradeBinding {
  SourcePartyTradeBinding._({
    required this.program,
    required this.sourceMapId,
    required this.sourceEventId,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.nativeEvolutionRulesHash,
    required this.evidence,
    required this.visualAdaptation,
  });

  final SourcePartyTradeProgramNode program;
  final int sourceMapId, sourceEventId;
  final SourceCharacterPresentationBinding? visualAdaptation;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final Sha256Hash nativeEvolutionRulesHash;
  final Map<String, Object?> evidence;

  bool isBoundToEvent({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event,
  }) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        !analysis.profile.isQualified ||
        event.isQuarantined ||
        event.sourceMapId != sourceMapId ||
        event.sourceEventId != sourceEventId ||
        event.identity != source.eventIdentity(sourceMapId, sourceEventId) ||
        event.pages.length != 1) {
      return false;
    }
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyze()
            .eventAt(sourceMapId, sourceEventId);
    if (expected == null ||
        expected.isQuarantined ||
        expected.pages.length != 1 ||
        expected.sourceFileId != event.sourceFileId ||
        expected.x != event.x ||
        expected.y != event.y ||
        expected.name != event.name ||
        canonicalJsonOf(expected.locator.toJson()) !=
            canonicalJsonOf(event.locator.toJson())) {
      return false;
    }
    final page = event.pages.single, original = expected.pages.single;
    if (page.rawDataRef == null ||
        page.graphic?.moveRouteNodeId != original.graphic?.moveRouteNodeId ||
        page.body.nodes.length != 1 ||
        page.body.nodes.single is! SourcePartyTradeProgramNode ||
        canonicalJsonOf(page.sourcePage.toJson()) !=
            canonicalJsonOf(original.sourcePage.toJson()) ||
        canonicalJsonOf(page.locator.toJson()) !=
            canonicalJsonOf(original.locator.toJson()) ||
        canonicalJsonOf(page.condition.toJson()) !=
            canonicalJsonOf(original.condition.toJson()) ||
        canonicalJsonOf(page.rawDataRef!.toJson()) !=
            canonicalJsonOf(original.rawDataRef?.toJson()) ||
        canonicalJsonOf((page.body.nodes.single as SourcePartyTradeProgramNode)
                .toJson()) !=
            canonicalJsonOf(program.toJson())) {
      return false;
    }
    final visual = visualAdaptation;
    if (visual != null &&
        !source.snapshot.entries.any((entry) =>
            entry.fileId == visual.actualSourceFile.fileId &&
            canonicalJsonOf(entry.toJson()) ==
                canonicalJsonOf(visual.actualSourceFile.toJson()))) {
      return false;
    }
    final rawEvent = source.maps
        .singleWhere((map) => map.map.sourceMapId == sourceMapId)
        .map
        .events
        .singleWhere((event) => event.sourceEventId == sourceEventId);
    return program.isBoundToSourceEvent(
        source: source,
        profile: analysis.profile,
        sourceMapId: sourceMapId,
        event: rawEvent);
  }
}

final class SourcePartyTradeBindingResolver {
  const SourcePartyTradeBindingResolver();

  SourcePartyTradeBinding? resolve(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required int sourceMapId,
      required int sourceEventId,
      NativePsdkCatalog? nativeCatalog}) {
    if (!analysis.profile.isQualified ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      return null;
    }
    final event = analysis.eventAt(sourceMapId, sourceEventId);
    if (event == null ||
        event.isQuarantined ||
        event.pages.length != 1 ||
        event.pages.single.body.nodes.length != 1 ||
        event.pages.single.body.nodes.single is! SourcePartyTradeProgramNode) {
      return null;
    }
    final program =
        event.pages.single.body.nodes.single as SourcePartyTradeProgramNode;
    final presentation = resolveSourceCharacterPresentation(
        snapshot: source.snapshot,
        profile: source.interpretationProfile,
        charsetName: event.pages.single.graphic?.characterName ?? '');
    final visual = presentation?.substitution == null ? null : presentation;
    final native = nativeCatalog ?? NativePsdkTrainerBundle.builtin();
    final rules = <String, Object?>{};
    for (final entry in native.evolutionsBySpeciesId.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      for (final rule
          in entry.value.evolutions.where((rule) => rule.method == 'trade')) {
        rule.validated();
        if (!native.speciesById.containsKey(entry.key) ||
            !native.speciesById.containsKey(rule.targetSpeciesId)) {
          return null;
        }
      }
      rules[entry.key] = entry.value.toJson();
    }
    final rulesHash = canonicalHashOf(rules);
    final binding = SourcePartyTradeBinding._(
        program: program,
        sourceMapId: sourceMapId,
        sourceEventId: sourceEventId,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: analysis.profile.canonicalHash,
        nativeEvolutionRulesHash: rulesHash,
        visualAdaptation: visual,
        evidence: _freeze({
          'kind': 'sourcePartyTradeBinding',
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'sourceProfileHash': analysis.profile.canonicalHash.value,
          'sourceProgram': program.toJson(),
          'visualPolicy':
              visual == null ? 'strictSource' : 'declaredProfileSubstitution',
          if (visual != null) 'visualAdaptation': visual.toJson(),
          'sourceVisualParity': false,
          'nativeEvolutionRulesHash': rulesHash.value,
          'nativeEvolutionAuthority': 'aveluneNativeProjectCatalog',
          'requiresNativePokemonCatalog': true,
          'nativeSpeciesIds': native.speciesById.keys.toList()..sort(),
          'sourceTemporaryVariablesExecuted': false,
          'nativeSelection': 'stableIndividualIdentity',
          'nativeCommit': 'onceAfterConfirmation',
          'nativePartyOrder': 'preserved',
          'nativePartner': 'unchanged',
          'nativeEvolutionCandidate': 'firstIndividualOnly',
          'nativeHeldPrevention': 'prevent_evolution',
          'cancellation': 'noMutation',
          'sourceTradePresentationParityQualified': false,
          'sourceEvolutionCatalogParityQualified': false,
          'sourceScriptsExecuted': 0,
        }) as Map<String, Object?>);
    return binding.isBoundToEvent(
            source: source, analysis: analysis, event: event)
        ? binding
        : null;
  }
}

Object? _freeze(Object? value) => switch (value) {
      Map value => Map<String, Object?>.unmodifiable(
          value.map((key, value) => MapEntry(key as String, _freeze(value)))),
      List value => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
