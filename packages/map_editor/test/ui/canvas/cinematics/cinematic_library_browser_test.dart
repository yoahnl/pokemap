import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_document_route.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_library_browser.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_library_dialogs.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  test('navigation keeps an independent context for each family', () {
    final state = CinematicLibraryNavigationState.initial()
        .updateActive(
          folderId: 'world-chapter',
          searchQuery: 'rival',
          sort: NarrativeLibrarySort.nameDescending,
          selectedAssetId: 'world-intro',
          scrollOffset: 240,
        )
        .switchFamily(CinematicLibraryFamily.presentation)
        .updateActive(
          folderId: 'presentation-opening',
          searchQuery: 'dragon',
          selectedAssetId: 'presentation-intro',
          scrollOffset: 80,
        )
        .switchFamily(CinematicLibraryFamily.world);

    expect(state.activeFamily, CinematicLibraryFamily.world);
    expect(state.active.folderId, 'world-chapter');
    expect(state.active.searchQuery, 'rival');
    expect(state.active.sort, NarrativeLibrarySort.nameDescending);
    expect(state.active.selectedAssetId, 'world-intro');
    expect(state.active.scrollOffset, 240);

    final presentation = state.switchFamily(
      CinematicLibraryFamily.presentation,
    );
    expect(presentation.active.folderId, 'presentation-opening');
    expect(presentation.active.searchQuery, 'dragon');
    expect(presentation.active.selectedAssetId, 'presentation-intro');
    expect(presentation.active.scrollOffset, 80);
  });

  test('an inaccessible folder fails closed to its family root', () {
    final state = CinematicLibraryNavigationState.initial().updateActive(
      folderId: 'deleted-folder',
      selectedAssetId: 'world-intro',
      scrollOffset: 120,
    );

    final normalized = state.normalize(_project().cinematicLibraryCatalog);

    expect(normalized.active.folderId, isNull);
    expect(normalized.active.selectedAssetId, isNull);
    expect(normalized.active.scrollOffset, 0);
    expect(normalized.folderWasInaccessible, isTrue);
  });

  testWidgets(
    'browser starts in-game and traverses recursive family folders without ids',
    (tester) async {
      var state = CinematicLibraryNavigationState.initial();
      await tester.pumpWidget(
        _Harness(
          project: _project(),
          state: state,
          onChanged: (value) => state = value,
        ),
      );

      expect(find.text('Cinématiques in-game'), findsOneWidget);
      expect(find.text('Cinématiques de présentation'), findsOneWidget);
      expect(find.text('Histoire'), findsOneWidget);
      expect(find.text('Ouvertures'), findsNothing);
      expect(find.text('world-story'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-folder-world-story')),
      );
      await tester.pump();
      expect(find.text('Chapitre 1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('cinematic-folder-world-chapter')),
      );
      await tester.pump();
      expect(find.text('Duel du rival'), findsOneWidget);
      expect(find.text('world-intro'), findsNothing);

      await tester.tap(find.text('Cinématiques de présentation'));
      await tester.pump();
      expect(find.text('Ouvertures'), findsOneWidget);
      expect(find.text('Histoire'), findsNothing);

      await tester.tap(find.text('Cinématiques in-game'));
      await tester.pump();
      expect(find.text('Chapitre 1'), findsWidgets);
      expect(state.active.folderId, 'world-chapter');
    },
  );

  testWidgets('search, sort, view mode and Presentation opening stay typed', (
    tester,
  ) async {
    var state = CinematicLibraryNavigationState.initial().switchFamily(
      CinematicLibraryFamily.presentation,
    );
    NarrativeLibrarySourceContext? openedSource;
    String? openedId;

    await tester.pumpWidget(
      _Harness(
        project: _project(),
        state: state,
        onChanged: (value) => state = value,
        onOpenPresentation: ({required cinematicId, required source}) {
          openedId = cinematicId;
          openedSource = source;
        },
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('cinematic-family-search')),
      'logo',
    );
    await tester.pump();
    expect(find.text('Logo Avelune'), findsOneWidget);
    expect(find.text('Ouverture du monde'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('cinematic-family-sort')),
        matching: find.byType(DropdownButton<NarrativeLibrarySort>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nom Z–A').last);
    await tester.pumpAndSettle();
    expect(state.active.sort, NarrativeLibrarySort.nameDescending);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('cinematic-family-visibility')),
        matching: find.byType(DropdownButton<NarrativeLibraryVisibility>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes').last);
    await tester.pumpAndSettle();
    expect(state.active.visibility, NarrativeLibraryVisibility.all);

    await tester.tap(find.byKey(const ValueKey('cinematic-view-grid')));
    await tester.pump();
    expect(state.active.viewMode, CinematicLibraryViewMode.grid);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-asset-presentation-logo')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cinematic-open-selection')));
    await tester.pump();

    expect(openedId, 'presentation-logo');
    expect(openedSource?.cinematicFamily, CinematicLibraryFamily.presentation);
    expect(openedSource?.searchQuery, 'logo');
    expect(openedSource?.sort, NarrativeLibrarySort.nameDescending);
    expect(openedSource?.visibility, NarrativeLibraryVisibility.all);
    expect(openedSource?.selectedAssetId, 'presentation-logo');
  });

  testWidgets('renders loading, empty search and load error states', (
    tester,
  ) async {
    Future<void> pump(CinematicLibraryBrowserLoadState loadState) async {
      await tester.pumpWidget(
        _Harness(
          project: _project(),
          state: CinematicLibraryNavigationState.initial(),
          loadState: loadState,
        ),
      );
    }

    await pump(CinematicLibraryBrowserLoadState.loading);
    expect(find.byType(PokeMapCinematicSkeletonTile), findsNWidgets(3));

    await pump(CinematicLibraryBrowserLoadState.error);
    expect(find.text('Bibliothèque indisponible'), findsOneWidget);

    await pump(CinematicLibraryBrowserLoadState.content);
    await tester.enterText(
      find.byKey(const ValueKey('cinematic-family-search')),
      'aucun résultat possible',
    );
    await tester.pump();
    expect(find.text('Aucun résultat'), findsOneWidget);
  });

  testWidgets('renders a truly empty family and recovers a stale folder', (
    tester,
  ) async {
    final emptyProject = _project().copyWith(
      cinematics: const [],
      cinematicLibraryCatalog: const CinematicLibraryCatalog.empty(),
    );
    await tester.pumpWidget(
      _Harness(
        key: const ValueKey('empty-family'),
        project: emptyProject,
        state: CinematicLibraryNavigationState.initial(),
      ),
    );
    expect(find.text('Bibliothèque vide'), findsOneWidget);

    await tester.pumpWidget(
      _Harness(
        key: const ValueKey('stale-folder'),
        project: _project(),
        state: CinematicLibraryNavigationState.initial().updateActive(
          folderId: 'folder-that-no-longer-exists',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Dossier indisponible'), findsOneWidget);
    expect(find.text('Histoire'), findsOneWidget);
  });

  testWidgets('new Presentation flow exposes the six presets without ratio', (
    tester,
  ) async {
    CinematicLibraryCreateRequest? received;
    await tester.pumpWidget(
      _Harness(
        project: _project(),
        state: CinematicLibraryNavigationState.initial().switchFamily(
          CinematicLibraryFamily.presentation,
        ),
        onCreate: (request) async {
          received = request;
          return 'new-presentation';
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cinematic-library-new')));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle cinématique de présentation'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('presentation-template-card')),
      findsNWidgets(6),
    );
    expect(find.textContaining('16:9'), findsNothing);
    expect(find.textContaining('9:16'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('cinematic-create-title')),
      'Ouverture céleste',
    );
    final immersive = find.byKey(
      const ValueKey('presentation-template-immersiveOpening'),
    );
    await tester.ensureVisible(immersive);
    await tester.tap(immersive);
    await tester.tap(find.byKey(const ValueKey('cinematic-create-submit')));
    await tester.pumpAndSettle();

    expect(received?.title, 'Ouverture céleste');
    expect(received?.family, CinematicLibraryFamily.presentation);
    expect(received?.presentationTemplateId, 'immersiveOpening');
    expect(received?.presentationTemplateVersion, 1);
  });

  testWidgets('new in-game flow offers only the three starting points', (
    tester,
  ) async {
    CinematicLibraryCreateRequest? received;
    await tester.pumpWidget(
      _Harness(
        project: _project(),
        state: CinematicLibraryNavigationState.initial(),
        onCreate: (request) async {
          received = request;
          return 'new-world';
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cinematic-library-new')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('world-starting-point-card')),
      findsNWidgets(3),
    );

    await tester.enterText(
      find.byKey(const ValueKey('cinematic-create-title')),
      'Arrivée au port',
    );
    await tester.tap(
      find.byKey(const ValueKey('world-starting-point-establishingShot')),
    );
    await tester.tap(find.byKey(const ValueKey('cinematic-create-submit')));
    await tester.pumpAndSettle();

    expect(received?.family, CinematicLibraryFamily.world);
    expect(
      received?.worldStartingPoint,
      CinematicLibraryWorldStartingPoint.establishingShot,
    );
  });

  testWidgets('selected asset exposes the complete management command set', (
    tester,
  ) async {
    String? duplicatedId;
    await tester.pumpWidget(
      _Harness(
        project: _project(),
        state: CinematicLibraryNavigationState.initial()
            .updateActive(folderId: 'world-story')
            .updateActive(folderId: 'world-chapter'),
        onDuplicate: ({required family, required cinematicId, folderId}) async {
          duplicatedId = cinematicId;
          return 'world-intro-copy';
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cinematic-entry-world-intro')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cinematic-library-actions')));
    await tester.pumpAndSettle();

    expect(find.text('Renommer'), findsOneWidget);
    expect(find.text('Déplacer'), findsOneWidget);
    expect(find.text('Dupliquer'), findsOneWidget);
    expect(find.text('Archiver'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);

    await tester.tap(find.text('Dupliquer'));
    await tester.pumpAndSettle();
    expect(duplicatedId, 'world-intro');
  });

  testWidgets(
    'creation keeps values on failure and neutralizes double submit',
    (tester) async {
      final pending = Completer<String?>();
      var calls = 0;
      await tester.pumpWidget(
        _Harness(
          project: _project(),
          state: CinematicLibraryNavigationState.initial(),
          onCreate: (request) {
            calls += 1;
            return pending.future;
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey('cinematic-library-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('cinematic-create-title')),
        'Titre conservé',
      );
      final submit = find.byKey(const ValueKey('cinematic-create-submit'));
      await tester.tap(submit);
      await tester.tap(submit, warnIfMissed: false);
      expect(calls, 1);

      pending.completeError(StateError('Conflit simulé'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle cinématique in-game'), findsOneWidget);
      expect(find.text('Titre conservé'), findsOneWidget);
      expect(find.textContaining('Conflit simulé'), findsOneWidget);
    },
  );
}

class _Harness extends StatefulWidget {
  const _Harness({
    super.key,
    required this.project,
    required this.state,
    this.onChanged,
    this.onOpenPresentation,
    this.onCreate,
    this.onDuplicate,
    this.loadState = CinematicLibraryBrowserLoadState.content,
  });

  final ProjectManifest project;
  final CinematicLibraryNavigationState state;
  final ValueChanged<CinematicLibraryNavigationState>? onChanged;
  final OpenPresentationCinematicCallback? onOpenPresentation;
  final CinematicLibraryCreateCallback? onCreate;
  final CinematicLibraryDuplicateCallback? onDuplicate;
  final CinematicLibraryBrowserLoadState loadState;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late CinematicLibraryNavigationState state = widget.state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 760,
          child: CinematicLibraryBrowser(
            project: widget.project,
            navigation: state,
            loadState: widget.loadState,
            onNavigationChanged: (value) {
              setState(() => state = value);
              widget.onChanged?.call(value);
            },
            onOpenInGame: (_) {},
            onOpenPresentation:
                widget.onOpenPresentation ??
                ({required cinematicId, required source}) {},
            onCreate: widget.onCreate,
            onDuplicate: widget.onDuplicate,
          ),
        ),
      ),
    );
  }
}

ProjectManifest _project() => ProjectManifest(
  name: 'Library fixture',
  version: ProjectVersion.v7,
  maps: const [],
  tilesets: const [],
  cinematics: [
    CinematicAsset(
      id: 'world-intro',
      title: 'Duel du rival',
      timeline: CinematicTimeline(),
    ),
  ],
  presentationCinematics: [
    PresentationCinematicAsset(
      id: 'presentation-intro',
      title: 'Ouverture du monde',
      durationUs: 12000000,
    ),
    PresentationCinematicAsset(
      id: 'presentation-logo',
      title: 'Logo Avelune',
      durationUs: 6000000,
    ),
  ],
  cinematicLibraryCatalog: CinematicLibraryCatalog(
    folders: [
      CinematicLibraryFolder(
        id: 'world-story',
        family: CinematicLibraryFamily.world,
        name: 'Histoire',
        sortOrder: 0,
      ),
      CinematicLibraryFolder(
        id: 'world-chapter',
        family: CinematicLibraryFamily.world,
        name: 'Chapitre 1',
        parentFolderId: 'world-story',
        sortOrder: 0,
      ),
      CinematicLibraryFolder(
        id: 'presentation-opening',
        family: CinematicLibraryFamily.presentation,
        name: 'Ouvertures',
        sortOrder: 0,
      ),
    ],
    entries: [
      CinematicLibraryEntry(
        family: CinematicLibraryFamily.world,
        cinematicId: 'world-intro',
        folderId: 'world-chapter',
        sortOrder: 0,
      ),
      CinematicLibraryEntry(
        family: CinematicLibraryFamily.presentation,
        cinematicId: 'presentation-intro',
        folderId: 'presentation-opening',
        sortOrder: 0,
      ),
      CinematicLibraryEntry(
        family: CinematicLibraryFamily.presentation,
        cinematicId: 'presentation-logo',
        sortOrder: 0,
      ),
    ],
  ),
);
