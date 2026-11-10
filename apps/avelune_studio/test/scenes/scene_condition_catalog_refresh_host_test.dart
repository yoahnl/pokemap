import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_condition_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Commerce publication is visible to a fresh scene catalogue without changing cached Pokemon data', () async {
    final fixture = await Ui06SceneFixture.create();
    addTearDown(fixture.dispose);
    final catalog = File('${fixture.directory.path}/data/pokemon/catalogs/items.json');
    await catalog.parent.create(recursive: true);
    await File('../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json')
        .copy(catalog.path);
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(fixture.session, maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final pokemonPort = LocalPokemonWorkspaceAdapter(
      session: fixture.session, mapAdapter: maps,
    );
    addTearDown(pokemonPort.dispose);
    final commerce = PokemonCommerceController(
      LocalPokemonCommerceAdapter(session: fixture.session, mapAdapter: maps),
      changed: () {},
    );
    final pokemon = PokemonWorkspaceController(
      pokemonPort, changed: () {}, commerce: commerce,
    );
    await pokemon.load();
    await commerce.load();
    final cached = pokemon.index!;
    expect(cached.enabled, isTrue);
    expect(cached.items, isNot(contains('condition-tonic')));
    expect(cached.itemCatalog, isNotNull);
    final sessions = WorkspaceSessionControllers(
      controller: workspace,
      changed: () {},
      visualCatalogChanged: (_) {},
      flushEditors: () async => true,
    )..pokemon = pokemon;
    addTearDown(sessions.dispose);
    final scenes = SceneWorkspaceController(
      workspace,
      LocalSceneAdapter(session: fixture.session, mapAdapter: maps),
      changed: () {},
    );
    sessions.scenes = scenes;
    final beforeMaps = {
      for (final entry in workspace.project!.maps)
        entry.id: await File('${fixture.directory.path}/${entry.relativePath}').readAsBytes(),
    };
    expect(commerce.createItem('condition-tonic'), isTrue);
    commerce.editItem((item) => item.copyWith(displayName: 'Tonique de recette'));
    expect(await commerce.save(), isTrue, reason: commerce.error);
    expect(commerce.dirty, isFalse);
    expect(pokemon.index, same(cached));
    expect(cached.items, isNot(contains('condition-tonic')));
    final fresh = await sessions.loadSceneItems();
    expect(fresh['condition-tonic'], 'Tonique de recette');
    expect(pokemon.index, same(cached));
    expect(cached.itemCatalog!.entries.map((item) => item.id),
        isNot(contains('condition-tonic')));

    expect(scenes.open(Ui06SceneFixture.sceneId), isTrue);
    final edit = scenes.active!;
    final original = edit.current;
    final node = original.graph.nodes.singleWhere((node) => node.id == 'pass');
    final payload = node.payload as SceneConditionPayload;
    final ready = Completer<void>();
    late SceneConditionDraft draft;
    draft = SceneConditionDraft(
      project: workspace.project!,
      current: payload,
      loadItems: sessions.loadSceneItems,
      changed: () {
        if (!draft.itemsLoading && !ready.isCompleted) ready.complete();
      },
    );
    addTearDown(draft.dispose);
    draft.selectFamily('inventoryItem');
    await ready.future;
    expect(draft.itemsError, isNull);
    expect(draft.references['condition-tonic'], 'Tonique de recette');
    draft.selectReference('condition-tonic');
    draft.minimumQuantity = '3';
    draft.expected = false;
    expect(edit.current, original);
    expect(edit.dirty, isFalse);
    expect((await LocalMapWorkspaceAdapter().loadProject(fixture.session)).scenes.single, original);
    final source = draft.prepared!;
    expect(edit.mutate((scene) => updateSceneConditionSource(
      scene, nodeId: 'pass', source: source,
    ).updatedScene), isTrue, reason: edit.error);
    expect(edit.dirty, isTrue);
    expect(edit.undoCount, 1);
    expect(source.sourceKind, SceneConditionSourceKind.inventoryItem);
    expect(source.sourceId, 'condition-tonic');
    expect(source.inventoryQuantityThreshold, 3);
    expect(source.operator, SceneConditionOperator.isFalse);
    expect(source.label, 'Tonique de recette');
    final edited = edit.current;
    expect((await LocalMapWorkspaceAdapter().loadProject(fixture.session)).scenes.single, original);
    expect(await scenes.save(), isTrue, reason: scenes.error);
    expect(edit.dirty, isFalse);
    final coldAdapter = LocalMapWorkspaceAdapter();
    final coldWorkspace = MapWorkspaceController(fixture.session, coldAdapter);
    addTearDown(coldWorkspace.dispose);
    await coldWorkspace.initialize();
    final coldScenes = SceneWorkspaceController(
      coldWorkspace,
      LocalSceneAdapter(session: fixture.session, mapAdapter: coldAdapter),
      changed: () {},
    );
    addTearDown(coldScenes.dispose);
    expect(coldScenes.open(Ui06SceneFixture.sceneId), isTrue);
    expect(coldScenes.active!.current, edited);
    final restored = (coldScenes.active!.current.graph.nodes
        .singleWhere((node) => node.id == 'pass').payload as SceneConditionPayload)
        .conditionSource!;
    expect(restored, source);
    final coldPokemonPort = LocalPokemonWorkspaceAdapter(
      session: fixture.session, mapAdapter: coldAdapter,
    );
    addTearDown(coldPokemonPort.dispose);
    final coldPokemon = PokemonWorkspaceController(coldPokemonPort, changed: () {});
    await coldPokemon.load();
    final coldSessions = WorkspaceSessionControllers(
      controller: coldWorkspace,
      changed: () {},
      visualCatalogChanged: (_) {},
      flushEditors: () async => true,
    )..pokemon = coldPokemon;
    addTearDown(coldSessions.dispose);
    final coldReady = Completer<void>();
    late SceneConditionDraft coldDraft;
    coldDraft = SceneConditionDraft(
      project: coldWorkspace.project!,
      current: SceneConditionPayload(conditionSource: restored),
      loadItems: coldSessions.loadSceneItems,
      changed: () {
        if (!coldDraft.itemsLoading && !coldReady.isCompleted) coldReady.complete();
      },
    );
    addTearDown(coldDraft.dispose);
    await coldReady.future;
    expect(coldDraft.itemsError, isNull);
    expect(coldDraft.references['condition-tonic'], 'Tonique de recette');
    expect(coldDraft.prepared, source);
    for (final entry in workspace.project!.maps) {
      expect(await File('${fixture.directory.path}/${entry.relativePath}').readAsBytes(),
          beforeMaps[entry.id]);
    }

    final delayed = _DelayedIndexPort();
    final stale = PokemonWorkspaceController(delayed, changed: () {});
    sessions.pokemon = stale;
    final loading = sessions.loadSceneItems();
    await delayed.started.future;
    sessions.pokemon = pokemon;
    delayed.result.complete(cached);
    await expectLater(loading, throwsA(isA<StateError>()));
    stale.dispose();

    final duringClose = _DelayedIndexPort();
    pokemon.dispose();
    sessions.pokemon = PokemonWorkspaceController(duringClose, changed: () {});
    final closingLoad = sessions.loadSceneItems();
    await duringClose.started.future;
    await sessions.dispose();
    expect(workspace.isDisposed, isFalse);
    duringClose.result.complete(cached);
    await expectLater(closingLoad, throwsA(isA<StateError>()));
    await expectLater(sessions.loadSceneItems(), throwsA(isA<StateError>()));
  });
}

class _DelayedIndexPort implements PokemonWorkspacePort {
  final started = Completer<void>();
  final result = Completer<PokemonWorkspaceIndex>();

  @override
  Future<PokemonWorkspaceIndex> loadIndex() {
    started.complete();
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
