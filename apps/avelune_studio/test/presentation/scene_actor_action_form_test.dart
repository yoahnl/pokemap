import 'dart:async';

import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

List<NarrativeCommandDescriptor> _commands() => [
  for (final command in NarrativeCommandCatalog.canonical().commands)
    if ([
      NarrativeCommandIds.actorRoute,
      NarrativeCommandIds.actorVisibility,
    ].contains(command.id))
      NarrativeCommandDescriptor(
        id: command.id,
        label: command.label,
        description: command.description,
        backend: command.backend,
        capabilities: const NarrativeCommandCapabilities.supported(),
        fgLotId: command.fgLotId,
        wireId: command.wireId,
        parameters: command.parameters,
        isPersistent: command.isPersistent,
        isAwaitable: command.isAwaitable,
      ),
];

ProjectManifest _project({
  List<ProjectCharacterEntry>? characters,
  List<CinematicMediaAsset>? media,
  bool spatial = false,
}) => ProjectManifest(
  name: 'Original actor UI QA',
  maps: const [
    ProjectMapEntry(
      id: 'alpha',
      name: 'Alpha',
      relativePath: 'maps/alpha.json',
    ),
    ProjectMapEntry(id: 'beta', name: 'Beta', relativePath: 'maps/beta.json'),
  ],
  settings: ProjectSettings(
    dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
  ),
  tilesets: const [
    ProjectTilesetEntry(
      id: 'sheet',
      name: 'Original QA sheet',
      relativePath: 'assets/sheet.png',
    ),
  ],
  characters:
      characters ??
      const [
        ProjectCharacterEntry(
          id: 'actor-character',
          name: 'Original actor',
          tilesetId: 'sheet',
        ),
      ],
  cinematicMediaAssets:
      media ??
      [
        for (final id in ['door', 'bell'])
          CinematicMediaAsset(
            id: id,
            label: id == 'door' ? 'Porte' : 'Cloche',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'audio/$id.wav',
          ),
      ],
);

MapData _map(String id, {List<MapEntity>? entities, bool spatial = false}) =>
    MapData(
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      id: id,
      name: id,
      size: const GridSize(width: 4, height: 4),
      spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
      entities:
          entities ??
          [
            MapEntity(
              id: 'actor',
              name: '$id actor',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 1, y: 1),
              npc: const MapEntityNpcData(characterId: 'actor-character'),
            ),
          ],
    );

List<SceneActorRouteStep> _steps() => [
  SceneActorRouteStep.face(direction: EntityFacing.east, durationMs: 50),
  SceneActorRouteStep.move(direction: EntityFacing.south, durationMs: 200),
  SceneActorRouteStep.wait(durationMs: 0),
  SceneActorRouteStep.through(enabled: true),
  SceneActorRouteStep.sound(mediaAssetId: 'bell', gain: 0.35),
];

SceneActionPayload _route({
  SceneActorTarget? target,
  List<SceneActorRouteStep>? steps,
}) => SceneActionPayload.interactive(
  SceneInteractiveCommand.actorRoute(
    target:
        target ?? SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor'),
    steps: steps ?? _steps(),
    skippable: true,
  ),
  actionKind: 'keep-action',
  parameters: const {'keep': 'parameter'},
);

