import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  for (final linked in [false, true]) {
    test(
      'retired linked dialogue preview reads no source and preserves the cinematic draft linked=$linked',
      () async {
        final asset = CinematicAsset(
          id: 'cinematic',
          title: 'Scène conservée',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'dialogue',
                kind: CinematicTimelineStepKind.dialogueLine,
                assetRef: linked ? 'linked' : null,
                dialogueText: linked ? null : 'Réplique intégrée',
                durationMs: 1000,
              ),
            ],
          ),
        );
        final fixture = await CinematicAdapterFixture.create(
          cinematics: [asset],
        );
        final maps = MapWorkspaceController(fixture.session, fixture.maps);
        await maps.initialize();
        final port = _NoDialogueAccess();
        final narrative = NarrativeWorkspaceController(
          maps,
          port,
          () {},
          (_, _) async {},
        );
        final controller = CinematicWorkspaceController(
          narrative,
          fixture.adapter(),
          changed: () {},
        );
        addTearDown(() async {
          controller.dispose();
          narrative.dispose();
          maps.dispose();
          await fixture.dispose();
        });
        maps.project = maps.project!.copyWith(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'linked',
              name: 'Document lié',
              relativePath: 'linked.yarn',
            ),
          ],
        );
        expect(
          await controller.open(asset.id),
          isTrue,
          reason: controller.error,
        );
        expect(controller.rename('Brouillon conservé'), isTrue);
        final draft = controller.active!;
        final authored = draft.asset;
        final recorded = await fixture.file('project.json').readAsBytes();
        controller.preparePreview();
        controller.transport.seek(0);
        expect(controller.transport.frame!.activeStepIds, contains('dialogue'));
        final plan = controller.transport.plan!;
        final cue = plan.playbackCues.single;
        expect(cue.kind, CinematicPlaybackCueKind.dialogue);
        expect(cue.referenceId, linked ? 'linked' : isNull);
        expect(cue.dialogueText, linked ? 'Document lié' : 'Réplique intégrée');
        expect(
          controller.active!.asset.timeline.steps.single.dialogueText,
          linked ? isNull : 'Réplique intégrée',
        );
        for (final time in [0, 500, 999]) {
          controller.transport.seek(time);
          expect(controller.transport.timeMs, time);
          expect(controller.transport.frame!.activeStepIds, ['dialogue']);
          expect(controller.transport.frame!.activeCues.single, cue);
        }
        controller.transport.stop();
        expect(controller.transport.timeMs, 0);
        expect(controller.transport.previewActive, isFalse);
        expect(port.reads, 0);
        expect(port.writes, 0);
        expect(controller.active!.asset, same(authored));
        expect(controller.active!.dirty, isTrue);
        expect(controller.transport.plan, same(plan));
        expect(await fixture.file('project.json').readAsBytes(), recorded);
      },
    );
  }
}

class _NoDialogueAccess implements NarrativePort {
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async {
    reads++;
    return NarrativeDialogueSource(
      entry: entry,
      source: 'title: Start\n---\nTexte lié historique\n===\n',
    );
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    writes++;
    throw StateError('Preview cannot publish');
  }
}
