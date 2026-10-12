import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  final project = spatialEnvironmentProject();
  EditableMapDocument document() {
    final map = spatialEnvironmentMap();
    return EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
  }

  test(
    'spatial preview is native, follows ground, applies once and undoes',
    () {
      final doc = document();
      final commands = EnvironmentEditingCommands(doc, project);
      final session = commands.create(project.environmentPresets.single);
      expect(doc.current.layers.whereType<TileLayer>(), isEmpty);
      expect(
        doc.current.layers
            .whereType<EnvironmentLayer>()
            .single
            .content
            .targetsSpatialTerrain,
        isTrue,
      );
      commands.paint(session, [
        const GridPos(x: 3, y: 5),
        const GridPos(x: 5, y: 5),
      ], erase: false);
      final source = doc.current;
      final count = doc.undoCount;
      commands.preview(session);
      expect(doc.current, same(source));
      expect(doc.undoCount, count);
      expect(session.previewResult!.placedElements, isEmpty);
      final instances = session.previewResult!.spatialScene!.instances;
      expect(instances, hasLength(2));
      expect(
        instances.map((instance) => instance.position.y),
        everyElement(source.spatialScene!.worldHeightAt(3.5, 5.5)),
      );
      commands.apply(session);
      expect(doc.current.spatialScene!.instances, instances);
      expect(doc.undoCount, count + 1);
      expect(MapData.fromJson(doc.current.toJson()), doc.current);
      doc.restore(redo: false);
      expect(doc.current, source);
      doc.restore(redo: true);
      expect(doc.current.spatialScene!.instances, instances);
    },
  );

  test(
    'generated edits persist through regeneration and deletion is scoped',
    () {
      final doc = document();
      final commands = EnvironmentEditingCommands(doc, project);
      final session = commands.create(project.environmentPresets.single);
      commands.paint(session, [
        const GridPos(x: 3, y: 5),
        const GridPos(x: 5, y: 5),
      ], erase: false);
      commands.preview(session);
      commands.apply(session);
      final models = SpatialModelEditingCommands(doc, project);
      final moved = doc.current.spatialScene!.instances.first;
      models.update(
        moved.id,
        x: 7.25,
        z: 5.75,
        rotation: 90,
        scale: .8,
        blocksMovement: false,
      );
      final expected = models.selected(moved.id)!;
      expect(commands.area(session)!.manualPlacementIds, contains(moved.id));
      expect(
        commands
            .area(session)!
            .mask
            .isActiveAt(moved.position.x.floor(), moved.position.z.floor()),
        isFalse,
      );
      final removed = doc.current.spatialScene!.instances.last;
      models.delete(removed.id);
      final independent = models.place(
        project.models3d.single,
        const GridPos(x: 9, y: 4),
      );
      commands.changeSeed(session);
      commands.preview(session);
      commands.apply(session);
      expect(models.selected(moved.id), expected);
      expect(models.selected(removed.id), isNull);
      expect(models.selected(independent.id), independent);
      commands.delete(session);
      expect(doc.current.spatialScene!.instances, [independent]);
    },
  );

  test('stale spatial preview rejects a changed map or project', () {
    final doc = document();
    final commands = EnvironmentEditingCommands(doc, project);
    final session = commands.create(project.environmentPresets.single);
    commands.paint(session, [const GridPos(x: 3, y: 5)], erase: false);
    commands.preview(session);
    doc.commit(doc.current.copyWith(name: 'Nouvelle révision'));
    final source = doc.current;
    expect(() => commands.apply(session), throwsStateError);
    expect(doc.current, same(source));
    commands.preview(session);
    expect(
      () => EnvironmentEditingCommands(
        doc,
        project.copyWith(name: 'Autre projet'),
      ).apply(session),
      throwsStateError,
    );
    expect(doc.current, same(source));
  });
}
