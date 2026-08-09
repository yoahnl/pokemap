import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/app/providers/editor/map_use_case_providers.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/pending_border_save_dialog.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';

/// Le point d'entrée partagé de sauvegarde monte le dialogue lui-même, donc il
/// suffit d'un bouton qui l'appelle : pas besoin de la coquille complète de
/// l'éditeur, dont le chemin canonique réclame une révision disque attestée.
Future<({_FakeMapRepository repository, EditorNotifier notifier})> _pump(
  WidgetTester tester, {
  required int savedPlacements,
  required int currentPlacements,
}) async {
  final repository = _FakeMapRepository();
  final container = ProviderContainer(
    overrides: <Override>[
      mapRepositoryProvider.overrideWith((ref) => repository),
      saveMapUseCaseProvider.overrideWith((ref) => SaveMapUseCase(repository)),
    ],
  );
  addTearDown(container.dispose);
  final notifier = container.read(editorNotifierProvider.notifier);
  final saved = _mapWithPlacementCount(savedPlacements);
  notifier.state = EditorState(
    project: _manifest(),
    activeMap: saved.copyWith(
      placedElements: saved.placedElements.take(currentPlacements).toList(),
    ),
    activeMapPath: '/project/maps/town.json',
    savedMapSnapshot: saved,
    isDirty: true,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('save'),
              onPressed: () => requestActiveMapSaveWithBorderPreviewGuard(
                context: context,
                notifier: notifier,
              ),
              child: const Text('Enregistrer'),
            ),
          ),
        ),
      ),
    ),
  );
  return (repository: repository, notifier: notifier);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une perte massive propose une confirmation au lieu d\'un mur', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      savedPlacements: 8,
      currentPlacements: 3,
    );

    await _save(tester);

    expect(find.byKey(const Key('bulk-placement-loss-dialog')), findsOneWidget);
    expect(find.textContaining('8'), findsWidgets);
    expect(find.textContaining('3'), findsWidgets);
    expect(harness.repository.savedMaps, isEmpty);
  });

  testWidgets('le bouton nomme le nombre exact de placements supprimés', (
    tester,
  ) async {
    await _pump(tester, savedPlacements: 8, currentPlacements: 3);

    await _save(tester);

    expect(find.text('Supprimer 5 placements et sauvegarder'), findsOneWidget);
  });

  testWidgets('confirmer écrit la carte amputée', (tester) async {
    final harness = await _pump(
      tester,
      savedPlacements: 8,
      currentPlacements: 3,
    );

    await _save(tester);
    await tester.tap(find.byKey(const Key('bulk-placement-loss-confirm')));
    await tester.pumpAndSettle();

    expect(harness.repository.savedMaps, hasLength(1));
    expect(harness.repository.savedMaps.single.placedElements, hasLength(3));
    expect(harness.notifier.state.isDirty, isFalse);
  });

  testWidgets('annuler n\'écrit rien et garde la carte modifiée', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      savedPlacements: 8,
      currentPlacements: 3,
    );

    await _save(tester);
    await tester.tap(find.byKey(const Key('bulk-placement-loss-cancel')));
    await tester.pumpAndSettle();

    expect(harness.repository.savedMaps, isEmpty);
    expect(harness.notifier.state.isDirty, isTrue);
    expect(harness.notifier.state.activeMap!.placedElements, hasLength(3));
  });

  testWidgets('une perte sous le seuil sauvegarde sans rien demander', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      savedPlacements: 8,
      currentPlacements: 7,
    );

    await _save(tester);

    expect(find.byKey(const Key('bulk-placement-loss-dialog')), findsNothing);
    expect(harness.repository.savedMaps, hasLength(1));
  });
}

class _FakeMapRepository implements MapRepository {
  final List<MapData> savedMaps = <MapData>[];

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    savedMaps.add(map);
  }

  @override
  Future<MapData> loadMap(String path) => throw UnimplementedError();

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}
}

MapData _mapWithPlacementCount(int count) => MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: count, height: 1),
  layers: <MapLayer>[
    MapLayer.tile(
      id: 'decor',
      name: 'Decor',
      cells: List<int>.filled(count, 0),
    ),
  ],
  placedElements: <MapPlacedElement>[
    for (var index = 0; index < count; index += 1)
      MapPlacedElement(
        id: 'placement_$index',
        layerId: 'decor',
        elementId: 'tree',
        pos: GridPos(x: index, y: 0),
      ),
  ],
);

ProjectManifest _manifest() => const ProjectManifest(
  name: 'Demo',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'nature',
      name: 'Nature',
      relativePath: 'tilesets/nature.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'nature',
      categoryId: 'nature',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    ),
  ],
);
