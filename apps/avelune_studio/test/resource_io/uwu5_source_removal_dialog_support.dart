import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_removal_dialog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/load_desktop_capture_fonts.dart';

final class RemovalAnalysis {
  RemovalAnalysis(this.removeSource);
  final bool removeSource;
  final result = Completer<ResourceMutationPreparation>();
}

final class RemovalDialogHarness {
  final analyses = <RemovalAnalysis>[];
  final applied = <ResourceMutationPreparation>[];
  final captureKey = GlobalKey();

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(1536, 1024),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(loadDesktopCaptureFonts);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          theme: studioTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: StudioButton(
                label: 'Retirer la planche',
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ResourceRemovalDialog(
                    item: const ResourceItem(
                      id: 'sheet',
                      name: 'Planche témoin',
                      kind: ResourceKind.images,
                      tileset: ProjectTilesetEntry(
                        id: 'sheet',
                        name: 'Planche témoin',
                        relativePath: 'assets/planche.png',
                      ),
                    ),
                    preview: const Center(child: Text('Aperçu témoin')),
                    prepare: (choice) {
                      final analysis = RemovalAnalysis(choice);
                      analyses.add(analysis);
                      return analysis.result.future;
                    },
                    apply: (preparation) async {
                      applied.add(preparation);
                      return null;
                    },
                    openUsages: () {},
                    dirtyOwners: () => [],
                    canApply: () => true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Retirer la planche'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  ResourceMutationPreparation preparation(
    RemovalAnalysis analysis, {
    bool? capability = true,
    bool? sourceRemoved,
    bool logicalFileRemoved = true,
    String? reason,
  }) => ResourceMutationPreparation(
    sessionId: 'session',
    actionId: 'tileset.remove',
    parameters: {'tilesetId': 'sheet', 'removeSource': analysis.removeSource},
    snapshotRevision: 'snapshot-${analyses.indexOf(analysis)}',
    manifestRevision: 'manifest',
    changedPaths: [
      'project.json',
      if (sourceRemoved ?? analysis.removeSource) 'assets/catalog.json',
      if ((sourceRemoved ?? analysis.removeSource) && logicalFileRemoved)
        'assets/planche.png',
    ],
    confirmationRequired: true,
    impact: {
      'sourceRemovalSupported': ?capability,
      'sourceRemoved': sourceRemoved ?? analysis.removeSource,
      'logicalFileRemoved': logicalFileRemoved,
      'logicalSourcePath': 'assets/planche.png',
      'sourceRemovalReason': ?reason,
    },
  );

  Future<void> ready(
    WidgetTester tester, {
    bool? capability = true,
    bool? sourceRemoved,
    bool logicalFileRemoved = true,
    String? reason,
  }) async {
    final analysis = analyses.last;
    analysis.result.complete(
      preparation(
        analysis,
        capability: capability,
        sourceRemoved: sourceRemoved,
        logicalFileRemoved: logicalFileRemoved,
        reason: reason,
      ),
    );
    await tester.pumpAndSettle();
  }

  CheckboxListTile checkbox(WidgetTester tester, String key) =>
      tester.widget<CheckboxListTile>(find.byKey(ValueKey(key)));
  bool canSubmit(WidgetTester tester) =>
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('resource-management-save')),
          )
          .onPressed !=
      null;
  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final output = Platform.environment['AVELUNE_CAPTURE_DIR'];
    if (output == null || output.isEmpty) return;
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final frame = await boundary.toImage(pixelRatio: 1);
      try {
        final png = await frame.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/$name.png').writeAsBytes(png!.buffer.asUint8List());
      } finally {
        frame.dispose();
      }
    });
  }
}
