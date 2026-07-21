import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../operations/narrative_project_validator.dart';
import 'narrative_dependency_index.dart';

/// Product-facing families searchable from every Narrative Studio workspace.
enum NarrativeGlobalSearchKind {
  map,
  storyline,
  chapter,
  step,
  scene,
  event,
  cinematic,
  dialogue,
  fact,
  worldRule,
  media,
  diagnostic,
}

@immutable
final class NarrativeGlobalSearchEntry {
  const NarrativeGlobalSearchEntry({
    required this.kind,
    required this.technicalId,
    required this.label,
    this.description,
    this.tags = const [],
    this.keywords = const [],
    this.consumerLabels = const [],
    this.mapId,
    this.storylineId,
    this.parentId,
    this.rootId,
    this.navigationIntent,
    this.diagnostic,
  });

  final NarrativeGlobalSearchKind kind;
  final String technicalId;
  final String label;
  final String? description;
  final List<String> tags;
  final List<String> keywords;
  final List<String> consumerLabels;
  final String? mapId;
  final String? storylineId;
  final String? parentId;
  final String? rootId;
  final NarrativeDependencyNavigationIntent? navigationIntent;
  final NarrativeProjectDiagnostic? diagnostic;

  String get stableKey => '${kind.name}:$technicalId';
}

@immutable
final class NarrativeGlobalSearchFilter {
  NarrativeGlobalSearchFilter({
    Set<NarrativeGlobalSearchKind> kinds = const {},
    this.mapId,
    this.storylineId,
  }) : kinds = Set.unmodifiable(kinds);

  final Set<NarrativeGlobalSearchKind> kinds;
  final String? mapId;
  final String? storylineId;

  bool accepts(NarrativeGlobalSearchEntry entry) {
    if (kinds.isNotEmpty && !kinds.contains(entry.kind)) return false;
    if (mapId != null && entry.mapId != mapId) return false;
    if (storylineId != null && entry.storylineId != storylineId) return false;
    return true;
  }
}

@immutable
final class NarrativeGlobalSearchQuery {
  const NarrativeGlobalSearchQuery({
    required this.text,
    this.filter,
    this.limit = 50,
    this.requestRevision = 0,
  }) : assert(limit > 0);

  final String text;
  final NarrativeGlobalSearchFilter? filter;
  final int limit;

  /// Caller-owned generation used to discard a response after a newer query.
  final int requestRevision;
}

@immutable
final class NarrativeGlobalSearchResult {
  const NarrativeGlobalSearchResult({
    required this.entry,
    required this.score,
  });

  final NarrativeGlobalSearchEntry entry;
  final int score;
}

@immutable
final class NarrativeGlobalSearchResponse {
  NarrativeGlobalSearchResponse({
    required this.indexRevision,
    required this.requestRevision,
    required List<NarrativeGlobalSearchResult> results,
  }) : results = List.unmodifiable(results);

  final int indexRevision;
  final int requestRevision;
  final List<NarrativeGlobalSearchResult> results;

  bool isStaleComparedTo(NarrativeGlobalSearchIndex currentIndex) =>
      indexRevision != currentIndex.revision;
}

/// Immutable, allocation-bounded fuzzy index for project-wide navigation.
///
/// Search never reaches repositories or mutates project data. A caller can
/// safely replace the whole index after a save and reject old responses with
/// [NarrativeGlobalSearchResponse.isStaleComparedTo].
final class NarrativeGlobalSearchIndex {
  NarrativeGlobalSearchIndex.fromEntries({
    required this.revision,
    required Iterable<NarrativeGlobalSearchEntry> entries,
  }) : entries = List.unmodifiable(entries) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'Must be non-negative.');
    }
  }

  final int revision;
  final List<NarrativeGlobalSearchEntry> entries;

  NarrativeGlobalSearchResponse search(NarrativeGlobalSearchQuery query) {
    final normalizedQuery = _normalize(query.text);
    final tokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final results = <NarrativeGlobalSearchResult>[];
    for (final entry in entries) {
      if (query.filter?.accepts(entry) == false) continue;
      final score = _scoreEntry(entry, normalizedQuery, tokens);
      if (score == null) continue;
      results.add(NarrativeGlobalSearchResult(entry: entry, score: score));
    }
    results.sort(_compareResults);
    return NarrativeGlobalSearchResponse(
      indexRevision: revision,
      requestRevision: query.requestRevision,
      results: results.take(query.limit).toList(growable: false),
    );
  }
}

