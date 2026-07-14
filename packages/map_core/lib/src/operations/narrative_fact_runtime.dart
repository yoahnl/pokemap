import 'package:meta/meta.dart' show immutable;

import '../models/game_state.dart';
import '../models/narrative_fact.dart';
import '../models/narrative_fact_runtime_state.dart';

enum NarrativeFactRuntimeValueSource {
  explicitOverride,
  legacyStoryFlag,
  defaultValue,
}

enum NarrativeFactRuntimeCatalogIssueCode {
  duplicateFactId,
  duplicateLegacyFlagName,
  legacyFlagNameConflictsWithFactId,
  duplicateRuntimeKey,
}

@immutable
final class NarrativeFactRuntimeCatalogIssue {
  NarrativeFactRuntimeCatalogIssue({
    required this.code,
    required this.runtimeKey,
    required List<String> factIds,
  }) : factIds = List<String>.unmodifiable(factIds);

  final NarrativeFactRuntimeCatalogIssueCode code;
  final String runtimeKey;
  final List<String> factIds;

  String get message =>
      '${code.name}: "$runtimeKey" is shared by ${factIds.join(', ')}.';
}

sealed class NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeResolution();
}

@immutable
final class NarrativeFactRuntimeResolved
    extends NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeResolved({
    required this.fact,
    required this.runtimeKey,
    required this.value,
    required this.source,
  });

  final NarrativeFactDefinition fact;
  final String runtimeKey;
  final bool value;
  final NarrativeFactRuntimeValueSource source;
}

@immutable
final class NarrativeFactRuntimeUnknownFact
    extends NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeUnknownFact(this.factId);

  final String factId;
}

@immutable
final class NarrativeFactRuntimeAmbiguousFact
    extends NarrativeFactRuntimeResolution {
  NarrativeFactRuntimeAmbiguousFact({
    required this.factId,
    required List<NarrativeFactRuntimeCatalogIssue> issues,
  }) : issues = List<NarrativeFactRuntimeCatalogIssue>.unmodifiable(issues);

  final String factId;
  final List<NarrativeFactRuntimeCatalogIssue> issues;
}

@immutable
final class NarrativeFactRuntimeInvalidRuntimeKey
    extends NarrativeFactRuntimeResolution {
  const NarrativeFactRuntimeInvalidRuntimeKey({
    required this.factId,
    required this.runtimeKey,
  });

  final String factId;
  final String runtimeKey;
}

@immutable
final class NarrativeFactRuntimeResolver {
  NarrativeFactRuntimeResolver._({
    required Map<String, List<NarrativeFactDefinition>> factsById,
    required List<NarrativeFactRuntimeCatalogIssue> issues,
  })  : _factsById = Map<String, List<NarrativeFactDefinition>>.unmodifiable({
          for (final entry in factsById.entries)
            entry.key: List<NarrativeFactDefinition>.unmodifiable(entry.value),
        }),
        issues = List<NarrativeFactRuntimeCatalogIssue>.unmodifiable(issues);

  factory NarrativeFactRuntimeResolver.fromFacts(
    Iterable<NarrativeFactDefinition> facts,
  ) {
    final definitions = List<NarrativeFactDefinition>.of(facts);
    final factsById = <String, List<NarrativeFactDefinition>>{};
    final factsByAlias = <String, List<NarrativeFactDefinition>>{};
    final factsByRuntimeKey = <String, List<NarrativeFactDefinition>>{};
    for (final fact in definitions) {
      factsById.putIfAbsent(fact.id, () => []).add(fact);
      final alias = fact.legacyFlagName;
      if (alias != null) {
        factsByAlias.putIfAbsent(alias, () => []).add(fact);
      }
      final runtimeKey = alias ?? fact.id;
      factsByRuntimeKey.putIfAbsent(runtimeKey, () => []).add(fact);
    }

    final issues = <NarrativeFactRuntimeCatalogIssue>[];
    _appendGroupedIssues(
      issues,
      NarrativeFactRuntimeCatalogIssueCode.duplicateFactId,
      factsById,
    );
    _appendGroupedIssues(
      issues,
      NarrativeFactRuntimeCatalogIssueCode.duplicateLegacyFlagName,
      factsByAlias,
    );

    final aliasIdConflicts = <String, List<NarrativeFactDefinition>>{};
    for (final entry in factsByAlias.entries) {
      final idOwners = factsById[entry.key];
      if (idOwners == null ||
          entry.value.every((fact) => fact.id == entry.key)) {
        continue;
      }
      aliasIdConflicts[entry.key] = <NarrativeFactDefinition>[
        ...entry.value,
        ...idOwners,
      ];
    }
    for (final entry in aliasIdConflicts.entries) {
      issues.add(
        NarrativeFactRuntimeCatalogIssue(
          code: NarrativeFactRuntimeCatalogIssueCode
              .legacyFlagNameConflictsWithFactId,
          runtimeKey: entry.key,
          factIds: _stableFactIds(entry.value),
        ),
      );
    }
    _appendGroupedIssues(
      issues,
      NarrativeFactRuntimeCatalogIssueCode.duplicateRuntimeKey,
      factsByRuntimeKey,
    );
    issues.sort(_compareCatalogIssues);

    return NarrativeFactRuntimeResolver._(
      factsById: factsById,
      issues: issues,
    );
  }

