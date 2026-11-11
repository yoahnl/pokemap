import 'package:avelune_studio/features/cinematics/application/cinematic_library_filter.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController controller;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [
        CinematicAdapterFixture.asset('a'),
        CinematicAdapterFixture.asset('b').copyWith(title: 'Arrivée au port'),
      ],
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    controller = CinematicWorkspaceController(
      narrative,
      f.adapter(),
      changed: () {},
    );
  });
  tearDown(() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });

  List<String> visible({
    String search = '',
    String folderId = '',
    bool archived = false,
  }) => [
    for (final asset in cinematicLibraryEntries(
      controller,
      search: search,
      folderId: folderId,
      archived: archived,
    ))
      asset.id,
  ];

  void catalog({List<CinematicLibraryEntry> entries = const []}) {
    maps.project = maps.project!.copyWith(
      cinematicLibraryCatalog: CinematicLibraryCatalog(
        folders: [
          CinematicLibraryFolder(
            id: 'intro',
            family: CinematicLibraryFamily.world,
            name: 'Introduction',
            sortOrder: 0,
          ),
        ],
        entries: entries,
      ),
    );
  }

  test(
    'two unpublished drafts remain visible in their selected folder',
    () async {
      final before = await f.file('project.json').readAsBytes();
      catalog();

      expect(
        await controller.create('Introduction sur carte', folderId: 'intro'),
        isTrue,
      );
      final first = controller.activeId!;
      expect(
        await controller.duplicate(first),
        isTrue,
        reason: controller.error,
      );
      final second = controller.activeId!;

      expect(controller.session(first)!.folderId, 'intro');
      expect(controller.session(second)!.folderId, 'intro');
      expect(visible(folderId: 'intro'), unorderedEquals([first, second]));
      expect(visible(folderId: 'autre'), isEmpty);
      expect(visible(), containsAll(['a', 'b', first, second]));
      expect(await f.file('project.json').readAsBytes(), before);
    },
  );

  test(
    'library search matches title map name and identifier ignoring case',
    () {
      expect(visible(search: '  ARRIVÉE '), ['b']);
      expect(visible(search: 'sans carte'), unorderedEquals(['a', 'b']));
      expect(visible(search: 'a'), contains('a'));
      expect(visible(search: 'introuvable'), isEmpty);
    },
  );

  test('archived cinematics stay hidden unless archives are shown', () {
    catalog(
      entries: [
        CinematicLibraryEntry(
          family: CinematicLibraryFamily.world,
          cinematicId: 'b',
          folderId: 'intro',
          sortOrder: 0,
          isArchived: true,
        ),
      ],
    );

    expect(visible(), ['a']);
    expect(visible(archived: true), unorderedEquals(['a', 'b']));
    expect(visible(folderId: 'intro', archived: true), ['b']);
  });
}
