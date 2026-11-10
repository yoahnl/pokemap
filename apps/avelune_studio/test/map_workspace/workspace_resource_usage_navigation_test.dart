import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/resource_map_journey_fixture.dart';

const _mapUsage = ResourceUsageEntry(
  ownerKind: 'map',
  ownerId: 'clairiere',
  ownerLabel: 'Clairière',
  location: 'maps/clairiere.json',
  relation: ResourceUsageRelation.direct,
  mapId: 'clairiere',
  entityId: 'clairiere-arbre',
);

const _decorUsage = ResourceUsageEntry(
  ownerKind: 'resource',
  ownerId: 'arbre',
  ownerLabel: 'Arbre',
  location: 'project.json',
  relation: ResourceUsageRelation.direct,
  resourceFamily: 'decors',
  resourceId: 'arbre',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a map usage opens the closed map and selects its exact instance without writing', () async {
    final fixture = await ResourceMapJourneyFixture.create();
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final project = File('${fixture.root.path}/project.json');
    final map = File('${fixture.root.path}/maps/clairiere.json');
    final projectBefore = await project.readAsBytes();
    final mapBefore = await map.readAsBytes();
    var focusFlushes = 0;
    var toolChanges = 0;
    final navigation = WorkspaceNavigationSession(
      controller: fixture.workspace,
      isActive: () => !fixture.workspace.isDisposed,
      changed: () {},
      resources: () => fixture.navigation,
      mapView: () => view,
      toolChanged: () => toolChanges++,
      flushResourceFocus: () => focusFlushes++,
    )..space = WorkspaceSpace.resources;
    expect(fixture.workspace.documents.containsKey('clairiere'), isFalse);
    expect(navigation.canOpenResourceUsage(_mapUsage), isTrue);
    expect(await navigation.openResourceUsage(_mapUsage), isTrue);
    final document = fixture.workspace.active!;
    expect(document.current.id, 'clairiere');
    expect(view.selectedFor('clairiere', MapSelectionFamily.decor), 'clairiere-arbre');
    expect(document.undoCount, 0);
    expect(document.dirty, isFalse);
    expect(navigation.space, WorkspaceSpace.map);
    expect((focusFlushes, toolChanges), (1, 1));
    expect(await project.readAsBytes(), projectBefore);
    expect(await map.readAsBytes(), mapBefore);
  });

  test('resource usage opens the exact project resource and keeps the active map', () async {
    final fixture = await ResourceMapJourneyFixture.create();
    final current = fixture.workspace.active;
    final navigation = WorkspaceNavigationSession(
      controller: fixture.workspace,
      isActive: () => !fixture.workspace.isDisposed,
      changed: () {},
      resources: () => fixture.navigation,
    );
    expect(await navigation.openResourceUsage(_decorUsage), isTrue);
    expect(fixture.navigation.page, ResourcePage.library);
    expect(fixture.navigation.library.selectedIdentity, 'element:arbre');
    expect(fixture.workspace.active, same(current));
    expect(navigation.space, WorkspaceSpace.resources);
  });

  test('busy owners, pending receipts, dialogs and missing targets refuse navigation', () async {
    final fixture = await ResourceMapJourneyFixture.create();
    var workspaceBusy = true;
    var focusFlushes = 0;
    final navigation = WorkspaceNavigationSession(
      controller: fixture.workspace,
      isActive: () => !fixture.workspace.isDisposed,
      changed: () {},
      resources: () => fixture.navigation,
      resourceUsageBusy: () => workspaceBusy,
      flushResourceFocus: () => focusFlushes++,
    );
    expect(await navigation.openResourceUsage(_decorUsage), isFalse);
    workspaceBusy = false;
    fixture.navigation.busy = true;
    expect(await navigation.openResourceUsage(_decorUsage), isFalse);
    fixture.navigation.busy = false;
    fixture.navigation.beginManagementDialog();
    expect(await navigation.openResourceUsage(_decorUsage), isFalse);
    fixture.navigation.endManagementDialog();
    final project = fixture.workspace.project!;
    fixture.navigation.pendingReceipt = ResourceMutationReceipt(
      before: project,
      manifest: project,
      beforeRevision: 'before',
      revision: 'after',
      changedPaths: const [],
    );
    expect(await navigation.openResourceUsage(_decorUsage), isFalse);
    fixture.navigation.pendingReceipt = null;
    const missing = ResourceUsageEntry(
      ownerKind: 'map', ownerId: 'absent', ownerLabel: 'Absente',
      location: 'missing.json', relation: ResourceUsageRelation.direct,
      mapId: 'absent',
    );
    expect(navigation.canOpenResourceUsage(missing), isFalse);
    expect(await navigation.openResourceUsage(missing), isFalse);
    expect(focusFlushes, 0);
    expect(fixture.workspace.active!.current.id, 'jardin');
  });

  test('a newer route prevents a late map usage from taking focus', () async {
    final port = _DelayedMapPort();
    final controller = MapWorkspaceController(workspaceSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final navigation = WorkspaceNavigationSession(
      controller: controller,
      isActive: () => !controller.isDisposed,
      changed: () {},
    )..space = WorkspaceSpace.resources;
    const entry = ResourceUsageEntry(
      ownerKind: 'map', ownerId: 'b', ownerLabel: 'Jardin',
      location: 'b.json', relation: ResourceUsageRelation.direct, mapId: 'b',
    );
    final opening = navigation.openResourceUsage(entry);
    await port.started.future;
    navigation.show(WorkspaceSpace.story);
    port.release.complete();
    expect(await opening, isFalse);
    expect(navigation.space, WorkspaceSpace.story);
    expect(controller.active!.current.id, 'a');
  });

  test('diagnostic owners resolve actual project identities before opening', () async {
    final fixture = await ResourceMapJourneyFixture.create();
    final navigation = WorkspaceNavigationSession(
      controller: fixture.workspace,
      isActive: () => !fixture.workspace.isDisposed,
      changed: () {},
      resources: () => fixture.navigation,
    );
    var workshopCalls = 0;
    Future<void> openWorkshop(void Function() prepare) async {
      workshopCalls++;
      prepare();
    }
    expect(await navigation.openResourceDiagnosticOwner(
      'element', 'arbre', openWorkshop: openWorkshop,
    ), isTrue);
    expect(fixture.navigation.library.selectedIdentity, 'element:arbre');
    expect(await navigation.openResourceDiagnosticOwner(
      'element', 'missing', openWorkshop: openWorkshop,
    ), isFalse);
    expect(await navigation.openResourceDiagnosticOwner(
      'character', 'missing', openWorkshop: openWorkshop,
    ), isFalse);
    expect(workshopCalls, 1);
  });
}

class _DelayedMapPort extends WorkspaceMemoryPort {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    if (entry.id == 'b') {
      started.complete();
      await release.future;
    }
    return super.loadMap(session, entry);
  }
}
