import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;
import '../support/ui05_narrative_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui_pokemon_commerce_port.dart';
import '../support/ui_pokemon_port.dart';

void main() {
  testWidgets(
    'Commerce saves a new item and the real scene host reads its fresh catalog',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(() async {
        final fixture = await Ui06SceneFixture.create();
        final catalog = File(
          '${fixture.directory.path}/data/pokemon/catalogs/items.json',
        );
        await catalog.parent.create(recursive: true);
        await File(
          '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
        ).copy(catalog.path);
        return fixture;
      }))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(fixture.dispose);
      });
      final host = await _Host.mount(tester, fixture, 'initial');
      final beforeMaps = (await tester.runAsync(host.mapBytes))!;
      await _navigate(tester, 'Pokémon');
      final pokemon = tester
          .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
          .controller!;
      final cachedIndex = pokemon.index!;
      expect(cachedIndex.enabled, isTrue);
      expect(cachedIndex.itemCatalog, isNotNull);
      expect(cachedIndex.items, isNot(contains('condition-tonic')));
      await _tap(tester, find.text('Objets').first);
      await _tap(tester, find.text('Créer un objet').last);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'condition-tonic',
      );
      await _tap(tester, find.text('Créer').last);
      await tester.enterText(
        find.byKey(const ValueKey('item-name-condition-tonic')),
        'Tonique de recette',
      );
      await _tap(tester, find.text('Enregistrer').last);
      expect(pokemon.commerce!.error, isNull);
      expect(pokemon.commerce!.dirty, isFalse);
      expect(pokemon.commerce!.item!.id, 'condition-tonic');
      expect(pokemon.commerce!.item!.displayName, 'Tonique de recette');
      expect(pokemon.index, same(cachedIndex));
      expect(cachedIndex.items, isNot(contains('condition-tonic')));
      expect(
        cachedIndex.itemCatalog!.entries.any(
          (item) => item.id == 'condition-tonic',
        ),
        isFalse,
      );
      final savedCatalog = (await tester.runAsync(() async {
        final maps = LocalMapWorkspaceAdapter();
        await maps.loadProject(host.session);
        return LocalPokemonCommerceAdapter(
          session: host.session,
          mapAdapter: maps,
        ).load();
      }))!;
      expect(
        savedCatalog.catalog!.entries
            .singleWhere((item) => item.id == 'condition-tonic')
            .displayName,
        'Tonique de recette',
      );

      await _openCondition(tester, fixture.scene.name);
      final page = _scenePage(tester);
      final edit = page.controller.active!;
      final original = edit.current;
      await _choose(tester, 'Source de la condition', 'inventoryItem');
      expect(
        _select(tester, 'Référence').options['condition-tonic'],
        'Tonique de recette',
      );
      expect(pokemon.index, same(cachedIndex));
      expect(cachedIndex.items, isNot(contains('condition-tonic')));
      await _choose(tester, 'Référence', 'condition-tonic');
      final quantity = find.byWidgetPredicate(
        (widget) =>
            widget is StudioDraftField && widget.label == 'Quantité minimale',
      );
      await tester.ensureVisible(quantity);
      await tester.enterText(
        find.descendant(of: quantity, matching: find.byType(TextField)),
        '3',
      );
      await _choose(tester, 'Présent en quantité suffisante', 'false');
      expect(edit.current, original);
      expect(edit.dirty, isFalse);
      expect((await tester.runAsync(host.readScene))!, original);
      await _tap(tester, find.text('Appliquer la condition'));
      expect(edit.dirty, isTrue);
      expect(edit.undoCount, 1);
      final draft = edit.current;
      final source = _condition(draft);
      expect(source.sourceKind, SceneConditionSourceKind.inventoryItem);
      expect(source.sourceId, 'condition-tonic');
      expect(source.inventoryQuantityThreshold, 3);
      expect(source.operator, SceneConditionOperator.isFalse);
      expect(source.label, 'Tonique de recette');
      expect((await tester.runAsync(host.readScene))!, original);
      await _tap(
        tester,
        find.descendant(
          of: find.byType(SceneBuilderPage),
          matching: find.widgetWithText(StudioButton, 'Enregistrer'),
        ),
      );
      expect(edit.error, isNull);
      expect(edit.dirty, isFalse);
      expect(edit.current, draft);
      expect((await tester.runAsync(host.readScene))!, draft);
      expect((await tester.runAsync(host.mapBytes))!, beforeMaps);
      await host.close(tester);

      final cold = await _Host.mount(tester, fixture, 'cold');
      expect(cold.maps, isNot(same(host.maps)));
      await _openCondition(tester, fixture.scene.name);
      final reopened = _scenePage(tester).controller.active!;
      expect(reopened.current, draft);
      expect(reopened.dirty, isFalse);
      expect(_select(tester, 'Source de la condition').value, 'inventoryItem');
      expect(_select(tester, 'Référence').value, 'condition-tonic');
      expect(
        _select(tester, 'Référence').options['condition-tonic'],
        'Tonique de recette',
      );
      expect(_select(tester, 'Présent en quantité suffisante').value, 'false');
      expect(
        tester
            .widget<StudioDraftField>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is StudioDraftField &&
                    widget.label == 'Quantité minimale',
              ),
            )
            .value,
        '3',
      );
      expect((await tester.runAsync(cold.mapBytes))!, beforeMaps);
      expect(tester.takeException(), isNull);
      await cold.close(tester);
    },
  );
}

