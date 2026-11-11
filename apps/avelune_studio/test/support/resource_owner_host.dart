import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../resource_io/resource_fixture.dart';
import 'map_workspace_fixture.dart';

class ResourceOwnerHost {
  ResourceOwnerHost(this.fixture, this.workspace, this.navigation);

  final ResourceFixture fixture;
  final MapWorkspaceController workspace;
  final ResourceNavigation navigation;

  static Future<ResourceOwnerHost> create({
    bool withMap = true,
    Future<void> Function(ResourceFixture)? configure,
  }) async {
    final fixture = await ResourceFixture.create(withMap: withMap);
    addTearDown(fixture.dispose);
    await fixture.import();
    await configure?.call(fixture);
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final visuals = WorkspaceTestVisuals();
    addTearDown(visuals.dispose);
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: fixture.resources,
      visuals: visuals,
      onUse: (_) {},
    );
    addTearDown(() {
      if (!navigation.isDisposed) navigation.dispose();
    });
    return ResourceOwnerHost(fixture, workspace, navigation);
  }

  ResourceItem get item => resourceCatalog(
    workspace.project!,
  ).singleWhere((item) => item.tileset != null);

  Future<ProjectManifest> reopen() =>
      LocalMapWorkspaceAdapter().loadProject(fixture.session);
}
