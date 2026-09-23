import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_reader.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'load_desktop_capture_fonts.dart';
import 'm2_ui_fixture.dart';
import 'm3_story_fixture.dart';

part 'ui05_narrative_port.dart';

class Ui05NarrativeFixture {
  Ui05NarrativeFixture(this.source, this.controller, this.port, this.visuals);
  final M3StoryFixture source;
  final WidgetMapController controller;
  final Ui05NarrativePort port;
  final StudioMapResources visuals;
  final captureKey = GlobalKey();
  static String eventId(int number) =>
      'evt_019abcde-9000-7000-8000-${number.toString().padLeft(12, '0')}';

  static Future<Ui05NarrativeFixture> create(
    WidgetTester tester, {
    int extraStories = 0,
  }) async {
    await loadDesktopCaptureFonts();
    final fixture = await M3StoryFixture.create();
    final port = LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    );
    final manifest = await fixture.maps.loadProject(fixture.session);
    final base = await fixture.maps.loadMap(
      fixture.session,
      manifest.maps.first,
    );
    final projections = [
      for (final number in [1, 7])
        readStudioInteraction(
          manifest.eventRegistry!.records.firstWhere(
            (record) => record.id == eventId(number),
          ),
          manifest,
        )!.revise(name: 'Les traces de Mame').project(),
      NarrativeInteractionDraft(
        id: eventId(101),
        name: 'Le signal ancien',
        mapId: base.map.id,
        source: NarrativeEventSourceRef.mapEnter(base.map.id),
        dialogueId: 'zone',
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventId(1), true),
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
                id: 'departure-intro',
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
      id: eventId(100),
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
    final controller = WidgetMapController(
      fixture.session,
      fixture.maps,
      tester,
    );
    await controller.initialize();
    final visuals = await StudioMapResources.load(
      fixture.session,
      controller.project!,
    );
    return Ui05NarrativeFixture(
      fixture,
      controller,
      Ui05NarrativePort(port, tester),
      visuals,
    );
  }

  Widget app(
    WidgetTester tester, {
    double textScale = 1,
    bool withOwners = false,
  }) => RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: MapWorkspaceScreen(
        controller: controller,
        narrativePort: port,
        storyPort: withOwners
            ? LocalStoryAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        scenePort: withOwners
            ? LocalSceneAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        eventPort: withOwners
            ? LocalEventAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        dialoguePort: withOwners
            ? LocalDialogueAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        verificationPort: withOwners
            ? LocalVerificationAdapter(
                session: source.session,
                mapAdapter: source.maps,
              )
            : null,
        loadVisuals: (_, _) async => visuals,
        runtimeBuilder: (_, _, _) => const SizedBox(),
        onClose: () async {},
        registerExitGuard: (_) {},
      ),
    ),
  );

  Future<void> seedLocalDraft(NarrativeWorkspaceController narrative) async {
    final record = controller.project!.eventRegistry!.records.firstWhere(
      (record) => record.id == eventId(2),
    );
    await narrative.openRecord(record);
    final edit = narrative.active!;
    final updated = edit.current.interaction.revise(
      name: 'Voyageuse · texte en préparation',
    );
    edit.change(interaction: updated);
    edit.document.commit(
      edit.document.current.copyWith(name: 'Jardin · travail non enregistré'),
    );
    narrative.changed();
  }

  Future<Map<String, List<int>>> diskSnapshot() async => {
    for (final file
        in await source.directory
            .list(recursive: true)
            .where((file) => file is File && !file.path.contains('/.pokemap/'))
            .cast<File>()
            .toList())
      file.path.substring(source.directory.path.length): await file
          .readAsBytes(),
  };
  Future<void> dispose() async {
    controller.dispose();
    await visuals.dispose();
    await source.directory.delete(recursive: true);
  }
}