  final Map<String, List<NarrativeFactDefinition>> _factsById;
  final List<NarrativeFactRuntimeCatalogIssue> issues;

  bool get isValid => issues.isEmpty;

  NarrativeFactRuntimeResolution resolve({
    required String factId,
    required NarrativeFactRuntimeState runtimeState,
    required StoryFlags storyFlags,
  }) {
    if (factId.isEmpty || factId.trim() != factId) {
      return NarrativeFactRuntimeInvalidRuntimeKey(
        factId: factId,
        runtimeKey: factId,
      );
    }
    if (!isValid) {
      return NarrativeFactRuntimeAmbiguousFact(
        factId: factId,
        issues: issues,
      );
    }
    final matches = _factsById[factId];
    if (matches == null || matches.isEmpty) {
      return NarrativeFactRuntimeUnknownFact(factId);
    }
    if (matches.length != 1) {
      return NarrativeFactRuntimeAmbiguousFact(
        factId: factId,
        issues: issues,
      );
    }
    final fact = matches.single;
    final runtimeKey = fact.legacyFlagName ?? fact.id;
    if (runtimeKey.isEmpty || runtimeKey.trim() != runtimeKey) {
      return NarrativeFactRuntimeInvalidRuntimeKey(
        factId: factId,
        runtimeKey: runtimeKey,
      );
    }
    if (runtimeState.overridesByFactId.containsKey(fact.id)) {
      return NarrativeFactRuntimeResolved(
        fact: fact,
        runtimeKey: runtimeKey,
        value: runtimeState.overridesByFactId[fact.id]!,
        source: NarrativeFactRuntimeValueSource.explicitOverride,
      );
    }
    if (storyFlags.activeFlags.contains(runtimeKey)) {
      return NarrativeFactRuntimeResolved(
        fact: fact,
        runtimeKey: runtimeKey,
        value: true,
        source: NarrativeFactRuntimeValueSource.legacyStoryFlag,
      );
    }
    return NarrativeFactRuntimeResolved(
      fact: fact,
      runtimeKey: runtimeKey,
      value: fact.defaultValue,
      source: NarrativeFactRuntimeValueSource.defaultValue,
    );
  }
}

enum NarrativeFactRuntimeWriteErrorCode {
  unknownFact,
  ambiguousFact,
  invalidRuntimeKey,
}

sealed class NarrativeFactRuntimeWriteResult {
  const NarrativeFactRuntimeWriteResult();

  GameState get gameState;
  bool get success;
  NarrativeFactRuntimeWriteErrorCode? get errorCode;
}

@immutable
final class NarrativeFactRuntimeWriteApplied
    extends NarrativeFactRuntimeWriteResult {
  const NarrativeFactRuntimeWriteApplied({
    required this.gameState,
    required this.fact,
    required this.runtimeKey,
    required this.value,
  });

  @override
  final GameState gameState;
  final NarrativeFactDefinition fact;
  final String runtimeKey;
  final bool value;

  @override
  bool get success => true;

  @override
  NarrativeFactRuntimeWriteErrorCode? get errorCode => null;
}

