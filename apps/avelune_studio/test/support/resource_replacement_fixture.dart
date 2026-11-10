import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';

import '../resource_io/resource_fixture.dart';
import 'map_workspace_fixture.dart';

class ResourceReplacementFixture {
  ResourceReplacementFixture(this.fixture, this.workspace, this.navigation);

  final ResourceFixture fixture;
  final MapWorkspaceController workspace;
  final ResourceNavigation navigation;

  static Future<ResourceReplacementFixture> create({
    Future<void> Function()? beforeReconciliation,
    bool withMap = true,
  }) async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    final fixture = await ResourceFixture.create(
      parent: parent,
      withMap: withMap,
    );
    addTearDown(fixture.dispose);
    await fixture.import();
    final adapter = LocalResourceAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
      beforeReconciliation: beforeReconciliation,
    );
    addTearDown(adapter.dispose);
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final visuals = WorkspaceTestVisuals();
    addTearDown(visuals.dispose);
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: adapter,
      visuals: visuals,
      onUse: (_) {},
    );
    addTearDown(navigation.dispose);
    return ResourceReplacementFixture(fixture, workspace, navigation);
  }

  ResourceItem get item =>
      resourceCatalog(workspace.project!)
          .singleWhere((item) => item.tileset != null);

  Future<ProjectManifest> reopen() => fixture.maps.loadProject(fixture.session);

  Future<PickedResourceImage> candidate({
    int width = 64,
    int height = 48,
    String name = 'candidate',
  }) async {
    final pixels = image.Image(width: width, height: height);
    image.fill(pixels, color: image.ColorRgba8(220, 80, 30, 255));
    final bytes = Uint8List.fromList(image.encodePng(pixels));
    final file = File('${fixture.root.path}/$name.png');
    await file.writeAsBytes(bytes);
    return PickedResourceImage(file.path, name, bytes, width, height);
  }

  Future<Map<String, List<int>>> files() async => {
    for (final entity in fixture.root.listSync(recursive: true))
      if (entity is File) entity.path: await entity.readAsBytes(),
  };
}
