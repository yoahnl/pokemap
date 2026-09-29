import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final project = ProjectManifest(name: 'Format', maps: const [], tilesets: const []);
  const map = MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 2, height: 2),
    visualStack: MapVisualStackConfig.canonicalV1,
  );

  test('project and map default to the strict v8 format', () {
    expect(project.version.name, 'v8');
    expect(map.version.name, 'v8');
  });

  test('v8 round trips through project, map and launch identity readers', () {
    final decodedProject = ProjectManifest.fromJson(project.toJson()..['version'] = 'v8');
    final decodedMap = MapData.fromJson(map.toJson()..['version'] = 'v8');
    expect(decodedProject.toJson()['version'], 'v8');
    expect(decodedMap.toJson()['version'], 'v8');
    expect(decodedMap.visualStack, map.visualStack);
    ProjectValidator.validate(decodedProject);
    MapValidator.validate(decodedMap, projectDialogueContext: decodedProject);
    expect(ProjectFormat.parse('v8').name, 'v8');
  });

  for (final version in [null, 'v1', 'v5', 'v6', 'v7', 'v9']) {
    test('rejects project and map format $version before reading content', () {
      final projectJson = project.toJson();
      final mapJson = map.toJson();
      if (version == null) {
        projectJson.remove('version');
        mapJson.remove('version');
      } else {
        projectJson['version'] = version;
        mapJson['version'] = version;
      }
      final failure = throwsA(isA<FormatException>().having(
        (error) => error.message,
        'message',
        contains('expected=v8'),
      ));
      expect(() => ProjectManifest.fromJson(projectJson), failure);
      expect(() => MapData.fromJson(mapJson), failure);
    });
  }

  test('validators reject legacy in-memory project and map versions', () {
    for (final version in [ProjectVersion.v6, ProjectVersion.v7]) {
      expect(() => ProjectValidator.validate(project.copyWith(version: version)),
          throwsA(isA<ValidationException>()));
      expect(() => MapValidator.validate(map.copyWith(version: version)),
          throwsA(isA<ValidationException>()));
    }
  });
}
