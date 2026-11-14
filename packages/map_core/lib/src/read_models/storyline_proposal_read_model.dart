import '../authoring/storyline_milestone_operations.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';

final class StorylineProposal {
  StorylineProposal({
    required this.storyline,
    required this.unlockCount,
    required List<String> scenesOutsideStoryline,
  }) : scenesOutsideStoryline = List.unmodifiable(scenesOutsideStoryline);

  final StorylineAsset? storyline;
  final int unlockCount;
  final List<String> scenesOutsideStoryline;

  int get milestoneCount => storyline == null
      ? 0
      : storyline!.chapters.fold(0, (total, c) => total + c.steps.length);
}

StorylineProposal proposeStoryline(
  ProjectManifest project, {
  String storylineId = 'proposed_main',
}) {
  final excluded = {
    for (final storyline in project.storylines)
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps)
          ?storylineMilestoneCompletionFactId(step),
  };
  final facts = {
    for (final fact in project.facts)
      if (fact.valueKind == NarrativeValueKind.boolean &&
          !excluded.contains(fact.id))
        fact.id: fact,
  };
  final rank = {for (final (i, id) in facts.keys.indexed) id: i};
  final writers = <String, List<String>>{};
  for (final scene in project.scenes) {
    for (final factId in _factsSetTrue(scene)) {
      if (facts.containsKey(factId)) {
        final list = writers.putIfAbsent(factId, () => []);
        if (!list.contains(scene.id)) list.add(scene.id);
      }
    }
  }
  final reads = <String, Set<String>>{};
  for (final record in project.eventRegistry?.records ?? const []) {
    final definition = record.definitionOrNull;
    if (definition == null) continue;
    reads
        .putIfAbsent(definition.sceneId, () => {})
        .addAll(_factsReadTrue(definition.toJson()));
  }
  final unlocks = <String, Set<String>>{};
  for (final MapEntry(key: factId, value: scenes) in writers.entries) {
    for (final scene in scenes) {
      for (final prerequisite in reads[scene] ?? const <String>{}) {
        if (prerequisite != factId && writers.containsKey(prerequisite)) {
          unlocks.putIfAbsent(prerequisite, () => {}).add(factId);
        }
      }
    }
  }
  final order = _ordered(writers.keys, unlocks, rank);
  final assigned = <String>{};
  final chapters = <String, List<StorylineStep>>{};
  for (final factId in order) {
    final scenes = [
      for (final scene in writers[factId]!)
        if (assigned.add(scene)) scene,
    ];
    if (scenes.isEmpty) continue;
    final fact = facts[factId]!;
    final steps = chapters.putIfAbsent(fact.category, () => []);
    steps.add(
      StorylineStep(
        id: 'proposed_$factId',
        title: fact.label,
        order: steps.length,
        sceneLinkIds: scenes,
        completionCondition: ScriptConditionFactory.factEquals(
          factId,
          const NarrativeValue.boolean(true),
        ),
      ),
    );
  }
  final outside = [
    for (final scene in project.scenes)
      if (!assigned.contains(scene.id)) scene.id,
  ];
  final unlockCount = unlocks.values.fold<int>(
    0,
    (total, targets) => total + targets.length,
  );
  if (chapters.isEmpty) {
    return StorylineProposal(
      storyline: null,
      unlockCount: unlockCount,
      scenesOutsideStoryline: outside,
    );
  }
  return StorylineProposal(
    storyline: StorylineAsset(
      id: storylineId,
      type: StorylineType.main,
      title: project.name,
      chapters: [
        for (final (index, MapEntry(key: category, value: steps))
            in chapters.entries.indexed)
          StorylineChapter(
            id: 'proposed_chapter_$index',
            title: category.isEmpty ? steps.first.title : category,
            order: index,
            steps: steps,
          ),
      ],
    ),
    unlockCount: unlockCount,
    scenesOutsideStoryline: outside,
  );
}

Iterable<String> _factsSetTrue(SceneAsset scene) sync* {
  for (final node in scene.graph.nodes) {
    if (node.payload
        case SceneActionPayload(
          consequence: SceneSetFactConsequence(
            :final factId,
            :final narrativeValue,
          ),
        )
        when narrativeValue.kind == NarrativeValueKind.boolean &&
            narrativeValue.boolValue) {
      yield factId;
    }
  }
}

Set<String> _factsReadTrue(Object? json) {
  final result = <String>{};
  void visit(Object? value) {
    if (value is Map) {
      if (value['kind'] == 'fact' &&
          value['factId'] is String &&
          value['expectedValue'] == true) {
        result.add(value['factId'] as String);
      }
      value.values.forEach(visit);
    } else if (value is List) {
      value.forEach(visit);
    }
  }

  visit(json);
  return result;
}

List<String> _ordered(
  Iterable<String> nodes,
  Map<String, Set<String>> edges,
  Map<String, int> rank,
) {
  final incoming = {for (final node in nodes) node: 0};
  for (final targets in edges.values) {
    for (final target in targets) {
      incoming[target] = incoming[target]! + 1;
    }
  }
  final ready = [
    for (final node in nodes)
      if (incoming[node] == 0) node,
  ];
  final result = <String>[];
  while (ready.isNotEmpty) {
    ready.sort((a, b) => rank[a]!.compareTo(rank[b]!));
    final node = ready.removeAt(0);
    result.add(node);
    for (final target in edges[node] ?? const <String>{}) {
      incoming[target] = incoming[target]! - 1;
      if (incoming[target] == 0) ready.add(target);
    }
  }
  final placed = result.toSet();
  return [
    ...result,
    ...nodes.where((node) => !placed.contains(node)).toList()
      ..sort((a, b) => rank[a]!.compareTo(rank[b]!)),
  ];
}
