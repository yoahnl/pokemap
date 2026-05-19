import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPreset', () {
    test('stores the parametric projected building shadow fields', () {
      final direction = _direction();
      final shape = _shape();
      final appearance = _appearance();

      final preset = ProjectBuildingShadowPreset(
        id: 'short-west-building-shadow',
        name: 'Short west building shadow',
        direction: direction,
        shape: shape,
        appearance: appearance,
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
        sortOrder: -10,
      );

      expect(preset.id, 'short-west-building-shadow');
      expect(preset.name, 'Short west building shadow');
      expect(preset.direction, direction);
      expect(preset.shape, shape);
      expect(preset.appearance, appearance);
      expect(preset.timeOfDayMode, ProjectedShadowTimeOfDayMode.fixed);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, -10);
    });

    test('stores a non-null category id', () {
      final preset = _preset(categoryId: 'building-shadows');

      expect(preset.categoryId, 'building-shadows');
    });

    test('uses sortOrder zero by default', () {
      expect(_preset().sortOrder, 0);
    });

    test('refuses blank id values while preserving valid raw ids', () {
      expect(
        () => _preset(id: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _preset(id: '   '),
        throwsA(isA<ArgumentError>()),
      );

      final id = '  short-west-building-shadow  ';
      expect(_preset(id: id).id, id);
    });

    test('refuses blank name values while preserving valid raw names', () {
      expect(
        () => _preset(name: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _preset(name: '   '),
        throwsA(isA<ArgumentError>()),
      );

      final name = '  Short west building shadow  ';
      expect(_preset(name: name).name, name);
    });

    test('validates optional category id', () {
      expect(_preset(categoryId: null).categoryId, isNull);
      expect(_preset(categoryId: 'building-shadows').categoryId,
          'building-shadows');
      expect(
        () => _preset(categoryId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _preset(categoryId: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uses value equality for identical presets', () {
      expect(_preset(), _preset());
      expect(_preset().hashCode, _preset().hashCode);
    });

    test('value equality includes id', () {
      expect(_preset(id: 'a'), isNot(_preset(id: 'b')));
    });

    test('value equality includes name', () {
      expect(_preset(name: 'A'), isNot(_preset(name: 'B')));
    });

    test('value equality includes direction', () {
      expect(
        _preset(direction: ProjectedShadowDirection(x: -0.55, y: 0.35)),
        isNot(_preset(direction: ProjectedShadowDirection(x: -0.25, y: 0.35))),
      );
    });

    test('value equality includes shape', () {
      expect(
        _preset(shape: _shape(lengthRatio: 0.28)),
        isNot(_preset(shape: _shape(lengthRatio: 0.32))),
      );
    });

    test('value equality includes appearance', () {
      expect(
        _preset(appearance: ProjectedShadowAppearance(opacity: 0.18)),
        isNot(_preset(appearance: ProjectedShadowAppearance(opacity: 0.22))),
      );
    });

    test('value equality includes timeOfDayMode', () {
      expect(
        _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed),
        isNot(_preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun)),
      );
    });

    test('value equality includes categoryId', () {
      expect(
        _preset(categoryId: 'short'),
        isNot(_preset(categoryId: 'long')),
      );
    });

    test('value equality includes sortOrder', () {
      expect(_preset(sortOrder: 0), isNot(_preset(sortOrder: 1)));
    });
  });
}

ProjectBuildingShadowPreset _preset({
  String id = 'short-west-building-shadow',
  String name = 'Short west building shadow',
  ProjectedShadowDirection? direction,
  ProjectedShadowShapeTuning? shape,
  ProjectedShadowAppearance? appearance,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: name,
    direction: direction ?? _direction(),
    shape: shape ?? _shape(),
    appearance: appearance ?? _appearance(),
    timeOfDayMode: timeOfDayMode,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectedShadowDirection _direction() {
  return ProjectedShadowDirection(x: -0.55, y: 0.35);
}

ProjectedShadowShapeTuning _shape({double lengthRatio = 0.28}) {
  return ProjectedShadowShapeTuning(
    lengthRatio: lengthRatio,
    nearWidthRatio: 0.85,
    farWidthRatio: 0.75,
  );
}

ProjectedShadowAppearance _appearance() {
  return ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000');
}
