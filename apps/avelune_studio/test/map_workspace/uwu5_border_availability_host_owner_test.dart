import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_disk_owner_fixture.dart';

void main() {
  testWidgets('an unavailable selected border is never replaced by another', (
    tester,
  ) async {
    final host = await MapDiskOwnerFixture.open(
      tester,
      prepareSource: (source) async {
        final file = File('${source.directory.path}/project.json');
        final manifest = ProjectManifest.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        final catalog = testBorderCatalog();
        final published = catalog.records.single;
        final deprecated = BorderBlueprintRecord(
          id: published.id,
          draft: published.draft,
          latestPublished: published.latestPublished,
          isDeprecated: true,
        );
        final other = BorderBlueprintRecord(
          id: 'another-border',
          draft: published.draft,
          latestPublished: published.latestPublished,
        );
        await file.writeAsString(
          jsonEncode(
            manifest
                .copyWith(
                  borderCatalog: ProjectBorderCatalog(
                    formatVersion: catalog.formatVersion,
                    records: [deprecated, other],
                    visualSnapshots: catalog.visualSnapshots,
                  ),
                )
                .toJson(),
          ),
        );
      },
    );
    await host.selectTool(StudioMapTool.border);
    final view = host.view;
    expect(view.borderBlueprintId, isNull);
    expect(
      MapBorderEditingCommands.publishedLines(host.maps.project!)
          .map((record) => record.id),
      ['another-border'],
    );
    final before = host.document.current;
    await host.tapCell(10, 8);
    await host.pump(frames: 2);
    expect(view.borderDraft, isNull);
    expect(host.document.current, before);
    expect(host.document.error, contains('Choisissez'));
    expect(view.borderBlueprintId, isNot('another-border'));
  });
}
