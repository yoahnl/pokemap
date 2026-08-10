import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_portrait_inspector_read_model.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/presentation/portraits/portrait_inspector.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets(
    'portrait inspector follows selection and distinguishes every diagnostic',
    (tester) async {
      final project = _project();
      var selectedStateId = 'neutral';
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SizedBox(
                  width: 360,
                  height: 800,
                  child: PortraitInspector(
                    project: project,
                    character: project.characters.first,
                    portraitStateId: selectedStateId,
                    projectRootPath: '/project',
                    projectRevision: 'r1',
                    mediaResolver: _Resolver(invalidAssets: {'elia-surprised'}),
                    dialogueSourceReader: const _DialogueReader(),
                    isSaving: false,
                    onReplace: () async => true,
                    onFitChanged: (_) async => true,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Neutre'), findsWidgets);
      expect(find.text('neutral'), findsOneWidget);
      expect(find.text('elia-neutral'), findsOneWidget);
      expect(find.text('Source valide'), findsOneWidget);
      expect(find.text('Référence utilisée'), findsOneWidget);
      expect(find.text('Utilisé dans 1 dialogue'), findsOneWidget);
      expect(find.text('Attends… tu as vu ça ?'), findsOneWidget);
      expect(find.textContaining('Nox'), findsOneWidget);

      rebuild(() => selectedStateId = 'surprised');
      await tester.pumpAndSettle();

      expect(find.text('Surprise'), findsWidgets);
      expect(find.text('surprised'), findsOneWidget);
      expect(find.text('Source invalide'), findsOneWidget);
      expect(find.text('Quoi ?!'), findsOneWidget);

      rebuild(() => selectedStateId = 'angry');
      await tester.pumpAndSettle();

      expect(find.text('En colère'), findsWidgets);
      expect(find.text('Portrait absent'), findsOneWidget);
      expect(find.text('Aucune source'), findsOneWidget);
    },
  );
}

final class _Resolver implements CharacterStudioMediaResolverContract {
  const _Resolver({this.invalidAssets = const <String>{}});

  final Set<String> invalidAssets;

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) async {
    if (invalidAssets.contains(request.assetId)) {
      throw const FormatException('invalid portrait');
    }
    return Uint8List.fromList(const <int>[1, 2, 3]);
  }
}

final class _DialogueReader implements CharacterPortraitDialogueSourceReader {
  const _DialogueReader();

  @override
  Future<String?> read({
    required String projectRootPath,
    required String relativePath,
  }) async {
    return '''title: Start
---
<<portrait elia neutral>>
Élia: Attends… tu as vu ça ?
<<portrait elia surprised>>
Élia: Quoi ?!
===
''';
  }
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Portrait inspector',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'intro',
        name: 'Introduction',
        relativePath: 'dialogues/intro.yarn',
      ),
    ],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
        CharacterPortraitStateDefinition(
          id: 'surprised',
          displayName: 'Surprise',
          sortOrder: 1,
        ),
        CharacterPortraitStateDefinition(
          id: 'angry',
          displayName: 'En colère',
          sortOrder: 2,
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
          CharacterPortraitVariant(
            portraitStateId: 'surprised',
            assetId: 'elia-surprised',
          ),
        ],
      ),
      ProjectCharacterEntry(id: 'nox', name: 'Nox', tilesetId: 'nox'),
    ],
  );
}