NarrativeGlobalSearchIndex buildNarrativeGlobalSearchIndex({
  required ProjectManifest project,
  NarrativeDependencyIndex? dependencyIndex,
  Iterable<NarrativeProjectDiagnostic> diagnostics = const [],
  int revision = 0,
}) {
  final dependency = dependencyIndex ?? NarrativeDependencyIndex();
  final definitionLabels = <NarrativeDependencyKey, String>{
    for (final definition in dependency.definitions)
      definition.key: definition.label,
  };
  final entries = <NarrativeGlobalSearchEntry>[];

  List<String> consumersFor(NarrativeDependencyKey key) {
    final labels = <String>{};
    for (final usage in dependency.usagesFor(key)) {
      labels.add(definitionLabels[usage.owner] ?? usage.owner.id);
    }
    final sorted = labels.toList()..sort(_compareNormalizedStrings);
    return List.unmodifiable(sorted);
  }

  void add({
    required NarrativeGlobalSearchKind kind,
    required String id,
    required String label,
    String? description,
    Iterable<String> tags = const [],
    Iterable<String> keywords = const [],
    String? mapId,
    String? storylineId,
    String? parentId,
    String? rootId,
    NarrativeDependencyKey? dependencyKey,
    NarrativeDependencyNavigationIntent? navigationIntent,
    NarrativeProjectDiagnostic? diagnostic,
  }) {
    final normalizedTags = _stableStrings(tags);
    final normalizedKeywords = _stableStrings(keywords);
    entries.add(
      NarrativeGlobalSearchEntry(
        kind: kind,
        technicalId: id,
        label: label,
        description: description,
        tags: normalizedTags,
        keywords: normalizedKeywords,
        consumerLabels:
            dependencyKey == null ? const [] : consumersFor(dependencyKey),
        mapId: mapId,
        storylineId: storylineId,
        parentId: parentId,
        rootId: rootId,
        navigationIntent: navigationIntent ??
            (dependencyKey == null
                ? null
                : NarrativeDependencyNavigationIntent.fromKey(
                    dependencyKey,
                    parentId: parentId,
                    rootId: rootId,
                  )),
        diagnostic: diagnostic,
      ),
    );
  }

  for (final map in project.maps) {
    final key = NarrativeDependencyKey.map(map.id);
    add(
      kind: NarrativeGlobalSearchKind.map,
      id: map.id,
      label: map.name,
      keywords: [map.relativePath, map.role.name],
      mapId: map.id,
      dependencyKey: key,
    );
  }
  for (final storyline in project.storylines) {
    final storylineKey = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.storyline,
      storyline.id,
    );
    add(
      kind: NarrativeGlobalSearchKind.storyline,
      id: storyline.id,
      label: storyline.title,
      description: storyline.description,
      keywords: [
        storyline.type.name,
        storyline.status.name,
        ...storyline.metadata.keys,
        ...storyline.metadata.values,
      ],
      storylineId: storyline.id,
      rootId: storyline.id,
      dependencyKey: storylineKey,
    );
    for (final chapter in storyline.chapters) {
      final chapterKey = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.chapter,
        chapter.id,
        parentId: storyline.id,
      );
      add(
        kind: NarrativeGlobalSearchKind.chapter,
        id: chapter.id,
        label: chapter.title,
        description: chapter.description,
        storylineId: storyline.id,
        parentId: storyline.id,
        rootId: storyline.id,
        keywords: [storyline.title],
        dependencyKey: chapterKey,
      );
      for (final step in chapter.steps) {
        final stepKey = NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          step.id,
          parentId: chapter.id,
        );
        add(
          kind: NarrativeGlobalSearchKind.step,
          id: step.id,
          label: step.title,
          description: step.description,
          storylineId: storyline.id,
          parentId: chapter.id,
          rootId: storyline.id,
          keywords: [storyline.title, chapter.title],
          dependencyKey: stepKey,
        );
      }
    }
  }
  for (final scene in project.scenes) {
    final key = NarrativeDependencyKey.scene(scene.id);
    add(
      kind: NarrativeGlobalSearchKind.scene,
      id: scene.id,
      label: scene.name,
      description: scene.description,
      tags: scene.tags,
      storylineId: scene.storylineId,
      parentId: scene.chapterId,
      rootId: scene.storylineId,
      dependencyKey: key,
    );
  }
  for (final record in project.eventRegistry?.records ?? const []) {
    final draft = record.draftOrNull;
    final definition = record.definitionOrNull;
    final id = record.id;
    final source = definition?.source ?? draft?.source;
    final mapId = _eventSourceMapId(source);
    final key = NarrativeDependencyKey.eventV2(id);
    add(
      kind: NarrativeGlobalSearchKind.event,
      id: id,
      label: definition?.name ?? draft?.name ?? id,
      keywords: [
        if (source != null) _eventSourceKindKeyword(source.kind),
        if (record.enabledOrNull != null)
          record.enabledOrNull! ? 'active' : 'inactive',
      ],
      mapId: mapId,
      parentId: mapId,
      dependencyKey: key,
    );
  }
  for (final cinematic in project.cinematics) {
    final key = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.cinematic,
      cinematic.id,
    );
    add(
      kind: NarrativeGlobalSearchKind.cinematic,
      id: cinematic.id,
      label: cinematic.title,
      description: cinematic.description,
      tags: cinematic.tags,
      mapId: cinematic.mapId,
      storylineId: cinematic.storylineId,
      parentId: cinematic.chapterId,
      rootId: cinematic.storylineId,
      dependencyKey: key,
    );
  }
  for (final dialogue in project.dialogues) {
    final key = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.dialogue,
      dialogue.id,
    );
    add(
      kind: NarrativeGlobalSearchKind.dialogue,
      id: dialogue.id,
      label: dialogue.name,
      description: dialogue.description,
      tags: dialogue.tags,
      keywords: [dialogue.relativePath],
      parentId: dialogue.folderId,
      dependencyKey: key,
    );
  }
  for (final fact in project.facts) {
    final key = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.fact,
      fact.id,
    );
    add(
      kind: NarrativeGlobalSearchKind.fact,
      id: fact.id,
      label: fact.label,
      description: fact.description,
      tags: fact.tags,
      keywords: [fact.category, fact.valueKind.name],
      dependencyKey: key,
    );
  }
  for (final rule in project.worldRules) {
    final key = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.worldRule,
      rule.id,
    );
    add(
      kind: NarrativeGlobalSearchKind.worldRule,
      id: rule.id,
      label: rule.label,
      description: rule.description,
      tags: rule.tags,
      keywords: [
        if (rule.debugTechnicalLabel != null) rule.debugTechnicalLabel!
      ],
      dependencyKey: key,
    );
  }
  for (final media in project.cinematicMediaAssets) {
    final key = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.media,
      media.id,
    );
    add(
      kind: NarrativeGlobalSearchKind.media,
      id: media.id,
      label: media.label,
      keywords: [
        media.kind.name,
        media.relativePath,
        if (media.channel != null) media.channel!,
        ...media.metadata.keys,
        ...media.metadata.values,
      ],
      dependencyKey: key,
    );
  }
  for (final diagnostic in diagnostics) {
    final target = _diagnosticTarget(diagnostic);
    add(
      kind: NarrativeGlobalSearchKind.diagnostic,
      id: diagnostic.stableKey,
      label: diagnostic.message,
      description: diagnostic.suggestedFixLabel,
      tags: [diagnostic.severity.name, diagnostic.domain.name],
      keywords: [diagnostic.code, diagnostic.path],
      mapId: diagnostic.mapId,
      storylineId: diagnostic.storylineId,
      parentId: diagnostic.chapterId,
      rootId: diagnostic.storylineId,
      navigationIntent: target,
      diagnostic: diagnostic,
    );
  }

  entries.sort((a, b) {
    final kind = a.kind.index.compareTo(b.kind.index);
    if (kind != 0) return kind;
    final label = _compareNormalizedStrings(a.label, b.label);
    if (label != 0) return label;
    return a.technicalId.compareTo(b.technicalId);
  });
  return NarrativeGlobalSearchIndex.fromEntries(
    revision: revision,
    entries: entries,
  );
}

