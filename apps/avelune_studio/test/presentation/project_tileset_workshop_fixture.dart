import 'package:avelune_studio/features/rendering/contracts/scoped_resource_preview_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/resources/domain/project_tileset_workshop_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_tileset_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

Future<void> pumpTilesetWorkshop(
  WidgetTester tester,
  ProjectTilesetSource? source, {
  TilesetWorkshopTestVisuals? visuals,
  List<String>? reads,
  Map<String, String>? usages,
  Future<bool> Function(String)? onOpenMap,
  VoidCallback? onBack,
  String? cardName,
  ProjectTilesetSource Function()? readSource,
  ProjectTilesetGridEditor? gridEditor,
}) async {
  final atlas = ProjectTilesetEntry(
    id: 'atlas',
    name: 'Planche du jardin',
    relativePath: 'atlas.png',
    source: source,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProjectTilesetWorkshop(
          item: ProjectLibraryItem(
            kind: 'tileset',
            id: atlas.id,
            name: cardName ?? atlas.name,
          ),
          visuals: visuals,
          previews: ProjectResourcePreviews((item) async {
            reads?.add(item.identity);
            return ProjectManifest(
              name: 'Jardin',
              maps: const [],
              tilesets: [atlas.copyWith(source: readSource?.call() ?? source)],
            );
          }),
          usages: usages,
          onOpenMap: onOpenMap,
          onBack: onBack ?? () {},
          gridEditor: gridEditor,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class TilesetWorkshopTestVisuals extends WorkspaceTestVisuals
    implements ScopedResourcePreviewVisuals {
  late AtlasPreviewSource last;

  @override
  void refreshResourcePreviews() {}

  @override
  void invalidateResourcePreviews(Set<String> changedRelativePaths) {}

  @override
  Widget scopedResourcePreview(
    ResourcePreviewSource source,
    ProjectManifest project, {
    required double size,
  }) {
    last = source as AtlasPreviewSource;
    return const SizedBox.expand();
  }
}
