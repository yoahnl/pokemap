import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/presentation/portraits/character_studio_portraits_tab.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('portrait grid keeps selection after a successful import', (
    tester,
  ) async {
    var project = _project();
    String? importedState;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SizedBox(
                width: 900,
                height: 760,
                child: CharacterStudioPortraitsTab(
                  project: project,
                  character: project.characters.single,
                  projectRootPath: '/project',
                  projectRevision: 'r1',
                  mediaResolver: _MemoryResolver(),
                  isSaving: false,
                  onImport: (stateId) async {
                    importedState = stateId;
                    final character = project.characters.single;
                    project = project.copyWith(
                      characters: <ProjectCharacterEntry>[
                        character.copyWith(
                          portraits: <CharacterPortraitVariant>[
                            ...character.portraits,
                            CharacterPortraitVariant(
                              portraitStateId: stateId,
                              assetId: 'elia-$stateId',
                            ),
                          ],
                        ),
                      ],
                    );
                    rebuild(() {});
                    return true;
                  },
                  onClear: (_) async => true,
                  onFitChanged: (_, _) async => true,
                  onManageGlobalStates: () {},
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Neutre'), findsWidgets);
    expect(find.text('Surprise'), findsWidgets);
    expect(find.text('Non défini'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-state-card-surprised')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('portrait-selected-surprised')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-import-surprised')),
    );
    await tester.pumpAndSettle();

    expect(importedState, 'surprised');
    expect(
      find.byKey(const ValueKey<String>('portrait-selected-surprised')),
      findsOneWidget,
    );
    expect(find.text('Portrait importé'), findsOneWidget);
  });

  testWidgets('portrait tab exposes replace clear fit and global catalog', (
    tester,
  ) async {
    var replaced = 0;
    String? cleared;
    CharacterPortraitFitMode? fitMode;
    var globalRequests = 0;
    final project = _project();
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 760,
            child: CharacterStudioPortraitsTab(
              project: project,
              character: project.characters.single,
              projectRootPath: '/project',
              projectRevision: 'r1',
              mediaResolver: _MemoryResolver(),
              isSaving: false,
              onImport: (_) async {
                replaced++;
                return true;
              },
              onClear: (stateId) async {
                cleared = stateId;
                return true;
              },
              onFitChanged: (stateId, value) async {
                fitMode = value;
                return true;
              },
              onManageGlobalStates: () => globalRequests++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-replace-neutral')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('portrait-fit-cover')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-clear-neutral')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('portrait-manage-global-states')),
    );

    expect(replaced, 1);
    expect(cleared, 'neutral');
    expect(fitMode, CharacterPortraitFitMode.cover);
    expect(globalRequests, 1);
  });
}

final class _MemoryResolver implements CharacterStudioMediaResolverContract {
  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) async {
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLzNwAAAABJRU5ErkJggg==',
    );
  }
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Portrait tab',
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
    ],
  );
}
