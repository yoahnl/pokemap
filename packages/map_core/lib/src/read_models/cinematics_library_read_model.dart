import 'package:meta/meta.dart' show immutable;

import '../diagnostics/cinematic_diagnostics.dart';
import '../models/cinematic_asset.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import 'linked_asset_public_contracts.dart';
import 'narrative_dependency_index.dart';

enum CinematicsLibraryEntryKind {
  canonical,
  scenarioBridge,
}

enum CinematicsLibraryReferenceStatus {
  canonical,
  bridgeLegacy,
  unknown,
}

enum CinematicsLibraryDiagnosticSeverity {
  error,
  warning,
  info,
}

enum CinematicsLibraryVisibility { active, archived, all }

enum CinematicsLibrarySort {
  titleAscending,
  durationDescending,
  usageDescending,
  locationAscending,
}

@immutable
final class CinematicsLibraryQuery {
  const CinematicsLibraryQuery({
    this.searchText = '',
    this.visibility = CinematicsLibraryVisibility.active,
    this.sort = CinematicsLibrarySort.titleAscending,
    this.kind,
  });

  final String searchText;
  final CinematicsLibraryVisibility visibility;
  final CinematicsLibrarySort sort;
  final CinematicsLibraryEntryKind? kind;
}

@immutable
final class CinematicsLibraryGroup {
  CinematicsLibraryGroup({
    required this.storylineLabel,
    required this.chapterLabel,
    required this.locationLabel,
    required List<CinematicsLibraryEntry> entries,
  }) : entries = List<CinematicsLibraryEntry>.unmodifiable(entries);

  final String storylineLabel;
  final String chapterLabel;
  final String locationLabel;
  final List<CinematicsLibraryEntry> entries;
}

@immutable
final class CinematicsLibraryReadModel {
  CinematicsLibraryReadModel({
    required List<CinematicsLibraryEntry> canonicalEntries,
    required List<CinematicsLibraryEntry> bridgeEntries,
    required List<CinematicsLibraryUsage> unknownUsages,
    required this.metrics,
  })  : canonicalEntries =
            List<CinematicsLibraryEntry>.unmodifiable(canonicalEntries),
        bridgeEntries = List<CinematicsLibraryEntry>.unmodifiable(
          bridgeEntries,
        ),
        unknownUsages = List<CinematicsLibraryUsage>.unmodifiable(
          unknownUsages,
        );

  final List<CinematicsLibraryEntry> canonicalEntries;
  final List<CinematicsLibraryEntry> bridgeEntries;
  final List<CinematicsLibraryUsage> unknownUsages;
  final CinematicsLibraryMetrics metrics;

  List<CinematicsLibraryEntry> get allEntries => List.unmodifiable([
        ...canonicalEntries,
        ...bridgeEntries,
      ]);

