import 'dart:async';

import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    ProjectManifest? project,
    SceneNodePayload? current,
    Future<MapData> Function(String)? loadMap,
    bool mapLoaderAvailable = true,
    required ValueChanged<SceneNodePayload> onApply,
  }) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 440,
            child: SceneActionForm(
              project: project ?? _project(),
              current: current,
              loadMap: mapLoaderAvailable
                  ? loadMap ?? (id) async => _map(id)
                  : null,
              onApply: onApply,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder select(String label) => find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == label,
  );

  Future<void> pick(WidgetTester tester, String label, String value) async {
    await tester.tap(
      find.descendant(
        of: select(label),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  StudioButton apply(WidgetTester tester) => tester.widget<StudioButton>(
    find.byWidgetPredicate(
      (widget) =>
          widget is StudioButton &&
          (widget.label == 'Ajouter l’action' ||
              widget.label == 'Appliquer l’action'),
    ),
  );

  testWidgets('2D map arrival points produce a typed warp with defaults', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    final loaded = <String>[];
    await pump(
      tester,
      loadMap: (id) async {
        loaded.add(id);
        return _map(id);
      },
      onApply: applied.add,
    );
    await pick(tester, 'Commande', 'Téléporter');
    expect(apply(tester).onPressed, isNull);
    await pick(tester, 'Carte de destination', 'Village');
    expect(loaded, ['village']);
    expect(apply(tester).onPressed, isNull);
    await pick(tester, 'Point d’arrivée', 'Point d’arrivée 1 · (2, 3)');
    expect(find.text('Conserver la direction'), findsOneWidget);
    expect(find.text('Transition de la carte'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('village-entry'), findsNothing);
    expect(apply(tester).onPressed, isNotNull);
    await tester.tap(find.text('Ajouter l’action'));
    final command = (applied.single as SceneActionPayload).interactiveCommand!;
    expect(command, isA<SceneWarpInteractiveCommand>());
    expect(command.toJson(), {
      'kind': 'warp',
      'destinationMapId': 'village',
      'warpId': 'village-entry',
      'transition': 'mapDefault',
    });
  });

  testWidgets('arrival direction and transition selectors keep typed values', (
    tester,
  ) async {
    final applied = <SceneNodePayload>[];
    await pump(tester, onApply: applied.add);
    await pick(tester, 'Commande', 'Téléporter');
    await pick(tester, 'Carte de destination', 'Village');
    await pick(tester, 'Point d’arrivée', 'Point d’arrivée 1 · (2, 3)');
    await pick(tester, 'Transition', 'Sans transition');
    for (final facing in {
      'Nord': 'north',
      'Sud': 'south',
      'Est': 'east',
      'Ouest': 'west',
    }.entries) {
      await pick(tester, 'Direction à l’arrivée', facing.key);
      await tester.tap(find.text('Ajouter l’action'));
      expect(
        (applied.last as SceneActionPayload).interactiveCommand!.toJson(),
        {
          'kind': 'warp',
          'destinationMapId': 'village',
          'warpId': 'village-entry',
          'arrivalFacing': facing.value,
          'transition': 'none',
        },
      );
    }
    await pick(tester, 'Direction à l’arrivée', 'Conserver la direction');
    await pick(tester, 'Transition', 'Transition de la carte');
    await tester.tap(find.text('Ajouter l’action'));
    final json = (applied.last as SceneActionPayload).interactiveCommand!
        .toJson();
    expect(json.containsKey('arrivalFacing'), isFalse);
    expect(json['transition'], 'mapDefault');
  });

  testWidgets('editing a warp round trips its options and opaque metadata', (
    tester,
  ) async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.fromJson({
        'kind': 'warp',
        'destinationMapId': 'village',
        'warpId': 'village-entry',
        'arrivalFacing': 'east',
        'transition': 'none',
      }),
      actionKind: 'imported-transfer',
      parameters: const {'sourceEvent': '12'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: original, onApply: applied.add);
    expect(find.text('Village'), findsOneWidget);
    expect(find.text('Point d’arrivée 1 · (2, 3)'), findsOneWidget);
    expect(find.text('Est'), findsOneWidget);
    expect(find.text('Sans transition'), findsOneWidget);
    expect(find.textContaining('paramètres avancés'), findsNothing);
    expect(apply(tester).onPressed, isNotNull);
    expect(applied, isEmpty);
    await tester.tap(find.text('Appliquer l’action'));
    expect(applied.single, original);
  });

  testWidgets('changing destination clears even a shared arrival point ID', (
    tester,
  ) async {
    await pump(
      tester,
      current: SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
          destinationMapId: 'village',
          warpId: 'shared-entry',
        ),
      ),
      loadMap: (id) async => _map(id).copyWith(
        warps: [
          MapWarp(
            id: 'shared-entry',
            pos: const GridPos(x: 2, y: 3),
            targetMapId: 'other',
            targetPos: const GridPos(x: 1, y: 1),
          ),
        ],
      ),
      onApply: (_) => fail('A new arrival point must be chosen'),
    );
    expect(apply(tester).onPressed, isNotNull);
    await pick(tester, 'Carte de destination', 'Forêt');
    expect(
      tester.widget<StudioSelect>(select('Point d’arrivée')).value,
      isNull,
    );
    expect(apply(tester).onPressed, isNull);
  });

  testWidgets('late map response cannot restore stale arrival points', (
    tester,
  ) async {
    final first = Completer<MapData>(), second = Completer<MapData>();
    await pump(
      tester,
      loadMap: (id) => id == 'village' ? first.future : second.future,
      onApply: (_) {},
    );
    await pick(tester, 'Commande', 'Téléporter');
    await pick(tester, 'Carte de destination', 'Village');
    await pick(tester, 'Carte de destination', 'Forêt');
    second.complete(_map('forest'));
    await tester.pumpAndSettle();
    first.complete(_map('village'));
    await tester.pumpAndSettle();
    final arrival = tester.widget<StudioSelect>(select('Point d’arrivée'));
    expect(arrival.options.keys, ['forest-entry']);
    expect(apply(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a map response after disposal does not update the form', (
    tester,
  ) async {
    final pending = Completer<MapData>();
    var requested = false;
    await pump(
      tester,
      loadMap: (id) {
        requested = true;
        return pending.future;
      },
      onApply: (_) {},
    );
    await pick(tester, 'Commande', 'Téléporter');
    await pick(tester, 'Carte de destination', 'Village');
    expect(requested, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(_map('village'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a loaded map with another ID cannot provide arrival points', (
    tester,
  ) async {
    await pump(
      tester,
      loadMap: (_) async => _map('forest'),
      current: SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
          destinationMapId: 'village',
          warpId: 'forest-entry',
        ),
      ),
      onApply: (_) => fail('Wrong map must be rejected'),
    );
    expect(
      find.text('La carte chargée ne correspond pas à la destination.'),
      findsOneWidget,
    );
    expect(
      tester.widget<StudioSelect>(select('Point d’arrivée')).options,
      isEmpty,
    );
    expect(apply(tester).onPressed, isNull);
  });

  testWidgets('a removed arrival point stays explicit and cannot apply', (
    tester,
  ) async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'village',
        warpId: 'deleted-entry',
      ),
    );
    await pump(
      tester,
      current: original,
      onApply: (_) => fail('Removed arrival point must be rejected'),
    );
    expect(
      find.textContaining('Référence introuvable : deleted-entry'),
      findsOneWidget,
    );
    expect(
      tester.widget<StudioSelect>(select('Point d’arrivée')).options.keys,
      ['village-entry'],
    );
    expect(apply(tester).onPressed, isNull);
    expect(original.interactiveCommand!.toJson()['warpId'], 'deleted-entry');
  });

  testWidgets('a removed destination does not load or allow applying', (
    tester,
  ) async {
    final loaded = <String>[];
    await pump(
      tester,
      current: SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
          destinationMapId: 'removed',
          warpId: 'entry',
        ),
      ),
      loadMap: (id) async {
        loaded.add(id);
        return _map(id);
      },
      onApply: (_) => fail('Removed destination must be rejected'),
    );
    expect(
      find.textContaining('Référence introuvable : removed'),
      findsOneWidget,
    );
    expect(loaded, isEmpty);
    expect(apply(tester).onPressed, isNull);
  });

  testWidgets('an unavailable map loader cannot offer arrival points', (
    tester,
  ) async {
    await pump(
      tester,
      mapLoaderAvailable: false,
      onApply: (_) => fail('Unavailable destination must be rejected'),
    );
    await pick(tester, 'Commande', 'Téléporter');
    await pick(tester, 'Carte de destination', 'Village');
    expect(
      find.text('La carte n’est pas disponible dans cet éditeur.'),
      findsOneWidget,
    );
    expect(apply(tester).onPressed, isNull);
  });

  testWidgets('a failed destination load can be retried', (tester) async {
    var attempts = 0;
    await pump(
      tester,
      loadMap: (id) async {
        if (++attempts == 1) throw StateError('unavailable');
        return _map(id);
      },
      onApply: (_) {},
    );
    await pick(tester, 'Commande', 'Téléporter');
    await pick(tester, 'Carte de destination', 'Village');
    expect(
      find.textContaining('Impossible de charger les points d’arrivée'),
      findsOneWidget,
    );
    expect(apply(tester).onPressed, isNull);
    await tester.tap(find.text('Recharger la carte'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      tester.widget<StudioSelect>(select('Point d’arrivée')).options.keys,
      ['village-entry'],
    );
    expect(tester.takeException(), isNull);
  });
}

ProjectManifest _project() => ProjectManifest(
  name: 'Téléportation',
  maps: const [
    ProjectMapEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'village.json',
    ),
    ProjectMapEntry(id: 'forest', name: 'Forêt', relativePath: 'forest.json'),
  ],
  tilesets: [],
);

MapData _map(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 8, height: 8),
  warps: [
    MapWarp(
      id: '$id-entry',
      pos: const GridPos(x: 2, y: 3),
      targetMapId: 'other',
      targetPos: const GridPos(x: 1, y: 1),
    ),
  ],
);
