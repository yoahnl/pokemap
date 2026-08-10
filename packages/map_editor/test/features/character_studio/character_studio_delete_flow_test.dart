import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/use_cases/character_use_cases.dart';
import 'package:map_editor/src/features/character_studio/presentation/identity/character_studio_delete_dialog.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  test('delete plan parses dependencies and named replacements', () {
    final plan = CharacterDeletePlan.fromPreview(const <String, Object?>{
      'characterId': 'elia',
      'requiresResolution': true,
      'dependencies': <Object?>[
        <String, Object?>{
          'sourceKind': 'mapNpc',
          'sourceId': 'route_1:npc_3',
          'path': '/entities/2/characterId',
        },
      ],
      'replacementCandidates': <Object?>[
        <String, Object?>{'id': 'nox', 'name': 'Nox'},
      ],
    });

    expect(plan.characterId, 'elia');
    expect(plan.requiresResolution, isTrue);
    expect(plan.dependencies.single.sourceKind, 'mapNpc');
    expect(plan.replacementCandidates.single.name, 'Nox');
  });

  testWidgets('delete dialog shows impacts before resolving references', (
    tester,
  ) async {
    CharacterDeleteDecision? decision;
    final plan = CharacterDeletePlan.fromPreview(const <String, Object?>{
      'characterId': 'elia',
      'requiresResolution': true,
      'dependencies': <Object?>[
        <String, Object?>{
          'sourceKind': 'defaultPlayer',
          'sourceId': 'project',
          'path': '/settings/defaultPlayerCharacterId',
        },
        <String, Object?>{
          'sourceKind': 'mapNpc',
          'sourceId': 'route_1:npc_3',
          'path': '/entities/2/characterId',
        },
      ],
      'replacementCandidates': <Object?>[
        <String, Object?>{'id': 'nox', 'name': 'Nox'},
        <String, Object?>{'id': 'orme', 'name': 'Prof. Orme'},
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                decision = await showCharacterDeleteDialog(
                  context: context,
                  characterName: 'Élia',
                  plan: plan,
                );
              },
              child: const Text('Supprimer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('character-delete-dependencies')),
      findsOneWidget,
    );
    expect(find.text('Personnage joueur par défaut'), findsOneWidget);
    expect(find.text('PNJ de carte · route_1:npc_3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('character-delete-resolution-replace')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nox'), findsWidgets);
    expect(find.text('nox'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('character-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(decision?.resolution, CharacterDeleteResolution.replace);
    expect(decision?.replacementId, 'nox');
  });
}