  CinematicsLibraryEntry? entryById(String cinematicId) {
    final id = cinematicId.trim();
    for (final entry in allEntries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  List<CinematicsLibraryEntry> queryEntries(CinematicsLibraryQuery query) {
    final terms = query.searchText
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    final result = allEntries.where((entry) {
      if (query.kind != null && entry.kind != query.kind) return false;
      final visible = switch (query.visibility) {
        CinematicsLibraryVisibility.active => !entry.isArchived,
        CinematicsLibraryVisibility.archived => entry.isArchived,
        CinematicsLibraryVisibility.all => true,
      };
      if (!visible) return false;
      if (terms.isEmpty) return true;
      final searchable = <String>[
        entry.id,
        entry.title,
        entry.description ?? '',
        entry.mapLabel,
        entry.storylineTitle,
        entry.chapterTitle,
        ...entry.tags,
        ...entry.usages.map((usage) => usage.sceneTitle),
        ...entry.usages.expand((usage) => usage.outcomeLabels),
      ].join(' ').toLowerCase();
      return terms.every(searchable.contains);
    }).toList(growable: false);
    result.sort((left, right) {
      final byKind = left.kind.index.compareTo(right.kind.index);
      if (byKind != 0) return byKind;
      final compared = switch (query.sort) {
        CinematicsLibrarySort.titleAscending => _compareEntry(left, right),
        CinematicsLibrarySort.durationDescending =>
          (right.timeline.estimatedDurationMs ?? -1).compareTo(
            left.timeline.estimatedDurationMs ?? -1,
          ),
        CinematicsLibrarySort.usageDescending =>
          right.usages.length.compareTo(left.usages.length),
        CinematicsLibrarySort.locationAscending =>
          '${left.storylineTitle}\u0000${left.chapterTitle}\u0000${left.mapLabel}\u0000${left.title}'
              .compareTo(
            '${right.storylineTitle}\u0000${right.chapterTitle}\u0000${right.mapLabel}\u0000${right.title}',
          ),
      };
      return compared != 0 ? compared : _compareEntry(left, right);
    });
    return List<CinematicsLibraryEntry>.unmodifiable(result);
  }

  List<CinematicsLibraryGroup> groupEntries(CinematicsLibraryQuery query) {
    final grouped = <String, List<CinematicsLibraryEntry>>{};
    for (final entry in queryEntries(query)) {
      final key =
          '${entry.storylineTitle}\u0000${entry.chapterTitle}\u0000${entry.mapLabel}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return List<CinematicsLibraryGroup>.unmodifiable([
      for (final group in grouped.entries)
        CinematicsLibraryGroup(
          storylineLabel: group.value.first.storylineTitle,
          chapterLabel: group.value.first.chapterTitle,
          locationLabel: group.value.first.mapLabel,
          entries: group.value,
        ),
    ]);
  }
}

@immutable
final class CinematicsLibraryEntry {
  CinematicsLibraryEntry({
    required this.id,
    required this.title,
    this.description,
    required this.kind,
    required this.statusLabel,
    this.mapId,
    required this.mapLabel,
    this.storylineId,
    required this.storylineTitle,
    this.chapterId,
    required this.chapterTitle,
    required List<String> tags,
    required List<CinematicsLibraryActor> requiredActors,
    required this.timeline,
    this.notes,
    this.sourceScenarioId,
    required List<CinematicsLibraryDiagnosticView> diagnostics,
    required List<CinematicsLibraryUsage> usages,
    required this.isEditable,
    required this.isRemovable,
    required this.isArchived,
  })  : tags = List<String>.unmodifiable(tags),
        requiredActors =
            List<CinematicsLibraryActor>.unmodifiable(requiredActors),
        diagnostics =
            List<CinematicsLibraryDiagnosticView>.unmodifiable(diagnostics),
        usages = List<CinematicsLibraryUsage>.unmodifiable(usages);

  final String id;
  final String title;
  final String? description;
  final CinematicsLibraryEntryKind kind;
  final String statusLabel;
  final String? mapId;
  final String mapLabel;
  final String? storylineId;
  final String storylineTitle;
  final String? chapterId;
  final String chapterTitle;
  final List<String> tags;
  final List<CinematicsLibraryActor> requiredActors;
  final CinematicTimelineSummary timeline;
  final String? notes;
  final String? sourceScenarioId;
  final List<CinematicsLibraryDiagnosticView> diagnostics;
  final List<CinematicsLibraryUsage> usages;
  final bool isEditable;
  final bool isRemovable;
  final bool isArchived;

  bool get hasDiagnostics => diagnostics.isNotEmpty;
  bool get isReferenced => usages.isNotEmpty;
}

@immutable
final class CinematicsLibraryActor {
  const CinematicsLibraryActor({
    required this.actorId,
    this.label,
    this.entityId,
    this.role,
  });

  final String actorId;
  final String? label;
  final String? entityId;
  final String? role;

  String get displayLabel => label ?? actorId;
}

@immutable
final class CinematicTimelineSummary {
  CinematicTimelineSummary({
    required this.stepCount,
    required this.estimatedDurationMs,
    required List<String> stepKindLabels,
    required List<String> actorIds,
    required List<String> previewLabels,
  })  : stepKindLabels = List<String>.unmodifiable(stepKindLabels),
        actorIds = List<String>.unmodifiable(actorIds),
        previewLabels = List<String>.unmodifiable(previewLabels);

  final int stepCount;
  final int? estimatedDurationMs;
  final List<String> stepKindLabels;
  final List<String> actorIds;
  final List<String> previewLabels;

  bool get isEmpty => stepCount == 0;
}

@immutable
final class CinematicsLibraryUsage {
  CinematicsLibraryUsage({
    required this.cinematicId,
    required this.sceneId,
    required this.sceneTitle,
    required this.nodeId,
    required this.nodeTitle,
    required this.referenceStatus,
    this.referenceResolution = NarrativeDependencyResolution.resolved,
    List<String> outcomeLabels = const <String>[],
  }) : outcomeLabels = List<String>.unmodifiable(outcomeLabels);

