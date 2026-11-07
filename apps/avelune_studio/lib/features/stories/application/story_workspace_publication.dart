part of 'story_workspace_controller.dart';

extension StoryWorkspacePublication on StoryWorkspaceController {
  Future<bool> _publishAll() async {
    if (_closed || busy || narrative.saving) return false;
    reconcile();
    if (!dirty) return true;
    final snapshot = project;
    final stories = <String, StorylineAsset?>{
      ...narrative.pendingStories,
      for (final id in narrative.pendingStoryDeletions) id: null,
    };
    final facts = Map.of(narrative.pendingFacts);
    final dependencies = buildNarrativeDependencyIndex(project: snapshot);
    final cycle = <String>[];
    final ordered = _publicationOrder(
      stories,
      dependencies,
      buildNarrativeDependencyIndex(project: narrative.project),
      cycle,
    );
    cycleStoryIds = List.unmodifiable(cycle.toSet());
    if (ordered == null) {
      String title(String id) =>
          stories[id]?.title ??
          snapshot.storylines.where((s) => s.id == id).firstOrNull?.title ??
          id;
      error = cycle.isEmpty
          ? 'Les histoires à enregistrer forment un cycle de références.'
          : 'Les histoires à enregistrer forment un cycle de références : ${cycle.map(title).join(' → ')}. Ouvrez l’une d’elles et retirez une de ces références pour enregistrer.';
      changed();
      return false;
    }
    busy = true;
    error = null;
    changed();
    var saved = 0;
    try {
      for (final fact in facts.values) {
        final receipt = await port.publishFact(
          base: _factBases[fact.id],
          current: fact,
        );
        if (_closed) return false;
        _factBases[fact.id] = fact;
        if (narrative.pendingFacts[fact.id] == fact) {
          narrative.pendingFacts.remove(fact.id);
        }
        workspace.acceptResources(receipt.before, receipt.manifest);
        saved++;
      }
      for (final id in ordered) {
        final usages = dependencies
            .usagesOwnedBy(
              NarrativeDependencyKey(
                NarrativeDependencyTargetKind.storyline,
                id,
              ),
            )
            .where(
              (u) => u.resolution == NarrativeDependencyResolution.resolved,
            );
        Set<String> targets(NarrativeDependencyTargetKind kind) => usages
            .where((u) => u.target.kind == kind && u.target.id != id)
            .map((u) => u.target.id)
            .toSet();
        final receipt = await port.publishStory(
          id: id,
          base: _bases[id],
          current: stories[id],
          requiredStoryIds: targets(NarrativeDependencyTargetKind.storyline),
          requiredFactIds: targets(NarrativeDependencyTargetKind.fact),
          requiredSceneIds: targets(NarrativeDependencyTargetKind.scene),
        );
        if (_closed) return false;
        final desired = narrative.stories
            .where((story) => story.id == id)
            .firstOrNull;
        _bases[id] = stories[id];
        workspace.acceptResources(receipt.before, receipt.manifest);
        if (desired == stories[id]) {
          narrative.pendingStories.remove(id);
          narrative.pendingStoryDeletions.remove(id);
        } else if (desired == null) {
          narrative.pendingStories.remove(id);
          narrative.pendingStoryDeletions.add(id);
        } else {
          narrative.pendingStories[id] = desired;
          narrative.pendingStoryDeletions.remove(id);
        }
        saved++;
      }
      narrative.publicationError = null;
      return !dirty;
    } catch (failure) {
      if (!_closed) {
        final scope = saved == 0
            ? ''
            : '$saved document(s) déjà enregistré(s). Les autres brouillons restent ouverts. ';
        error = narrative.publicationError = '$scope$failure';
      }
      return false;
    } finally {
      busy = false;
      if (!_closed) {
        reconcile();
        changed();
      }
    }
  }

  List<String>? _publicationOrder(
    Map<String, StorylineAsset?> stories,
    NarrativeDependencyIndex dependencies,
    NarrativeDependencyIndex storedDependencies,
    List<String> cycle,
  ) {
    final result = <String>[];
    final visiting = <String>{};
    final path = <String>[];
    bool visit(String id) {
      if (result.contains(id)) return true;
      if (!visiting.add(id)) {
        if (cycle.isEmpty) cycle.addAll([...path.skip(path.indexOf(id)), id]);
        return false;
      }
      path.add(id);
      if (stories[id] == null) {
        final consumers = storedDependencies.usagesFor(
          NarrativeDependencyKey(NarrativeDependencyTargetKind.storyline, id),
        );
        for (final consumer in consumers) {
          final owner = consumer.owner;
          if (owner.kind == NarrativeDependencyTargetKind.storyline &&
              owner.id != id &&
              stories.containsKey(owner.id) &&
              stories[owner.id] == null &&
              !visit(owner.id)) {
            return false;
          }
        }
      }
      final refs = dependencies.usagesOwnedBy(
        NarrativeDependencyKey(NarrativeDependencyTargetKind.storyline, id),
      );
      for (final usage in refs) {
        if (usage.target.kind != NarrativeDependencyTargetKind.storyline) {
          continue;
        }
        final target = usage.target.id;
        if (target != id && stories[target] != null && !visit(target)) {
          return false;
        }
      }
      visiting.remove(id);
      path.removeLast();
      result.add(id);
      return true;
    }

    for (final id in stories.keys) {
      if (!visit(id)) return null;
    }
    return result;
  }
}
