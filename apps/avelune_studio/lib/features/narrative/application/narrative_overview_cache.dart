import 'narrative_overview.dart';
import 'narrative_overview_projection.dart';
import 'narrative_workspace_controller.dart';

class NarrativeOverviewCache {
  List<Object?> _fingerprint = const [];
  NarrativeOverview? _value;
  int buildCount = 0;

  NarrativeOverview read(NarrativeWorkspaceController controller) {
    final next = <Object?>[
      controller,
      controller.project,
      for (final entry in controller.pendingStories.entries) ...[
        entry.key,
        entry.value,
      ],
      ...controller.pendingStoryDeletions,
      for (final entry in controller.pendingFacts.entries) ...[
        entry.key,
        entry.value,
      ],
      for (final entry in controller.sessions.entries) ...[
        entry.key,
        entry.value,
        entry.value.current,
        entry.value.saved,
      ],
      for (final entry in controller.workspace.documents.entries) ...[
        entry.key,
        entry.value.current,
      ],
    ];
    if (_value != null && next.length == _fingerprint.length) {
      var same = true;
      for (var i = 0; i < next.length && same; i++) {
        same = identical(next[i], _fingerprint[i]);
      }
      if (same) return _value!;
    }
    _fingerprint = next;
    buildCount++;
    return _value = buildNarrativeOverview(controller);
  }
}