String _eventSourceKindKeyword(NarrativeEventSourceKind kind) => switch (kind) {
      NarrativeEventSourceKind.mapEnter => 'mapEnter',
      NarrativeEventSourceKind.triggerEnter => 'triggerEnter',
      NarrativeEventSourceKind.entityInteract => 'entityInteract',
      NarrativeEventSourceKind.outcomeReceived => 'outcomeReceived',
    };

NarrativeDependencyNavigationIntent? _diagnosticTarget(
  NarrativeProjectDiagnostic diagnostic,
) {
  NarrativeDependencyTargetKind? kind;
  String? id;
  switch (diagnostic.destination) {
    case NarrativeProjectDiagnosticDestination.map:
      kind = NarrativeDependencyTargetKind.sourceMap;
      id = diagnostic.mapId;
      break;
    case NarrativeProjectDiagnosticDestination.event:
      kind = NarrativeDependencyTargetKind.eventV2;
      id = diagnostic.eventId;
      break;
    case NarrativeProjectDiagnosticDestination.scene:
      kind = NarrativeDependencyTargetKind.scene;
      id = diagnostic.sceneId;
      break;
    case NarrativeProjectDiagnosticDestination.storyline:
      if (diagnostic.stepId != null) {
        kind = NarrativeDependencyTargetKind.step;
        id = diagnostic.stepId;
      } else if (diagnostic.chapterId != null) {
        kind = NarrativeDependencyTargetKind.chapter;
        id = diagnostic.chapterId;
      } else {
        kind = NarrativeDependencyTargetKind.storyline;
        id = diagnostic.storylineId;
      }
      break;
    case NarrativeProjectDiagnosticDestination.dialogue:
      kind = NarrativeDependencyTargetKind.dialogue;
      id = diagnostic.dialogueId;
      break;
    case NarrativeProjectDiagnosticDestination.cinematic:
      kind = NarrativeDependencyTargetKind.cinematic;
      id = diagnostic.cinematicId;
      break;
    case NarrativeProjectDiagnosticDestination.fact:
      kind = NarrativeDependencyTargetKind.fact;
      id = diagnostic.factId;
      break;
    case NarrativeProjectDiagnosticDestination.worldRule:
      kind = NarrativeDependencyTargetKind.worldRule;
      id = diagnostic.worldRuleId;
      break;
    case NarrativeProjectDiagnosticDestination.overview:
      return null;
  }
  if (id == null || id.trim().isEmpty) return null;
  return NarrativeDependencyNavigationIntent(
    kind: kind,
    assetId: id,
    parentId: diagnostic.chapterId,
    rootId: diagnostic.storylineId,
    mapId: diagnostic.mapId,
    context: diagnostic.path,
  );
}

