import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/platform/rendering/studio_border_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../resource_io/resource_fixture.dart';
import '../support/first_border_owner_fixture.dart';
import '../support/resource_replacement_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonically prepared border stays visible over opaque ground after canvas drawing and disk reopen',
    () async {
      final host = await ResourceReplacementFixture.create(
        configure: seedFirstBorderOverOpaqueGround,
      );
      final maps = host.workspace;
      final document = maps.active!;
      final initial = document.current;
      expect(initial.layers.whereType<BorderLayer>(), isEmpty);
      await maps.ensureBorderProfiles();
      final project = maps.project!;
      final published = project.borderCatalog
          .recordById(firstBorderId)!
          .latestPublished!;
      expect(
        MapBorderEditingCommands.publishedLines(
          project,
        ).map((record) => record.id),
        [firstBorderId],
      );

      final draft = MapBorderDrawingDraft.start(
        mapId: initial.id,
        mapSize: initial.size,
        blueprintId: firstBorderId,
        alignment: borderTemplateStrokeAlignment(published.definition.template),
        origin: const GridPos(x: 1, y: 1),
      ).addAngle(const GridPos(x: 2, y: 1));
      expect(draft.canFinish, isTrue);
      MapBorderEditingCommands(document, project).finish(draft);

      final map = document.current;
      final layer = map.layers.whereType<BorderLayer>().single;
      final feature = layer.content.features.single;
      expect(feature.blueprintId, firstBorderId);
      expect(feature.materialization, isNotNull);
      expect(
        feature.materialization!.receipt.blueprintRevision,
        published.revision,
      );
      expect(
        map.layers.whereType<TileLayer>().single,
        initial.layers.whereType<TileLayer>().single,
      );
      expect(
        map.layers.whereType<CollisionLayer>().single,
        initial.layers.whereType<CollisionLayer>().single,
      );

      expect(layer.renderInForeground, isFalse);
      final steps = buildMapVisualCompositionPlan(
        map,
      ).plan!.steps.map((step) => step.stableKey).toList();
      expect(steps, contains('tileBackgroundLayer:ground'));
      expect(
        steps.indexOf('tileBackgroundLayer:ground'),
        lessThan(steps.indexOf('borderLayer:${layer.id}')),
      );
      expect(steps, isNot(contains('foregroundBorderLayer:${layer.id}')));

      final preview = StudioBorderPreview(
        projectRoot: host.fixture.root.path,
        changed: () {},
      );
      addTearDown(preview.dispose);
      preview.setActiveMap(maps.visualProject!, map);
      expect(preview.loading, isTrue);
      await preview.settled;
      expect(preview.issue, isNull);
      expect(preview.loading, isFalse);
      expect(preview.hasVisibleBorders, isTrue);
      expect(preview.assetsFor(map), isNotNull);

      expect(await maps.save(document), isTrue, reason: document.error);
      expect(document.dirty, isFalse);
      final reopened = await host.fixture.maps.loadMap(
        host.fixture.session,
        ResourceFixture.entry,
      );
      expect(reopened.map.layers.whereType<BorderLayer>().single, layer);
      expect(
        reopened.map.layers.whereType<TileLayer>().single,
        initial.layers.whereType<TileLayer>().single,
      );
    },
  );
}
