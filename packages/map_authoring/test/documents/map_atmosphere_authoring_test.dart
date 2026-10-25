import 'dart:io';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('atmosphere_local_');
    root = Directory(await root.resolveSymbolicLinks());
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/shore.json')
        .writeAsString('map content must not be decoded');
    await File('${root.path}/project.json')
        .writeAsString('project content must not be decoded');
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() => root.delete(recursive: true));
  test('each cold first save persists only the small selected atmosphere',
      () async {
    for (final settings in [
      SpatialAtmosphereSettings(waterAnimated: true),
      SpatialAtmosphereSettings(windowsLit: true),
      SpatialAtmosphereSettings(fireflies: true)
    ]) {
      final service = LocalMapAtmosphereAuthoring(policy: policy);
      final before =
          await service.inspect(projectRoot: root.path, mapId: 'shore');
      final changed = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          settings: settings,
          operationId: 'save_${settings.hashCode.abs()}');
      expect(changed.afterSettings, settings);
      final reopened = await LocalMapAtmosphereAuthoring(policy: policy)
          .inspect(projectRoot: root.path, mapId: 'shore');
      expect(reopened.settings, settings);
      expect(reopened.revision, changed.afterRevision);
      expect((await File('${root.path}/maps/shore.atmosphere.json').length()),
          lessThan(1024));
    }
    expect(await File('${root.path}/project.json').readAsString(),
        'project content must not be decoded');
    expect(await File('${root.path}/maps/shore.json').readAsString(),
        'map content must not be decoded');
  });
}
