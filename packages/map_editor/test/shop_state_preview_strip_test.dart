import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/application/shop_state_simulation_controller.dart';
import 'package:map_editor/src/features/gameplay/presentation/shop_state_preview_strip.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main() {
  testWidgets('explains the selected state and an equal-priority conflict',
      (tester) async {
    final first = _state('after-lysa', 'Après la victoire contre Lysa');
    final second = _state('badge', 'Catalogue du Badge');
    final preview = ShopStateSimulationReadModel(
      resolvedState: ResolvedShopState(
        shopId: 'port',
        stateId: first.id,
        authoringLabel: first.label,
        storefrontLabel: 'Boutique du Port',
        priority: 20,
        isDefault: false,
        isOpen: true,
        message: '',
        entries: const <ShopEntryDefinition>[],
        matchedStateIds: <String>[first.id, second.id],
      ),
      matchedStates: <ShopStateDefinition>[first, second],
      conditionRows: <ShopStateSimulationConditionRow>[
        ShopStateSimulationConditionRow(
          stateId: first.id,
          label: first.label,
          priority: first.priority,
          matched: true,
          selected: true,
        ),
        ShopStateSimulationConditionRow(
          stateId: second.id,
          label: second.label,
          priority: second.priority,
          matched: true,
          selected: false,
        ),
      ],
      hasPriorityConflict: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: ShopStatePreviewStrip(
            preview: preview,
            contextLabel: 'Snapshot local',
          ),
        ),
      ),
    );

    expect(find.text('Contexte simulé'), findsOneWidget);
    expect(find.text('État retenu'), findsOneWidget);
    expect(find.text('Après la victoire contre Lysa'), findsWidgets);
    expect(find.text('2 conditions remplies'), findsOneWidget);
    expect(find.text('Priorité ambiguë'), findsOneWidget);
    expect(find.textContaining('Catalogue du Badge'), findsOneWidget);
  });
}

ShopStateDefinition _state(String id, String label) => ShopStateDefinition(
      id: id,
      label: label,
      priority: 20,
      activation: ScriptConditionFactory.flagIsSet(id),
    );
