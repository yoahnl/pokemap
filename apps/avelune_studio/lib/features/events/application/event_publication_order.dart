part of 'event_workspace_controller.dart';

extension EventPublicationOrder on EventWorkspaceController {
  List<String>? _publicationOrder(Map<String, NarrativeEventRecord?> snapshot) {
    final desired = buildNarrativeDependencyIndex(project: project, maps: maps);
    final stored = buildNarrativeDependencyIndex(
      project: narrative.project,
      maps: maps,
    );
    final ordered = <String>[];
    final visiting = <String>{};
    bool visit(String id) {
      if (ordered.contains(id)) return true;
      if (!visiting.add(id)) return false;
      final key = NarrativeDependencyKey.eventV2(id);
      if (snapshot[id] == null) {
        for (final usage in stored.usagesFor(key)) {
          final owner = usage.owner;
          if (owner.kind == NarrativeDependencyTargetKind.eventV2 &&
              owner.id != id &&
              snapshot.containsKey(owner.id) &&
              !visit(owner.id)) {
            return false;
          }
        }
      } else {
        for (final usage in desired.usagesOwnedBy(key)) {
          final target = usage.target;
          if (target.kind == NarrativeDependencyTargetKind.eventV2 &&
              target.id != id &&
              snapshot[target.id] != null &&
              !visit(target.id)) {
            return false;
          }
        }
      }
      visiting.remove(id);
      ordered.add(id);
      return true;
    }

    for (final id in snapshot.keys) {
      if (!visit(id)) return null;
    }
    return ordered;
  }
}
