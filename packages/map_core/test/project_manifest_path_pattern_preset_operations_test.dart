import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest PathPattern preset operations', () {
    test('read returns the manifest pathPatternPresets in order', () {
      final empty = _manifest();
      final withPresets =
          _manifest(pathPatternPresets: [_presetA(), _presetB()]);

      expect(readProjectPathPatternPresets(empty), isEmpty);
      expect(
          readProjectPathPatternPresets(withPresets), [_presetA(), _presetB()]);
    });

    test('replace swaps the list, preserves other fields, and keeps order', () {
      final pathPreset = _legacyPathPreset();
      final original = _manifest(
        name: 'Original',
        pathPresets: [pathPreset],
        pathPatternPresets: [_presetA()],
      );

      final next = replaceProjectPathPatternPresets(
        manifest: original,
        presets: [_presetB(), _presetC()],
      );

      expect(identical(next, original), isFalse);
      expect(next.pathPatternPresets, [_presetB(), _presetC()]);
      expect(next.name, original.name);
      expect(next.maps, original.maps);
      expect(next.tilesets, original.tilesets);
      expect(next.pathPresets, [pathPreset]);
      expect(next.surfaceCatalog, original.surfaceCatalog);
      expect(original.pathPatternPresets, [_presetA()]);
    });

    test('replace accepts an empty list and rejects duplicate exact ids', () {
      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
      final cleared = replaceProjectPathPatternPresets(
        manifest: original,
        presets: const [],
      );

      expect(cleared.pathPatternPresets, isEmpty);
      expect(
        () => replaceProjectPathPatternPresets(
          manifest: original,
          presets: [_presetA(), _presetA(name: 'Duplicate')],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('replace treats ids with different whitespace as distinct ids', () {
      final original = _manifest();

      final next = replaceProjectPathPatternPresets(
        manifest: original,
        presets: [_presetA(), _preset(' pattern-a ')],
      );

      expect(next.pathPatternPresets.map((preset) => preset.id), [
        'pattern-a',
        ' pattern-a ',
      ]);
    });

    test('upsert appends a new preset at the end', () {
      final original = _manifest(pathPatternPresets: [_presetA()]);

      final next = upsertProjectPathPatternPreset(
        manifest: original,
        preset: _presetB(),
      );

      expect(next.pathPatternPresets, [_presetA(), _presetB()]);
      expect(original.pathPatternPresets, [_presetA()]);
    });

    test('upsert replaces an existing preset in place', () {
      final original = _manifest(
        pathPatternPresets: [_presetA(), _presetB(), _presetC()],
      );
      final replacement = _presetB(name: 'Pattern B replacement');

      final next = upsertProjectPathPatternPreset(
        manifest: original,
        preset: replacement,
      );

      expect(next.pathPatternPresets, [_presetA(), replacement, _presetC()]);
    });

    test('upsert rejects ambiguous existing duplicate ids', () {
      final original = _manifestUnchecked([
        _presetA(),
        _presetA(name: 'Duplicate A'),
      ]);

      expect(
        () => upsertProjectPathPatternPreset(
          manifest: original,
          preset: _presetA(name: 'Replacement A'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('remove deletes an existing id and preserves order', () {
      final original = _manifest(
        pathPatternPresets: [_presetA(), _presetB(), _presetC()],
      );

      final next = removeProjectPathPatternPreset(
        manifest: original,
        presetId: 'pattern-b',
      );

      expect(next.pathPatternPresets, [_presetA(), _presetC()]);
      expect(original.pathPatternPresets, [_presetA(), _presetB(), _presetC()]);
    });

    test('remove missing id is a no-op with an equivalent new manifest', () {
      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);

      final next = removeProjectPathPatternPreset(
        manifest: original,
        presetId: 'missing',
      );

      expect(identical(next, original), isFalse);
      expect(next.pathPatternPresets, [_presetA(), _presetB()]);
      expect(next, original);
    });

    test('remove rejects blank ids and duplicate matching ids', () {
      final original = _manifestUnchecked([
        _presetA(),
        _presetA(name: 'Duplicate A'),
      ]);

      expect(
        () => removeProjectPathPatternPreset(
          manifest: _manifest(),
          presetId: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => removeProjectPathPatternPreset(
          manifest: _manifest(),
          presetId: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => removeProjectPathPatternPreset(
          manifest: original,
          presetId: 'pattern-a',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('clear removes all path pattern presets without mutating original',
        () {
      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
      final alreadyEmpty = _manifest();

      final cleared = clearProjectPathPatternPresets(original);
      final clearedAgain = clearProjectPathPatternPresets(alreadyEmpty);

      expect(cleared.pathPatternPresets, isEmpty);
      expect(clearedAgain.pathPatternPresets, isEmpty);
      expect(original.pathPatternPresets, [_presetA(), _presetB()]);
      expect(identical(cleared, original), isFalse);
      expect(identical(clearedAgain, alreadyEmpty), isFalse);
    });

    test('lookup helpers find exact ids, report missing ids, and reject blanks',
        () {
      final manifest = _manifest(pathPatternPresets: [_presetA(), _presetB()]);

      expect(
        projectPathPatternPresetById(
          manifest: manifest,
          presetId: 'pattern-a',
        ),
        _presetA(),
      );
      expect(
        projectPathPatternPresetById(
          manifest: manifest,
          presetId: 'missing',
        ),
        isNull,
      );
      expect(
        containsProjectPathPatternPreset(
          manifest: manifest,
          presetId: 'pattern-b',
        ),
        isTrue,
      );
      expect(
        containsProjectPathPatternPreset(
          manifest: manifest,
          presetId: 'missing',
        ),
        isFalse,
      );
      expect(
        () => projectPathPatternPresetById(
          manifest: manifest,
          presetId: ' ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lookup helpers reject duplicate exact ids', () {
      final manifest = _manifestUnchecked([
        _presetA(),
        _presetA(name: 'Duplicate A'),
      ]);

      expect(
        () => projectPathPatternPresetById(
          manifest: manifest,
          presetId: 'pattern-a',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => containsProjectPathPatternPreset(
          manifest: manifest,
          presetId: 'pattern-a',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('operations keep pathPatternPresets JSON stable', () {
      final upserted = upsertProjectPathPatternPreset(
        manifest: _manifest(),
        preset: _presetA(),
      );
      final cleared = clearProjectPathPatternPresets(upserted);

      expect(upserted.toJson()['pathPatternPresets'], [
        encodeProjectPathPatternPreset(_presetA()),
      ]);
      expect(cleared.toJson()['pathPatternPresets'], <Object?>[]);
    });
  });
}

ProjectManifest _manifest({
  String name = 'Project',
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'outdoor',
        name: 'Outdoor',
        relativePath: 'tilesets/outdoor.png',
      ),
    ],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectManifest _manifestUnchecked(List<ProjectPathPatternPreset> presets) {
  return ProjectManifest.fromJson({
    'name': 'Unchecked',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'pathPatternPresets': [
      for (final preset in presets) encodeProjectPathPatternPreset(preset),
    ],
  });
}

ProjectPathPreset _legacyPathPreset() {
  return ProjectPathPreset(
    id: 'legacy-water',
    name: 'Legacy Water',
    surfaceKind: PathSurfaceKind.water,
    tilesetId: 'outdoor',
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}

ProjectPathPatternPreset _presetA({String name = 'Pattern A'}) {
  return _preset('pattern-a', name: name, sortOrder: 1);
}

ProjectPathPatternPreset _presetB({String name = 'Pattern B'}) {
  return _preset('pattern-b', name: name, sortOrder: 2);
}

ProjectPathPatternPreset _presetC({String name = 'Pattern C'}) {
  return _preset('pattern-c', name: name, sortOrder: 3);
}

ProjectPathPatternPreset _preset(
  String id, {
  String? name,
  int sortOrder = 0,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: 'legacy-water',
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    ),
    sortOrder: sortOrder,
  );
}