String? _eventSourceMapId(NarrativeEventSourceRef? source) => source?.when(
      entityInteract: (mapId, entityId) => mapId,
      triggerEnter: (mapId, triggerId) => mapId,
      mapEnter: (mapId) => mapId,
      outcomeReceived: (outcome) => null,
    );

int? _scoreEntry(
  NarrativeGlobalSearchEntry entry,
  String query,
  List<String> tokens,
) {
  if (tokens.isEmpty) return 0;
  final label = _normalize(entry.label);
  final id = _normalize(entry.technicalId);
  final fields = <String>[
    label,
    id,
    if (entry.description != null) _normalize(entry.description!),
    ...entry.tags.map(_normalize),
    ...entry.keywords.map(_normalize),
    ...entry.consumerLabels.map(_normalize),
  ];
  var score = 0;
  for (final token in tokens) {
    var best = -1;
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      final candidate = _fieldScore(field, token, index);
      if (candidate > best) best = candidate;
    }
    if (best < 0) return null;
    score += best;
  }
  if (label == query) score += 1200;
  if (id == query) score += 1100;
  return score;
}

int _fieldScore(String field, String token, int fieldIndex) {
  if (field == token) return 1000 - fieldIndex * 3;
  if (field.startsWith(token)) return 850 - fieldIndex * 3;
  final contained = field.indexOf(token);
  if (contained >= 0) return 700 - contained - fieldIndex * 3;
  final fuzzy = _subsequenceGap(field, token);
  return fuzzy == null ? -1 : 420 - fuzzy - fieldIndex * 3;
}