  final String cinematicId;
  final String sceneId;
  final String sceneTitle;
  final String nodeId;
  final String nodeTitle;
  final CinematicsLibraryReferenceStatus referenceStatus;
  final NarrativeDependencyResolution referenceResolution;
  final List<String> outcomeLabels;
}

@immutable
final class CinematicsLibraryDiagnosticView {
  const CinematicsLibraryDiagnosticView({
    required this.code,
    required this.severity,
    required this.message,
    this.sourceId,
  });

  final String code;
  final CinematicsLibraryDiagnosticSeverity severity;
  final String message;
  final String? sourceId;
}

@immutable
final class CinematicsLibraryMetrics {
  const CinematicsLibraryMetrics({
    required this.canonicalCount,
    required this.bridgeCount,
    required this.diagnosticCount,
    required this.referencedCount,
    required this.emptyTimelineCount,
    required this.unknownReferenceCount,
  });

  final int canonicalCount;
  final int bridgeCount;
  final int diagnosticCount;
  final int referencedCount;
  final int emptyTimelineCount;
  final int unknownReferenceCount;
}

CinematicsLibraryReadModel buildCinematicsLibraryReadModel(
  ProjectManifest project, {
  NarrativeDependencyIndex? dependencyIndex,
}) {
  final contracts = buildCinematicPublicContracts(project);
  final bridgeContracts = {
    for (final contract in contracts)
      if (contract.sourceKind ==
          CinematicPublicContractSourceKind.scenarioBridge)
        contract.id: contract,
  };
  final canonicalIds =
      project.cinematics.map((cinematic) => cinematic.id).toSet();
  final bridgeIds = bridgeContracts.keys.toSet();
  final usagesByCinematicId = _collectSceneUsages(
    project.scenes,
    canonicalIds: canonicalIds,
    bridgeIds: bridgeIds,
    dependencyIndex: dependencyIndex,
  );
  final diagnosticsByCinematicId = _groupCinematicDiagnostics(
    diagnoseCinematicsAgainstProject(project).diagnostics,
  );
  final mapLabels = {for (final map in project.maps) map.id: map.name};
  final storylineLabels = {
    for (final storyline in project.storylines) storyline.id: storyline.title,
  };
  final chapterLabels = {
    for (final storyline in project.storylines)
      for (final chapter in storyline.chapters)
        '${storyline.id}\u0000${chapter.id}': chapter.title,
  };

  final canonicalEntries = [
    for (final cinematic in project.cinematics)
      CinematicsLibraryEntry(
        id: cinematic.id,
        title: cinematic.title,
        description: cinematic.description,
        kind: CinematicsLibraryEntryKind.canonical,
        statusLabel: 'CinematicAsset canonique',
        mapId: cinematic.mapId,
        mapLabel: cinematic.mapId == null
            ? 'Sans lieu'
            : mapLabels[cinematic.mapId] ?? 'Map manquante',
        storylineId: cinematic.storylineId,
        storylineTitle: cinematic.storylineId == null
            ? 'Sans storyline'
            : storylineLabels[cinematic.storylineId] ?? 'Storyline manquante',
        chapterId: cinematic.chapterId,
        chapterTitle: cinematic.chapterId == null
            ? 'Sans chapitre'
            : chapterLabels[
                    '${cinematic.storylineId}\u0000${cinematic.chapterId}'] ??
                'Chapitre manquant',
        tags: cinematic.tags,
        requiredActors: [
          for (final actor in cinematic.requiredActors)
            CinematicsLibraryActor(
              actorId: actor.actorId,
              label: actor.label,
              entityId: actor.entityId,
              role: actor.role,
            ),
        ],
        timeline: _summarizeTimeline(cinematic.timeline),
        notes: cinematic.notes,
        diagnostics: diagnosticsByCinematicId[cinematic.id] ?? const [],
        usages: usagesByCinematicId[cinematic.id] ?? const [],
        isEditable: true,
        isRemovable: (usagesByCinematicId[cinematic.id] ?? const []).isEmpty,
        isArchived: isCinematicArchived(cinematic),
      ),
  ]..sort(_compareEntry);

  final bridgeEntries = [
    for (final contract in bridgeContracts.values)
      CinematicsLibraryEntry(
        id: contract.id,
        title: contract.label,
        kind: CinematicsLibraryEntryKind.scenarioBridge,
        statusLabel: 'Bridge legacy Scenario/Cutscene',
        mapId: contract.mapId,
        mapLabel: contract.mapId == null
            ? 'Sans lieu'
            : mapLabels[contract.mapId] ?? 'Map manquante',
        storylineTitle: 'Legacy',
        chapterTitle: 'Bridge',
        tags: const [],
        requiredActors: const [],
        timeline: CinematicTimelineSummary(
          stepCount: 0,
          estimatedDurationMs: null,
          stepKindLabels: const [],
          actorIds: const [],
          previewLabels: const [],
        ),
        sourceScenarioId: contract.id,
        diagnostics: [
          for (final diagnostic in contract.diagnostics)
            _fromContractDiagnostic(diagnostic),
        ],
        usages: usagesByCinematicId[contract.id] ?? const [],
        isEditable: false,
        isRemovable: false,
        isArchived: false,
      ),
  ]..sort(_compareEntry);

  final unknownUsages = [
    for (final usages in usagesByCinematicId.values)
      for (final usage in usages)
        if (usage.referenceStatus == CinematicsLibraryReferenceStatus.unknown)
          usage,
  ]..sort(_compareUsage);

  return CinematicsLibraryReadModel(
    canonicalEntries: canonicalEntries,
    bridgeEntries: bridgeEntries,
    unknownUsages: unknownUsages,
    metrics: CinematicsLibraryMetrics(
      canonicalCount: canonicalEntries.length,
      bridgeCount: bridgeEntries.length,
      diagnosticCount: [
        for (final entry in [...canonicalEntries, ...bridgeEntries])
          ...entry.diagnostics,
      ].length,
      referencedCount: [
        for (final entry in [...canonicalEntries, ...bridgeEntries])
          if (entry.usages.isNotEmpty) entry.id,
      ].length,
      emptyTimelineCount:
          canonicalEntries.where((entry) => entry.timeline.isEmpty).length,
      unknownReferenceCount: unknownUsages.length,
    ),
  );
}

Map<String, List<CinematicsLibraryDiagnosticView>> _groupCinematicDiagnostics(
  List<CinematicDiagnostic> diagnostics,
) {
  final grouped = <String, List<CinematicsLibraryDiagnosticView>>{};
  for (final diagnostic in diagnostics) {
    grouped
        .putIfAbsent(diagnostic.cinematicId, () => [])
        .add(_fromCinematicDiagnostic(diagnostic));
  }
  return {
    for (final entry in grouped.entries)
      entry.key: List<CinematicsLibraryDiagnosticView>.unmodifiable(
        entry.value,
      ),
  };
}

Map<String, List<CinematicsLibraryUsage>> _collectSceneUsages(
  List<SceneAsset> scenes, {
  required Set<String> canonicalIds,
  required Set<String> bridgeIds,
  NarrativeDependencyIndex? dependencyIndex,
}) {
  final usages = <String, List<CinematicsLibraryUsage>>{};
  for (final scene in scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneCinematicPayload) {
        continue;
      }
      final cinematicId = payload.cinematicId;
      final referenceStatus = _referenceStatusFor(
        cinematicId,
        canonicalIds: canonicalIds,
        bridgeIds: bridgeIds,
      );
      final indexedUsages = dependencyIndex?.usagesFor(
        NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          cinematicId,
        ),
      );
      final indexedSceneUsage = indexedUsages
          ?.where(
            (usage) => usage.owner == NarrativeDependencyKey.scene(scene.id),
          )
          .firstOrNull;
      final usage = CinematicsLibraryUsage(
        cinematicId: cinematicId,
        sceneId: scene.id,
        sceneTitle: scene.name,
        nodeId: node.id,
        nodeTitle: node.title ?? node.id,
        referenceStatus: referenceStatus,
        outcomeLabels: [
          for (final edge in scene.graph.edges)
            if (edge.fromNodeId == node.id) edge.label ?? edge.fromPortId,
        ],
        referenceResolution: referenceStatus ==
                CinematicsLibraryReferenceStatus.bridgeLegacy
            ? NarrativeDependencyResolution.legacyExternal
            : indexedSceneUsage?.resolution ??
                (referenceStatus == CinematicsLibraryReferenceStatus.canonical
                    ? NarrativeDependencyResolution.resolved
                    : NarrativeDependencyResolution.missing),
      );
      usages.putIfAbsent(cinematicId, () => []).add(usage);
    }
  }
  return {
    for (final entry in usages.entries)
      entry.key: List<CinematicsLibraryUsage>.unmodifiable(
        entry.value..sort(_compareUsage),
      ),
  };
}