Future<void> _pump(
  WidgetTester tester, {
  ProjectManifest? project,
  SceneActionPayload? current,
  Future<MapData> Function(String)? loadMap,
  required ValueChanged<SceneNodePayload> onApply,
  bool injected = true,
  bool loader = true,
}) async {
  tester.view.physicalSize = const Size(900, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: SceneActionForm(
              project: project ?? _project(),
              current: current,
              commandCatalog: injected ? _commands() : null,
              loadMap: loader ? loadMap ?? (id) async => _map(id) : null,
              onApply: onApply,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _select(String label) =>
    find.byWidgetPredicate((w) => w is StudioSelect && w.label == label);
Future<void> _pick(WidgetTester tester, String label, String option) async {
  final field = find.descendant(
    of: _select(label),
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

StudioButton _apply(WidgetTester tester) => tester
    .widgetList<StudioButton>(find.byType(StudioButton))
    .singleWhere(
      (b) => b.label == 'Ajouter l’action' || b.label == 'Appliquer l’action',
    );
Future<void> _submit(WidgetTester tester) async {
  final button = find.byWidgetPredicate(
    (w) =>
        w is StudioButton &&
        (w.label == 'Ajouter l’action' || w.label == 'Appliquer l’action'),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

void main() {
  for (final route in [false, true]) {
    testWidgets(
      'default catalogue edits ${route ? 'actor route' : 'actor visibility'} without injected capabilities',
      (tester) async {
        final original = route
            ? _route()
            : SceneActionPayload.interactive(
                SceneInteractiveCommand.actorVisibility(
                  target: SceneActorTarget.entity(
                    mapId: 'alpha',
                    entityId: 'actor',
                  ),
                  visible: false,
                ),
              );
        final applied = <SceneNodePayload>[];
        await _pump(
          tester,
          current: original,
          injected: false,
          onApply: applied.add,
        );
        await tester.pumpAndSettle();
        expect(_select('Carte de l’acteur'), findsOneWidget);
        expect(_apply(tester).onPressed, isNotNull);
        await _submit(tester);
        expect(applied.single, original);
      },
    );
  }

  testWidgets(
    'new route is authored with guided target and every ordered step',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, onApply: applied.add);
      await _pick(
        tester,
        'Commande',
        _commands()
            .firstWhere((c) => c.id == NarrativeCommandIds.actorRoute)
            .label,
      );
      expect(_apply(tester).onPressed, isNull);
      await _pick(tester, 'Carte de l’acteur', 'Alpha');
      await _pick(tester, 'Acteur', 'PNJ de la carte');
      await _pick(tester, 'PNJ', 'alpha actor');
      for (var index = 0; index < 5; index++) {
        final add = find.byKey(const ValueKey('actor-add-step'));
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pump();
        await _pick(
          tester,
          'Action de l’étape ${index + 1}',
          [
            'Se tourner',
            'Avancer d’une case',
            'Attendre',
            'Traverser les obstacles',
            'Jouer un son',
          ][index],
        );
        if (index < 2) {
          await _pick(
            tester,
            'Direction de l’étape ${index + 1}',
            index == 0 ? 'Est' : 'Sud',
          );
        }
        if (index < 3) {
          await _enter(
            tester,
            'actor-step-$index-duration',
            ['50', '200', '0'][index],
          );
        }
        if (index == 3) {
          final toggle = find.widgetWithText(
            SwitchListTile,
            'Traversée autorisée',
          );
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pump();
        }
        if (index == 4) {
          await _pick(tester, 'Son de l’étape 5', 'Cloche');
          await _enter(tester, 'actor-step-4-gain', '0.35');
        }
      }
      await _submit(tester);
      final command =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        command.target,
        SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor'),
      );
      expect(command.steps, _steps());
      expect(command.skippable, isFalse);
    },
  );

  testWidgets(
    'new visibility action chooses its player map without a raw ID field',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, onApply: applied.add);
      await _pick(
        tester,
        'Commande',
        _commands()
            .firstWhere((c) => c.id == NarrativeCommandIds.actorVisibility)
            .label,
      );
      await _pick(tester, 'Carte de l’acteur', 'Beta');
      await _submit(tester);
      expect(
        (applied.single as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.actorVisibility(
          target: SceneActorTarget.player(mapId: 'beta'),
          visible: true,
        ),
      );
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'guided route hydrates every typed step and preserves payload metadata',
    (tester) async {
      final original = _route();
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: original, onApply: applied.add);
      await tester.pumpAndSettle();
      expect(_select('Carte de l’acteur'), findsOneWidget);
      expect(_select('PNJ'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('actor-step-0-duration')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('actor-step-4-gain')), findsOneWidget);
      expect(_apply(tester).onPressed, isNotNull);
      await _submit(tester);
      expect(applied.single, original);
      expect(
        (original.interactiveCommand as SceneActorRouteInteractiveCommand)
            .steps,
        _steps(),
      );
    },
  );

  testWidgets(
    'route steps add reorder delete and apply through the actual callback',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: _route(), onApply: applied.add);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('actor-step-1-up')));
      await tester.tap(find.byKey(const ValueKey('actor-step-1-up')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('actor-step-2-delete')),
      );
      await tester.tap(find.byKey(const ValueKey('actor-step-2-delete')));
      await tester.pump();
      final add = find.byKey(const ValueKey('actor-add-step'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
      await _pick(tester, 'Action de l’étape 5', 'Attendre');
      await _enter(tester, 'actor-step-5-duration', '75');
      await _submit(tester);
      final command =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(command.steps, [
        _steps()[1],
        _steps()[0],
        _steps()[3],
        _steps()[4],
        SceneActorRouteStep.wait(durationMs: 75),
      ]);
    },
  );

  for (final entity in [false, true]) {
    testWidgets(
      'visibility ${entity ? 'NPC' : 'player'} round trips without changing collision metadata',
      (tester) async {
        final original = SceneActionPayload.interactive(
          SceneInteractiveCommand.actorVisibility(
            target: entity
                ? SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor')
                : SceneActorTarget.player(mapId: 'alpha'),
            visible: false,
          ),
          actionKind: 'keep',
          parameters: const {'blocksMovement': 'true'},
        );
        final applied = <SceneNodePayload>[];
        await _pump(tester, current: original, onApply: applied.add);
        await tester.pumpAndSettle();
        expect(_select('Carte de l’acteur'), findsOneWidget);
        expect(_apply(tester).onPressed, isNotNull);
        await _submit(tester);
        expect(applied.single, original);
      },
    );
  }

  for (final fixture in [
    (
      'sign',
      const MapEntity(
        id: 'actor',
        kind: MapEntityKind.sign,
        pos: GridPos(x: 1, y: 1),
      ),
    ),
    (
      'empty NPC',
      const MapEntity(
        id: 'actor',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(),
      ),
    ),
    (
      'unknown character',
      const MapEntity(
        id: 'actor',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(characterId: 'missing'),
      ),
    ),
  ]) {
    testWidgets(
      'guided actor refuses ${fixture.$1} without replacing the existing payload',
      (tester) async {
        final applied = <SceneNodePayload>[];
        final original = _route();
        await _pump(
          tester,
          current: original,
          loadMap: (id) async => _map(id, entities: [fixture.$2]),
          onApply: applied.add,
        );
        await tester.pumpAndSettle();
        expect(_select('PNJ'), findsOneWidget);
        expect(tester.widget<StudioSelect>(_select('PNJ')).options, isEmpty);
        expect(_apply(tester).onPressed, isNull);
        expect(applied, isEmpty);
        expect(original, _route());
      },
    );
  }

  testWidgets(
    'duplicate NPC and character IDs remain unavailable in guided pickers',
    (tester) async {
      for (final duplicateCharacter in [false, true]) {
        final project = _project();
        final map = _map('alpha');
        await _pump(
          tester,
          current: _route(),
          project: duplicateCharacter
              ? project.copyWith(
                  characters: [...project.characters, ...project.characters],
                )
              : project,
          loadMap: (id) async => duplicateCharacter
              ? map
              : map.copyWith(entities: [...map.entities, ...map.entities]),
          onApply: (_) => fail('invalid target applied'),
        );
        await tester.pumpAndSettle();
        expect(_select('PNJ'), findsOneWidget);
        expect(tester.widget<StudioSelect>(_select('PNJ')).options, isEmpty);
        expect(_apply(tester).onPressed, isNull);
      }
    },
  );

  testWidgets(
    'trainer-backed NPC is selectable only with unique trainer and character references',
    (tester) async {
      const trainer = ProjectTrainerEntry(
        id: 'trainer',
        name: 'Original trainer',
        trainerClass: 'QA',
        characterId: 'actor-character',
      );
      for (final mode in ['known', 'duplicate', 'missing-character']) {
        final project = _project().copyWith(
          trainers: [trainer, if (mode == 'duplicate') trainer],
          characters: mode == 'missing-character' ? [] : _project().characters,
        );
        final applied = <SceneNodePayload>[];
        await _pump(
          tester,
          current: _route(),
          project: project,
          onApply: applied.add,
          loadMap: (id) async => _map(
            id,
            entities: const [
              MapEntity(
                id: 'actor',
                name: 'Trainer actor',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 1, y: 1),
                npc: MapEntityNpcData(trainerId: 'trainer'),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(_apply(tester).onPressed != null, mode == 'known');
        if (mode == 'known') {
          await _submit(tester);
          expect(applied.single, _route());
        } else {
          expect(applied, isEmpty);
        }
      }
    },
  );

  testWidgets(
    'wrong map spatial map missing loader and duplicate map block Apply',
    (tester) async {
      for (final mode in ['wrong', 'spatial', 'missing-loader', 'duplicate']) {
        final project = _project();
        await _pump(
          tester,
          current: _route(),
          loader: mode != 'missing-loader',
          project: mode == 'duplicate'
              ? project.copyWith(maps: [...project.maps, project.maps.first])
              : project,
          loadMap: (id) async => mode == 'wrong'
              ? _map('other')
              : _map(id, spatial: mode == 'spatial'),
          onApply: (_) => fail('invalid map applied'),
        );
        await tester.pumpAndSettle();
        expect(_select('Carte de l’acteur'), findsOneWidget);
        expect(_apply(tester).onPressed, isNull);
      }
    },
  );

  testWidgets(
    'invalid duration and nonfinite or out of bounds gain block the real Apply callback',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: _route(), onApply: applied.add);
      await tester.pumpAndSettle();
      expect(_apply(tester).onPressed, isNotNull);
      for (final value in ['', '-1', '0.5', '2147483648']) {
        await _enter(tester, 'actor-step-0-duration', value);
        expect(_apply(tester).onPressed, isNull);
      }
      await _enter(tester, 'actor-step-0-duration', '0');
      for (final value in ['0', '-1', '0.5', '2147483648']) {
        await _enter(tester, 'actor-step-1-duration', value);
        expect(_apply(tester).onPressed, isNull);
      }
      await _enter(tester, 'actor-step-1-duration', '1');
      for (final value in ['', 'NaN', 'Infinity', '-0.01', '1.01']) {
        await _enter(tester, 'actor-step-4-gain', value);
        expect(_apply(tester).onPressed, isNull);
      }
      await _enter(tester, 'actor-step-4-gain', '0');
      expect(_apply(tester).onPressed, isNotNull);
      expect(applied, isEmpty);
      await _submit(tester);
      expect(applied, hasLength(1));
    },
  );

  testWidgets(
    'sound picker counts the whole registry and blocks removed or looping sounds',
    (tester) async {
      final project = _project();
      for (final mode in ['duplicate', 'loop', 'removed']) {
        final bell = project.cinematicMediaAssets.last;
        final media = [
          project.cinematicMediaAssets.first,
          if (mode != 'removed')
            CinematicMediaAsset(
              id: bell.id,
              label: bell.label,
              kind: bell.kind,
              relativePath: bell.relativePath,
              loopByDefault: mode == 'loop',
            ),
          if (mode == 'duplicate')
            CinematicMediaAsset(
              id: bell.id,
              label: bell.label,
              kind: CinematicMediaAssetKind.music,
              relativePath: bell.relativePath,
            ),
        ];
        await _pump(
          tester,
          current: _route(),
          project: project.copyWith(cinematicMediaAssets: media),
          onApply: (_) => fail('invalid sound applied'),
        );
        await tester.pumpAndSettle();
        expect(_select('Son de l’étape 5'), findsOneWidget);
        expect(
          tester.widget<StudioSelect>(_select('Son de l’étape 5')).options.keys,
          ['door'],
        );
        expect(_apply(tester).onPressed, isNull);
      }
    },
  );

  testWidgets('quick map changes ignore stale success and stale errors', (
    tester,
  ) async {
    for (final error in [false, true]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final first = Completer<MapData>();
      final second = Completer<MapData>();
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: _route(),
        loadMap: (id) => id == 'alpha' ? first.future : second.future,
        onApply: applied.add,
      );
      expect(_apply(tester).onPressed, isNull);
      await _pick(tester, 'Carte de l’acteur', 'Beta');
      second.complete(_map('beta'));
      await tester.pumpAndSettle();
      await _pick(tester, 'PNJ', 'beta actor');
      if (error) {
        first.completeError(StateError('stale alpha'));
      } else {
        first.complete(_map('alpha'));
      }
      await tester.pumpAndSettle();
      expect(_apply(tester).onPressed, isNotNull);
      await _submit(tester);
      final command =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        command.target,
        SceneActorTarget.entity(mapId: 'beta', entityId: 'actor'),
      );
      expect(command.steps, _steps());
    }
  });

  testWidgets(
    'actor commands are absent from a 3D project even with supported test descriptors',
    (tester) async {
      await _pump(
        tester,
        project: _project(spatial: true),
        onApply: (_) => fail('3D actor applied'),
      );
      final commands = tester.widget<StudioSelect>(_select('Commande')).options;
      expect(commands.containsKey(NarrativeCommandIds.actorRoute), isFalse);
      expect(
        commands.containsKey(NarrativeCommandIds.actorVisibility),
        isFalse,
      );
      expect(_apply(tester).onPressed, isNull);
    },
  );
}
