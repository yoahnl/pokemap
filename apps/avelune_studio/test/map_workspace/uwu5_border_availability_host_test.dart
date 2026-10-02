import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('an unavailable selected border is never replaced by another', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
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
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 4);
    final view = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    view.borderBlueprintId = 'muret';
    host.maps.notify();
    await pumpIo(tester, frames: 3);
    expect(view.borderBlueprintId, isNull);
    expect(view.tool.name, 'select');
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 3);
    final picker = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('border-model-picker')),
    );
    expect(picker.value, isNull);
    final before = host.document.current;
    await host.tapCell(10, 8);
    await pumpIo(tester, frames: 2);
    expect(view.borderDraft, isNull);
    expect(host.document.current, before);
    expect(host.document.error, contains('Choisissez'));
    expect(view.borderBlueprintId, isNot('another-border'));
  });
}