CinematicsLibraryReferenceStatus _referenceStatusFor(
  String cinematicId, {
  required Set<String> canonicalIds,
  required Set<String> bridgeIds,
}) {
  if (canonicalIds.contains(cinematicId)) {
    return CinematicsLibraryReferenceStatus.canonical;
  }
  if (bridgeIds.contains(cinematicId)) {
    return CinematicsLibraryReferenceStatus.bridgeLegacy;
  }
  return CinematicsLibraryReferenceStatus.unknown;
}

CinematicTimelineSummary _summarizeTimeline(CinematicTimeline timeline) {
  final kinds = <String>{};
  final actors = <String>{};
  final previewLabels = <String>[];
  var duration = 0;
  var hasDuration = false;

  for (final step in timeline.steps) {
    kinds.add(step.kind.name);
    final actorId = step.actorId;
    if (actorId != null) {
      actors.add(actorId);
    }
    if (previewLabels.length < 4) {
      previewLabels.add(step.label ?? step.id);
    }
    final durationMs = step.durationMs;
    if (durationMs != null && durationMs > 0) {
      duration += durationMs;
      hasDuration = true;
    }
  }

  return CinematicTimelineSummary(
    stepCount: timeline.steps.length,
    estimatedDurationMs: hasDuration ? duration : null,
    stepKindLabels: (kinds.toList()..sort()),
    actorIds: (actors.toList()..sort()),
    previewLabels: previewLabels,
  );
}

