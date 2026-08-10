import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/presentation/identity/character_studio_identity_editor.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('identity edits named fields without exposing engine ids', (
    tester,
  ) async {
    final project = _project();
    CharacterIdentityDraft? saved;
    var defaultRequests = 0;
    var dirtyRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 780,
            child: CharacterStudioIdentityEditor(
              project: project,
              character: project.characters.single,
              isDefaultCharacter: false,
              isSaving: false,
              onSave: (value) => saved = value,
              onDirtyChanged: (dirty) {
                if (dirty) dirtyRequests++;
              },
              onSetDefault: () => defaultRequests++,
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sprites des héros'), findsWidgets);
    expect(find.text('characters_main'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-name')),
      'Élia la Rouge',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-frame-width')),
      '4',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-frame-height')),
      '8',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-tags')),
      'héroïne, jouable, guilde rouge',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('character-identity-save')),
    );
    await tester.pump();

    expect(saved?.name, 'Élia la Rouge');
    expect(saved?.tilesetId, 'characters_main');
    expect(saved?.frameWidth, 4);
    expect(saved?.frameHeight, 8);
    expect(saved?.tags, <String>['héroïne', 'jouable', 'guilde rouge']);
    expect(dirtyRequests, greaterThan(0));

    await tester.tap(
      find.byKey(const ValueKey<String>('character-set-default')),
    );
    expect(defaultRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('identity validates required values before save', (tester) async {
    final project = _project();
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 780,
            child: CharacterStudioIdentityEditor(
              project: project,
              character: project.characters.single,
              isDefaultCharacter: true,
              isSaving: false,
              onSave: (_) => saves++,
              onSetDefault: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-name')),
      '   ',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('character-identity-save')),
    );
    await tester.pump();

    expect(saves, 0);
    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Character Studio',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters_main',
        name: 'Sprites des héros',
        relativePath: 'tilesets/characters.png',
      ),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'characters_main',
        tags: <String>['héroïne'],
      ),
    ],
  );
}
