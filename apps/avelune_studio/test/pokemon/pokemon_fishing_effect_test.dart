import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_table_detail.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_item_effects.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'general table picker preserves every non-fishing kind and contextual rates',
    (tester) async {
      final port = FishingCombatPort();
      VoidCallback redraw = () {};
      final combat = PokemonCombatController(port, changed: () => redraw());
      await combat.load();
      combat.selectTable(port.table);
      addTearDown(combat.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = () => setState(() {});
                return PokemonCombatTableDetail(
                  combat: combat,
                  onDelete: () {},
                  index: const PokemonWorkspaceIndex(
                    enabled: true,
                    entries: [],
                    types: [],
                    items: {},
                    moves: PokemonMovesCatalogView(
                      entries: [],
                      relativePath: 'moves.json',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      for (final kind in EncounterKind.values) {
        final picker = tester
            .widgetList<StudioSelect>(find.byType(StudioSelect))
            .singleWhere((widget) => widget.label == 'Déclenchement');
        expect(
          picker.options.keys.toSet(),
          EncounterKind.values.map((kind) => kind.name).toSet(),
        );
        picker.onChanged!(kind.name);
        await tester.pump();
        expect(combat.table!.current.encounterKind, kind);
        final perAttempt = {
          EncounterKind.oldRod,
          EncounterKind.goodRod,
          EncounterKind.superRod,
          EncounterKind.headbutt,
          EncounterKind.special,
        }.contains(kind);
        expect(
          find.text(
            perAttempt
                ? 'Probabilité par tentative (0 à 100 %)'
                : 'Probabilité par pas (0 à 100 %)',
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'guided fishing picker authors three reusable rods and preserves the item',
    (tester) async {
      final port = FishingCommercePort();
      VoidCallback redraw = () {};
      final commerce = PokemonCommerceController(port, changed: () => redraw());
      await commerce.load();
      commerce.selectItem(port.item);
      addTearDown(commerce.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = () => setState(() {});
                return SingleChildScrollView(
                  child: PokemonItemEffects(commerce: commerce),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ajouter un effet').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .widgetWithText(DropdownButtonFormField<String>, 'Type d’effet')
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pêche').last);
      await tester.pumpAndSettle();
      for (final entry in {
        'Canne': ProjectFishingRodKind.oldRod,
        'Super Canne': ProjectFishingRodKind.goodRod,
        'Méga Canne': ProjectFishingRodKind.superRod,
      }.entries) {
        final picker = find.byWidgetPredicate(
          (widget) =>
              widget is StudioSelect && widget.label == 'Canne de pêche',
        );
        await tester.ensureVisible(picker);
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key).last);
        await tester.pumpAndSettle();
        final item = commerce.item!;
        expect(item.id, 'custom_tool');
        expect(item.pocketId, 'custom');
        expect(item.tags, contains('key-item'));
        expect(
          item.uses.single.effect,
          ProjectItemEffectDefinition.fishing(rodKind: entry.value),
        );
        expect(item.uses.single.target, ProjectItemTargetKind.world);
        expect(
          item.uses.single.consumption,
          ProjectItemConsumptionPolicy.never,
        );
        expect(
          validateProjectItemCatalog(
            ProjectItemCatalog(schemaVersion: 1, entries: [item]),
            capabilityTruth: itemSystemV1CapabilityTruth,
          ).hasBlockingDiagnostics,
          isFalse,
        );
      }
      expect(await commerce.save(), isTrue);
      final reopened = await port.load();
      expect(
        reopened.catalog!.entries.single.uses.single.effect,
        const ProjectItemEffectDefinition.fishing(
          rodKind: ProjectFishingRodKind.superRod,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class FishingCommercePort implements PokemonCommercePort {
  ProjectItemDefinition item = const ProjectItemDefinition(
    id: 'custom_tool',
    displayName: 'Outil',
    pocketId: 'custom',
  );
  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) async {
    item = after;
  }

  @override
  Future<PokemonCommerceSnapshot> load() async => PokemonCommerceSnapshot(
    project: const ProjectManifest(name: 'Fishing', maps: [], tilesets: []),
    catalog: ProjectItemCatalog(schemaVersion: 1, entries: [item]),
    shops: const [],
    references: ProjectItemReferenceIndex(const []),
    narrativeReferences: NarrativeDependencyIndex(),
    shopDiagnostics: const [],
    catalogPath: 'data/pokemon/catalogs/items.json',
    problem: null,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FishingCombatPort implements PokemonCombatPort {
  @override
  Future<void> setRuleset(
    PokemonRulesetProfile before,
    PokemonRulesetProfile after,
  ) => throw UnimplementedError();

  final table = const ProjectEncounterTable(
    id: 'all-kinds',
    name: 'All kinds',
    encounterKind: EncounterKind.headbutt,
    entries: [],
  );
  @override
  Future<PokemonCombatSnapshot> load() async => PokemonCombatSnapshot(
    project: ProjectManifest(
      name: 'Fishing',
      maps: [],
      tilesets: [],
      encounterTables: [table],
    ),
    maps: [],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
