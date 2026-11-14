import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_border_commands_test.dart' show borderDocument;
import 'border_stroke_erase_editor_support.dart';

void main() {
  test('world cell quantization roundtrips quarter half and integer border offsets', () {
    for (final value in [
      -1.25,
      -1,
      -.75,
      -.5,
      -.25,
      0.0,
      .25,
      .5,
      .75,
      1.0,
      1.25,
    ]) {
      final fixture = eraseFixture(
        true,
        offset: Model3dVector3(x: value, y: 0, z: value),
      );
      final draft = MapBorderEraseDraft(
        sourceMap: fixture.map,
        sourceProject: fixture.project,
        layerId: 'studio-bordures',
        featureId: 'line',
        points: const [],
      );
      final world = GridPos(x: (5.5 + value).floor(), y: (5.5 + value).floor());
      expect(draft.pointFromWorldCell(world), const GridPos(x: 5, y: 5));
    }
  });
  for (final spatial in [false, true]) {
    test(
      'shared ${spatial ? '3D' : '2D'} command previews split commits once and undoes exactly',
      () {
        final fixture = eraseFixture(spatial);
        final document = borderDocument(fixture.map);
        final commands = MapBorderEditingCommands(document, fixture.project);
        final draft = MapBorderEraseDraft(
          sourceMap: fixture.map,
          sourceProject: fixture.project,
          layerId: 'studio-bordures',
          featureId: 'line',
          points: const [GridPos(x: 5, y: 5)],
        );
        final preview = commands.previewErase(draft);
        expectSplit(preview);
        expect(document.current, same(fixture.map));
        expect(document.undoCount, 0);
        commands.finishErase(draft);
        expect(document.current, preview);
        expect(document.undoCount, 1);
        expect(MapData.fromJson(preview.toJson()), preview);
        document.restore(redo: false);
        expect(document.current, fixture.map);
        document.restore(redo: true);
        expect(document.current, preview);
        expect(
          () => commands.finishErase(draft),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapBorderEditingCommands(
            borderDocument(fixture.map),
            fixture.project.copyWith(name: 'Changed'),
          ).previewErase(draft),
          throwsA(isA<ValidationException>()),
        );
        final hidden = fixture.map.copyWith(
          layers: [
            for (final layer in fixture.map.layers)
              layer.id == 'studio-bordures'
                  ? layer.copyWith(isVisible: false)
                  : layer,
          ],
        );
        expect(
          () =>
              MapBorderEditingCommands(
                borderDocument(hidden),
                fixture.project,
              ).previewErase(
                MapBorderEraseDraft(
                  sourceMap: hidden,
                  sourceProject: fixture.project,
                  layerId: 'studio-bordures',
                  featureId: 'line',
                  points: draft.points,
                ),
              ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  }

  for (final spatial in [false, true]) {
    testWidgets(
      '${spatial ? '3D' : '2D'} hidden selection requires an explicit visible trace choice',
      (tester) async {
        final host = await pumpEraseHost(tester, spatial);
        armErase(host);
        await tester.pump();
        final original = host.document.current;
        final first = original.layers.whereType<BorderLayer>().single;
        final feature = first.content.features.single;
        var map = addBorderLayer(
          original,
          id: 'other-border',
          name: 'Autre calque',
        );
        map = upsertBorderFeature(
          map,
          layerId: 'other-border',
          feature: BorderFeature(
            id: 'other',
            name: 'Autre tracé',
            blueprintId: feature.blueprintId,
            seed: feature.seed,
            overrides: const [],
            keepOutRegions: const [],
            geometry: feature.geometry,
          ),
        );
        map = map.copyWith(
          layers: [
            for (final layer in map.layers)
              layer.id == first.id ? layer.copyWith(isVisible: false) : layer,
          ],
        );
        host.document.current = map;
        host.refresh();
        await tester.pump();
        final commands = MapBorderEditingCommands(host.document, host.project);
        final visible = commands.visibleFeatures;
        expect(visible, hasLength(1));
        expect(visible.single.layer.id, 'other-border');
        expect(
          visible.any(
            (entry) =>
                entry.layer.id == host.view.borderFeature?.layerId &&
                entry.feature.id == host.view.borderFeature?.featureId,
          ),
          isFalse,
        );
        final before = host.document.current;
        host.view.selectBorderFeature((
          layerId: visible.single.layer.id,
          featureId: visible.single.feature.id,
        ));
        host.refresh();
        await tester.pump();
        expect(host.view.borderFeature, (
          layerId: 'other-border',
          featureId: 'other',
        ));
        expect(host.document.current, same(before));
        expect(host.document.undoCount, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
