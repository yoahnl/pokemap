import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'm2_ui_fixture.dart';
import 'widget_resource_management_port.dart';

class UwUResourceHost {
  UwUResourceHost(this.tester, this.fixture);
  final WidgetTester tester;
  final M2UiFixture fixture;
  ResourceNavigation get navigation => tester
      .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
      .navigation;

  static Future<UwUResourceHost> open(
    WidgetTester tester, {
    bool noMaps = false,
    Size size = const Size(1536, 1024),
    double textScale = 1,
    ResourceUsagePort Function(ResourceUsagePort)? wrapUsages,
    PickResourceImage? imagePicker,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    if (noMaps) {
      await tester.runAsync(() async {
        final file = File('${fixture.directory.path}/project.json');
        final manifest = ProjectManifest.fromJson(
          jsonDecode(await file.readAsString()),
        );
        await file.writeAsString(
          jsonEncode(manifest.copyWith(maps: []).toJson()),
        );
      });
      fixture.controller.project = null;
      fixture.controller.active = null;
      fixture.controller.documents.clear();
    }
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      fixture.app(
        tester,
        textScale: textScale,
        imagePicker: imagePicker,
        resourcePort: WidgetResourceManagementPort(
          fixture.resources,
          tester,
          wrapUsages: wrapUsages,
        ),
      ),
    );
    await pumpIo(tester);
    await tester.tap(find.byTooltip('Ressources').first);
    await pumpIo(tester);
    return UwUResourceHost(tester, fixture);
  }

  Future<void> family(ResourceKind kind) async {
    await tester.tap(
      find.text(switch (kind) {
        ResourceKind.images => 'Images et tuiles',
        ResourceKind.decors => 'Décors',
        ResourceKind.terrains => 'Terrains',
      }).first,
    );
    await pumpIo(tester, frames: 8);
  }

  Future<void> tap(String key) async {
    final finder = find.byKey(ValueKey(key));
    if (key == 'resource-manage-containers' && finder.evaluate().isEmpty) {
      await tester.tap(find.text('Actions').first);
      await pumpIo(tester, frames: 6);
    }
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> action(String identity, String label) async {
    await tap('resource-actions-$identity');
    await tester.tap(find.text(label).last);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> enter(String key, String value) async {
    final field = find.byKey(ValueKey(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> choose(String key, String label) async {
    final field = find.byKey(ValueKey(key));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await pumpIo(tester, frames: 6);
    await tester.tap(find.text(label).last);
    await pumpIo(tester, frames: 4);
  }

  Future<void> openUsage(ResourceUsageEntry entry) async {
    final finder = find.byKey(
      ValueKey(
        'resource-usage-open-${entry.ownerKind}:${entry.ownerId}:${entry.location}:${entry.relation.name}',
      ),
    );
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find
          .descendant(
            of: find.byType(ResourceUsageResults),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();
    await tester.tap(finder);
    await pumpIo(tester, frames: 20);
  }

  Future<ProjectManifest> reopen() async =>
      (await WidgetResourcePort.serial(tester, () async {
        final sessions = LocalProjectSessionAdapter();
        final session = await sessions.open(fixture.directory.path);
        try {
          return await LocalMapWorkspaceAdapter().loadProject(session);
        } finally {
          await sessions.close(session);
        }
      }))!;
}
