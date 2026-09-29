import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';
import '../support/border_catalog_fixture.dart';

void main() {
  testWidgets('Bordures explains when this project has no published model', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(tester);
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 4);

    expect(
      find.textContaining('Aucun modèle de bordure linéaire'),
      findsOneWidget,
    );
    expect(fixture.document.dirty, isFalse);
  });

  testWidgets('a previewed angled border finishes in one undoable save', (
    tester,
  ) async {
    final fixture = await _openWithBorder(tester);
    final initial = fixture.document.current;
    final undoBefore = fixture.document.undoCount;

    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 4);
    await tester.tap(find.byKey(const ValueKey('border-model-picker')));
    await pumpIo(tester, frames: 2);
    expect(find.text('Muret de test'), findsWidgets);
    await tester.tap(find.text('Muret de test').last);
    await pumpIo(tester, frames: 2);
    await fixture.tapCell(10, 8);
    final pointer = TestPointer(42, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(fixture.cellAt(13, 8)));
    await pumpIo(tester, frames: 3);
    final previewView = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    expect(
      previewView.borderDraft?.previewCells,
      contains(const GridPos(x: 13, y: 8)),
    );
    expect(fixture.document.current, initial);
    await fixture.tapCell(13, 8);
    expect(fixture.document.current, initial);
    final view = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    expect(
      view.borderDraft?.anchors.length,
      2,
      reason: '${view.borderDraft?.anchors} · ${fixture.document.error}',
    );
    expect(find.textContaining('2 points'), findsOneWidget);

    await fixture.tapCell(13, 11);
    await fixture.key(LogicalKeyboardKey.enter);
    await pumpIo(tester, frames: 6);

    final layer = fixture.document.current.layers
        .whereType<BorderLayer>()
        .single;
    final feature = layer.content.features.single;
    final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
    expect(stroke.points, contains(const GridPos(x: 13, y: 8)));
    expect(stroke.points, contains(const GridPos(x: 13, y: 11)));
    expect(feature.materialization, isNotNull);
    expect(fixture.document.undoCount, undoBefore + 1);

    await tester.tap(find.byKey(const ValueKey('Enregistrer')));
    for (var index = 0; index < 50 && fixture.document.dirty; index++) {
      await pumpIo(tester, frames: 3);
    }
    expect(fixture.document.dirty, isFalse, reason: fixture.document.error);
    final reopened = (await tester.runAsync(() async {
      final adapter = LocalMapWorkspaceAdapter();
      final project = await adapter.loadProject(fixture.source.session);
      return adapter.loadMap(
        fixture.source.session,
        project.maps.firstWhere((entry) => entry.id == initial.id),
      );
    }))!;
    final saved = reopened.map.layers.whereType<BorderLayer>().single;
    expect(saved.content.features.single, feature);
  });

  testWidgets('cancelling a trace leaves the map and history untouched', (
    tester,
  ) async {
    final fixture = await _openWithBorder(tester);
    final initial = fixture.document.current;
    final undoBefore = fixture.document.undoCount;
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 4);
    await fixture.tapCell(10, 8);
    await fixture.tapCell(13, 8);
    await tester.tap(find.text('Annuler le tracé'));
    await pumpIo(tester, frames: 3);

    final view = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    expect(view.borderDraft, isNull);
    expect(fixture.document.current, initial);
    expect(fixture.document.undoCount, undoBefore);
    expect(fixture.document.dirty, isFalse);
  });

  testWidgets('switching tools keeps the unfinished border draft', (
    tester,
  ) async {
    final fixture = await _openWithBorder(tester);
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 4);
    await fixture.tapCell(10, 8);
    await fixture.tapCell(13, 8);
    final view = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    final draft = view.borderDraft;
    await tester.ensureVisible(find.byKey(const ValueKey('Sélectionner')));
    await tester.tap(find.byKey(const ValueKey('Sélectionner')));
    await pumpIo(tester, frames: 3);
    expect(view.tool.name, 'select');
    expect(view.borderDraft?.anchors, draft?.anchors);
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 3);
    expect(view.tool.name, 'border');
    expect(view.borderDraft?.anchors, draft?.anchors);
    expect(fixture.document.dirty, isFalse);
    await fixture.switchMap('Clairière');
    final otherView = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    expect(otherView.borderDraft, isNull);
    await fixture.switchMap('Jardin des essais');
    expect(view.borderDraft?.anchors, draft?.anchors);
  });

  test('border draft rejects a crossing and leaves its anchors unchanged', () {
    final draft =
        MapBorderDrawingDraft.start(
              mapId: 'map',
              mapSize: const GridSize(width: 12, height: 12),
              blueprintId: 'muret',
              origin: const GridPos(x: 2, y: 2),
            )
            .addAngle(const GridPos(x: 7, y: 2))
            .addAngle(const GridPos(x: 7, y: 7))
            .addAngle(const GridPos(x: 4, y: 7));
    expect(
      () => draft.addAngle(const GridPos(x: 4, y: 1)),
      throwsA(isA<ValidationException>()),
    );
    expect(draft.anchors.length, 4);
  });

  test('clicking the origin closes and previews the final segment', () {
    final draft =
        MapBorderDrawingDraft.start(
              mapId: 'map',
              mapSize: const GridSize(width: 12, height: 12),
              blueprintId: 'muret',
              origin: const GridPos(x: 2, y: 2),
            )
            .addAngle(const GridPos(x: 5, y: 2))
            .addAngle(const GridPos(x: 5, y: 5))
            .addAngle(const GridPos(x: 2, y: 5))
            .addAngle(const GridPos(x: 2, y: 2));
    expect(draft.closed, isTrue);
    expect(draft.canFinish, isTrue);
    expect(draft.previewCells, contains(const GridPos(x: 2, y: 4)));
  });

  test('grid-edge draft reaches the outer border of the map', () {
    final draft = MapBorderDrawingDraft.start(
      mapId: 'map',
      mapSize: const GridSize(width: 12, height: 12),
      blueprintId: 'stone',
      alignment: BorderStrokeAlignment.gridEdges,
      origin: const GridPos(x: 12, y: 2),
    ).addAngle(const GridPos(x: 12, y: 8));
    expect(draft.canFinish, isTrue);
    expect(draft.previewCells, contains(const GridPos(x: 12, y: 5)));
  });

  testWidgets('a published stone chain uses grid edges through the host', (
    tester,
  ) async {
    final fixture = await _openWithBorder(
      tester,
      template: BorderBlueprintTemplate.stoneChainLine,
    );
    await tester.ensureVisible(find.text('Bordures'));
    await tester.tap(find.text('Bordures'));
    await pumpIo(tester, frames: 4);
    await fixture.tapCell(10, 8);
    await fixture.tapCell(13, 8);
    final draft = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view
        .borderDraft;
    expect(draft?.alignment, BorderStrokeAlignment.gridEdges);
    expect(draft?.canFinish, isTrue);
    await tester.tap(find.text('Terminer le tracé'));
    await pumpIo(tester, frames: 4);
    final feature = fixture.document.current.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(
      (feature.geometry as BorderStrokeGeometry).alignment,
      BorderStrokeAlignment.gridEdges,
    );
    expect(feature.materialization, isNotNull);
  });
}

Future<MapHostFixture> _openWithBorder(
  WidgetTester tester, {
  BorderBlueprintTemplate template = BorderBlueprintTemplate.connectedLine,
}) => MapHostFixture.open(
  tester,
  prepareSource: (source) async {
    final projectFile = File('${source.directory.path}/project.json');
    final project = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );
    await projectFile.writeAsString(
      jsonEncode(
        project
            .copyWith(borderCatalog: testBorderCatalog(template: template))
            .toJson(),
      ),
    );
  },
);