CinematicsLibraryDiagnosticView _fromCinematicDiagnostic(
  CinematicDiagnostic diagnostic,
) {
  return CinematicsLibraryDiagnosticView(
    code: diagnostic.code.name,
    severity: switch (diagnostic.severity) {
      CinematicDiagnosticSeverity.error =>
        CinematicsLibraryDiagnosticSeverity.error,
      CinematicDiagnosticSeverity.warning =>
        CinematicsLibraryDiagnosticSeverity.warning,
      CinematicDiagnosticSeverity.info =>
        CinematicsLibraryDiagnosticSeverity.info,
    },
    message: diagnostic.message,
    sourceId: diagnostic.referenceId ?? diagnostic.stepId,
  );
}

CinematicsLibraryDiagnosticView _fromContractDiagnostic(
  LinkedAssetContractDiagnostic diagnostic,
) {
  return CinematicsLibraryDiagnosticView(
    code: diagnostic.code.name,
    severity: switch (diagnostic.severity) {
      LinkedAssetContractDiagnosticSeverity.error =>
        CinematicsLibraryDiagnosticSeverity.error,
      LinkedAssetContractDiagnosticSeverity.warning =>
        CinematicsLibraryDiagnosticSeverity.warning,
      LinkedAssetContractDiagnosticSeverity.info =>
        CinematicsLibraryDiagnosticSeverity.info,
    },
    message: diagnostic.message,
    sourceId: diagnostic.sourceId,
  );
}

int _compareEntry(CinematicsLibraryEntry a, CinematicsLibraryEntry b) {
  final byTitle = _compareStrings(a.title, b.title);
  if (byTitle != 0) {
    return byTitle;
  }
  return _compareStrings(a.id, b.id);
}

int _compareUsage(CinematicsLibraryUsage a, CinematicsLibraryUsage b) {
  final byScene = _compareStrings(a.sceneTitle, b.sceneTitle);
  if (byScene != 0) {
    return byScene;
  }
  return _compareStrings(a.nodeTitle, b.nodeTitle);
}

int _compareStrings(String a, String b) {
  final lowerA = a.toLowerCase();
  final lowerB = b.toLowerCase();
  final byLower = lowerA.compareTo(lowerB);
  if (byLower != 0) {
    return byLower;
  }
  return a.compareTo(b);
}
