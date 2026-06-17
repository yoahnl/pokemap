import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/canvas/events/event_builder_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('NS-EVENT-04 shows a readable empty state', (tester) async {
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
    );

    expect(find.text('Événements'), findsOneWidget);
    expect(
      find.text(
        'Déclenchez des scènes depuis la carte, sous conditions, puis '
        'suivez leurs conséquences.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aucun événement sur cette map'), findsOneWidget);
    expect(find.text('Nouvel événement'), findsWidgets);
    expect(
      find.text(
          'Sélectionnez une position sur la carte pour créer un événement.'),
      findsWidgets,
    );
    expect(find.text('Sauvegarder'), findsNothing);
  });

  testWidgets('NS-EVENT-04 renders statuses and no-code details',
      (tester) async {
    final readModel = _sampleReadModel();

    await _pumpWorkspace(tester, readModel);

    expect(find.text('Rencontre rival au port'), findsWidgets);
    expect(find.text('Coffre abandonné'), findsWidgets);
    expect(find.text('Garde somnolent'), findsWidgets);
    expect(find.text('Rumeur cassée'), findsWidgets);
    expect(find.text('Actif'), findsWidgets);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(find.text('Inactif'), findsOneWidget);
    expect(find.text('Invalide'), findsOneWidget);

    expect(find.text('Interaction avec un PNJ'), findsWidgets);
    expect(find.text('Jouer la scène "Rencontre rival"'), findsWidgets);
    expect(find.text('0 condition'), findsWidgets);
    expect(find.text('1 diagnostic'), findsWidgets);
    expect(find.text('Aucune action principale'), findsWidgets);
    expect(find.text('ID technique'), findsWidgets);
    expect(find.text('EVT_RIVAL_PORT_MEET'), findsWidgets);

    await _tapEventCard(tester, 'Herbes médicinales');

    expect(
      find.text('Cette condition contient une partie avancée préservée.'),
      findsWidgets,
    );
    expect(
      find.text('Elle est lisible, mais pas encore éditable partiellement.'),
      findsWidgets,
    );
    expect(find.text('Condition avancée préservée'), findsWidgets);
    expect(find.text('Fact "Départ accepté" est vrai'), findsWidgets);

    expect(find.text('Nouvel événement'), findsWidgets);
    expect(find.text('Créer'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);
    expect(find.text('Ajouter une condition'), findsNothing);
  });

  testWidgets('NS-EVENT-05 displays read-only sections with summaries',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    expect(find.text('Déclencheur'), findsOneWidget);
    expect(find.text('Conditions'), findsOneWidget);
    expect(find.text('Action principale'), findsOneWidget);
    expect(find.text('Comportement'), findsOneWidget);
    expect(find.text('Changements du monde'), findsOneWidget);
    expect(find.text('Diagnostics'), findsWidgets);
    expect(find.text('Informations techniques'), findsOneWidget);

    expect(find.text('Déclencheur configuré'), findsOneWidget);
    expect(find.text('1 impact(s) prévisible(s)'), findsOneWidget);
    expect(
      find.text('Événement consommé : Rencontre rival au port'),
      findsOneWidget,
    );
    expect(find.text('0 diagnostic'), findsWidgets);
    expect(
      find.text('Le read model ne signale aucun problème bloquant.'),
      findsOneWidget,
    );
    expect(find.text('EVT_RIVAL_PORT_MEET'), findsWidgets);
  });

  testWidgets(
      'NS-EVENT-05 shows missing action diagnostic only for draft selection',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    expect(
      find.text('Le read model ne signale aucun problème bloquant.'),
      findsOneWidget,
    );

    await _tapEventCard(tester, 'Coffre abandonné');

    expect(
      find.text('Le read model ne signale aucun problème bloquant.'),
      findsNothing,
    );
    expect(find.text('Action principale manquante'), findsWidgets);
    expect(find.text('Section : Action principale'), findsOneWidget);
    expect(find.text('1 diagnostic'), findsWidgets);
    expect(find.text('Bloquant'), findsWidgets);
  });

  testWidgets('NS-EVENT-05 explains locked legacy conditions clearly',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    await _tapEventCard(tester, 'Herbes médicinales');

    expect(
      find.text('Cette condition contient une partie avancée préservée.'),
      findsWidgets,
    );
    expect(
      find.text('Elle est lisible, mais pas encore éditable partiellement.'),
      findsWidgets,
    );
    expect(
      find.text('La condition complète est conservée telle quelle.'),
      findsWidgets,
    );
    expect(find.text('Fact "Départ accepté" est vrai'), findsWidgets);
    expect(find.text('Condition avancée préservée'), findsWidgets);
    expect(find.text('Ajouter une condition'), findsNothing);
  });

  testWidgets('NS-EVENT-05 surfaces legacy script and message warnings',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    await _tapEventCard(tester, 'Messager legacy');

    expect(find.text('Script legacy préservé'), findsOneWidget);
    expect(find.text('Message legacy préservé'), findsOneWidget);
    expect(find.text('Avertissement'), findsWidgets);
    expect(find.text('Section : Action principale'), findsWidgets);
    expect(find.text('2 diagnostics'), findsWidgets);
  });

  testWidgets('NS-EVENT-05 surfaces malformed metadata warning',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    await _tapEventCard(tester, 'Réglage cassé');

    expect(find.text('Réglage Event Builder illisible'), findsOneWidget);
    expect(find.text('Section : Comportement'), findsOneWidget);
    expect(
      find.text('Chemin : page.metadata.eventBuilder.reusePolicy'),
      findsOneWidget,
    );
    expect(find.text('Avertissement'), findsWidgets);
  });

  testWidgets('NS-EVENT-05 keeps event details read-only', (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    expect(find.text('Nouvel événement'), findsWidgets);
    expect(
      find.text(
          'Sélectionnez une position sur la carte pour créer un événement.'),
      findsOneWidget,
    );
    expect(find.text('Créer'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);
    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets(
      'NS-EVENT-07 keeps draft creation blocked without explicit position',
      (tester) async {
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
    );

    expect(find.byKey(const ValueKey('event-builder-new-event-button')),
        findsOneWidget);
    expect(find.text('Nouvel événement'), findsWidgets);
    expect(find.text('Position requise'), findsOneWidget);
    expect(
      find.text(
          'Sélectionnez une position sur la carte pour créer un événement.'),
      findsWidgets,
    );

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('event-builder-event-list')), findsNothing);
    expect(find.text('Brouillon'), findsNothing);
    expect(find.textContaining('0,0'), findsNothing);
    expect(find.textContaining('0, 0'), findsNothing);
  });

  testWidgets(
      'NS-EVENT-16 map activation explains missing active map and opens a project map',
      (tester) async {
    String? openedMapId;
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(events: const []),
      draftCreationGate: const EventBuilderDraftCreationGate.disabled(
        disabledReason:
            'Ouvrez une map active pour choisir la position de l’événement.',
      ),
      mapOptions: const [
        EventBuilderMapOption(id: 'map_port', label: 'Port Selbrume'),
      ],
      onOpenMap: (mapId) async {
        openedMapId = mapId;
      },
    );

    expect(find.text('Aucune map active'), findsOneWidget);
    expect(
      find.text('Choisissez une map du projet pour créer des événements.'),
      findsOneWidget,
    );
    expect(find.text('Ouvrir “Port Selbrume”'), findsOneWidget);
    expect(find.text('Map active'), findsNothing);
    expect(find.text('Position requise'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('event-builder-new-event-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Ouvrir “Port Selbrume”'));
    await tester.pumpAndSettle();

    expect(openedMapId, 'map_port');
  });

  testWidgets('NS-EVENT-16 map activation handles project without maps',
      (tester) async {
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(events: const []),
      draftCreationGate: const EventBuilderDraftCreationGate.disabled(
        disabledReason:
            'Ouvrez une map active pour choisir la position de l’événement.',
      ),
    );

    expect(find.text('Aucune map active'), findsOneWidget);
    expect(find.text('Aucune map dans ce projet.'), findsOneWidget);
    expect(
      find.text('Créez une map avant d’ajouter des événements.'),
      findsOneWidget,
    );
    expect(find.text('Map active'), findsNothing);
  });

  testWidgets(
      'NS-EVENT-16 map activation from NarrativeWorkspaceCanvas opens map and keeps events workspace',
      (tester) async {
    final repo = _FakeMapRepository(
      mapsByPath: {
        '/project/maps/port.json': _mapWithObjectLayerFirst(),
      },
    );
    final container = await _pumpNarrativeEventsShell(
      tester,
      startWithoutActiveMap: true,
      projectRootPath: '/project',
      providerOverrides: [
        mapRepositoryProvider.overrideWith((ref) => repo),
        projectWorkspaceFactoryProvider.overrideWith(
          (ref) => const _FakeWorkspaceFactory(
            workspace: _FakeWorkspace(projectRoot: '/project'),
          ),
        ),
      ],
    );

    expect(find.text('Aucune map active'), findsOneWidget);
    expect(find.text('Ouvrir “Port Selbrume”'), findsOneWidget);

    await tester.tap(find.text('Ouvrir “Port Selbrume”'));
    await tester.pumpAndSettle();

    final state = container.read(editorNotifierProvider);
    expect(repo.loadedPaths, ['/project/maps/port.json']);
    expect(state.activeMap?.id, 'map_port');
    expect(state.workspaceMode, EditorWorkspaceMode.events);
    expect(find.text('Couche : Objets'), findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsOneWidget);
  });

  testWidgets('NS-EVENT-07 calls the creation entry only when gate is ready',
      (tester) async {
    var calls = 0;
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
      draftCreationGate: EventBuilderDraftCreationGate.enabled(
        onCreateDraft: () => calls++,
      ),
    );

    expect(find.text('Position prête'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(calls, 1);
  });

  testWidgets(
      'NS-EVENT-07 does not expose condition action or scene editing controls',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Jouer une scène'), findsNothing);
    expect(find.text('Définir fact'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);
  });

  testWidgets(
      'NS-EVENT-08 selected explicit position enables draft creation gate',
      (tester) async {
    EventPosition? createdPosition;
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
      draftCreationGate: EventBuilderDraftCreationGate.positionPicker(
        mapId: 'map_port',
        mapWidth: 4,
        mapHeight: 3,
        layerId: 'objects',
        layerLabel: 'Objets',
        layerValid: true,
        onCreateDraftAt: (position) {
          createdPosition = position;
          return 'evt_nouvel_evenement';
        },
      ),
    );

    expect(find.text('Position requise'), findsOneWidget);
    expect(find.text('Couche : Objets'), findsOneWidget);
    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
    await tester.pumpAndSettle();

    expect(find.text('Position sélectionnée : x 2, y 1'), findsOneWidget);
    expect(find.text('Position prête'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(
      createdPosition,
      const EventPosition(layerId: 'objects', x: 2, y: 1),
    );
  });

  testWidgets('NS-EVENT-08 invalid active layer keeps creation blocked',
      (tester) async {
    var calls = 0;
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
      draftCreationGate: EventBuilderDraftCreationGate.positionPicker(
        mapId: 'map_port',
        mapWidth: 4,
        mapHeight: 3,
        layerId: 'ground',
        layerLabel: 'Sol',
        layerValid: false,
        onCreateDraftAt: (_) {
          calls++;
          return 'evt_nouvel_evenement';
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('event-builder-position-1-1')));
    await tester.pumpAndSettle();

    expect(find.text('Position sélectionnée : x 1, y 1'), findsOneWidget);
    expect(find.text('Couche requise'), findsWidgets);
    expect(
      find.text(
          'Sélectionnez une couche de destination pour créer un événement.'),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('NS-EVENT-08 clearing explicit position blocks creation again',
      (tester) async {
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
      draftCreationGate: EventBuilderDraftCreationGate.positionPicker(
        mapId: 'map_port',
        mapWidth: 4,
        mapHeight: 3,
        layerId: 'objects',
        layerLabel: 'Objets',
        layerValid: true,
        onCreateDraftAt: (_) => 'evt_nouvel_evenement',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('event-builder-position-3-2')));
    await tester.pumpAndSettle();
    expect(find.text('Position prête'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-clear-position')));
    await tester.pumpAndSettle();

    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
    expect(find.text('Position requise'), findsOneWidget);
  });

  testWidgets(
      'NS-EVENT-09 creates a draft through the narrative workspace and resets position',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
    expect(find.text('Position requise'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
    await tester.pumpAndSettle();

    expect(find.text('Position sélectionnée : x 2, y 1'), findsOneWidget);
    expect(find.text('Position prête'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    final state = container.read(editorNotifierProvider);
    final events = state.activeMap!.events;
    expect(events, hasLength(2));
    final created = events.last;
    expect(state.selectedMapEventId, created.id);
    expect(state.statusMessage, 'Brouillon d’événement créé');
    expect(created.title, 'Nouvel événement');
    expect(
      created.position,
      const EventPosition(layerId: 'objects', x: 2, y: 1),
    );
    expect(created.pages, hasLength(1));
    expect(created.pages.single.sceneTarget, isNull);
    expect(created.pages.single.script, isNull);
    expect(created.pages.single.message, isNull);
    expect(created.pages.single.condition, isNull);

    expect(
      find.byKey(ValueKey('event-builder-event-card-${created.id}')),
      findsOneWidget,
    );
    expect(find.text('Nouvel événement'), findsWidgets);
    expect(find.text('Brouillon'), findsWidgets);
    expect(find.text('Action principale manquante'), findsWidgets);
    expect(find.text('ID technique'), findsWidgets);
    expect(find.text(created.id), findsWidgets);
    expect(
      find.text(
        'Brouillon d’événement créé. Sélectionnez une nouvelle position '
        'pour en créer un autre.',
      ),
      findsOneWidget,
    );
    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
    expect(find.text('Position requise'), findsOneWidget);
    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(
        container.read(editorNotifierProvider).activeMap!.events, hasLength(2));
  });

  testWidgets(
      'NS-EVENT-10 renames the selected event title without changing id',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    expect(find.text('Événement existant'), findsWidgets);
    expect(find.text('evt_existing'), findsWidgets);
    expect(find.byKey(const ValueKey('event-builder-rename-title-button')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-rename-title-button')));
    await tester.pumpAndSettle();

    expect(find.text('Titre de l’événement'), findsWidgets);
    expect(find.byKey(const ValueKey('event-builder-title-field')),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('event-builder-title-field')),
      '  Rencontre rival au port  ',
    );
    await tester
        .tap(find.byKey(const ValueKey('event-builder-save-title-button')));
    await tester.pumpAndSettle();

    final state = container.read(editorNotifierProvider);
    final event = state.activeMap!.events.single;
    expect(event.id, 'evt_existing');
    expect(event.title, 'Rencontre rival au port');
    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(event.pages.single.script, isNull);
    expect(event.pages.single.message, isNull);
    expect(event.pages.single.condition, isNull);
    expect(state.selectedMapEventId, 'evt_existing');
    expect(state.statusMessage, 'Événement renommé');

    expect(find.text('Rencontre rival au port'), findsWidgets);
    expect(find.text('Événement existant'), findsNothing);
    expect(find.text('Titre mis à jour.'), findsOneWidget);
    expect(find.text('evt_existing'), findsWidgets);
    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Choisir une scène'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);
  });

  testWidgets('NS-EVENT-10 canceling title edit keeps event unchanged',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-rename-title-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-builder-title-field')),
      'Titre annulé',
    );
    await tester
        .tap(find.byKey(const ValueKey('event-builder-cancel-title-button')));
    await tester.pumpAndSettle();

    final event =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(event.id, 'evt_existing');
    expect(event.title, 'Événement existant');
    expect(find.text('Événement existant'), findsWidgets);
    expect(find.text('Titre annulé'), findsNothing);
  });

  testWidgets('NS-EVENT-10 empty title is refused in the details panel',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-rename-title-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-builder-title-field')),
      '   ',
    );
    await tester
        .tap(find.byKey(const ValueKey('event-builder-save-title-button')));
    await tester.pumpAndSettle();

    final state = container.read(editorNotifierProvider);
    final event = state.activeMap!.events.single;
    expect(event.id, 'evt_existing');
    expect(event.title, 'Événement existant');
    expect(state.selectedMapEventId, isNull);
    expect(find.text('Le titre est obligatoire.'), findsOneWidget);
    expect(find.text('Événement existant'), findsWidgets);
  });

  testWidgets(
      'NS-EVENT-11 selects a scene action for a draft event without changing id',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    final createdBefore =
        container.read(editorNotifierProvider).activeMap!.events.last;
    expect(createdBefore.id, 'evt_nouvel_evenement');
    expect(createdBefore.pages.single.sceneTarget, isNull);
    expect(find.text('Action principale manquante'), findsWidgets);
    expect(find.text('Brouillon'), findsWidgets);
    expect(find.byKey(const ValueKey('event-builder-choose-scene-button')),
        findsOneWidget);
    expect(find.text('Choisir une scène'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('event-builder-choose-scene-button')));
    await tester.pumpAndSettle();

    expect(find.text('Scène existante'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
        findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
    );
    await tester.pumpAndSettle();

    final state = container.read(editorNotifierProvider);
    final createdAfter = state.activeMap!.events.last;
    expect(createdAfter.id, createdBefore.id);
    expect(createdAfter.title, createdBefore.title);
    expect(createdAfter.position, createdBefore.position);
    expect(createdAfter.type, createdBefore.type);
    expect(createdAfter.metadata, createdBefore.metadata);
    expect(createdAfter.pages, hasLength(1));
    expect(createdAfter.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(createdAfter.pages.single.condition, isNull);
    expect(createdAfter.pages.single.script, isNull);
    expect(createdAfter.pages.single.message, isNull);
    expect(state.selectedMapEventId, createdAfter.id);
    expect(state.statusMessage, 'Scène d’événement mise à jour');

    expect(find.text('Jouer la scène "Scène existante"'), findsWidgets);
    expect(find.text('Actif'), findsWidgets);
    expect(find.text(createdAfter.id), findsWidgets);
    expect(find.text('Scène mise à jour.'), findsOneWidget);
    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Créer une scène'), findsNothing);
    expect(find.text('Éditer la scène'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);
  });

  testWidgets('NS-EVENT-11 shows an empty scene picker message',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _draftReadModelWithoutScene(),
      sceneOptions: const [],
      onUpdateSceneAction: ({required eventId, required sceneId}) => false,
    );

    expect(find.text('Choisir une scène'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-choose-scene-button')));
    await tester.pumpAndSettle();

    expect(find.text('Aucune scène disponible.'), findsOneWidget);
    expect(find.text('Créer une scène'), findsNothing);
    expect(find.text('Éditer la scène'), findsNothing);
  });

  testWidgets(
      'NS-EVENT-12 changes reuse policy without changing id or scene action',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    expect(find.text('Une seule fois'), findsWidgets);
    expect(find.text('Réutilisable'), findsWidgets);
    expect(find.text('evt_existing'), findsWidgets);
    expect(find.text('Jouer la scène "Scène existante"'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
    );
    await tester.pumpAndSettle();

    var state = container.read(editorNotifierProvider);
    var event = state.activeMap!.events.single;
    expect(event.id, 'evt_existing');
    expect(event.title, 'Événement existant');
    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(
      event.pages.single.metadata[EventBuilderMetadataKeys.schemaVersion],
      EventBuilderMetadataKeys.currentSchemaVersion,
    );
    expect(
      event.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
      EventBuilderReusePolicy.reusable.name,
    );
    expect(state.selectedMapEventId, 'evt_existing');
    expect(state.statusMessage, 'Comportement d’événement mis à jour');
    expect(find.text('Réutilisation'), findsWidgets);
    expect(find.text('Réutilisable'), findsWidgets);
    expect(find.text('Comportement mis à jour.'), findsOneWidget);
    expect(find.text('Jouer la scène "Scène existante"'), findsWidgets);
    expect(find.text('eventBuilder.reusePolicy'), findsNothing);
    expect(find.text('eventBuilder.schemaVersion'), findsNothing);
    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Créer une règle'), findsNothing);
    expect(find.text('Modifier le déclencheur'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-reuse-oneShot-button')),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    event = state.activeMap!.events.single;
    expect(
      event.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
      EventBuilderReusePolicy.oneShot.name,
    );
    expect(event.id, 'evt_existing');
    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(find.text('Une seule fois'), findsWidgets);
    expect(find.text('Comportement mis à jour.'), findsOneWidget);
  });

  testWidgets('NS-EVENT-12 keeps behavior read-only without update callback',
      (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    expect(find.text('Comportement'), findsOneWidget);
    expect(find.text('Réutilisation'), findsOneWidget);
    expect(find.text('Une seule fois'), findsWidgets);
    expect(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('event-builder-reuse-oneShot-button')),
      findsNothing,
    );
    expect(find.text('eventBuilder.reusePolicy'), findsNothing);
  });

  testWidgets('NS-EVENT-13 adds and removes Fact conditions from details',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    expect(find.text('Aucune condition'), findsWidgets);
    expect(
        find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
        findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Facts disponibles'), findsOneWidget);
    expect(find.text('Départ accepté'), findsOneWidget);
    expect(find.text('Rival battu'), findsOneWidget);
    expect(find.text('fact_started'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();

    var state = container.read(editorNotifierProvider);
    var page = state.activeMap!.events.single.pages.single;
    expect(page.condition, ScriptConditionFactory.flagIsSet('fact_started'));
    expect(page.sceneTarget?.sceneId, 'scene_existing');
    expect(state.selectedMapEventId, 'evt_existing');
    expect(state.statusMessage, 'Condition d’événement ajoutée');
    expect(find.text('Fact "Départ accepté" est vrai'), findsWidgets);
    expect(find.text('Condition ajoutée.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-fact-false-fact_blocked')),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    page = state.activeMap!.events.single.pages.single;
    expect(page.condition?.type, ScriptConditionType.allOf);
    expect(page.condition?.children, [
      ScriptConditionFactory.flagIsSet('fact_started'),
      ScriptConditionFactory.flagIsUnset('fact_blocked'),
    ]);
    expect(find.text('Fact "Rival battu" est faux'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-remove-condition-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('event-builder-remove-condition-0')),
        matching: find.text('Retirer'),
      ),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    page = state.activeMap!.events.single.pages.single;
    expect(page.condition, ScriptConditionFactory.flagIsUnset('fact_blocked'));
    expect(find.text('Fact "Départ accepté" est vrai'), findsNothing);
    expect(find.text('Condition retirée.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-remove-condition-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('event-builder-remove-condition-0')),
        matching: find.text('Retirer'),
      ),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    page = state.activeMap!.events.single.pages.single;
    expect(page.condition, isNull);
    expect(find.text('Aucune condition'), findsWidgets);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Créer une règle'), findsNothing);
    expect(find.text('Modifier le déclencheur'), findsNothing);
  });

  testWidgets('NS-EVENT-13 explains that no Fact is available', (tester) async {
    await _pumpWorkspace(
      tester,
      _draftReadModelWithoutScene(),
      factOptions: const [],
      onAddFactCondition: ({
        required eventId,
        required factId,
        required expectedValue,
      }) =>
          false,
      onRemoveCondition: ({required eventId, required conditionIndex}) => false,
    );

    expect(find.text('Aucun Fact disponible.'), findsOneWidget);
    expect(
      find.text('Créez un Fact dans le workspace Facts avant d’ajouter une '
          'condition.'),
      findsOneWidget,
    );
    expect(find.text('Ajouter une condition Fact'), findsNothing);
  });

  testWidgets('NS-EVENT-13 keeps locked legacy conditions read-only',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _sampleReadModel(),
      factOptions: _sampleFactOptions,
      onAddFactCondition: ({
        required eventId,
        required factId,
        required expectedValue,
      }) =>
          false,
      onRemoveCondition: ({required eventId, required conditionIndex}) => false,
    );

    await _tapEventCard(tester, 'Herbes médicinales');

    expect(find.text('Conditions verrouillées'), findsWidgets);
    expect(find.text('Condition avancée préservée'), findsWidgets);
    expect(find.text('Ajouter une condition Fact'), findsNothing);
    expect(
      find.byKey(const ValueKey('event-builder-remove-condition-0')),
      findsNothing,
    );
  });

  testWidgets('NS-EVENT-14 adds and removes Event consumed conditions',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      activeMap: _mapWithEventConditionTargets(),
    );

    await _tapEventCard(tester, 'Événement existant');
    expect(
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Événements disponibles'), findsOneWidget);
    expect(find.text('Rival au port'), findsWidgets);
    expect(find.text('Garde endormi'), findsWidgets);
    expect(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_existing')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );
    await tester.pumpAndSettle();

    var state = container.read(editorNotifierProvider);
    var sourceEvent = state.activeMap!.events
        .singleWhere((event) => event.id == 'evt_existing');
    var page = sourceEvent.pages.single;
    expect(page.condition, ScriptConditionFactory.eventIsConsumed('evt_rival'));
    expect(page.sceneTarget?.sceneId, 'scene_existing');
    expect(state.selectedMapEventId, 'evt_existing');
    expect(state.statusMessage, 'Condition d’événement ajoutée');
    expect(find.text('Événement "Rival au port" déjà consommé'), findsWidgets);
    expect(find.text('Condition ajoutée.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('event-builder-event-not-consumed-evt_guard'),
      ),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    sourceEvent = state.activeMap!.events
        .singleWhere((event) => event.id == 'evt_existing');
    page = sourceEvent.pages.single;
    expect(page.condition?.type, ScriptConditionType.allOf);
    expect(page.condition?.children, [
      ScriptConditionFactory.eventIsConsumed('evt_rival'),
      ScriptConditionFactory.not(
        ScriptConditionFactory.eventIsConsumed('evt_guard'),
      ),
    ]);
    expect(
      find.text('Événement "Garde endormi" pas encore consommé'),
      findsWidgets,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-remove-condition-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('event-builder-remove-condition-0')),
        matching: find.text('Retirer'),
      ),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    sourceEvent = state.activeMap!.events
        .singleWhere((event) => event.id == 'evt_existing');
    page = sourceEvent.pages.single;
    expect(
      page.condition,
      ScriptConditionFactory.not(
        ScriptConditionFactory.eventIsConsumed('evt_guard'),
      ),
    );
    expect(find.text('Événement "Rival au port" déjà consommé'), findsNothing);
    expect(find.text('Condition retirée.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-remove-condition-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('event-builder-remove-condition-0')),
        matching: find.text('Retirer'),
      ),
    );
    await tester.pumpAndSettle();

    state = container.read(editorNotifierProvider);
    sourceEvent = state.activeMap!.events
        .singleWhere((event) => event.id == 'evt_existing');
    page = sourceEvent.pages.single;
    expect(page.condition, isNull);
    expect(find.text('Aucune condition'), findsWidgets);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Créer une règle'), findsNothing);
    expect(find.text('Modifier le déclencheur'), findsNothing);
  });

  testWidgets('NS-EVENT-14 explains that no other event target is available',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _draftReadModelWithoutScene(),
      eventConditionOptions: const [
        EventBuilderConditionEventOption(
          id: 'evt_draft',
          label: 'Nouvel événement',
        ),
      ],
      onAddFactCondition: ({
        required eventId,
        required factId,
        required expectedValue,
      }) =>
          false,
      onAddEventConsumedCondition: ({
        required eventId,
        required targetEventId,
        required expectedConsumed,
      }) =>
          false,
      onRemoveCondition: ({required eventId, required conditionIndex}) => false,
    );

    expect(find.text('Aucun autre événement disponible.'), findsOneWidget);
    expect(
      find.text(
        'Créez d’abord un autre événement sur cette map pour ajouter cette '
        'condition.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ajouter une condition d’événement'), findsNothing);
  });

  testWidgets('NS-EVENT-14 keeps locked legacy event conditions read-only',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _sampleReadModel(),
      factOptions: _sampleFactOptions,
      eventConditionOptions: _sampleEventConditionOptions,
      onAddFactCondition: ({
        required eventId,
        required factId,
        required expectedValue,
      }) =>
          false,
      onAddEventConsumedCondition: ({
        required eventId,
        required targetEventId,
        required expectedConsumed,
      }) =>
          false,
      onRemoveCondition: ({required eventId, required conditionIndex}) => false,
    );

    await _tapEventCard(tester, 'Herbes médicinales');

    expect(find.text('Conditions verrouillées'), findsWidgets);
    expect(find.text('Ajouter une condition d’événement'), findsNothing);
    expect(
      find.byKey(const ValueKey('event-builder-remove-condition-0')),
      findsNothing,
    );
  });

  testWidgets('NS-EVENT-15 edits trigger type with no-code labels',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    expect(find.text('Interaction avec un PNJ'), findsWidgets);
    expect(
      find.byKey(const ValueKey('event-builder-trigger-object-button')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-trigger-object-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-object-button')),
    );
    await tester.pumpAndSettle();

    var state = container.read(editorNotifierProvider);
    var event = state.activeMap!.events.single;
    expect(event.type, MapEventType.object);
    expect(event.id, 'evt_existing');
    expect(event.title, 'Événement existant');
    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(state.selectedMapEventId, 'evt_existing');
    expect(state.statusMessage, 'Déclencheur d’événement mis à jour');
    expect(find.text('Interaction avec un objet'), findsWidgets);
    expect(find.text('Déclencheur mis à jour.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-zone-button')),
    );
    await tester.pumpAndSettle();
    state = container.read(editorNotifierProvider);
    event = state.activeMap!.events.single;
    expect(event.type, MapEventType.triggerZone);
    expect(find.text('Entrée dans une zone'), findsWidgets);
    expect(find.text('Déclencheur mis à jour.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-actor-button')),
    );
    await tester.pumpAndSettle();
    state = container.read(editorNotifierProvider);
    event = state.activeMap!.events.single;
    expect(event.type, MapEventType.actor);
    expect(find.text('Interaction avec un PNJ'), findsWidgets);
    expect(find.text('Déclencheur mis à jour.'), findsOneWidget);

    expect(find.text('effect'), findsNothing);
    expect(find.text('MapEventType'), findsNothing);
    expect(find.text('Modifier la position'), findsNothing);
    expect(find.text('Changer la couche'), findsNothing);
    expect(find.text('Taille de zone'), findsNothing);
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Créer une règle'), findsNothing);
    expect(find.text('Flow editor'), findsNothing);
  });

  testWidgets('NS-EVENT-15 keeps effect trigger type read-only',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _readModelForEffectTriggerType(),
      onUpdateTriggerType: ({
        required eventId,
        required type,
      }) =>
          false,
    );

    expect(find.text('Interaction / effet'), findsWidgets);
    expect(
      find.text('Ce type de déclencheur n’est pas éditable dans ce lot.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-trigger-object-button')),
      findsNothing,
    );
    expect(find.text('effect'), findsNothing);
  });

  testWidgets('NS-EVENT-16 consolidates the workspace into guided blocks',
      (tester) async {
    await _pumpNarrativeEventsShell(tester);

    expect(find.text('Créer un événement'), findsOneWidget);
    expect(
      find.text(
          'Édition guidée : déclencheur, conditions, scène et comportement.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Création de brouillon uniquement. L’édition reste verrouillée dans ce lot.',
      ),
      findsNothing,
    );

    expect(find.text('Builder d’événement'), findsOneWidget);
    expect(find.text('Identité'), findsOneWidget);
    expect(find.text('Déclencheur'), findsOneWidget);
    expect(find.text('Conditions'), findsOneWidget);
    expect(find.text('Action principale'), findsOneWidget);
    expect(find.text('Comportement'), findsOneWidget);
    expect(find.text('Changements du monde'), findsOneWidget);
    expect(find.text('Diagnostics'), findsWidgets);
    expect(find.text('Informations techniques'), findsOneWidget);
    expect(find.text('Piloté par les conséquences de scène.'), findsOneWidget);

    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Résultats possibles'), findsNothing);
    expect(find.text('Ajouter une réaction'), findsNothing);
    expect(find.text('Créer une règle'), findsNothing);
    expect(find.text('Flow editor'), findsNothing);
    expect(find.text('Drag/drop'), findsNothing);
  });

  testWidgets('captures NS-EVENT-07 draft creation position gate visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_07_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
      fontFamily: _screenshotFontFamily,
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_07_draft_creation_ui_gate_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-08 explicit position picker visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_08_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpWorkspace(
      tester,
      buildEventBuilderReadModel(
        events: const [],
        mapId: 'map_port',
        mapTitle: 'Port Selbrume',
      ),
      fontFamily: _screenshotFontFamily,
      draftCreationGate: EventBuilderDraftCreationGate.positionPicker(
        mapId: 'map_port',
        mapWidth: 4,
        mapHeight: 3,
        layerId: 'objects',
        layerLabel: 'Objets',
        layerValid: true,
        onCreateDraftAt: (_) => 'evt_nouvel_evenement',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_08_explicit_position_picker_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-09 draft creation closure visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_09_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
    );
    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_09_draft_creation_flow_closure_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-10 draft title authoring visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_10_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
    );
    await tester
        .tap(find.byKey(const ValueKey('event-builder-rename-title-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-builder-title-field')),
      'Rencontre rival au port',
    );
    await tester
        .tap(find.byKey(const ValueKey('event-builder-save-title-button')));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_10_draft_title_authoring_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-11 scene action authoring visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_11_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
    );
    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('event-builder-choose-scene-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Action principale'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_11_scene_action_authoring_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-12 behavior authoring visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_12_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Comportement'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_12_behavior_authoring_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-13 fact conditions authoring visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_13_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Conditions'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_13_fact_conditions_authoring_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-14 event consumed authoring visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_14_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      activeMap: _mapWithEventConditionTargets(),
    );
    await _tapEventCard(tester, 'Événement existant');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Conditions'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_14_event_consumed_conditions_authoring_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-15 trigger type authoring visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_15_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-trigger-zone-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-zone-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Déclencheur'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_15_trigger_type_authoring_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-16 block layout consolidation visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_16_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_16_block_layout_consolidation_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-16 map activation visual gate',
      (tester) async {
    if (!const bool.fromEnvironment(
        'NS_EVENT_16_MAP_ACTIVATION_CAPTURE_WORKSPACE')) {
      return;
    }

    await _pumpNarrativeEventsShell(
      tester,
      startWithoutActiveMap: true,
      surfaceSize: const Size(1440, 1100),
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_16_map_activation_creation_availability_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-04 workspace visual gate', (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_04_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpWorkspace(
      tester,
      _sampleReadModel(),
      fontFamily: _screenshotFontFamily,
    );

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_04_workspace_list_readonly_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-05 readonly diagnostics visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_05_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpWorkspace(
      tester,
      _sampleReadModel(),
      fontFamily: _screenshotFontFamily,
    );
    await _tapEventCard(tester, 'Herbes médicinales');

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_05_readonly_details_diagnostics_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });
}

