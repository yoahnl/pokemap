import 'package:avelune_studio/presentation/features/events/standard_event_template_form.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_landing.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets('guided map picker loads only the chosen map once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requested = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StandardEventTemplateForm(
            project: _project().copyWith(
              maps: [
                ..._project().maps,
                const ProjectMapEntry(
                  id: 'second',
                  name: 'Jardin',
                  relativePath: 'maps/second.json',
                ),
                const ProjectMapEntry(
                  id: 'unrelated',
                  name: 'Autre',
                  relativePath: 'maps/unrelated.json',
                ),
              ],
            ),
            maps: [_map()],
            itemOptions: const {},
            loadMap: (id) async {
              requested.add(id);
              return _map().copyWith(id: id);
            },
            onSave: (_) async => true,
            onAdvanced: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requested, isEmpty);
    StudioSelect picker() => tester.widget<StudioSelect>(
      find.byKey(const ValueKey('standard-event-map')),
    );
    expect(picker().options.keys, ['room', 'second', 'unrelated']);
    picker().onChanged!('second');
    await tester.pumpAndSettle();
    expect(requested, ['second']);
    expect(
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('standard-event-entity')),
          )
          .options
          .keys,
      ['guide', 'other'],
    );
    picker().onChanged!('room');
    await tester.pumpAndSettle();
    picker().onChanged!('second');
    await tester.pumpAndSettle();
    expect(requested, ['second']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'history opens guided event authoring without creating a blank draft',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final search = TextEditingController();
      final scroll = ScrollController();
      addTearDown(search.dispose);
      addTearDown(scroll.dispose);
      var opened = 0;
      var created = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: NarrativeOverviewLanding(
              overview: NarrativeOverview(
                stories: [],
                facts: [],
                interactions: [],
                stepsById: {},
                stepLinks: {},
                factLinks: {},
                dirtyCount: 0,
              ),
              project: _project(),
              scenes: const [],
              dialogues: const [],
              events: const [],
              search: search,
              onSearch: (_) {},
              resultsScroll: scroll,
              onLibrary: () {},
              onCreateStory: null,
              onCreateScene: null,
              onCreateEvent: () => created++,
              onProgression: null,
              onScenes: null,
              onEvents: () => opened++,
              onVerification: null,
              onOpenStory: (_) {},
              onOpenStep: (_, _) {},
              onOpenScene: null,
              onOpenInteraction: (_) {},
              onOpenDialogue: null,
              onOpenEvent: null,
              onOpenMap: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final guided = find.byKey(const ValueKey('overview-guided-events'));
      expect(guided, findsOneWidget);
      await tester.ensureVisible(guided);
      await tester.tap(guided);
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(created, 0);
    },
  );

  testWidgets('a removed catalog item blocks the guided save', (tester) async {
    await _open(
      tester,
      initial: StandardEventTemplateSpec(
        kind: StandardEventTemplateKind.pickup,
        mapId: 'room',
        entityId: 'guide',
        name: 'Objet',
        parameters: const {
          'itemId': 'removed',
          'quantity': 1,
          'characterId': 'person',
        },
      ),
    );
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('standard-event-save')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(const ValueKey('standard-event-problem')),
      findsOneWidget,
    );
  });

  for (final kind in StandardEventTemplateKind.values) {
    testWidgets('${kind.name} previews both states with selected resources', (
      tester,
    ) async {
      final initial = StandardEventTemplateSpec(
        kind: kind,
        mapId: 'room',
        entityId: 'guide',
        name: 'Événement de démonstration',
        parameters: switch (kind) {
          StandardEventTemplateKind.conditionalNpc => _spec().parameters,
          StandardEventTemplateKind.pickup => const {
            'itemId': 'key',
            'quantity': 1,
            'characterId': 'person',
          },
          StandardEventTemplateKind.lockedDoor => const {
            'itemId': 'key',
            'destinationMapId': 'room',
            'destinationWarpId': 'arrival',
            'dialogueId': 'hello',
          },
          StandardEventTemplateKind.trainer => const {
            'trainerId': 'trainer',
            'dialogueId': 'hello',
            'alternateDialogueId': 'after',
            'characterId': 'person',
          },
        },
      );
      await _open(tester, initial: initial);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('standard-event-save')),
            )
            .onPressed,
        isNotNull,
      );
      final preview = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('standard-event-simulation')),
      );
      preview.onChanged!('true');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('standard-event-active-page')),
        findsOneWidget,
      );
      if (kind == StandardEventTemplateKind.pickup) {
        expect(
          find.text('Entité masquée et collision retirée'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('advanced actions publish the current recipe before navigation', (
    tester,
  ) async {
    final order = <String>[];
    await _open(
      tester,
      onSave: (_) async {
        order.add('saved');
        return true;
      },
      onAdvanced: (_) => order.add('advanced'),
    );
    final advanced = find.textContaining('ouvrir les actions avancées').first;
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(order, ['saved', 'advanced']);
  });

  testWidgets('failed publication never navigates away from guided settings', (
    tester,
  ) async {
    final opened = <String>[];
    await _open(tester, onSave: (_) async => false, onAdvanced: opened.add);
    final advanced = find.textContaining('ouvrir les actions avancées').first;
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(find.textContaining('Vos réglages restent ici'), findsOneWidget);
  });

  testWidgets('edits one logical NPC with named references and both pages', (
    tester,
  ) async {
    final submissions = <StandardEventTemplateSpec>[];
    await _open(
      tester,
      onSave: (spec) async {
        submissions.add(spec);
        return false;
      },
    );
    expect(find.text('Pages et conséquences'), findsOneWidget);
    expect(find.text('Guide après changement'), findsOneWidget);
    final picker = tester.widget<StudioSelect>(
      find.byKey(const ValueKey('standard-event-alternateDialogueId')),
    );
    expect(picker.options, {'hello': 'Bonjour', 'after': 'Après la rencontre'});
    picker.onChanged!('hello');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('standard-event-save')),
    );
    await tester.tap(find.byKey(const ValueKey('standard-event-save')));
    await tester.pumpAndSettle();
    expect(submissions.single.parameters['alternateDialogueId'], 'hello');
    expect(submissions.single.entityId, 'guide');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reusing a recipe selects a new owner without altering the first',
    (tester) async {
      final submissions = <StandardEventTemplateSpec>[];
      await _open(
        tester,
        onSave: (spec) async {
          submissions.add(spec);
          return false;
        },
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('standard-event-reuse')),
      );
      await tester.tap(find.byKey(const ValueKey('standard-event-reuse')));
      await tester.pumpAndSettle();
      final owner = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('standard-event-entity')),
      );
      expect(owner.value, isNull);
      owner.onChanged!('other');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('standard-event-save')),
      );
      await tester.tap(find.byKey(const ValueKey('standard-event-save')));
      await tester.pumpAndSettle();
      expect(submissions.single.entityId, 'other');
      expect(submissions.single.parameters['factId'], 'met');
      expect(_spec().entityId, 'guide');
    },
  );

  testWidgets(
    'invalid references prevent publication and explain the problem',
    (tester) async {
      await _open(
        tester,
        initial: StandardEventTemplateSpec(
          kind: StandardEventTemplateKind.conditionalNpc,
          mapId: 'room',
          entityId: 'guide',
          name: 'Guide après changement',
          parameters: {..._spec().parameters, 'factId': 'removed'},
        ),
      );
      final save = tester.widget<StudioButton>(
        find.byKey(const ValueKey('standard-event-save')),
      );
      expect(save.onPressed, isNull);
      expect(
        find.byKey(const ValueKey('standard-event-problem')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed publication keeps the local settings available', (
    tester,
  ) async {
    await _open(
      tester,
      onSave: (_) async => throw StateError('Conflit de révision'),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('standard-event-save')),
    );
    await tester.tap(find.byKey(const ValueKey('standard-event-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Conflit de révision'), findsOneWidget);
    expect(find.byType(StandardEventTemplateForm), findsOneWidget);
    expect(
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('standard-event-factId')),
          )
          .value,
      'met',
    );
  });
}

