import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

Future<void> openWorkspace(
  WidgetTester tester,
  DeferredRegionalMapPort regional,
  VoidCallback runtimeStarted,
) async {
  tester.view.physicalSize = const Size(1500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  );
  final visuals = WorkspaceTestVisuals();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    regional.complete();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: MapWorkspaceScreen(
        controller: controller,
        loadVisuals: (_, _) async => visuals,
        regionalMapPort: regional,
        runtimeBuilder: (_, _, close) {
          runtimeStarted();
          return Scaffold(
            body: TextButton(
              onPressed: close,
              child: const Text('Revenir à la carte'),
            ),
          );
        },
        onClose: () async {},
        registerExitGuard: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder destination(String label) => find.descendant(
  of: find.byType(StudioPrimaryNavigation),
  matching: find.byTooltip(label),
);

void main() {
  testWidgets(
    'local map playtest starts without loading the regional catalogue',
    (tester) async {
      final regional = DeferredRegionalMapPort();
      var starts = 0;
      await openWorkspace(tester, regional, () => starts++);
      await tester.tap(find.byKey(const ValueKey('Enregistrer et tester')));
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(regional.loads, 0);
      expect(find.text('Revenir à la carte'), findsOneWidget);
      await tester.tap(find.text('Revenir à la carte'));
      await tester.pumpAndSettle();
      expect(find.byType(MapWorkspaceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'regional catalogue is loaded when its editor opens and refreshed on return',
    (tester) async {
      final regional = DeferredRegionalMapPort();
      await openWorkspace(tester, regional, () {});
      expect(regional.loads, 0);
      await tester.tap(destination('Carte régionale'));
      await tester.pump();
      expect(regional.loads, 1);
      regional.complete();
      await tester.pumpAndSettle();
      expect(find.byType(RegionalMapPage), findsOneWidget);
      await tester.tap(destination('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(destination('Carte régionale'));
      await tester.pumpAndSettle();
      expect(regional.loads, 2);
      expect(find.byType(RegionalMapPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class DeferredRegionalMapPort implements RegionalMapPort {
  final pending = Completer<RegionalMapSource>();
  var loads = 0;

  void complete() {
    if (pending.isCompleted) return;
    pending.complete(
      RegionalMapSource(
        project: workspaceProject,
        revision: 'regional-source',
        maps: {
          for (final entry in workspaceEntries)
            entry.id: workspaceMap(entry.id),
        },
        images: const {},
      ),
    );
  }

  @override
  Future<RegionalMapSource> load() {
    loads++;
    return pending.future;
  }

  @override
  Future<Uint8List?> readImage(String path) async => null;

  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) => throw UnsupportedError(
    'The loading regression does not publish a catalogue.',
  );
}
