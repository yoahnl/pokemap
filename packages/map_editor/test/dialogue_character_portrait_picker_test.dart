import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/dialogue/presentation/dialogue_character_portrait_picker.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('dialogue portrait picker exposes names and hides Yarn syntax', (
    tester,
  ) async {
    String? characterId;
    String? portraitStateId;
    (String?, String?)? lastSelection;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SizedBox(
                width: 420,
                child: DialogueCharacterPortraitPicker(
                  project: _project(),
                  characterId: characterId,
                  portraitStateId: portraitStateId,
                  onChanged: (nextCharacterId, nextPortraitStateId) {
                    lastSelection = (nextCharacterId, nextPortraitStateId);
                    rebuild(() {
                      characterId = nextCharacterId;
                      portraitStateId = nextPortraitStateId;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Aucun portrait'), findsOneWidget);
    expect(find.textContaining('<<portrait'), findsNothing);

    final characterPicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey<String>('dialogue-line-character-picker')),
    );
    expect(
      characterPicker.items.map((item) => item.label),
      containsAll(<String>['Aucun portrait', 'Élia', 'Nox']),
    );
    characterPicker.onChanged('elia');
    await tester.pump();

    expect(lastSelection, ('elia', 'neutral'));
    final portraitPicker = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const ValueKey<String>('dialogue-line-portrait-state-picker')),
    );
    expect(
      portraitPicker.items.map((item) => item.label),
      containsAll(<String>['Neutre', 'Surprise']),
    );
    portraitPicker.onChanged('surprised');
    await tester.pump();

    expect(lastSelection, ('elia', 'surprised'));
    expect(find.text('Portrait non défini pour Élia'), findsOneWidget);

    tester
        .widget<PokeMapDropdownField<String>>(
          find.byKey(const ValueKey<String>('dialogue-line-character-picker')),
        )
        .onChanged('');
    await tester.pump();

    expect(lastSelection, (null, null));
    expect(find.textContaining('<<portrait'), findsNothing);
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Dialogue picker',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
        CharacterPortraitStateDefinition(
          id: 'surprised',
          displayName: 'Surprise',
          sortOrder: 1,
        ),
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
        ],
      ),
      ProjectCharacterEntry(id: 'nox', name: 'Nox', tilesetId: 'nox'),
    ],
  );
}
