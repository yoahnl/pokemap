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
  ActorRouteTransientScope transientScope = ActorRouteTransientScope.route,
}) => SceneActionPayload.interactive(
  SceneInteractiveCommand.actorRoute(
    target:
        target ?? SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor'),
    steps: steps ?? _steps(),
    skippable: true,
    transientScope: transientScope,
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

SceneActionPayload _egress({List<SceneActorRouteStep>? steps}) => _route(
  target: SceneActorTarget.player(mapId: 'alpha'),
  steps:
      steps ??
      [
        SceneActorRouteStep.move(
          direction: EntityFacing.south,
          durationMs: 200,
          initialCollisionOwnerEntityId: 'actor',
        ),
      ],
);

Future<void> _tapStep(WidgetTester tester, int id, String action) async {
  final tool = find.byKey(ValueKey('actor-step-$id-$action'));
  await tester.ensureVisible(tool);
  await tester.tap(tool);
  await tester.pump();
}

void main() {
  for (final enabled in [false, true]) {
    testWidgets(
      'v2 imported scene route preserves all seven typed steps and render flag $enabled',
      (tester) async {
        final original = SceneActionPayload.fromJson(
          _route(
            transientScope: ActorRouteTransientScope.scene,
            steps: [
              ..._steps().take(2),
              SceneActorRouteStep.moveDiagonal(
                horizontal: EntityFacing.west,
                vertical: EntityFacing.north,
                durationMs: 350,
              ),
              ..._steps().skip(2).take(2),
              SceneActorRouteStep.renderAboveMap(enabled: enabled),
              _steps().last,
            ],
          ).toJson(),
        );
        final applied = <SceneNodePayload>[];
        await _pump(
          tester,
          current: original,
          injected: false,
          onApply: applied.add,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<StudioSelect>(
                _select('Restauration des effets temporaires'),
              )
              .value,
          'scene',
        );
        final stepTypes = tester.widget<StudioSelect>(
          _select('Action de l’étape 1'),
        );
        expect(
          stepTypes.options.keys.toSet(),
          SceneActorRouteStepKind.values.map((kind) => kind.name).toSet(),
        );
        expect(_select('Direction horizontale de l’étape 3'), findsOneWidget);
        expect(_select('Direction verticale de l’étape 3'), findsOneWidget);
        expect(
          tester
              .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, 'Acteur au premier plan'),
              )
              .value,
          enabled,
        );
        await _submit(tester);
        expect(applied.single, original);
        expect(
          SceneActionPayload.fromJson(
            (applied.single as SceneActionPayload).toJson(),
          ),
          original,
        );
      },
    );
  }

  testWidgets(
    'v2 imported scene route edits axes duration rendering and restoration scope',
    (tester) async {
      final original = _route(
        transientScope: ActorRouteTransientScope.scene,
        steps: [
          SceneActorRouteStep.moveDiagonal(
            horizontal: EntityFacing.west,
            vertical: EntityFacing.north,
            durationMs: 350,
          ),
          SceneActorRouteStep.renderAboveMap(enabled: true),
        ],
      );
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: original,
        injected: false,
        onApply: applied.add,
      );
      await tester.pumpAndSettle();
      await _pick(tester, 'Direction horizontale de l’étape 1', 'Est');
      await _pick(tester, 'Direction verticale de l’étape 1', 'Sud');
      await _enter(tester, 'actor-step-0-duration', '475');
      final toggle = find.widgetWithText(
        SwitchListTile,
        'Acteur au premier plan',
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      await _pick(
        tester,
        'Restauration des effets temporaires',
        'À la fin du trajet',
      );
      await _submit(tester);
      final first = applied.single as SceneActionPayload;
      expect(first.actionKind, original.actionKind);
      expect(first.parameters, original.parameters);
      final command =
          first.interactiveCommand as SceneActorRouteInteractiveCommand;
      expect(command.transientScope, ActorRouteTransientScope.route);
      expect(command.skippable, isTrue);
      expect(command.steps, [
        SceneActorRouteStep.moveDiagonal(
          horizontal: EntityFacing.east,
          vertical: EntityFacing.south,
          durationMs: 475,
        ),
        SceneActorRouteStep.renderAboveMap(enabled: false),
      ]);
      await _pick(
        tester,
        'Restauration des effets temporaires',
        'À la fin de la scène',
      );
      await _submit(tester);
      expect(
        (applied.last as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.actorRoute(
          target: command.target,
          steps: command.steps,
          skippable: true,
          transientScope: ActorRouteTransientScope.scene,
        ),
      );
    },
  );

  testWidgets(
    'v2 new route creates diagonal and foreground steps through guided controls',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, injected: false, onApply: applied.add);
      await _pick(
        tester,
        'Commande',
        _commands()
            .firstWhere((c) => c.id == NarrativeCommandIds.actorRoute)
            .label,
      );
      await _pick(tester, 'Carte de l’acteur', 'Alpha');
      expect(
        tester
            .widget<StudioSelect>(
              _select('Restauration des effets temporaires'),
            )
            .value,
        'route',
      );
      final add = find.byKey(const ValueKey('actor-add-step'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
      await _pick(tester, 'Action de l’étape 1', 'Avancer en diagonale');
      expect(_select('Personnage à quitter'), findsNothing);
      expect(_apply(tester).onPressed, isNotNull);
      await _submit(tester);
      final defaults =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        defaults.steps.single,
        SceneActorRouteStep.moveDiagonal(
          horizontal: EntityFacing.west,
          vertical: EntityFacing.north,
          durationMs: 200,
        ),
      );
      applied.clear();
      await _pick(tester, 'Direction horizontale de l’étape 1', 'Est');
      await _pick(tester, 'Direction verticale de l’étape 1', 'Sud');
      await _enter(tester, 'actor-step-0-duration', '125');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
      await _pick(tester, 'Action de l’étape 2', 'Afficher au premier plan');
      expect(find.byKey(const ValueKey('actor-step-1-duration')), findsNothing);
      final toggle = find.widgetWithText(
        SwitchListTile,
        'Acteur au premier plan',
      );
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      await _pick(
        tester,
        'Restauration des effets temporaires',
        'À la fin de la scène',
      );
      await _submit(tester);
      expect(
        (applied.single as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.actorRoute(
          target: SceneActorTarget.player(mapId: 'alpha'),
          transientScope: ActorRouteTransientScope.scene,
          steps: [
            SceneActorRouteStep.moveDiagonal(
              horizontal: EntityFacing.east,
              vertical: EntityFacing.south,
              durationMs: 125,
            ),
            SceneActorRouteStep.renderAboveMap(enabled: true),
          ],
        ),
      );
      await _pick(tester, 'Action de l’étape 2', 'Avancer en diagonale');
      await _submit(tester);
      final changed =
          (applied.last as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        changed.steps.last,
        SceneActorRouteStep.moveDiagonal(
          horizontal: EntityFacing.west,
          vertical: EntityFacing.north,
          durationMs: 200,
        ),
      );
    },
  );

  testWidgets('v2 diagonal rejects invalid duration and axes before applying', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    await _pump(
      tester,
      current: _route(
        steps: [
          SceneActorRouteStep.moveDiagonal(
            horizontal: EntityFacing.west,
            vertical: EntityFacing.north,
            durationMs: 200,
          ),
        ],
      ),
      onApply: applied.add,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StudioSelect>(_select('Direction horizontale de l’étape 1'))
          .options
          .keys
          .toSet(),
      {'west', 'east'},
    );
    expect(
      tester
          .widget<StudioSelect>(_select('Direction verticale de l’étape 1'))
          .options
          .keys
          .toSet(),
      {'north', 'south'},
    );
    for (final value in ['', '0', '-1', '0.5', '2147483648']) {
      await _enter(tester, 'actor-step-0-duration', value);
      expect(_apply(tester).onPressed, isNull);
    }
    await _enter(tester, 'actor-step-0-duration', '1');
    expect(_apply(tester).onPressed, isNotNull);
    tester
        .widget<StudioSelect>(_select('Direction horizontale de l’étape 1'))
        .onChanged!('north');
    await tester.pump();
    expect(_apply(tester).onPressed, isNull);
    await _pick(tester, 'Direction horizontale de l’étape 1', 'Ouest');
    tester
        .widget<StudioSelect>(_select('Direction verticale de l’étape 1'))
        .onChanged!('east');
    await tester.pump();
    expect(_apply(tester).onPressed, isNull);
    expect(applied, isEmpty);
    await _pick(tester, 'Direction verticale de l’étape 1', 'Sud');
    await _enter(tester, 'actor-step-0-duration', '2147483647');
    await _submit(tester);
    expect(
      ((applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand)
          .steps
          .single,
      SceneActorRouteStep.moveDiagonal(
        horizontal: EntityFacing.west,
        vertical: EntityFacing.south,
        durationMs: 2147483647,
      ),
    );
  });

  testWidgets(
    'v2 diagonal cannot silently inherit a cardinal collision owner',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: _egress(), onApply: applied.add);
      await tester.pumpAndSettle();
      await _pick(tester, 'Action de l’étape 1', 'Avancer en diagonale');
      expect(_apply(tester).onPressed, isNull);
      expect(_select('Personnage à quitter'), findsOneWidget);
      await _pick(tester, 'Personnage à quitter', 'Aucun');
      expect(_select('Personnage à quitter'), findsNothing);
      await _submit(tester);
      final command =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        command.steps.single,
        SceneActorRouteStep.moveDiagonal(
          horizontal: EntityFacing.west,
          vertical: EntityFacing.north,
          durationMs: 200,
        ),
      );
    },
  );

  testWidgets('face update yield hydrates and can be disabled without losing hold', (tester) async {
    final original = _route(steps: [
      SceneActorRouteStep.face(direction: EntityFacing.east, durationMs: 50, yieldAfter: true),
    ]);
    final applied = <SceneNodePayload>[];
    await _pump(tester, current: original, injected: false, onApply: applied.add);
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('actor-step-0-yield'));
    expect(toggle, findsOneWidget);
    await _submit(tester);
    expect(applied.single, original);
    applied.clear();
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await _submit(tester);
    final command = (applied.single as SceneActionPayload).interactiveCommand
        as SceneActorRouteInteractiveCommand;
    expect(command.steps.single, SceneActorRouteStep.face(
        direction: EntityFacing.east, durationMs: 50));
  });


  testWidgets(
    'egress stays unavailable in a 3D project even when its map is flat',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: _egress(),
        project: _project(spatial: true),
        loadMap: (id) async => _map(id),
        onApply: applied.add,
        injected: false,
      );
      await tester.pumpAndSettle();
      expect(_apply(tester).onPressed, isNull);
      expect(_select('Personnage à quitter'), findsNothing);
      expect(applied, isEmpty);
    },
  );

  testWidgets(
    'egress stale owner choice cannot bind a same-ID character from another map',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: _egress(
          steps: [
            SceneActorRouteStep.move(
              direction: EntityFacing.south,
              durationMs: 200,
            ),
          ],
        ),
        onApply: applied.add,
      );
      await tester.pumpAndSettle();
      final picker = tester.widget<StudioSelect>(
        _select('Personnage à quitter'),
      );
      final oldChoice = picker.options.entries
          .singleWhere((entry) => entry.value == 'alpha actor')
          .key;
      final oldSelect = picker.onChanged!;
      await _pick(tester, 'Carte de l’acteur', 'Beta');
      oldSelect(oldChoice);
      await tester.pump();
      await _submit(tester);
      final command =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(command.target, SceneActorTarget.player(mapId: 'beta'));
      expect(
        (command.steps.single as SceneActorMoveStep)
            .initialCollisionOwnerEntityId,
        isNull,
      );
    },
  );

  testWidgets('egress defaults to none and is chosen through the real picker', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    final ordinary = _egress(
      steps: [
        SceneActorRouteStep.move(
          direction: EntityFacing.south,
          durationMs: 200,
        ),
      ],
    );
    await _pump(
      tester,
      current: ordinary,
      onApply: applied.add,
      injected: false,
    );
    await tester.pumpAndSettle();
    expect(_select('Personnage à quitter'), findsOneWidget);
    expect(find.text('Aucun'), findsOneWidget);
    await _submit(tester);
    expect(applied.single, ordinary);
    await _pick(tester, 'Personnage à quitter', 'alpha actor');
    await _submit(tester);
    expect(applied.last, _egress());
  });

  testWidgets(
    'egress survives direction duration reorder add and delete edits',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: _egress(
          steps: [
            SceneActorRouteStep.face(direction: EntityFacing.east),
            (_egress().interactiveCommand as SceneActorRouteInteractiveCommand)
                .steps
                .single,
            SceneActorRouteStep.wait(durationMs: 0),
          ],
        ),
        onApply: applied.add,
      );
      await tester.pumpAndSettle();
      await _enter(tester, 'actor-step-1-duration', '350');
      await _pick(tester, 'Direction de l’étape 2', 'Ouest');
      await _tapStep(tester, 1, 'up');
      await _tapStep(tester, 2, 'delete');
      final add = find.byKey(const ValueKey('actor-add-step'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
      await _pick(tester, 'Action de l’étape 3', 'Attendre');
      await _enter(tester, 'actor-step-3-duration', '80');
      await _submit(tester);
      final payload = applied.single as SceneActionPayload;
      final command =
          payload.interactiveCommand as SceneActorRouteInteractiveCommand;
      expect(command.steps, [
        SceneActorRouteStep.move(
          direction: EntityFacing.west,
          durationMs: 350,
          initialCollisionOwnerEntityId: 'actor',
        ),
        SceneActorRouteStep.face(direction: EntityFacing.east),
        SceneActorRouteStep.wait(durationMs: 80),
      ]);
      expect(payload.actionKind, 'keep-action');
      expect(payload.parameters, const {'keep': 'parameter'});
    },
  );

  testWidgets(
    'egress keeps its reference when actor becomes NPC until explicitly removed',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: _egress(), onApply: applied.add);
      await tester.pumpAndSettle();
      await _pick(tester, 'Acteur', 'PNJ de la carte');
      await _pick(tester, 'PNJ', 'alpha actor');
      expect(_select('Personnage à quitter'), findsOneWidget);
      expect(_apply(tester).onPressed, isNull);
      expect(applied, isEmpty);
      await _pick(tester, 'Acteur', 'Joueur');
      await _submit(tester);
      expect(applied.single, _egress());
      await _pick(tester, 'Acteur', 'PNJ de la carte');
      await _pick(tester, 'PNJ', 'alpha actor');
      await _pick(tester, 'Personnage à quitter', 'Aucun');
      expect(_apply(tester).onPressed, isNotNull);
      await _submit(tester);
      final command =
          (applied.last as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        command.target,
        SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor'),
      );
      expect(
        (command.steps.single as SceneActorMoveStep)
            .initialCollisionOwnerEntityId,
        isNull,
      );
    },
  );

  testWidgets(
    'egress checks cumulative through state after toggle and reorder',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(
        tester,
        current: _egress(
          steps: [
            SceneActorRouteStep.through(enabled: false),
            (_egress().interactiveCommand as SceneActorRouteInteractiveCommand)
                .steps
                .single,
            SceneActorRouteStep.through(enabled: true),
          ],
        ),
        onApply: applied.add,
      );
      await tester.pumpAndSettle();
      final toggle = find.descendant(
        of: find.byKey(const ValueKey('actor-step-0')),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();
      expect(_apply(tester).onPressed, isNull);
      expect(_select('Personnage à quitter'), findsOneWidget);
      await tester.tap(toggle);
      await tester.pump();
      expect(_apply(tester).onPressed, isNotNull);
      await _tapStep(tester, 1, 'down');
      expect(_apply(tester).onPressed, isNull);
      await _tapStep(tester, 1, 'up');
      await _submit(tester);
      final command =
          (applied.single as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(
        (command.steps[1] as SceneActorMoveStep).initialCollisionOwnerEntityId,
        'actor',
      );
    },
  );

  testWidgets(
    'egress changing step kind requires explicit removal instead of losing the reference',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: _egress(), onApply: applied.add);
      await tester.pumpAndSettle();
      await _pick(tester, 'Action de l’étape 1', 'Attendre');
      expect(_apply(tester).onPressed, isNull);
      expect(_select('Personnage à quitter'), findsOneWidget);
      await _pick(tester, 'Action de l’étape 1', 'Avancer d’une case');
      await _submit(tester);
      expect(applied.single, _egress());
      await _pick(tester, 'Action de l’étape 1', 'Attendre');
      await _pick(tester, 'Personnage à quitter', 'Aucun');
      await _submit(tester);
      final command =
          (applied.last as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(command.steps.single, SceneActorRouteStep.wait(durationMs: 0));
    },
  );

  testWidgets(
    'egress map change never rebinds the same entity ID without an explicit selection',
    (tester) async {
      final applied = <SceneNodePayload>[];
      await _pump(tester, current: _egress(), onApply: applied.add);
      await tester.pumpAndSettle();
      await _pick(tester, 'Carte de l’acteur', 'Beta');
      expect(_apply(tester).onPressed, isNull);
      expect(_select('Personnage à quitter'), findsOneWidget);
      expect(applied, isEmpty);
      await _pick(tester, 'Carte de l’acteur', 'Alpha');
      await _submit(tester);
      expect(applied.single, _egress());
      await _pick(tester, 'Carte de l’acteur', 'Beta');
      await _pick(tester, 'Personnage à quitter', 'beta actor');
      await _submit(tester);
      final command =
          (applied.last as SceneActionPayload).interactiveCommand
              as SceneActorRouteInteractiveCommand;
      expect(command.target, SceneActorTarget.player(mapId: 'beta'));
      expect(
        (command.steps.single as SceneActorMoveStep)
            .initialCollisionOwnerEntityId,
        'actor',
      );
    },
  );

  testWidgets(
    'egress ignores stale map success and errors after explicit reselection',
    (tester) async {
      for (final error in [false, true]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final first = Completer<MapData>();
        final second = Completer<MapData>();
        final applied = <SceneNodePayload>[];
        await _pump(
          tester,
          current: _egress(),
          loadMap: (id) => id == 'alpha' ? first.future : second.future,
          onApply: applied.add,
        );
        await _pick(tester, 'Carte de l’acteur', 'Beta');
        second.complete(_map('beta'));
        await tester.pumpAndSettle();
        expect(_apply(tester).onPressed, isNull);
        await _pick(tester, 'Personnage à quitter', 'beta actor');
        if (error) {
          first.completeError(StateError('stale alpha owner'));
        } else {
          first.complete(_map('alpha'));
        }
        await tester.pumpAndSettle();
        await _submit(tester);
        final command =
            (applied.single as SceneActionPayload).interactiveCommand
                as SceneActorRouteInteractiveCommand;
        expect(command.target, SceneActorTarget.player(mapId: 'beta'));
        expect(
          (command.steps.single as SceneActorMoveStep)
              .initialCollisionOwnerEntityId,
          'actor',
        );
      }
    },
  );

  testWidgets(
    'egress refuses ghost ambiguous non-NPC and non-1x1 contacts before Apply',
    (tester) async {
      final entity = _map('alpha').entities.single;
      for (final mode in [
        'sign',
        'ghost',
        'missing-character',
        'duplicate-entity',
        'duplicate-character',
        'wide-contact',
        'default-tall',
        'shifted-contact',
        'removed',
        'spatial',
        'wrong-map',
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final applied = <SceneNodePayload>[];
        final project = _project();
        final entities = switch (mode) {
          'sign' => [entity.copyWith(kind: MapEntityKind.sign)],
          'ghost' => [entity.copyWith(npc: const MapEntityNpcData())],
          'missing-character' => [
            entity.copyWith(
              npc: const MapEntityNpcData(characterId: 'missing'),
            ),
          ],
          'duplicate-entity' => [
            entity,
            entity.copyWith(kind: MapEntityKind.sign),
          ],
          'wide-contact' => [
            entity.copyWith(size: const GridSize(width: 2, height: 1)),
          ],
          'default-tall' => [
            entity.copyWith(size: const GridSize(width: 1, height: 2)),
          ],
          'shifted-contact' => [
            entity.copyWith(
              size: const GridSize(width: 2, height: 1),
              properties: const {
                'collision.width': '1',
                'collision.height': '1',
                'collision.offsetX': '1',
              },
            ),
          ],
          'removed' => <MapEntity>[],
          _ => [entity],
        };
        await _pump(
          tester,
          current: _egress(),
          project: mode == 'duplicate-character'
              ? project.copyWith(
                  characters: [...project.characters, ...project.characters],
                )
              : project,
          loadMap: (id) async => _map(
            mode == 'wrong-map' ? 'beta' : id,
            entities: entities,
            spatial: mode == 'spatial',
          ),
          onApply: applied.add,
        );
        await tester.pumpAndSettle();
        expect(_apply(tester).onPressed, isNull, reason: mode);
        expect(applied, isEmpty);
        if (mode != 'spatial' && mode != 'wrong-map') {
          await _pick(tester, 'Personnage à quitter', 'Aucun');
          expect(_apply(tester).onPressed, isNotNull, reason: mode);
        }
      }
    },
  );

  testWidgets(
    'egress accepts a tall trainer-backed character with a canonical 1x1 contact',
    (tester) async {
      final applied = <SceneNodePayload>[];
      final entity = _map('alpha').entities.single.copyWith(
        size: const GridSize(width: 1, height: 2),
        properties: const {'collision.height': '1', 'collision.offsetY': '0'},
        npc: const MapEntityNpcData(trainerId: 'trainer'),
      );
      await _pump(
        tester,
        current: _egress(),
        project: _project().copyWith(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer',
              name: 'Original trainer',
              trainerClass: 'QA',
              characterId: 'actor-character',
            ),
          ],
        ),
        loadMap: (id) async => _map(id, entities: [entity]),
        onApply: applied.add,
      );
      await tester.pumpAndSettle();
      expect(_select('Personnage à quitter'), findsOneWidget);
      expect(_apply(tester).onPressed, isNotNull);
      await _submit(tester);
      expect(applied.single, _egress());
    },
  );
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