const _screenshotFontFamily = 'NsEvent04ScreenshotFont';

Future<void> _loadScreenshotFont() async {
  final fontBytes = File(
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ).readAsBytesSync();
  final loader = FontLoader(_screenshotFontFamily)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
  await loader.load();
}

EventBuilderReadModel _sampleReadModel() {
  return buildEventBuilderReadModel(
    events: [
      _event(
        id: 'EVT_RIVAL_PORT_MEET',
        title: 'Rencontre rival au port',
        x: 0,
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
        ),
      ),
      _event(
        id: 'evt_draft',
        title: 'Coffre abandonné',
        x: 1,
        page: const MapEventPage(pageNumber: 0),
      ),
      _event(
        id: 'evt_inactive',
        title: 'Garde somnolent',
        x: 2,
        page: const MapEventPage(
          pageNumber: 0,
          isDisabled: true,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_guard'),
        ),
      ),
      const MapEventDefinition(
        id: 'evt_invalid',
        title: 'Rumeur cassée',
        position: EventPosition(layerId: 'events', x: 3, y: 0),
        pages: [],
      ),
      _event(
        id: 'evt_legacy',
        title: 'Herbes médicinales',
        x: 4,
        page: MapEventPage(
          pageNumber: 0,
          sceneTarget: const MapEventSceneTarget(sceneId: 'scene_herbs'),
          condition: ScriptConditionFactory.allOf([
            ScriptConditionFactory.flagIsSet('fact_started'),
            ScriptConditionFactory.variableEqualsString(
              'legacy_variable',
              'yes',
            ),
          ]),
        ),
      ),
      _event(
        id: 'evt_legacy_script',
        title: 'Messager legacy',
        x: 5,
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_message'),
          script: ScriptRef(scriptId: 'legacy_script'),
          message: 'Bonjour legacy',
        ),
      ),
      _event(
        id: 'evt_malformed',
        title: 'Réglage cassé',
        x: 6,
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_malformed'),
          metadata: {
            EventBuilderMetadataKeys.reusePolicy: 'reuse-forever',
          },
        ),
      ),
    ],
    mapId: 'map_port',
    mapTitle: 'Port Selbrume',
    sceneLabels: const {
      'scene_rival': 'Rencontre rival',
      'scene_guard': 'Réveil du garde',
      'scene_herbs': 'Cueillir les herbes',
      'scene_message': 'Lire le message',
      'scene_malformed': 'Scène réglage',
    },
    factLabels: const {
      'fact_started': 'Départ accepté',
    },
  );
}

