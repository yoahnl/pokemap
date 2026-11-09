import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart';

void main() {
  testWidgets('World Rules create a civil weekday source without a manual ID', (
    tester,
  ) async {
    WorldRuleSource? created;
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = ProjectManifest(
      name: 'Weekday',
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: const [],
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 4, height: 4),
      entities: [
        MapEntity(
          id: 'tree',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 1),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: FactsWorldRulesWorkspace(
              project: project,
              activeMap: map,
              initialMode: FactsWorldRulesWorkspaceMode.worldRules,
              onCreateFact: ({required label}) async => null,
              onDuplicateFact: ({required factId}) async => null,
              onUpdateFact:
                  ({
                    required factId,
                    required label,
                    required description,
                    required category,
                    required initialValue,
                  }) async => false,
              onRemoveFact: ({required factId}) async => false,
              onCreateWorldRule:
                  ({
                    required label,
                    required description,
                    required enabled,
                    required source,
                    required target,
                    required effect,
                    required priority,
                  }) async {
                    created = source;
                    return null;
                  },
              onUpdateWorldRule:
                  ({
                    required ruleId,
                    required label,
                    required description,
                    required enabled,
                    required source,
                    required target,
                    required effect,
                    required priority,
                  }) async => false,
              onRemoveWorldRule: ({required ruleId}) async => false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final apply = find.byKey(const ValueKey('civil-weekday-apply'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.text('Jour civil : Vendredi'), findsWidgets);
    final create = find.byKey(const ValueKey('world-rule-create-submit'));
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(
      created,
      WorldRuleSource.civilWeekday(
        weekday: CivilWeekday.friday,
        expectedValue: true,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
