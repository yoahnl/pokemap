import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPresetCatalog', () {
    test('accepts an empty catalog', () {
      final catalog = ProjectBuildingShadowPresetCatalog();

      expect(catalog.presets, isEmpty);
      expect(catalog.length, 0);
      expect(catalog.isEmpty, isTrue);
      expect(catalog.isNotEmpty, isFalse);
      expect(catalog.presetById('missing'), isNull);
      expect(catalog.containsPresetId('missing'), isFalse);
    });

    test('accepts presets and preserves order', () {
      final first = _preset(id: 'short-west');
      final second = _preset(id: 'long-east');
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[first, second],
      );

      expect(catalog.presets, <ProjectBuildingShadowPreset>[first, second]);
      expect(catalog.length, 2);
      expect(catalog.isEmpty, isFalse);
      expect(catalog.isNotEmpty, isTrue);
    });

    test('looks up presets by exact id', () {
      final lower = _preset(id: 'shadow');
      final upper = _preset(id: 'SHADOW');
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[lower, upper],
      );

      expect(catalog.presetById('shadow'), same(lower));
      expect(catalog.presetById('SHADOW'), same(upper));
      expect(catalog.presetById('Shadow'), isNull);
      expect(catalog.containsPresetId('shadow'), isTrue);
      expect(catalog.containsPresetId('missing'), isFalse);
    });

    test('rejects duplicate preset ids', () {
      expect(
        () => ProjectBuildingShadowPresetCatalog(
          presets: <ProjectBuildingShadowPreset>[
            _preset(id: 'duplicate'),
            _preset(id: 'duplicate', name: 'Duplicate copy'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('defensively copies the source list', () {
      final first = _preset(id: 'short-west');
      final second = _preset(id: 'long-east');
      final source = <ProjectBuildingShadowPreset>[first];
      final catalog = ProjectBuildingShadowPresetCatalog(presets: source);

      source.add(second);

      expect(catalog.presets, <ProjectBuildingShadowPreset>[first]);
      expect(catalog.presetById('long-east'), isNull);
    });

    test('exposes an unmodifiable presets list', () {
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[_preset(id: 'short-west')],
      );

      expect(
        () => catalog.presets.add(_preset(id: 'long-east')),
        throwsUnsupportedError,
      );
    });

    test('uses ordered value equality and matching hashCode', () {
      final first = _preset(id: 'short-west');
      final second = _preset(id: 'long-east');

      final a = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[first, second],
      );
      final b = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[first, second],
      );
      final reversed = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[second, first],
      );
      final changed = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[
          first,
          _preset(id: 'different'),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(reversed));
      expect(a, isNot(changed));
    });
  });
}

ProjectBuildingShadowPreset _preset({
  required String id,
  String? name,
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: name ?? 'Preset $id',
    direction: ProjectedShadowDirection(x: -0.55, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.28,
      nearWidthRatio: 0.85,
      farWidthRatio: 0.75,
    ),
    appearance: ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}
