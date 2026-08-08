import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_connection_context.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_connections_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_connection_context_provider.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('WorldMapConnectionsInspector', () {
    testWidgets('shares the selected direction with the canvas context',
        (tester) async {
      final harness = _ConnectionsHarness();
      addTearDown(harness.dispose);
      await harness.pump(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-east')),
      );
      await tester.pump();

      expect(
        harness.container.read(worldMapConnectionDirectionProvider),
        MapConnectionDirection.east,
      );
    });

    testWidgets('shows four directions and excludes the active map from picker',
        (tester) async {
      final harness = _ConnectionsHarness();
      addTearDown(harness.dispose);

      await harness.pump(tester);

      for (final direction in MapConnectionDirection.values) {
        expect(
          find.byKey(
            ValueKey<String>('world-map-connection-${direction.name}'),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('North Shore'), findsAtLeastNWidgets(1));
      expect(find.text('East Road'), findsAtLeastNWidgets(1));
      expect(find.text('+ Ajouter'), findsNWidgets(2));

      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(
          const ValueKey<String>('world-map-connection-target'),
        ),
      );
      expect(picker.items.map((item) => item.value), isNot(contains('active')));
      expect(
        picker.items.map((item) => item.value),
        orderedEquals(['', 'north', 'east', 'south', 'west']),
      );
    });

    testWidgets('accepts a signed offset and applies a reciprocal draft',
        (tester) async {
      final applied = <({
        MapConnectionDirection direction,
        String targetMapId,
        int offset,
        bool reciprocal,
      })>[];
      final harness = _ConnectionsHarness(
        onApply: ({
          required direction,
          required targetMapId,
          required offset,
          required reciprocal,
        }) async {
          applied.add((
            direction: direction,
            targetMapId: targetMapId,
            offset: offset,
            reciprocal: reciprocal,
          ));
        },
      );
      addTearDown(harness.dispose);
      await harness.pump(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-south')),
      );
      await tester.pump();
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(
          const ValueKey<String>('world-map-connection-target'),
        ),
      );
      picker.onChanged('south');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('world-map-connection-offset')),
        '-4',
      );
      await tester.pump();

      expect(find.text('Recouvrement : 4 tiles communes.'), findsOneWidget);
      expect(find.text('Valide'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-apply')),
      );
      await tester.pumpAndSettle();

      expect(
        applied,
        [
          (
            direction: MapConnectionDirection.south,
            targetMapId: 'south',
            offset: -4,
            reciprocal: true,
          ),
        ],
      );
      expect(
        find.text('Connexion Sud appliquée.'),
        findsOneWidget,
      );
      final announcement = tester.widget<Semantics>(
        find.byKey(
          const ValueKey<String>('world-map-connection-announcement'),
        ),
      );
      expect(announcement.properties.liveRegion, isTrue);
    });

    testWidgets(
        'loads a new draft target while persisted connection context is active',
        (tester) async {
      final applied = <({String targetMapId, int offset})>[];
      final harness = _ConnectionsHarness(
        withSharedContext: true,
        onApply: ({
          required direction,
          required targetMapId,
          required offset,
          required reciprocal,
        }) async {
          applied.add((targetMapId: targetMapId, offset: offset));
        },
      );
      addTearDown(harness.dispose);
      await harness.pump(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-south')),
      );
      await tester.pump();
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(
              const ValueKey<String>('world-map-connection-target'),
            ),
          )
          .onChanged('south');
      await tester.pumpAndSettle();

      expect(find.text('Recouvrement : 8 tiles communes.'), findsOneWidget);
      expect(find.text('Valide'), findsOneWidget);
      final apply = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('world-map-connection-apply')),
      );
      expect(apply.onPressed, isNotNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-apply')),
      );
      await tester.pumpAndSettle();

      expect(applied, [(targetMapId: 'south', offset: 0)]);
    });

    testWidgets('disables apply when offset removes every overlap',
        (tester) async {
      final harness = _ConnectionsHarness();
      addTearDown(harness.dispose);
      await harness.pump(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-south')),
      );
      await tester.pump();
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(
              const ValueKey<String>('world-map-connection-target'),
            ),
          )
          .onChanged('south');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('world-map-connection-offset')),
        '99',
      );
      await tester.pump();

      expect(
        find.text('Aucun recouvrement : rapprochez les deux maps.'),
        findsOneWidget,
      );
      final apply = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey<String>('world-map-connection-apply')),
      );
      expect(apply.onPressed, isNull);
      expect(
        apply.disabledReason,
        'Le décalage ne laisse aucun recouvrement.',
      );
    });

    testWidgets('detects an exact pair and routes open and delete callbacks',
        (tester) async {
      final opened = <MapConnectionDirection>[];
      final deleted = <MapConnectionDirection>[];
      final harness = _ConnectionsHarness(
        onOpen: (direction) async => opened.add(direction),
        onDelete: (direction) async => deleted.add(direction),
      );
      addTearDown(harness.dispose);
      await harness.pump(tester);

      final reciprocal = tester.widget<PokeMapButton>(
        find.byKey(
          const ValueKey<String>('world-map-connection-reciprocal'),
        ),
      );
      expect(reciprocal.isSelected, isTrue);
      expect(reciprocal.onPressed, isNull);
      expect(
        find.textContaining('Paire réciproque détectée'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-open')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-connection-delete')),
      );
      await tester.pumpAndSettle();

      expect(opened, [MapConnectionDirection.north]);
      expect(deleted, [MapConnectionDirection.north]);
    });

    testWidgets('resets direction drafts when the active map changes',
        (tester) async {
      final harness = _ConnectionsHarness();
      addTearDown(harness.dispose);
      await harness.pump(tester);

      expect(
        tester
            .widget<TextField>(
              find.byKey(
                const ValueKey<String>('world-map-connection-offset'),
              ),
            )
            .controller
            ?.text,
        '0',
      );
      harness.notifier.state = harness.notifier.state.copyWith(
        activeMap: _targetMap('south').copyWith(
          connections: const [
            MapConnection(
              direction: MapConnectionDirection.north,
              targetMapId: 'active',
              offset: 4,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Map'), findsAtLeastNWidgets(1));
      expect(
        tester
            .widget<TextField>(
              find.byKey(
                const ValueKey<String>('world-map-connection-offset'),
              ),
            )
            .controller
            ?.text,
        '4',
      );
    });
  });
}

class _ConnectionsHarness {
  _ConnectionsHarness({
    this.onApply,
    this.onDelete,
    this.onOpen,
    this.withSharedContext = false,
  }) {
    container = ProviderContainer(
      overrides: [
        if (withSharedContext)
          worldMapConnectionContextProvider.overrideWith(
            (ref, request) async => WorldMapConnectionContext(
              sourceMap: request.sourceMap,
              neighbors: const {},
              issues: const {},
            ),
          ),
      ],
    );
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      project: _project,
      activeMap: _activeMap,
      projectRootPath: withSharedContext ? '/project' : null,
    );
  }

  final WorldMapConnectionApplyCallback? onApply;
  final WorldMapConnectionDirectionCallback? onDelete;
  final WorldMapConnectionDirectionCallback? onOpen;
  final bool withSharedContext;
  late final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 1200,
              child: WorldMapConnectionsInspector(
                onApply: onApply,
                onDelete: onDelete,
                onOpen: onOpen,
                loadTargetMap: (id) async => switch (id) {
                  'north' => _northMap,
                  'east' => _targetMap('east'),
                  'south' => _targetMap('south'),
                  'west' => _targetMap('west'),
                  _ => null,
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

const _project = ProjectManifest(
  name: 'Connection UI fixture',
  maps: [
    ProjectMapEntry(
      id: 'active',
      name: 'Active Map',
      relativePath: 'maps/active.json',
    ),
    ProjectMapEntry(
      id: 'north',
      name: 'North Shore',
      relativePath: 'maps/north.json',
      sortOrder: 1,
    ),
    ProjectMapEntry(
      id: 'east',
      name: 'East Road',
      relativePath: 'maps/east.json',
      sortOrder: 2,
    ),
    ProjectMapEntry(
      id: 'south',
      name: 'South Garden',
      relativePath: 'maps/south.json',
      sortOrder: 3,
    ),
    ProjectMapEntry(
      id: 'west',
      name: 'West Gate',
      relativePath: 'maps/west.json',
      sortOrder: 4,
    ),
  ],
  tilesets: [],
);

const _activeMap = MapData(
  id: 'active',
  name: 'Active Map',
  size: GridSize(width: 8, height: 8),
  connections: [
    MapConnection(
      direction: MapConnectionDirection.north,
      targetMapId: 'north',
      offset: 0,
    ),
    MapConnection(
      direction: MapConnectionDirection.east,
      targetMapId: 'east',
      offset: 0,
    ),
  ],
);

const _northMap = MapData(
  id: 'north',
  name: 'North Shore',
  size: GridSize(width: 8, height: 8),
  connections: [
    MapConnection(
      direction: MapConnectionDirection.south,
      targetMapId: 'active',
      offset: 0,
    ),
  ],
);

MapData _targetMap(String id) => MapData(
      id: id,
      name: switch (id) {
        'east' => 'East Road',
        'south' => 'South Garden',
        'west' => 'West Gate',
        _ => id,
      },
      size: const GridSize(width: 8, height: 8),
    );