int? _subsequenceGap(String value, String token) {
  var cursor = 0;
  var first = -1;
  var last = -1;
  for (var index = 0; index < value.length && cursor < token.length; index++) {
    if (value.codeUnitAt(index) != token.codeUnitAt(cursor)) continue;
    first = first < 0 ? index : first;
    last = index;
    cursor++;
  }
  if (cursor != token.length) return null;
  return (last - first + 1) - token.length + first;
}

int _compareResults(
  NarrativeGlobalSearchResult a,
  NarrativeGlobalSearchResult b,
) {
  final score = b.score.compareTo(a.score);
  if (score != 0) return score;
  final kind = a.entry.kind.index.compareTo(b.entry.kind.index);
  if (kind != 0) return kind;
  final label = _compareNormalizedStrings(a.entry.label, b.entry.label);
  if (label != 0) return label;
  return a.entry.technicalId.compareTo(b.entry.technicalId);
}

int _compareNormalizedStrings(String a, String b) {
  final normalized = _normalize(a).compareTo(_normalize(b));
  return normalized != 0 ? normalized : a.compareTo(b);
}

List<String> _stableStrings(Iterable<String> values) {
  final unique = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) unique.add(trimmed);
  }
  final result = unique.toList()..sort(_compareNormalizedStrings);
  return List.unmodifiable(result);
}

String _normalize(String value) {
  final buffer = StringBuffer();
  var separated = false;
  for (final rune in value.trim().toLowerCase().runes) {
    final replacement = _foldedRune(rune);
    if (replacement == null) {
      if (!separated) buffer.write(' ');
      separated = true;
      continue;
    }
    buffer.write(replacement);
    separated = false;
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

String? _foldedRune(int rune) {
  if ((rune >= 0x30 && rune <= 0x39) || (rune >= 0x61 && rune <= 0x7a)) {
    return String.fromCharCode(rune);
  }
  return switch (rune) {
    0x00e0 || 0x00e1 || 0x00e2 || 0x00e3 || 0x00e4 || 0x00e5 => 'a',
    0x00e7 => 'c',
    0x00e8 || 0x00e9 || 0x00ea || 0x00eb => 'e',
    0x00ec || 0x00ed || 0x00ee || 0x00ef => 'i',
    0x00f1 => 'n',
    0x00f2 || 0x00f3 || 0x00f4 || 0x00f5 || 0x00f6 => 'o',
    0x00f9 || 0x00fa || 0x00fb || 0x00fc => 'u',
    0x00fd || 0x00ff => 'y',
    0x0153 => 'oe',
    _ => null,
  };
}
