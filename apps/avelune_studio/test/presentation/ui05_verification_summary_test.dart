import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui13_verification_harness.dart';
import '../support/verification_port_probe.dart';

void main() {
  test(
    'overview consultation preserves the real report and never reruns analysis',
    () async {
      late VerificationPortProbe probe;
      final h = await Ui13VerificationHarness.create(
        wrap: (port) => probe = VerificationPortProbe(port),
      );
      addTearDown(h.dispose);
      final stories = StoryWorkspaceController(
        h.narrative,
        LocalStoryAdapter(session: h.session, mapAdapter: h.adapter),
        changed: () {},
      );
      addTearDown(stories.dispose);
      final navigation = WorkspaceNavigationSession(
        controller: h.maps,
        isActive: () => !h.maps.isDisposed,
        changed: () {},
        verification: () => h.verification,
        stories: () => stories,
      );
      navigation.show(WorkspaceSpace.story);
      expect(h.verification.report, isNull);
      expect(probe.revisions, 0);
      expect(probe.analyses, 0);
      expect(probe.sourceReads, 0);
      navigation.show(WorkspaceSpace.verification);
      expect(await h.verification.run(), isTrue, reason: h.verification.error);
      final report = h.verification.report!;
      final stamp = report.generatedAt;
      final counts = (probe.revisions, probe.analyses, probe.sourceReads);
      final diagnostic = report.diagnostics.first;
      h.verification.select(diagnostic.stableKey);
      h.verification.setSearch('zzz introuvable zzz');
      expect(h.verification.visible, isEmpty);
      expect(h.verification.selected?.stableKey, diagnostic.stableKey);
      expect(h.verification.selectionHidden, isTrue);
      expect(h.verification.graph.nodes, isNotEmpty);
      h.verification.clearFilters();
      expect(h.verification.visible, isNotEmpty);
      expect((probe.revisions, probe.analyses, probe.sourceReads), counts);
      navigation.returnFromVerification();
      expect(identical(h.verification.report, report), isTrue);
      expect(report.scope, isNotEmpty);
      expect((probe.revisions, probe.analyses, probe.sourceReads), counts);

      final story = stories.create('À vérifier')!;
      expect(h.verification.stale, isTrue);
      expect(h.verification.report!.generatedAt, stamp);
      expect((probe.revisions, probe.analyses, probe.sourceReads), counts);
      navigation.show(WorkspaceSpace.verification);
      expect(await h.verification.run(), isTrue, reason: h.verification.error);
      expect(h.verification.report!.requestId, isNot(report.requestId));
      expect(h.verification.stale, isFalse);
      final refreshed = (probe.revisions, probe.analyses, probe.sourceReads);
      navigation.returnFromVerification();
      expect(stories.open(story.id), isTrue);
      expect(
        stories.mutate(
          (current) => current.copyWith(
            storylines: [
              for (final item in current.storylines)
                item.id == story.id
                    ? item.copyWith(title: 'À vérifier encore')
                    : item,
            ],
          ),
        ),
        isTrue,
      );
      expect(h.verification.stale, isTrue);
      expect((probe.revisions, probe.analyses, probe.sourceReads), refreshed);
    },
  );
}
