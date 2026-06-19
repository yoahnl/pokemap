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
    expect(find.text('Actif'), findsWidgets);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(find.text('Inactif'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rumeur cassée'),
      120,
      scrollable: _eventBuilderEventListScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rumeur cassée'), findsWidgets);
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
    final central = find.byKey(const ValueKey('event-builder-central-flow'));

    expect(find.descendant(of: central, matching: find.text('Déclencheur')),
        findsOneWidget);
    expect(find.descendant(of: central, matching: find.text('Conditions')),
        findsOneWidget);
    expect(
        find.descendant(of: central, matching: find.text('Action principale')),
        findsOneWidget);
    expect(find.descendant(of: central, matching: find.text('Comportement')),
        findsOneWidget);
    expect(
        find.descendant(
          of: central,
          matching: find.text('Changements du monde'),
        ),
        findsOneWidget);
    expect(find.text('Diagnostics'), findsWidgets);
    expect(find.text('Informations techniques'), findsOneWidget);

    expect(find.text('Déclencheur configuré'), findsOneWidget);
    expect(
      find.descendant(
        of: central,
        matching: find.text('1 impact(s) prévisible(s)'),
      ),
      findsWidgets,
    );
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
    expect(find.byKey(const ValueKey('event-builder-creation-panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsNothing);
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
    final central = find.byKey(const ValueKey('event-builder-central-flow'));

    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(
      find.descendant(of: central, matching: find.text('Ajouter une scène')),
      findsNothing,
    );
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

    await _scrollDraftPositionIntoView(tester);
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

    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsOneWidget);
    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
    expect(find.text('Position requise'), findsOneWidget);
  });

  testWidgets(
      'NS-EVENT-09 creates a draft through the narrative workspace and resets position',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsNothing);
    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsOneWidget);
    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
    expect(find.text('Position requise'), findsOneWidget);

    await _scrollDraftPositionIntoView(tester);
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
    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsNothing);
    expect(find.text('Position sélectionnée : aucune'), findsNothing);
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

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();
    await _scrollDraftPositionIntoView(tester);
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
      scrollable: _eventBuilderCentralScrollable(),
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
    );
    await tester.pumpAndSettle();
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
      scrollable: _eventBuilderCentralScrollable(),
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-reuse-oneShot-button')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
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
    final central = find.byKey(const ValueKey('event-builder-central-flow'));

    expect(find.text('Comportement'), findsOneWidget);
    expect(find.descendant(of: central, matching: find.text('Réutilisation')),
        findsOneWidget);
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

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );

    expect(find.text('Facts disponibles'), findsOneWidget);
    expect(find.text('Départ accepté'), findsOneWidget);
    expect(find.text('Rival battu'), findsOneWidget);
    expect(find.text('fact_started'), findsNothing);

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );

    var state = container.read(editorNotifierProvider);
    var page = state.activeMap!.events.single.pages.single;
    expect(page.condition, ScriptConditionFactory.flagIsSet('fact_started'));
    expect(page.sceneTarget?.sceneId, 'scene_existing');
    expect(state.selectedMapEventId, 'evt_existing');
    expect(state.statusMessage, 'Condition d’événement ajoutée');
    expect(find.text('Fact "Départ accepté" est vrai'), findsWidgets);
    expect(find.text('Condition ajoutée.'), findsOneWidget);

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );
    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-fact-false-fact_blocked')),
    );

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

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
    );

    expect(find.text('Événements disponibles'), findsOneWidget);
    expect(find.text('Rival au port'), findsWidgets);
    expect(find.text('Garde endormi'), findsWidgets);
    expect(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_existing')),
      findsNothing,
    );

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );

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

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-add-event-condition-button')),
    );
    await _tapCentralBuilderTarget(
      tester,
      find.byKey(
        const ValueKey('event-builder-event-not-consumed-evt_guard'),
      ),
    );

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
      scrollable: _eventBuilderCentralScrollable(),
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

    await tester.pump(const Duration(seconds: 1));
    await tester.drag(_eventBuilderCentralScrollable(), const Offset(0, 120));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-trigger-actor-button')),
      80,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
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
    expect(find.text('Événement existant'), findsWidgets);
    final central = find.byKey(const ValueKey('event-builder-central-flow'));
    expect(central, findsOneWidget);
    expect(find.descendant(of: central, matching: find.text('Déclencheur')),
        findsOneWidget);
    expect(find.descendant(of: central, matching: find.text('Conditions')),
        findsOneWidget);
    expect(
        find.descendant(of: central, matching: find.text('Action principale')),
        findsOneWidget);
    expect(find.descendant(of: central, matching: find.text('Comportement')),
        findsOneWidget);
    expect(
        find.descendant(
          of: central,
          matching: find.text('Changements du monde'),
        ),
        findsOneWidget);
    expect(find.text('Diagnostics'), findsWidgets);
    expect(find.text('Informations techniques'), findsOneWidget);
    expect(find.text('Effets prévisibles en lecture seule.'), findsOneWidget);

    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Résultats possibles'), findsNothing);
    expect(find.text('Ajouter une réaction'), findsNothing);
    expect(find.text('Créer une règle'), findsNothing);
    expect(find.text('Flow editor'), findsNothing);
    expect(find.text('Drag/drop'), findsNothing);
  });

  testWidgets(
      'NS-EVENT-18 keeps creation compact for a selected event until requested',
      (tester) async {
    await _pumpNarrativeEventsShell(tester);

    expect(find.byKey(const ValueKey('event-builder-creation-panel')),
        findsOneWidget);
    expect(find.text('Créer un événement'), findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsNothing);
    expect(find.text('Position sélectionnée : aucune'), findsNothing);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsOneWidget);
    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
  });

  testWidgets('NS-EVENT-19 shows central flow blocks in canonical order',
      (tester) async {
    await _pumpNarrativeEventsShell(tester);

    expect(find.byKey(const ValueKey('event-builder-central-flow')),
        findsOneWidget);

    final trigger = find.byKey(
      const ValueKey('event-builder-flow-block-trigger'),
    );
    final conditions = find.byKey(
      const ValueKey('event-builder-flow-block-conditions'),
    );
    final actions = find.byKey(
      const ValueKey('event-builder-flow-block-actions'),
    );
    final behavior = find.byKey(
      const ValueKey('event-builder-flow-block-behavior'),
    );
    final world = find.byKey(
      const ValueKey('event-builder-flow-block-world'),
    );
    final diagnostics = find.byKey(
      const ValueKey('event-builder-flow-block-diagnostics'),
    );

    expect(trigger, findsOneWidget);
    expect(conditions, findsOneWidget);
    expect(actions, findsOneWidget);
    expect(behavior, findsOneWidget);
    expect(world, findsOneWidget);
    expect(diagnostics, findsOneWidget);

    double top(Finder finder) => tester.getTopLeft(finder).dy;
    expect(top(trigger), lessThan(top(conditions)));
    expect(top(conditions), lessThan(top(actions)));
    expect(top(actions), lessThan(top(behavior)));
    expect(top(behavior), lessThan(top(world)));
    expect(top(world), lessThan(top(diagnostics)));

    expect(find.text('Quand'), findsWidgets);
    expect(find.text('Si'), findsWidgets);
    expect(find.text('Alors'), findsWidgets);
    expect(find.text('Puis'), findsWidgets);
  });

  testWidgets('NS-EVENT-19 keeps trigger authoring working from the block',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);
    final triggerBlock = find.byKey(
      const ValueKey('event-builder-flow-block-trigger'),
    );

    expect(
      find.descendant(
        of: triggerBlock,
        matching: find.byKey(
          const ValueKey('event-builder-trigger-object-button'),
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-object-button')),
    );
    await tester.pumpAndSettle();

    final event =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(event.type, MapEventType.object);
    expect(find.text('Déclencheur mis à jour.'), findsOneWidget);
  });

  testWidgets('NS-EVENT-19 keeps condition authoring working from the block',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);
    final conditionsBlock = find.byKey(
      const ValueKey('event-builder-flow-block-conditions'),
    );

    expect(
      find.descendant(
        of: conditionsBlock,
        matching: find.byKey(
          const ValueKey('event-builder-add-fact-condition-button'),
        ),
      ),
      findsOneWidget,
    );

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );
    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );

    final page = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .single
        .pages
        .single;
    expect(page.condition, ScriptConditionFactory.flagIsSet('fact_started'));
    expect(find.text('Condition ajoutée.'), findsOneWidget);
  });

  testWidgets('NS-EVENT-19 keeps scene action authoring working from the block',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);
    final actionsBlock = find.byKey(
      const ValueKey('event-builder-flow-block-actions'),
    );

    expect(
      find.descendant(
        of: actionsBlock,
        matching: find.byKey(
          const ValueKey('event-builder-choose-scene-button'),
        ),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
    );
    await tester.pumpAndSettle();

    final page = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .single
        .pages
        .single;
    expect(page.sceneTarget?.sceneId, 'scene_existing');
    expect(find.text('Scène mise à jour.'), findsOneWidget);
  });

  testWidgets('NS-EVENT-19 keeps results and reactions read-only',
      (tester) async {
    await _pumpNarrativeEventsShell(tester);

    final central = find.byKey(const ValueKey('event-builder-central-flow'));
    expect(central, findsOneWidget);
    expect(
      find.descendant(
        of: central,
        matching: find.text('Issues de la scène liée'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: central, matching: find.text('Ajouter un résultat')),
      findsNothing,
    );
    expect(
      find.descendant(of: central, matching: find.text('Réactions')),
      findsNothing,
    );
    expect(
      find.descendant(of: central, matching: find.text('Ajouter une réaction')),
      findsNothing,
    );
    expect(find.text('Drag/drop'), findsNothing);
  });

  testWidgets('NS-EVENT-20 shows event inspector on the right', (tester) async {
    await _pumpNarrativeEventsShell(tester);

    final list = find.byKey(const ValueKey('event-builder-event-list'));
    final central = find.byKey(const ValueKey('event-builder-central-flow'));
    final inspector = find.byKey(
      const ValueKey('event-builder-inspector-panel'),
    );

    expect(list, findsOneWidget);
    expect(central, findsOneWidget);
    expect(inspector, findsOneWidget);
    expect(find.text('Inspecteur d’événement'), findsOneWidget);

    double left(Finder finder) => tester.getTopLeft(finder).dx;
    expect(left(list), lessThan(left(central)));
    expect(left(central), lessThan(left(inspector)));
  });

  testWidgets('NS-EVENT-20 keeps technical id secondary in inspector',
      (tester) async {
    await _pumpNarrativeEventsShell(tester);

    final central = find.byKey(const ValueKey('event-builder-central-flow'));
    final inspector = find.byKey(
      const ValueKey('event-builder-inspector-panel'),
    );

    expect(
      find.descendant(
        of: inspector,
        matching: find.text('Informations techniques'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inspector, matching: find.text('ID technique')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inspector, matching: find.text('evt_existing')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: central,
        matching: find.text('Informations techniques'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: central, matching: find.text('ID technique')),
      findsNothing,
    );
  });

  testWidgets(
      'NS-EVENT-20 title trigger scene behavior still update selected event',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(tester);

    await tester
        .tap(find.byKey(const ValueKey('event-builder-rename-title-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-builder-title-field')),
      'Rencontre test inspecteur',
    );
    await tester
        .tap(find.byKey(const ValueKey('event-builder-save-title-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-object-button')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-choose-scene-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
      -160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-add-fact-condition-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
    );
    await tester.pumpAndSettle();

    final event =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(event.title, 'Rencontre test inspecteur');
    expect(event.type, MapEventType.object);
    expect(
      event.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
      EventBuilderReusePolicy.reusable.name,
    );
    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(
      event.pages.single.condition,
      ScriptConditionFactory.flagIsSet('fact_started'),
    );
    expect(find.text('Rencontre test inspecteur'), findsWidgets);
    expect(find.text('Interaction avec un objet'), findsWidgets);
    expect(find.text('Jouer la scène "Scène existante"'), findsWidgets);
    expect(find.text('Fact "Départ accepté" est vrai'), findsWidgets);
    expect(find.text('Réutilisable'), findsWidgets);
  });

  testWidgets('NS-EVENT-21 shows read-only element library groups',
      (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final list = find.byKey(const ValueKey('event-builder-event-list'));
    final library = find.byKey(const ValueKey('event-builder-element-library'));
    final central = find.byKey(const ValueKey('event-builder-central-flow'));

    expect(list, findsOneWidget);
    expect(library, findsOneWidget);
    expect(central, findsOneWidget);
    expect(find.text('Bibliothèque d’éléments'), findsOneWidget);

    for (final group in [
      'Déclencheurs',
      'Conditions',
      'Actions',
      'Résultats',
      'Réactions',
      'Monde',
    ]) {
      expect(find.descendant(of: library, matching: find.text(group)),
          findsOneWidget);
    }

    double left(Finder finder) => tester.getTopLeft(finder).dx;
    expect(left(list), lessThan(left(library)));
    expect(left(library), lessThan(left(central)));
  });

  testWidgets('NS-EVENT-21 marks unsupported elements as coming later',
      (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final library = find.byKey(const ValueKey('event-builder-element-library'));

    expect(
      find.descendant(of: library, matching: find.text('Disponible')),
      findsWidgets,
    );
    expect(
      find.descendant(of: library, matching: find.text('À venir')),
      findsWidgets,
    );
    expect(find.descendant(of: library, matching: find.text('Combat')),
        findsOneWidget);
    expect(find.descendant(of: library, matching: find.text('Victoire')),
        findsOneWidget);
    expect(find.descendant(of: library, matching: find.text('Définir un Fact')),
        findsOneWidget);
  });

  testWidgets(
      'NS-EVENT-21 clicking read-only library item does not mutate event',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final before =
        container.read(editorNotifierProvider).activeMap!.events.single;
    final beforeSelected =
        container.read(editorNotifierProvider).selectedMapEventId;

    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-action-scene')),
    );
    await tester.pumpAndSettle();

    final after =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(after.id, before.id);
    expect(after.title, before.title);
    expect(after.type, before.type);
    expect(after.position, before.position);
    expect(after.metadata, before.metadata);
    expect(after.pages, before.pages);
    expect(
      container.read(editorNotifierProvider).selectedMapEventId,
      beforeSelected,
    );
    expect(find.text('Condition ajoutée.'), findsNothing);
    expect(find.text('Scène mise à jour.'), findsNothing);
  });

  testWidgets('NS-EVENT-21 does not expose raw metadata keys', (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final library = find.byKey(const ValueKey('event-builder-element-library'));

    expect(
      find.descendant(of: library, matching: find.text('eventBuilder')),
      findsNothing,
    );
    expect(
      find.descendant(of: library, matching: find.text('reusePolicy')),
      findsNothing,
    );
    expect(
      find.descendant(of: library, matching: find.text('MapEventType')),
      findsNothing,
    );
    expect(
      find.descendant(of: library, matching: find.text('ScriptCondition')),
      findsNothing,
    );
  });

  testWidgets(
      'NS-EVENT-22 clicking Fact condition library item opens fact choice',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Facts disponibles'), findsOneWidget);
    expect(find.text('Départ accepté'), findsWidgets);
    expect(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
      findsOneWidget,
    );

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );

    final event =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(
      event.pages.single.condition,
      ScriptConditionFactory.flagIsSet('fact_started'),
    );
    expect(find.text('Fact "Départ accepté" est vrai'), findsWidgets);
  });

  testWidgets(
      'NS-EVENT-22 clicking Event condition library item opens event choice',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      activeMap: _mapWithEventConditionTargets(),
      surfaceSize: const Size(1440, 1100),
    );

    await _tapEventCard(tester, 'Événement existant');
    await tester.tap(
      find.byKey(
        const ValueKey('event-builder-library-item-condition-event-consumed'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Événements disponibles'), findsOneWidget);
    expect(find.text('Rival au port'), findsWidgets);
    expect(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
      findsOneWidget,
    );

    await _tapCentralBuilderTarget(
      tester,
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );

    final event = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .singleWhere((event) => event.id == 'evt_existing');
    expect(
      event.pages.single.condition,
      ScriptConditionFactory.eventIsConsumed('evt_rival'),
    );
    expect(
      find.text('Événement "Rival au port" déjà consommé'),
      findsWidgets,
    );
  });

  testWidgets(
      'NS-EVENT-22 clicking Scene action library item focuses scene action',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      activeMap: const MapData(
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
            id: 'evt_missing_scene',
            title: 'Sans scène',
            position: EventPosition(layerId: 'objects', x: 0, y: 0),
            pages: [MapEventPage(pageNumber: 0)],
          ),
        ],
      ),
      surfaceSize: const Size(1440, 1100),
    );

    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-action-scene')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scènes disponibles'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
      160,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-scene-option-scene_existing')),
    );
    await tester.pumpAndSettle();

    final event =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
    expect(find.text('Scène mise à jour.'), findsOneWidget);
  });

  testWidgets(
      'NS-EVENT-22 unsupported library item shows not available message',
      (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );
    final before =
        container.read(editorNotifierProvider).activeMap!.events.single;

    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-action-battle')),
    );
    await tester.pumpAndSettle();

    expect(
        find.text('Cet élément arrive dans un prochain lot.'), findsOneWidget);
    final after =
        container.read(editorNotifierProvider).activeMap!.events.single;
    expect(after.id, before.id);
    expect(after.title, before.title);
    expect(after.type, before.type);
    expect(after.position, before.position);
    expect(after.metadata, before.metadata);
    expect(after.pages, before.pages);
    expect(find.text('Scène mise à jour.'), findsNothing);
    expect(find.text('Condition ajoutée.'), findsNothing);
  });

  testWidgets('NS-EVENT-23 condition rows remain removable', (tester) async {
    final container = await _pumpNarrativeEventsShell(
      tester,
      activeMap: _mapWithEventConditionTargets(),
      surfaceSize: const Size(1440, 1100),
    );

    await _tapEventCard(tester, 'Événement existant');
    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('event-builder-library-item-condition-event-consumed'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );
    await tester.pumpAndSettle();

    final factRow = find.byKey(const ValueKey('event-builder-condition-row-0'));
    final eventRow =
        find.byKey(const ValueKey('event-builder-condition-row-1'));
    expect(factRow, findsOneWidget);
    expect(eventRow, findsOneWidget);
    expect(find.descendant(of: factRow, matching: find.text('Fact')),
        findsOneWidget);
    expect(find.descendant(of: eventRow, matching: find.text('Événement')),
        findsOneWidget);
    expect(
      find.descendant(
        of: factRow,
        matching: find.text('Fact "Départ accepté" est vrai'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: eventRow,
        matching: find.text('Événement "Rival au port" déjà consommé'),
      ),
      findsOneWidget,
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

    final event = container
        .read(editorNotifierProvider)
        .activeMap!
        .events
        .singleWhere((event) => event.id == 'evt_existing');
    expect(event.pages.single.condition,
        ScriptConditionFactory.eventIsConsumed('evt_rival'));
    expect(find.text('Condition retirée.'), findsOneWidget);
  });

  testWidgets(
      'NS-EVENT-23 empty condition slot is visible without promising drag/drop',
      (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final emptySlot =
        find.byKey(const ValueKey('event-builder-empty-condition-slot'));
    expect(emptySlot, findsOneWidget);
    expect(
        find.descendant(of: emptySlot, matching: find.text('Aucune condition')),
        findsOneWidget);
    expect(
      find.descendant(
        of: emptySlot,
        matching: find.text(
          'Ajoutez une condition depuis la bibliothèque ou les boutons ci-dessous.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Déposez'), findsNothing);
    expect(find.text('Drag/drop'), findsNothing);
  });

  testWidgets('NS-EVENT-23 scene action block remains no-code', (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final actionsBlock = find.byKey(
      const ValueKey('event-builder-flow-block-actions'),
    );
    final sceneSlot =
        find.byKey(const ValueKey('event-builder-scene-action-slot'));

    expect(sceneSlot, findsOneWidget);
    expect(
        find.descendant(of: sceneSlot, matching: find.text('Jouer une scène')),
        findsOneWidget);
    expect(
        find.descendant(of: sceneSlot, matching: find.text('Scène existante')),
        findsOneWidget);
    expect(
      find.descendant(of: actionsBlock, matching: find.text('scene_existing')),
      findsNothing,
    );
    expect(
      find.descendant(of: actionsBlock, matching: find.text('sceneTarget')),
      findsNothing,
    );
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

  testWidgets('NS-EVENT-27 renders Scene outcomes as read-only projection',
      (tester) async {
    final readModel = buildEventBuilderReadModel(
      events: [
        _event(
          id: 'evt_projection',
          title: 'Événement avec issues',
          x: 0,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_projection'),
          ),
        ),
      ],
      mapId: 'map_port',
      mapTitle: 'Port Selbrume',
      sceneLabels: const {'scene_projection': 'Rencontre rival'},
      scenes: {
        'scene_projection': _eventScene(
          'scene_projection',
          'Rencontre rival',
          declaredOutcomes: [
            SceneOutcome(
              id: 'victory',
              label: 'Victoire',
              description: 'Le rival laisse passer le joueur.',
            ),
            SceneOutcome(id: 'defeat', label: 'Défaite'),
          ],
        ),
      },
    );

    await _pumpWorkspace(tester, readModel);

    expect(find.text('Issues de la scène liée'), findsOneWidget);
    expect(find.text('2 résultat(s) déclarés par la Scene'), findsWidgets);
    expect(find.text('Victoire'), findsWidgets);
    expect(find.text('Défaite'), findsWidgets);
    expect(find.text('Le rival laisse passer le joueur.'), findsOneWidget);
    expect(find.text('Lecture seule'), findsWidgets);
    expect(find.text('Défini dans la scène'), findsWidgets);
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Modifier le résultat'), findsNothing);
    expect(find.text('Ajouter une réaction'), findsNothing);
  });

  testWidgets('NS-EVENT-27 renders no Scene target projection', (tester) async {
    await _pumpWorkspace(tester, _draftReadModelWithoutScene());

    expect(find.text('Issues de la scène liée'), findsOneWidget);
    expect(find.text('Aucune scène liée'), findsWidgets);
    expect(
      find.text('Choisissez une scène pour voir ses résultats possibles.'),
      findsOneWidget,
    );
  });

  testWidgets('NS-EVENT-27 renders missing Scene projection', (tester) async {
    final readModel = buildEventBuilderReadModel(
      events: [
        _event(
          id: 'evt_missing_scene',
          title: 'Scène perdue',
          x: 0,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_missing'),
          ),
        ),
      ],
      mapId: 'map_port',
      mapTitle: 'Port Selbrume',
      sceneLabels: const {'scene_missing': 'Scène supprimée'},
    );

    await _pumpWorkspace(tester, readModel);

    expect(find.text('Scène introuvable'), findsWidgets);
    expect(
      find.text('La scène liée n’existe pas dans le projet.'),
      findsOneWidget,
    );
  });

  testWidgets('NS-EVENT-27 renders no declared outcomes projection',
      (tester) async {
    final readModel = buildEventBuilderReadModel(
      events: [
        _event(
          id: 'evt_no_outcome',
          title: 'Scène sans issue',
          x: 0,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_no_outcome'),
          ),
        ),
      ],
      mapId: 'map_port',
      mapTitle: 'Port Selbrume',
      scenes: {
        'scene_no_outcome': _eventScene(
          'scene_no_outcome',
          'Scène sans issue',
        ),
      },
    );

    await _pumpWorkspace(tester, readModel);

    expect(find.text('Aucun résultat déclaré'), findsWidgets);
    expect(
      find.text('Cette scène ne déclare pas encore de résultat.'),
      findsOneWidget,
    );
  });

  testWidgets('NS-EVENT-27 renders lifecycle states without runtime claims',
      (tester) async {
    final readModel = buildEventBuilderReadModel(
      events: [
        _event(
          id: 'evt_once',
          title: 'Une seule activation',
          x: 0,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_once'),
          ),
        ),
        _event(
          id: 'evt_reusable',
          title: 'Rejouable',
          x: 1,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_reusable'),
            metadata: {
              EventBuilderMetadataKeys.reusePolicy: 'reusable',
            },
          ),
        ),
        _event(
          id: 'evt_consumed',
          title: 'Consommé par sa scène',
          x: 2,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_consumed'),
          ),
        ),
        _event(
          id: 'evt_other_consumed',
          title: 'Consomme ailleurs',
          x: 3,
          page: const MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_other_consumed'),
          ),
        ),
      ],
      mapId: 'map_port',
      mapTitle: 'Port Selbrume',
      scenes: {
        'scene_once': _eventScene('scene_once', 'Scène simple'),
        'scene_reusable': _eventScene('scene_reusable', 'Scène rejouable'),
        'scene_consumed': _eventScene(
          'scene_consumed',
          'Scène qui consomme',
          consumedEventId: 'evt_consumed',
        ),
        'scene_other_consumed': _eventScene(
          'scene_other_consumed',
          'Scène autre event',
          consumedEventId: 'evt_elsewhere',
        ),
      },
    );

    await _pumpWorkspace(tester, readModel);

    expect(find.text('Intention non garantie au runtime.'), findsWidgets);
    expect(find.textContaining('garanti au runtime'), findsNothing);

    await _tapEventCard(tester, 'Rejouable');
    expect(
      find.text('Aucune consommation d’événement nécessaire.'),
      findsWidgets,
    );

    await _tapEventCard(tester, 'Consommé par sa scène');
    expect(
      find.text('Consommation explicite trouvée dans la Scene.'),
      findsWidgets,
    );
    expect(
      find.text('Compatible, mais fragile si cette Scene est réutilisée.'),
      findsWidgets,
    );

    await _tapEventCard(tester, 'Consomme ailleurs');
    expect(
      find.text('Attention : la Scene consomme un autre événement.'),
      findsWidgets,
    );
  });

  testWidgets('NS-EVENT-28 renders empty world impacts as read-only guidance',
      (tester) async {
    await _pumpWorkspace(tester, _readModelWithWorldImpacts(const []));

    expect(find.text('Changements du monde'), findsOneWidget);
    expect(find.text('Effets prévisibles en lecture seule.'), findsOneWidget);
    expect(find.text('Aucun changement du monde détecté'), findsOneWidget);
    expect(
      find.text(
        'Les réactions et changements persistants se configurent dans la Scene ou dans les règles du monde.',
      ),
      findsOneWidget,
    );
    expect(find.text('Piloté par les conséquences de scène.'), findsNothing);
    expect(find.text('Ajouter un changement'), findsNothing);
    expect(find.text('Créer une règle monde'), findsNothing);
  });

  testWidgets('NS-EVENT-28 renders world impact categories as projections',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _readModelWithWorldImpacts(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.fact,
            sourceId: 'fact_rival_battu',
            label: 'Fact : Rival battu',
            reason: '',
          ),
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.storyStep,
            sourceId: 'step_port',
            label: 'Étape : Aller au port',
            reason: 'Progression narrative visible après la scène.',
          ),
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.consumedEvent,
            sourceId: 'evt_rival_port',
            label: 'Événement consommé : Rencontre rival au port',
            reason:
                'A one-shot event can drive World Rules through consumed event state after the Scene succeeds.',
          ),
        ],
      ),
    );

    final worldBlock = find.byKey(
      const ValueKey('event-builder-flow-block-world'),
    );

    expect(find.text('3 impact(s) prévisible(s)'), findsWidgets);
    expect(
      find.descendant(
        of: worldBlock,
        matching: find.text('Fait du monde'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: worldBlock,
        matching: find.text('Étape narrative'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: worldBlock,
        matching: find.text('Événement consommé'),
      ),
      findsOneWidget,
    );
    expect(find.text('Fact : Rival battu'), findsOneWidget);
    expect(find.text('Étape : Aller au port'), findsOneWidget);
    expect(
      find.text('Événement consommé : Rencontre rival au port'),
      findsOneWidget,
    );
    expect(find.text('Lecture seule'), findsWidgets);
    expect(find.text('Projection'), findsWidgets);
    expect(find.text('Impact'), findsNothing);
    expect(
      find.text(
        'A one-shot event can drive World Rules through consumed event state after the Scene succeeds.',
      ),
      findsNothing,
    );
    expect(
      find.text('Peut influencer les règles du monde après la scène.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Le statut de fiabilité est détaillé dans Comportement.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('NS-EVENT-28 keeps world projection free of authoring controls',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _readModelWithWorldImpacts(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.consumedEvent,
            sourceId: 'evt_rival_port',
            label: 'Événement consommé : Rencontre rival au port',
            reason: '',
          ),
        ],
      ),
      onUpdateSceneAction: ({required eventId, required sceneId}) => false,
      onUpdateReusePolicy: ({required eventId, required reusePolicy}) => false,
      onAddFactCondition: ({
        required eventId,
        required expectedValue,
        required factId,
      }) =>
          false,
      onAddEventConsumedCondition: ({
        required eventId,
        required expectedConsumed,
        required targetEventId,
      }) =>
          false,
      onRemoveCondition: ({required conditionIndex, required eventId}) => false,
    );

    final worldBlock =
        find.byKey(const ValueKey('event-builder-flow-block-world'));
    expect(
      find.descendant(of: worldBlock, matching: find.text('Définir un Fact')),
      findsNothing,
    );
    expect(
      find.descendant(of: worldBlock, matching: find.text('Compléter Step')),
      findsNothing,
    );
    expect(
      find.descendant(of: worldBlock, matching: find.text('Donner objet')),
      findsNothing,
    );

    expect(find.text('Ajouter un changement'), findsNothing);
    expect(find.text('Créer une règle monde'), findsNothing);
    expect(find.text('Ajouter une réaction'), findsNothing);
    expect(find.text('Drag/drop'), findsNothing);
  });

  testWidgets('NS-EVENT-28 keeps world library item read-only and explanatory',
      (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      surfaceSize: const Size(1440, 1100),
    );

    final library = find.byKey(const ValueKey('event-builder-element-library'));
    expect(
      find.descendant(
        of: library,
        matching: find.text('Afficher ou masquer un élément'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: library, matching: find.text('Lecture seule')),
      findsWidgets,
    );

    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-world-element')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Cet élément se règle depuis les règles du monde.'),
      findsOneWidget,
    );
    expect(find.text('Créer une règle monde'), findsNothing);
  });

  testWidgets('NS-EVENT-28 preserves NS-EVENT-27 projections', (tester) async {
    await _pumpWorkspace(tester, _sampleReadModel());

    expect(find.text('Issues de la scène liée'), findsOneWidget);
    expect(find.text('Défini dans la scène'), findsWidgets);
    expect(find.text('Intention non garantie au runtime.'), findsWidgets);
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Ajouter une réaction'), findsNothing);
  });

  testWidgets('NS-EVENT-31 passes project world rules into read model',
      (tester) async {
    await _pumpNarrativeEventsShell(
      tester,
      project: _eventProjectWithWorldRules(),
      surfaceSize: const Size(1440, 1100),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-world-rules-projection')),
      180,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Règles du monde concernées'), findsOneWidget);
    expect(find.text('Règle port observé'), findsOneWidget);
    expect(find.text('Fact "Départ accepté" est vrai'), findsOneWidget);
    expect(find.text('Rival au port'), findsOneWidget);
    expect(find.text('Rend visible'), findsOneWidget);
    expect(find.text('Projection passive'), findsWidgets);
    expect(find.text('Lecture seule'), findsWidgets);
  });

  testWidgets('NS-EVENT-31 renders no world impacts state', (tester) async {
    await _pumpWorkspace(tester, _readModelWithWorldImpacts(const []));

    expect(find.text('Règles du monde concernées'), findsOneWidget);
    expect(find.text('Aucune source d’état projetée'), findsOneWidget);
    expect(
      find.text(
        'Aucune règle du monde ne peut être reliée tant qu’aucun changement d’état n’est visible.',
      ),
      findsOneWidget,
    );
    expect(find.text('Créer une règle monde'), findsNothing);
    expect(find.text('Ajouter une règle'), findsNothing);
  });

  testWidgets('NS-EVENT-31 renders no matching world rules state',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _readModelWithWorldRules(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.fact,
            sourceId: 'fact_rival_battu',
            label: 'Fact : Rival battu',
            reason: '',
          ),
        ],
        EventBuilderWorldRulesProjection.noMatchingRules(),
      ),
    );

    expect(find.text('Règles du monde concernées'), findsOneWidget);
    expect(find.text('Aucune règle du monde liée'), findsOneWidget);
    expect(
      find.text(
        'Aucune règle du monde ne lit les sources d’état affichées ci-dessus.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ce n’est pas une erreur.'), findsOneWidget);
  });

  testWidgets('NS-EVENT-31 renders passive world rules without simulation',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _readModelWithWorldRules(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.fact,
            sourceId: 'fact_rival_battu',
            label: 'Fact : Rival battu',
            reason: '',
          ),
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.consumedEvent,
            sourceId: 'evt_rival_port',
            label: 'Événement consommé : Rencontre rival au port',
            reason: '',
          ),
        ],
        EventBuilderWorldRulesProjection.hasMatchingRules(
          const [
            EventBuilderWorldRuleProjectionReadModel(
              ruleId: 'rule_rival_visible',
              ruleLabel: 'Rival visible après victoire',
              description: '',
              enabled: true,
              sourceKind: WorldRuleSourceKind.fact,
              sourceId: 'fact_rival_battu',
              sourceLabel: 'Rival battu',
              predicateLabel: 'Fact "Rival battu" est vrai',
              targetKind: WorldRuleTargetKind.mapEntity,
              targetId: 'npc_rival',
              targetLabel: 'Rival au port',
              effectKind: WorldRuleEffectKind.entityVisible,
              effectLabel: 'Rend visible',
              reason: 'Cette règle lit un fait modifié par la Scene liée.',
              isReadOnly: true,
            ),
            EventBuilderWorldRuleProjectionReadModel(
              ruleId: 'rule_rival_intro_disabled',
              ruleLabel: 'Intro rival avant rencontre',
              description: 'Désactivée pendant le test.',
              enabled: false,
              sourceKind: WorldRuleSourceKind.consumedEvent,
              sourceId: 'evt_rival_port',
              sourceLabel: 'Rencontre rival au port',
              predicateLabel:
                  'Événement "Rencontre rival au port" non consommé',
              targetKind: WorldRuleTargetKind.mapEvent,
              targetId: 'evt_guard',
              targetLabel: 'Garde du port',
              effectKind: WorldRuleEffectKind.eventHidden,
              effectLabel: 'Masque l’événement',
              reason:
                  'Cette règle lit un événement consommé projeté par l’Event Builder.',
              isReadOnly: true,
            ),
          ],
        ),
      ),
    );

    final worldRules = find.byKey(
      const ValueKey('event-builder-world-rules-projection'),
    );

    expect(find.text('2 règle(s) du monde potentiellement concernée(s).'),
        findsWidgets);
    expect(
      find.descendant(
        of: worldRules,
        matching: find.text('Rival visible après victoire'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: worldRules,
        matching: find.text('Intro rival avant rencontre'),
      ),
      findsOneWidget,
    );
    expect(find.text('Activée'), findsOneWidget);
    expect(find.text('Désactivée'), findsOneWidget);
    expect(
      find.text('Ne produit pas d’effet tant qu’elle reste inactive.'),
      findsOneWidget,
    );
    expect(find.text('Fact "Rival battu" est vrai'), findsOneWidget);
    expect(
      find.text('Événement "Rencontre rival au port" non consommé'),
      findsOneWidget,
    );
    expect(find.text('Rival au port'), findsOneWidget);
    expect(find.text('Garde du port'), findsOneWidget);
    expect(find.text('Rend visible'), findsOneWidget);
    expect(find.text('Masque l’événement'), findsOneWidget);
    expect(find.text('Cette règle sera active'), findsNothing);
    expect(find.text('Effet appliqué'), findsNothing);
    expect(find.text('Créer une règle monde'), findsNothing);
    expect(find.text('Ajouter une règle'), findsNothing);
    expect(find.text('Éditer règle'), findsNothing);
    expect(find.text('Drag/drop'), findsNothing);
  });

  testWidgets('NS-EVENT-31 updates inspector world rules summary',
      (tester) async {
    await _pumpWorkspace(
      tester,
      _readModelWithWorldRules(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.fact,
            sourceId: 'fact_rival_battu',
            label: 'Fact : Rival battu',
            reason: '',
          ),
        ],
        EventBuilderWorldRulesProjection.hasMatchingRules(
          const [
            EventBuilderWorldRuleProjectionReadModel(
              ruleId: 'rule_rival_visible',
              ruleLabel: 'Rival visible après victoire',
              description: '',
              enabled: true,
              sourceKind: WorldRuleSourceKind.fact,
              sourceId: 'fact_rival_battu',
              sourceLabel: 'Rival battu',
              predicateLabel: 'Fact "Rival battu" est vrai',
              targetKind: WorldRuleTargetKind.mapEntity,
              targetId: 'npc_rival',
              targetLabel: 'Rival au port',
              effectKind: WorldRuleEffectKind.entityVisible,
              effectLabel: 'Rend visible',
              reason: 'Cette règle lit un fait modifié par la Scene liée.',
              isReadOnly: true,
            ),
          ],
        ),
      ),
    );

    final inspector =
        find.byKey(const ValueKey('event-builder-inspector-panel'));
    expect(
      find.descendant(of: inspector, matching: find.text('Règles monde')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: inspector,
        matching: find.text('1 règle potentiellement concernée'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('captures NS-EVENT-27 scene outcomes lifecycle visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_27_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-scene-outcomes-projection')),
      180,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Issues de la scène liée'), findsOneWidget);
    expect(find.text('Lecture seule'), findsWidgets);
    expect(find.text('Défini dans la scène'), findsWidgets);
    expect(
      find.text('Consommation explicite trouvée dans la Scene.'),
      findsWidgets,
    );
    expect(find.text('Ajouter un résultat'), findsNothing);
    expect(find.text('Ajouter une réaction'), findsNothing);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-28 world changes readonly visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_28_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpWorkspace(
      tester,
      _readModelWithWorldImpacts(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.fact,
            sourceId: 'fact_rival_battu',
            label: 'Fact : Rival battu',
            reason: '',
          ),
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.storyStep,
            sourceId: 'step_port',
            label: 'Étape : Aller au port',
            reason: 'Progression narrative visible après la scène.',
          ),
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.consumedEvent,
            sourceId: 'evt_rival_port',
            label: 'Événement consommé : Rencontre rival au port',
            reason:
                'A one-shot event can drive World Rules through consumed event state after the Scene succeeds.',
          ),
        ],
      ),
      fontFamily: _screenshotFontFamily,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-flow-block-world')),
      180,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();

    final worldBlock = find.byKey(
      const ValueKey('event-builder-flow-block-world'),
    );

    expect(find.text('Effets prévisibles en lecture seule.'), findsOneWidget);
    expect(
      find.descendant(of: worldBlock, matching: find.text('Fait du monde')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: worldBlock, matching: find.text('Étape narrative')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: worldBlock,
        matching: find.text('Événement consommé'),
      ),
      findsOneWidget,
    );
    expect(find.text('Lecture seule'), findsWidgets);
    expect(find.text('Projection'), findsWidgets);
    expect(find.text('Ajouter un changement'), findsNothing);
    expect(find.text('Créer une règle monde'), findsNothing);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_28_world_changes_readonly_projection_polish_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-31 passive world rules visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_31_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpWorkspace(
      tester,
      _readModelWithWorldRules(
        const [
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.fact,
            sourceId: 'fact_rival_battu',
            label: 'Fact : Rival battu',
            reason: '',
          ),
          EventBuilderWorldImpactReadModel(
            kind: EventBuilderWorldImpactKind.consumedEvent,
            sourceId: 'evt_rival_port',
            label: 'Événement consommé : Rencontre rival au port',
            reason: '',
          ),
        ],
        EventBuilderWorldRulesProjection.hasMatchingRules(
          const [
            EventBuilderWorldRuleProjectionReadModel(
              ruleId: 'rule_rival_visible',
              ruleLabel: 'Rival visible après victoire',
              description: '',
              enabled: true,
              sourceKind: WorldRuleSourceKind.fact,
              sourceId: 'fact_rival_battu',
              sourceLabel: 'Rival battu',
              predicateLabel: 'Fact "Rival battu" est vrai',
              targetKind: WorldRuleTargetKind.mapEntity,
              targetId: 'npc_rival',
              targetLabel: 'Rival au port',
              effectKind: WorldRuleEffectKind.entityVisible,
              effectLabel: 'Rend visible',
              reason: 'Cette règle lit un fait modifié par la Scene liée.',
              isReadOnly: true,
            ),
            EventBuilderWorldRuleProjectionReadModel(
              ruleId: 'rule_rival_intro_disabled',
              ruleLabel: 'Intro rival avant rencontre',
              description: '',
              enabled: false,
              sourceKind: WorldRuleSourceKind.consumedEvent,
              sourceId: 'evt_rival_port',
              sourceLabel: 'Rencontre rival au port',
              predicateLabel:
                  'Événement "Rencontre rival au port" non consommé',
              targetKind: WorldRuleTargetKind.mapEvent,
              targetId: 'evt_guard',
              targetLabel: 'Garde du port',
              effectKind: WorldRuleEffectKind.eventHidden,
              effectLabel: 'Masque l’événement',
              reason:
                  'Cette règle lit un événement consommé projeté par l’Event Builder.',
              isReadOnly: true,
            ),
          ],
        ),
      ),
      fontFamily: _screenshotFontFamily,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-world-rules-projection')),
      180,
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Règles du monde concernées'), findsOneWidget);
    expect(find.text('Rival visible après victoire'), findsOneWidget);
    expect(find.text('Intro rival avant rencontre'), findsOneWidget);
    expect(find.text('Projection passive'), findsWidgets);
    expect(find.text('Créer une règle monde'), findsNothing);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_31_passive_world_rules_projection_ui_v0.png',
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
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-reuse-reusable-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Comportement'),
      -120,
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
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
      scrollable: _eventBuilderCentralScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-trigger-zone-button')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Déclencheur'),
      -120,
      scrollable: _eventBuilderCentralScrollable(),
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

  testWidgets('captures NS-EVENT-18 creation panel compact visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_18_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    expect(find.byKey(const ValueKey('event-builder-creation-panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-position-grid')),
        findsNothing);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_18_creation_panel_compact_collapsible_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-19 central blocks layout visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_19_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    expect(find.byKey(const ValueKey('event-builder-central-flow')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-flow-block-trigger')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-flow-block-conditions')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-flow-block-actions')),
        findsOneWidget);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_19_event_builder_central_blocks_layout_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-20 inspector split visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_20_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    expect(
        find.byKey(const ValueKey('event-builder-event-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-central-flow')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-inspector-panel')),
        findsOneWidget);
    expect(find.text('Inspecteur d’événement'), findsOneWidget);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_20_event_inspector_split_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-21 element library read-only visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_21_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    expect(
        find.byKey(const ValueKey('event-builder-event-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-element-library')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-central-flow')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('event-builder-inspector-panel')),
        findsOneWidget);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_21_element_library_readonly_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-22 add-by-click library visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_22_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('event-builder-element-library')),
        findsOneWidget);
    expect(find.text('Facts disponibles'), findsOneWidget);
    expect(find.text('Bloc ouvert dans le builder.'), findsOneWidget);

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_22_add_by_click_from_library_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
      'captures NS-EVENT-23 actions conditions block polish visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_23_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      activeMap: _mapWithEventConditionTargets(),
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    await _tapEventCard(tester, 'Événement existant');
    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('event-builder-library-item-condition-event-consumed'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('event-builder-condition-row-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-condition-row-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-scene-action-slot')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-condition-row-0')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_23_actions_conditions_block_polish_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('event-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures NS-EVENT-24 MVP UX closure visual gate',
      (tester) async {
    if (!const bool.fromEnvironment('NS_EVENT_24_CAPTURE_WORKSPACE')) {
      return;
    }

    await _loadScreenshotFont();
    await _pumpNarrativeEventsShell(
      tester,
      activeMap: _mapWithEventConditionTargets(),
      fontFamily: _screenshotFontFamily,
      surfaceSize: const Size(1440, 1100),
    );

    await _tapEventCard(tester, 'Événement existant');
    await tester.tap(
      find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('event-builder-event-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-element-library')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-central-flow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-inspector-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-creation-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-condition-row-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-scene-action-slot')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-condition-row-0')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/events/screenshots/'
      'ns_event_24_mvp_ux_closure_visual_gate.png',
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

Finder _eventBuilderCentralScrollable() {
  return find.descendant(
    of: find.byKey(const ValueKey('event-builder-central-flow')),
    matching: find.byType(Scrollable),
  );
}

Finder _eventBuilderEventListScrollable() {
  return find.descendant(
    of: find.byKey(const ValueKey('event-builder-event-list')),
    matching: find.byType(Scrollable),
  );
}

Future<void> _scrollDraftPositionIntoView(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const ValueKey('event-builder-position-2-1')),
  );
  await tester.pumpAndSettle();
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
    scenes: {
      'scene_rival': _eventScene(
        'scene_rival',
        'Rencontre rival',
        declaredOutcomes: [
          SceneOutcome(id: 'victory', label: 'Victoire'),
          SceneOutcome(id: 'defeat', label: 'Défaite'),
        ],
      ),
      'scene_guard': _eventScene('scene_guard', 'Réveil du garde'),
      'scene_herbs': _eventScene('scene_herbs', 'Cueillir les herbes'),
      'scene_message': _eventScene('scene_message', 'Lire le message'),
      'scene_malformed': _eventScene('scene_malformed', 'Scène réglage'),
    },
  );
}

