import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_reader.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:map_core/map_core_domain.dart';

import 'm3_story_fixture.dart';

String ui05StoryEventId(int number) =>
    'evt_019abcde-9000-7000-8000-${number.toString().padLeft(12, '0')}';

Future<M3StoryFixture> createUi05StoryBackend({int extraStories = 0}) async {
  final fixture = await M3StoryFixture.create();
  final port = LocalNarrativeAdapter(
    session: fixture.session,
    mapAdapter: fixture.maps,
  );
  final manifest = await fixture.maps.loadProject(fixture.session);
  final base = await fixture.maps.loadMap(fixture.session, manifest.maps.first);
  final projections = [
    for (final number in [1, 7])
      readStudioInteraction(
        manifest.eventRegistry!.records.firstWhere(
          (record) => record.id == ui05StoryEventId(number),
        ),
        manifest,
      )!.revise(name: 'Les traces de Mame').project(),
    NarrativeInteractionDraft(
      id: ui05StoryEventId(101),
      name: 'Le signal ancien',
      mapId: base.map.id,
      source: NarrativeEventSourceRef.mapEnter(base.map.id),
      dialogueId: 'zone',
      conditions: [
        NarrativeEventCondition.narrativeEventConsumed(
          ui05StoryEventId(1),
          true,
        ),
      ],
      order: 101,
    ).project(),
  ];
  await port.publish(
    NarrativePublication(
      base: base,
      current: base.map,
      events: projections.map((projection) => projection.event).toList(),
      scenes: projections.map((projection) => projection.scene).toList(),
      cinematics: projections
          .expand((projection) => projection.cinematics)
          .toList(),
      storylines: [
        StorylineAsset(
          id: 'departure',
          type: StorylineType.main,
          title: 'Préparer le départ',
          description:
              'Retrouver la voyageuse et préparer le quai avant le départ.',
          chapters: [
            StorylineChapter(
              id: 'departure-final',
              title: 'Sur le quai',
              order: 20,
              steps: [
                StorylineStep(
                  id: 'unlinked',
                  title: 'Observer le panneau',
                  order: 20,
                ),
                StorylineStep(
                  id: 'finish',
                  title: 'Annoncer le départ',
                  order: 10,
                ),
              ],
            ),
            StorylineChapter(
              id: 'departure_chapter',
              title: 'Avant le départ',
              order: 10,
              steps: [
                StorylineStep(
                  id: 'help',
                  title: 'Aider la voyageuse',
                  order: 20,
                ),
                StorylineStep(
                  id: 'prepare',
                  title: 'Accepter d’aider',
                  order: 10,
                ),
              ],
            ),
          ],
        ),
        StorylineAsset(
          id: 'garden-traces',
          type: StorylineType.sideQuest,
          title: 'Les traces du jardin',
          chapters: [
            StorylineChapter(
              id: 'garden-first',
              title: 'Une piste discrète',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'garden-listen',
                  title: 'Écouter le guide',
                  order: 0,
                ),
                StorylineStep(
                  id: 'garden-cross',
                  title: 'Traverser la clairière',
                  order: 1,
                ),
              ],
            ),
          ],
          relationships: [
            StorylineRelationship(
              id: 'garden-departure-branch',
              kind: StorylineRelationshipKind.sideQuestAvailableDuring,
              sourceStorylineId: 'garden-traces',
              targetStorylineId: 'departure',
            ),
          ],
        ),
        for (var index = 0; index < extraStories; index++)
          StorylineAsset(
            id: 'collection-$index',
            type: StorylineType.sideQuest,
            title: 'Collection $index',
            chapters: const [],
          ),
      ],
    ),
  );
  final secondBase = await fixture.maps.loadMap(
    fixture.session,
    manifest.maps.last,
  );
  final arrival = NarrativeInteractionDraft(
    id: ui05StoryEventId(100),
    name: 'Les traces de Mame',
    mapId: secondBase.map.id,
    source: NarrativeEventSourceRef.mapEnter(secondBase.map.id),
    dialogueId: 'zone',
    order: 100,
    steps: [
      const NarrativeSequenceStep(
        kind: NarrativeSequenceKind.completeStep,
        targetId: 'garden-cross',
      ),
    ],
  ).project();
  await port.publish(
    NarrativePublication(
      base: secondBase,
      current: secondBase.map,
      events: [arrival.event],
      scenes: [arrival.scene],
      cinematics: arrival.cinematics,
    ),
  );
  return fixture;
}