Future<void> _pumpWorkspace(
  WidgetTester tester,
  EventBuilderReadModel readModel, {
  String? fontFamily,
  EventBuilderDraftCreationGate draftCreationGate =
      const EventBuilderDraftCreationGate.disabled(),
  List<EventBuilderSceneOption> sceneOptions = const [],
  List<EventBuilderFactOption> factOptions = const [],
  List<EventBuilderConditionEventOption> eventConditionOptions = const [],
  List<EventBuilderMapOption> mapOptions = const [],
  EventBuilderMapOpenCallback? onOpenMap,
  EventBuilderTriggerTypeUpdateCallback? onUpdateTriggerType,
  EventBuilderSceneActionUpdateCallback? onUpdateSceneAction,
  EventBuilderReusePolicyUpdateCallback? onUpdateReusePolicy,
  EventBuilderFactConditionAddCallback? onAddFactCondition,
  EventBuilderEventConsumedConditionAddCallback? onAddEventConsumedCondition,
  EventBuilderConditionRemoveCallback? onRemoveCondition,
}) async {
  tester.view.physicalSize = const Size(1280, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final theme = PokeMapTheme.dark();
  final themedWithFont = fontFamily == null
      ? theme
      : theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme:
              theme.primaryTextTheme.apply(fontFamily: fontFamily),
        );
  await tester.pumpWidget(
    MaterialApp(
      theme: themedWithFont,
      home: CupertinoPageScaffold(
        child: SizedBox.expand(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: fontFamily,
              decoration: TextDecoration.none,
            ),
            child: EventBuilderWorkspace(
              readModel: readModel,
              draftCreationGate: draftCreationGate,
              sceneOptions: sceneOptions,
              factOptions: factOptions,
              eventConditionOptions: eventConditionOptions,
              mapOptions: mapOptions,
              onOpenMap: onOpenMap,
              onUpdateTriggerType: onUpdateTriggerType,
              onUpdateSceneAction: onUpdateSceneAction,
              onUpdateReusePolicy: onUpdateReusePolicy,
              onAddFactCondition: onAddFactCondition,
              onAddEventConsumedCondition: onAddEventConsumedCondition,
              onRemoveCondition: onRemoveCondition,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<ProviderContainer> _pumpNarrativeEventsShell(
  WidgetTester tester, {
  String? fontFamily,
  MapData? activeMap,
  bool startWithoutActiveMap = false,
  String? projectRootPath,
  ProjectManifest? project,
  List<Override> providerOverrides = const [],
  Size surfaceSize = const Size(1440, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(overrides: providerOverrides);
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: projectRootPath,
    project: project ?? _eventProject(),
    workspaceMode: EditorWorkspaceMode.events,
    activeMap:
        startWithoutActiveMap ? null : activeMap ?? _mapWithObjectLayer(),
    activeLayerId: startWithoutActiveMap ? null : 'objects',
  );

  final theme = PokeMapTheme.dark();
  final themedWithFont = fontFamily == null
      ? theme
      : theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme:
              theme.primaryTextTheme.apply(fontFamily: fontFamily),
        );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: themedWithFont,
        home: CupertinoPageScaffold(
          child: SizedBox.expand(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontFamily: fontFamily,
                decoration: TextDecoration.none,
              ),
              child: const NarrativeWorkspaceCanvas(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

ProjectManifest _eventProject() {
  return ProjectManifest(
    name: 'Event Builder test',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port Selbrume',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    scenes: [_eventScene('scene_existing', 'Scène existante')],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_started',
        label: 'Départ accepté',
      ),
      NarrativeFactDefinition(
        id: 'fact_blocked',
        label: 'Rival battu',
      ),
    ],
  );
}

const _sampleFactOptions = [
  EventBuilderFactOption(id: 'fact_started', label: 'Départ accepté'),
  EventBuilderFactOption(id: 'fact_blocked', label: 'Rival battu'),
];

const _sampleEventConditionOptions = [
  EventBuilderConditionEventOption(id: 'evt_draft', label: 'Coffre abandonné'),
  EventBuilderConditionEventOption(
    id: 'evt_existing',
    label: 'Événement existant',
  ),
  EventBuilderConditionEventOption(id: 'evt_rival', label: 'Rival au port'),
];

EventBuilderReadModel _draftReadModelWithoutScene() {
  return buildEventBuilderReadModel(
    events: const [
      MapEventDefinition(
        id: 'evt_draft',
        title: 'Nouvel événement',
        position: EventPosition(layerId: 'objects', x: 2, y: 1),
        pages: [MapEventPage(pageNumber: 0)],
      ),
    ],
    mapId: 'map_port',
    mapTitle: 'Port Selbrume',
  );
}

EventBuilderReadModel _readModelForEffectTriggerType() {
  return buildEventBuilderReadModel(
    events: const [
      MapEventDefinition(
        id: 'evt_effect',
        title: 'Effet avancé',
        type: MapEventType.effect,
        position: EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
    ],
    mapId: 'map_port',
    mapTitle: 'Port Selbrume',
    sceneLabels: const {'scene_existing': 'Scène existante'},
  );
}

SceneAsset _eventScene(String id, String name) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

MapData _mapWithObjectLayer() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
    ],
  );
}

MapData _mapWithObjectLayerFirst() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.object(id: 'objects', name: 'Objets'),
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    events: [],
  );
}

MapData _mapWithEventConditionTargets() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
      MapEventDefinition(
        id: 'evt_rival',
        title: 'Rival au port',
        position: EventPosition(layerId: 'objects', x: 1, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
      MapEventDefinition(
        id: 'evt_guard',
        title: 'Garde endormi',
        position: EventPosition(layerId: 'objects', x: 2, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
    ],
  );
}

Future<void> _tapEventCard(WidgetTester tester, String label) async {
  final eventId = _eventIdsByLabel[label];
  final finder = find.text(label);
  final target = eventId == null
      ? finder
      : find.byKey(ValueKey('event-builder-event-card-$eventId'));
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target.first);
  await tester.pumpAndSettle();
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory({
    required this.workspace,
  });

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace({
    required this.projectRoot,
  });

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => '$projectRoot/project.json';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => true;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => true;

  @override
  String getMapPath(String mapId) => '$projectRoot/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      '$projectRoot/assets/${preferredName ?? 'tileset.png'}';

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakeMapRepository implements MapRepository {
  _FakeMapRepository({
    required Map<String, MapData> mapsByPath,
  }) : _mapsByPath = mapsByPath;

  final Map<String, MapData> _mapsByPath;
  final List<String> loadedPaths = [];

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    final map = _mapsByPath[path];
    if (map == null) {
      throw StateError('Map not found at $path');
    }
    return map;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {}
}

const _eventIdsByLabel = <String, String>{
  'Événement existant': 'evt_existing',
  'Rival au port': 'evt_rival',
  'Garde endormi': 'evt_guard',
  'Coffre abandonné': 'evt_draft',
  'Herbes médicinales': 'evt_legacy',
  'Messager legacy': 'evt_legacy_script',
  'Réglage cassé': 'evt_malformed',
};

MapEventDefinition _event({
  required String id,
  required String title,
  required int x,
  required MapEventPage page,
}) {
  return MapEventDefinition(
    id: id,
    title: title,
    position: EventPosition(layerId: 'events', x: x, y: 0),
    pages: [page],
  );
}
