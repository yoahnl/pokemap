import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_bindings.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late Map<String, MapEditingViewportSession> views;
  late WorkspaceMapCatalogBindings bindings;
  late MapData prepared;
  var busy = false, dependencyDraft = false, reconciliations = 0, bounds = 0;

  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    prepared = maps.active!.current;
    views = {
      'a': MapEditingViewportSession(),
      'b': MapEditingViewportSession(),
    };
    busy = false;
    dependencyDraft = false;
    reconciliations = 0;
    bounds = 0;
    bindings = WorkspaceMapCatalogBindings(
      controller: maps,
      views: () => views,
      activeView: () => views[maps.active?.base.mapId],
      preparedMap: () => prepared,
      reconcileBrushes: () => reconciliations++,
      isBusy: () => busy,
      hasDependencyDraft: () => dependencyDraft,
      boundsChanged: () => bounds++,
    )..bind();
  });

  tearDown(() {
    bindings.dispose();
    for (final view in views.values) {
      view.dispose();
    }
    maps.dispose();
  });

  test(
    'catalogue guard refuses foreign drafts and only releases its own binding',
    () {
      final guard = maps.catalogDependencyFailure!;
      expect(guard('map.duplicate', 'a'), isNull);
      busy = true;
      expect(guard('map.duplicate', 'a'), isNotNull);
      busy = false;
      dependencyDraft = true;
      expect(guard('map.resize_apply', 'a'), isNotNull);
      dependencyDraft = false;
      expect(guard('map.resize_apply', 'a'), isNull);
      bindings.dispose();
      expect(maps.catalogDependencyFailure, isNull);
      bindings.bind();
      String? replacement(String action, String target) => 'Another owner';
      maps.catalogDependencyFailure = replacement;
      bindings.dispose();
      expect(maps.catalogDependencyFailure, same(replacement));
    },
  );

  test('removed map views are disposed and retained framing survives reconciliation', () {
    final retained = views['a']!;
    final removed = views['b']!;
    retained.transform.value.translateByDouble(18, 24, 0, 1);
    final transform = retained.transform.value.clone();
    maps.project = maps.project!.copyWith(maps: [workspaceEntries.first]);
    bindings.reconcile();
    expect(views.keys, ['a']);
    expect(views['a'], same(retained));
    expect(retained.transform.value, transform);
    expect(() => removed.transform.addListener(() {}), throwsFlutterError);
    expect(reconciliations, 1);
    expect(bounds, 0);
  });

  test('scoped bounds changes reset native moves without discarding another map brush', () {
    final active = views['a']!..brush = workspaceElement;
    final other = views['b']!..brush = workspaceElement;
    active.positioned = true;
    active.pendingMove = const MapSelectionTarget(
      mapId: 'a',
      family: MapSelectionFamily.decor,
      id: 'tree',
    );
    maps.projectScope = MapWorkspaceProjectScope.mapSelection;
    maps.project = maps.project!.copyWith(elements: const []);
    maps.active!.commit(
      prepared.copyWith(
        size: const GridSize(width: 24, height: 20),
        layers: const [],
      ),
    );
    bindings.reconcile();
    expect(active.brush, isNull);
    expect(other.brush, same(workspaceElement));
    expect(active.positioned, isFalse);
    expect(active.pendingMove, isNull);
    expect(bounds, 1);
    expect(reconciliations, 1);
  });
}
