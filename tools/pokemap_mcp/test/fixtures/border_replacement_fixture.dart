import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/border_replacement_fixture.dart';

Future<void> main(List<String> args) async {
  final root = Directory(args.single);
  final fixture = await writeBorderReplacementFixture(root);
  final project = fixture.project;
  final blueprint = project.borderCatalog.records.single;
  final editable = encodeBorderBlueprintRecordJson(
    BorderBlueprintRecord(id: blueprint.id, draft: blueprint.draft),
    formatVersion: project.borderCatalog.formatVersion,
  );
  final draft = editable['draft'] as Map<String, Object?>;
  final definition = draft['definition'] as Map<String, Object?>;
  definition['name'] = 'Republished ledge modules';
  final tileset = project.tilesets.single;
  final sources = <Map<String, Object?>>[];
  for (final primitive in blueprint.draft.definition.primitives) {
    final element = project.elements.singleWhere(
      (element) => element.id == primitive.sourceElementId,
    );
    final cell = element.frames.single.source;
    sources.add({
      'primitiveId': primitive.id,
      'frames': [
        {
          'sourceProjectRelativePath': tileset.relativePath,
          'sourceRectPx': {
            'x': cell.x * project.settings.tileWidth,
            'y': cell.y * project.settings.tileHeight,
            'width': cell.width * project.settings.tileWidth,
            'height': cell.height * project.settings.tileHeight,
          },
        },
      ],
    });
  }
  await File('${root.path}-republish-record.json')
      .writeAsString(jsonEncode({'record': editable, 'sources': sources}));
}