StandardEventTemplateSpec _spec() => StandardEventTemplateSpec(
  kind: StandardEventTemplateKind.conditionalNpc,
  mapId: 'room',
  entityId: 'guide',
  name: 'Guide après changement',
  parameters: const {
    'factId': 'met',
    'dialogueId': 'hello',
    'alternateDialogueId': 'after',
    'characterId': 'person',
  },
);

MapData _map() => MapData(
  id: 'room',
  name: 'Salle',
  size: const GridSize(width: 4, height: 4),
  layers: [TileLayer(id: 'ground', name: 'Sol', cells: List.filled(16, 0))],
  entities: const [
    MapEntity(
      id: 'guide',
      name: 'Guide',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
    MapEntity(
      id: 'other',
      name: 'Autre personnage',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  warps: const [
    MapWarp(
      id: 'arrival',
      pos: GridPos(x: 0, y: 0),
      targetMapId: 'room',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

ProjectManifest _project() => ProjectManifest(
  name: 'Monde synthétique',
  tilesets: const [],
  maps: const [
    ProjectMapEntry(id: 'room', name: 'Salle', relativePath: 'maps/room.json'),
  ],
  characters: const [
    ProjectCharacterEntry(
      id: 'person',
      name: 'Personnage',
      tilesetId: 'people',
    ),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'hello',
      name: 'Bonjour',
      relativePath: 'dialogues/hello.yarn',
    ),
    ProjectDialogueEntry(
      id: 'after',
      name: 'Après la rencontre',
      relativePath: 'dialogues/after.yarn',
    ),
  ],
  facts: [NarrativeFactDefinition(id: 'met', label: 'Rencontre effectuée')],
  trainers: const [
    ProjectTrainerEntry(
      id: 'trainer',
      name: 'Dresseur de démonstration',
      trainerClass: 'Dresseur',
      team: [ProjectTrainerPokemonEntry(speciesId: 'sample', level: 5)],
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [],
    legacyClaims: [],
  ),
);

Future<void> _open(
  WidgetTester tester, {
  StandardEventTemplateSpec? initial,
  Future<bool> Function(StandardEventTemplateSpec)? onSave,
  ValueChanged<String>? onAdvanced,
}) async {
  tester.view.physicalSize = const Size(1500, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: StandardEventTemplateForm(
          project: _project(),
          maps: [_map()],
          initial: initial ?? _spec(),
          itemOptions: const {'key': 'Clé de démonstration'},
          onSave: onSave ?? (_) async => true,
          onAdvanced: onAdvanced ?? (_) {},
          onCancel: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