SceneConditionSource _condition(SceneAsset scene) =>
    (scene.graph.nodes.singleWhere((node) => node.id == 'pass').payload
            as SceneConditionPayload)
        .conditionSource!;

SceneBuilderPage _scenePage(WidgetTester tester) =>
    tester.widget<SceneBuilderPage>(find.byType(SceneBuilderPage));

StudioSelect _select(WidgetTester tester, String label) => tester
    .widgetList<StudioSelect>(find.byType(StudioSelect))
    .singleWhere((select) => select.label == label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 15);
}

Future<void> _navigate(WidgetTester tester, String destination) => _tap(
  tester,
  find.descendant(
    of: find.byType(StudioPrimaryNavigation),
    matching: find.byTooltip(destination),
  ),
);

Future<void> _openCondition(WidgetTester tester, String sceneName) async {
  await _navigate(tester, 'Histoire');
  await _tap(
    tester,
    find.widgetWithText(StudioButton, 'Voir toutes les scènes'),
  );
  await _tap(tester, find.text(sceneName).last);
  await _tap(
    tester,
    find.byKey(const ValueKey('scene-graph-node-drag-target-pass')),
  );
  expect(find.byType(SceneConditionForm), findsOneWidget);
}

Future<void> _choose(WidgetTester tester, String label, String value) async {
  final select = _select(tester, label);
  final option = select.options[value];
  expect(option, isNotNull, reason: '$label / $value');
  final field = find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == label,
  );
  await tester.ensureVisible(field);
  await tester.tap(
    find.descendant(
      of: field,
      matching: find.byType(DropdownButtonFormField<String>),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(option!).last);
  await tester.pumpAndSettle();
  await pumpIo(tester, frames: 15);
}

final class _Host {
  _Host(this.fixture, this.session, this.maps, this.adapter, this.pokemon);
  final Ui06SceneFixture fixture;
  final ProjectSession session;
  final WidgetMapController maps;
  final LocalMapWorkspaceAdapter adapter;
  final LocalPokemonWorkspaceAdapter pokemon;
  bool _closed = false;

  static Future<_Host> mount(
    WidgetTester tester,
    Ui06SceneFixture fixture,
    String name,
  ) async {
    final session = ProjectSession(
      sessionId: 'condition-commerce-$name',
      name: fixture.session.name,
      directoryPath: fixture.directory.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final maps = WidgetMapController(session, adapter, tester);
    await tester.runAsync(maps.initialize);
    final pokemon = LocalPokemonWorkspaceAdapter(
      session: session,
      mapAdapter: adapter,
    );
    final host = _Host(fixture, session, maps, adapter, pokemon);
    addTearDown(() => host.close(tester));
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          key: ValueKey(name),
          controller: maps,
          pokemonPort: UiPokemonPort(pokemon, tester),
          pokemonCommercePort: UiPokemonCommercePort(
            LocalPokemonCommerceAdapter(session: session, mapAdapter: adapter),
            tester,
          ),
          narrativePort: Ui05NarrativePort(
            LocalNarrativeAdapter(session: session, mapAdapter: adapter),
            tester,
          ),
          scenePort: _InteractiveSceneAdapter(
            tester: tester,
            session: session,
            mapAdapter: adapter,
          ),
          loadVisuals: (_, _) async => WorkspaceTestVisuals(),
          runtimeBuilder: (_, _, _) => const SizedBox.shrink(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await pumpIo(tester);
    return host;
  }

  Future<SceneAsset> readScene() async =>
      (await LocalMapWorkspaceAdapter().loadProject(session)).scenes
          .singleWhere((scene) => scene.id == Ui06SceneFixture.sceneId);

  Future<Map<String, List<int>>> mapBytes() async => {
    for (final entry in maps.project!.maps)
      entry.id: await File('${fixture.directory.path}/${entry.relativePath}')
          .readAsBytes(),
  };

  Future<void> close(WidgetTester tester) async {
    if (_closed) return;
    await tester.pumpWidget(const SizedBox.shrink());
    maps.dispose();
    pokemon.dispose();
    _closed = true;
  }
}

final class _InteractiveSceneAdapter extends LocalSceneAdapter {
  _InteractiveSceneAdapter({
    required this.tester,
    required super.session,
    required super.mapAdapter,
  });
  final WidgetTester tester;

  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    final result =
        (await WidgetResourcePort.serial<(ScenePublicationReceipt?, Object?)>(
          tester,
          () async {
            try {
              return (
                await super.publishScene(base: base, current: current),
                null,
              );
            } on Object catch (error) {
              return (null, error);
            }
          },
        ))!;
    if (result.$2 case final error?) throw error;
    return result.$1!;
  }
}