@immutable
final class NarrativeFactRuntimeWriteRejected
    extends NarrativeFactRuntimeWriteResult {
  const NarrativeFactRuntimeWriteRejected({
    required this.gameState,
    required this.errorCode,
    required this.message,
  });

  @override
  final GameState gameState;
  @override
  final NarrativeFactRuntimeWriteErrorCode errorCode;
  final String message;

  @override
  bool get success => false;
}

@immutable
final class NarrativeFactRuntimeWriter {
  const NarrativeFactRuntimeWriter(this.resolver);

  final NarrativeFactRuntimeResolver resolver;

  NarrativeFactRuntimeWriteResult setFact({
    required GameState gameState,
    required String factId,
    required bool value,
  }) {
    final resolution = resolver.resolve(
      factId: factId,
      runtimeState: gameState.narrativeFactRuntimeState,
      storyFlags: gameState.storyFlags,
    );
    return switch (resolution) {
      NarrativeFactRuntimeResolved() => _apply(
          gameState,
          resolution.fact,
          resolution.runtimeKey,
          value,
        ),
      NarrativeFactRuntimeUnknownFact() => NarrativeFactRuntimeWriteRejected(
          gameState: gameState,
          errorCode: NarrativeFactRuntimeWriteErrorCode.unknownFact,
          message: 'Unknown Fact "${resolution.factId}".',
        ),
      NarrativeFactRuntimeAmbiguousFact() => NarrativeFactRuntimeWriteRejected(
          gameState: gameState,
          errorCode: NarrativeFactRuntimeWriteErrorCode.ambiguousFact,
          message: 'Ambiguous Fact catalog for "${resolution.factId}".',
        ),
      NarrativeFactRuntimeInvalidRuntimeKey() =>
        NarrativeFactRuntimeWriteRejected(
          gameState: gameState,
          errorCode: NarrativeFactRuntimeWriteErrorCode.invalidRuntimeKey,
          message: 'Invalid runtime key "${resolution.runtimeKey}".',
        ),
    };
  }

  NarrativeFactRuntimeWriteApplied _apply(
    GameState gameState,
    NarrativeFactDefinition fact,
    String runtimeKey,
    bool value,
  ) {
    final overrides = <String, bool>{
      ...gameState.narrativeFactRuntimeState.overridesByFactId,
      fact.id: value,
    };
    final runtimeFlags = <String>{...gameState.storyFlags.activeFlags};
    final progressionFlags = <String>[
      ...gameState.progression.storyFlags,
    ];
    if (value) {
      runtimeFlags.add(runtimeKey);
      if (!progressionFlags.contains(runtimeKey)) {
        progressionFlags.add(runtimeKey);
      }
    } else {
      runtimeFlags.remove(runtimeKey);
      progressionFlags.removeWhere((flag) => flag == runtimeKey);
    }
    final nextState = gameState.copyWith(
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: overrides,
      ),
      storyFlags: gameState.storyFlags.copyWith(activeFlags: runtimeFlags),
      progression: gameState.progression.copyWith(
        storyFlags: progressionFlags,
      ),
    );
    return NarrativeFactRuntimeWriteApplied(
      gameState: nextState,
      fact: fact,
      runtimeKey: runtimeKey,
      value: value,
    );
  }
}

void _appendGroupedIssues(
  List<NarrativeFactRuntimeCatalogIssue> issues,
  NarrativeFactRuntimeCatalogIssueCode code,
  Map<String, List<NarrativeFactDefinition>> groupedFacts,
) {
  for (final entry in groupedFacts.entries) {
    if (entry.value.length < 2) {
      continue;
    }
    issues.add(
      NarrativeFactRuntimeCatalogIssue(
        code: code,
        runtimeKey: entry.key,
        factIds: _stableFactIds(entry.value),
      ),
    );
  }
}

List<String> _stableFactIds(Iterable<NarrativeFactDefinition> facts) {
  final ids = facts.map((fact) => fact.id).toSet().toList(growable: false)
    ..sort();
  return ids;
}

int _compareCatalogIssues(
  NarrativeFactRuntimeCatalogIssue left,
  NarrativeFactRuntimeCatalogIssue right,
) {
  final byCode = left.code.index.compareTo(right.code.index);
  if (byCode != 0) {
    return byCode;
  }
  final byKey = left.runtimeKey.compareTo(right.runtimeKey);
  if (byKey != 0) {
    return byKey;
  }
  return left.factIds.join('\u0000').compareTo(right.factIds.join('\u0000'));
}
