import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'environment_scope_test.dart' show EnvironmentScopeFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('canonical environment owner publication and catalogue use keep gestures as commands and disk reopen', () async {
    final scope = await EnvironmentScopeFixture.create(withZones: false);
    addTearDown(scope.dispose);
    final document = scope.workspace.active!;
    final commands = EnvironmentEditingCommands(document, scope.workspace.project!);
    final session = commands.create(scope.preset);
    final history = document.undoCount;
    commands.paint(session, [
      for (var x = 0; x <= 3; x++)
        for (var y = 0; y <= 3; y++) GridPos(x: x, y: y),
    ], erase: false);
    commands.paint(session, const [GridPos(x: 2, y: 2)], erase: true);
    expect(document.undoCount, greaterThan(history));
    final area = commands.area(session)!;
    expect(area.mask.isActiveAt(0, 0), isTrue);
    expect(area.mask.isActiveAt(2, 2), isFalse);
    expect(area.mask.isActiveAt(4, 4), isFalse);
    final beforePreview = document.current;
    commands.preview(session);
    expect(document.error, isNull);
    expect(document.current, beforePreview);
    expect(session.generation!.placements, isNotEmpty);
    expect(
      session.generation!.placements.any(
        (placement) => placement.pos == const GridPos(x: 2, y: 2),
      ),
      isFalse,
    );
    commands.apply(session);
    expect(
      document.current.placedElements.length,
      greaterThan(beforePreview.placedElements.length),
    );
    final savedArea = document.current.layers
        .whereType<EnvironmentLayer>()
        .single
        .content
        .areas
        .single;
    expect(await scope.workspace.save(document), isTrue, reason: document.error);
    expect(document.dirty, isFalse);
    final owner = LocalMapWorkspaceAdapter();
    final project = await owner.loadProject(scope.fixture.session);
    final disk = await owner.loadMap(
      scope.fixture.session,
      project.maps.firstWhere((entry) => entry.id == document.current.id),
    );
    expect(
      disk.map.layers.whereType<EnvironmentLayer>().single.content.areas.single,
      savedArea,
    );
  });

  test('canonical resource editor entry rejects an invalid recipe and retains its draft on library return without writes', () async {
    final scope = await EnvironmentScopeFixture.create(withZones: false);
    addTearDown(scope.dispose);
    final n = scope.navigation;
    final before = await scope.files();
    n.openEnvironment();
    final draft = n.environment!..name = 'Brouillon à garder';
    await expectLater(n.saveEnvironment(), throwsFormatException);
    expect(n.error, contains('Ajoutez au moins un décor'));
    expect(await scope.files(), before);
    final error = n.error;
    n.showLibrary();
    expect(n.error, error);
    expect(n.environment, same(draft));
    expect(n.environments[draft.id], same(draft));
    expect(draft.name, 'Brouillon à garder');
    expect(n.library.atelierVisible, isFalse);
    expect(n.dirty, isTrue);
  });

  test('retired environment routes preserve invalid drafts selection and native dirty refusal', () async {
    late EnvironmentScopeFixture scope;
    final view = MapWorkspaceEditingState();
    final uses = <bool>[];
    final pending = <Future<void>>[];
    scope = await EnvironmentScopeFixture.create(
      withZones: false,
      onUse: (item) {
        pending.add(
          useMapEnvironment(
            workspace: scope.workspace,
            resources: scope.navigation,
            preset: item.environment!,
            view: () => view,
            isActive: () => true,
            chooseMap: (_) async => null,
          ).then(uses.add),
        );
      },
    );
    addTearDown(scope.dispose);
    final n = scope.navigation;
    n.library
      ..query = scope.preset.name
      ..select(scope.item)
      ..marked.add(scope.item.identity);
    final beforeFiles = await scope.files();
    final beforeProject = scope.workspace.project!.toJson();
    final history = scope.workspace.active!.undoCount;
    n.onUse(scope.item);
    await Future.wait(pending);
    expect(uses, [true]);
    expect(scope.workspace.active!.undoCount, history + 1);
    final armedMap = scope.workspace.active!.current;
    final armedHistory = scope.workspace.active!.undoCount;
    n.openEnvironment(scope.preset);
    final draft = n.environment!..name = 'Saisie à conserver';
    draft.setWeightInput('tree', 'non');
    draft.setSpacingInput('-2');
    draft.setOffsetInput('tree', 'x', 'NaN');
    await expectLater(n.saveEnvironment(), throwsFormatException);
    final error = n.error;
    expect(error, isNotNull);
    final selected = n.library.selectedIdentity;
    final marked = {...n.library.marked};
    final query = n.library.query;
    n.showLibrary();
    expect(n.page, ResourcePage.library);
    expect(n.library.atelierVisible, isFalse);
    expect(n.library.selectedIdentity, selected);
    expect(n.library.marked, marked);
    expect(n.library.query, query);
    expect(n.environment, same(draft));
    expect(n.environments[draft.id], same(draft));
    expect(n.error, error);
    expect(draft.name, 'Saisie à conserver');
    expect(draft.weightInput('tree'), 'non');
    expect(draft.spacingInput, '-2');
    expect(draft.offsetInput('tree', 'x'), 'NaN');
    expect(draft.build, throwsFormatException);

    n.onUse(scope.item);
    await Future.wait(pending);
    expect(uses, [true, false]);
    expect(n.error, contains('Enregistrez ou annulez'));
    expect(scope.workspace.active!.current, armedMap);
    expect(scope.workspace.active!.undoCount, armedHistory);
    expect(await n.saveDrafts(), isFalse);
    expect(n.environments[draft.id], same(draft));
    expect(scope.workspace.project!.toJson(), beforeProject);
    expect(await scope.files(), beforeFiles);
  });

  test('returning from copied and new environment routes retains both independent owners without publishing', () async {
    final scope = await EnvironmentScopeFixture.create(withZones: false);
    addTearDown(scope.dispose);
    final n = scope.navigation;
    final beforeFiles = await scope.files();
    n.duplicateEnvironment(scope.preset);
    final copied = n.environment!;
    final copyValue = copied.build();
    expect(copied.original, isNull);
    expect(copied.id, isNot(scope.preset.id));
    expect(copyValue.palette, scope.preset.palette);
    n.showLibrary();
    n.openEnvironment();
    final empty = n.environment!;
    expect(empty.id, isNot(copied.id));
    n.showLibrary();
    expect(n.environments, hasLength(2));
    expect(n.environments[copied.id], same(copied));
    expect(copied.build(), copyValue);
    expect(n.environments[empty.id], same(empty));
    expect(empty.build, throwsFormatException);
    expect(n.environment, same(empty));
    expect(n.library.atelierVisible, isFalse);
    expect(scope.workspace.project!.environmentPresets, [scope.preset]);
    expect(await scope.files(), beforeFiles);
  });

  test('a retired environment route keeps its recipe without opening a decor owner', () async {
    final scope = await EnvironmentScopeFixture.create(withZones: false);
    addTearDown(scope.dispose);
    final n = scope.navigation;
    final beforeFiles = await scope.files();
    final beforeProject = scope.workspace.project!.toJson();
    final decor = resourceCatalog(
      scope.workspace.project!,
    ).firstWhere((item) => item.element != null);
    n.openEnvironment();
    final draft = n.environment!
      ..name = 'Palette conservée'
      ..add(decor.id);
    final prepared = draft.build();
    expect(n.decor, isNull);
    n.showLibrary();
    expect(n.page, ResourcePage.library);
    expect(n.environment, same(draft));
    expect(draft.build(), prepared);
    expect(n.decor, isNull);
    expect(scope.workspace.project!.toJson(), beforeProject);
    expect(await scope.files(), beforeFiles);
  });
}