EventBuilderReadModel _readModelWithWorldImpacts(
  List<EventBuilderWorldImpactReadModel> worldImpacts,
) {
  return _readModelWithWorldRules(
    worldImpacts,
    worldImpacts.isEmpty
        ? EventBuilderWorldRulesProjection.noWorldImpacts()
        : EventBuilderWorldRulesProjection.noMatchingRules(),
  );
}

EventBuilderReadModel _readModelWithWorldRules(
  List<EventBuilderWorldImpactReadModel> worldImpacts,
  EventBuilderWorldRulesProjection worldRules,
) {
  final base = _sampleReadModel();
  final selected = base.events.first;
  final sections = [
    for (final section in selected.sections)
      if (section.key == 'world')
        EventBuilderSectionReadModel(
          key: section.key,
          title: section.title,
          summary: worldImpacts.isEmpty
              ? 'Aucun impact monde prévisible'
              : '${worldImpacts.length} impact(s) prévisible(s)',
          diagnosticCount: section.diagnosticCount,
          hasBlockingDiagnostic: section.hasBlockingDiagnostic,
        )
      else
        section,
  ];

  final patched = EventBuilderEventSummary(
    eventId: selected.eventId,
    displayName: selected.displayName,
    technicalId: selected.technicalId,
    status: selected.status,
    statusLabel: selected.statusLabel,
    groupKey: selected.groupKey,
    position: selected.position,
    trigger: selected.trigger,
    conditions: selected.conditions,
    sceneAction: selected.sceneAction,
    behavior: selected.behavior,
    sceneOutcomes: selected.sceneOutcomes,
    lifecycle: selected.lifecycle,
    worldImpacts: worldImpacts,
    worldRules: worldRules,
    diagnostics: selected.diagnostics,
    sections: sections,
    conditionEditingLocked: selected.conditionEditingLocked,
    conditionEditingMessage: selected.conditionEditingMessage,
  );

  return EventBuilderReadModel(
    events: [patched, ...base.events.skip(1)],
    mapId: base.mapId,
    mapTitle: base.mapTitle,
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
    scenes: [
      _eventScene(
        'scene_existing',
        'Scène existante',
        declaredOutcomes: [
          SceneOutcome(id: 'completed', label: 'Terminé'),
        ],
        consumedEventId: 'evt_existing',
      ),
    ],
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

ProjectManifest _eventProjectWithWorldRules() {
  return _eventProject().copyWith(
    scenes: [
      _eventSceneWithSetFact(
        'scene_existing',
        'Scène existante',
        factId: 'fact_started',
        declaredOutcomes: [
          SceneOutcome(id: 'completed', label: 'Terminé'),
        ],
      ),
    ],
    worldRules: [
      WorldRuleDefinition(
        id: 'rule_port_observed',
        label: 'Règle port observé',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_started',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'npc_rival',
          label: 'Rival au port',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityVisible,
        ),
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

SceneAsset _eventScene(
  String id,
  String name, {
  List<SceneOutcome> declaredOutcomes = const [],
  String? consumedEventId,
}) {
  final hasConsequence = consumedEventId != null;
  return SceneAsset(
    id: id,
    name: name,
    declaredOutcomes: declaredOutcomes,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        if (hasConsequence)
          SceneNode(
            id: 'node_mark_consumed',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.markEventConsumed(
                mapId: 'map_port',
                eventId: consumedEventId,
              ),
            ),
          ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: hasConsequence ? 'node_mark_consumed' : 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
        if (hasConsequence)
          SceneEdge(
            id: 'edge_consumed_end',
            fromNodeId: 'node_mark_consumed',
            fromPortId: 'completed',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
}

SceneAsset _eventSceneWithSetFact(
  String id,
  String name, {
  required String factId,
  List<SceneOutcome> declaredOutcomes = const [],
}) {
  return SceneAsset(
    id: id,
    name: name,
    declaredOutcomes: declaredOutcomes,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_fact',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_fact_end',
          fromNodeId: 'node_set_fact',
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

Future<void> _tapCentralBuilderTarget(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: _eventBuilderCentralScrollable(),
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
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
