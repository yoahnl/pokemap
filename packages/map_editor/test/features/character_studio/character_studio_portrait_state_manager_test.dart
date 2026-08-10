import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/character_use_cases.dart';
import 'package:map_editor/src/features/character_studio/presentation/catalog/portrait_state_manager.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('portrait state manager sorts, reports coverage and reorders', (
    tester,
  ) async {
    List<String>? reordered;
    await tester.pumpWidget(
      _harness(
        PortraitStateManager(
          project: _project(),
          isSaving: false,
          onCreate: (_) async {},
          onRename: (_, _) async {},
          onReorder: (ids) async => reordered = ids,
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (_, _, _) async {},
        ),
      ),
    );

    expect(find.text('Expressions globales'), findsOneWidget);
    expect(find.text('1/2 personnages'), findsOneWidget);
    expect(find.text('2/2 personnages'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Neutre')).dy,
      lessThan(tester.getTopLeft(find.text('Surprise')).dy),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-state-move-down-neutral')),
    );
    await tester.pump();

    expect(reordered, <String>['surprised', 'neutral']);
  });

  testWidgets('portrait state manager creates and renames display labels', (
    tester,
  ) async {
    String? created;
    (String, String)? renamed;
    await tester.pumpWidget(
      _harness(
        PortraitStateManager(
          project: _project(),
          isSaving: false,
          onCreate: (label) async => created = label,
          onRename: (id, label) async => renamed = (id, label),
          onReorder: (_) async {},
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (_, _, _) async {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-state-create')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Très contente  ');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(created, 'Très contente');

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-state-rename-neutral')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Calme');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(renamed, ('neutral', 'Calme'));
  });

  testWidgets('delete preview names every affected character and dialogue', (
    tester,
  ) async {
    (String, PortraitStateDeleteResolution, String?)? deleted;
    await tester.pumpWidget(
      _harness(
        PortraitStateManager(
          project: _project(),
          isSaving: false,
          onCreate: (_) async {},
          onRename: (_, _) async {},
          onReorder: (_) async {},
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (id, resolution, replacementId) async {
            deleted = (id, resolution, replacementId);
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-state-delete-neutral')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personnage · Élia'), findsOneWidget);
    expect(find.text('Dialogue · Introduction'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey<String>('portrait-state-delete-confirm')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('portrait-state-delete-resolution-clear'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-state-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(deleted, ('neutral', PortraitStateDeleteResolution.clear, null));
  });
}

Widget _harness(Widget child) {
  return MaterialApp(
    theme: PokeMapTheme.dark(),
    home: Scaffold(body: SizedBox(width: 760, height: 760, child: child)),
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Character Studio',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(
          id: 'surprised',
          displayName: 'Surprise',
          sortOrder: 1,
        ),
        CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
      ],
    ),
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia',
        portraits: <CharacterPortraitVariant>[
          CharacterPortraitVariant(
            portraitStateId: 'neutral',
            assetId: 'elia-neutral',
          ),
          CharacterPortraitVariant(
            portraitStateId: 'surprised',
            assetId: 'elia-surprised',
          ),
        ],
      ),
      ProjectCharacterEntry(
        id: 'nox',
        name: 'Nox',
        tilesetId: 'nox',
        portraits: <CharacterPortraitVariant>[
          CharacterPortraitVariant(
            portraitStateId: 'surprised',
            assetId: 'nox-surprised',
          ),
        ],
      ),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'intro',
        name: 'Introduction',
        relativePath: 'dialogues/intro.yarn',
      ),
    ],
  );
}

PortraitStateDeletePlan _deletePlan() {
  return const PortraitStateDeletePlan(
    portraitStateId: 'neutral',
    requiresResolution: true,
    dependencies: <PortraitStateDeleteDependency>[
      PortraitStateDeleteDependency(
        sourceKind: 'characterPortrait',
        sourceId: 'elia',
        path: r'$.characters[0].portraits[0]',
      ),
      PortraitStateDeleteDependency(
        sourceKind: 'dialogue',
        sourceId: 'intro',
        path: r'$.dialogues[intro].lines[3]',
      ),
    ],
    replacementCandidates: <PortraitStateReplacementCandidate>[
      PortraitStateReplacementCandidate(
        id: 'surprised',
        displayName: 'Surprise',
      ),
    ],
  );
}
