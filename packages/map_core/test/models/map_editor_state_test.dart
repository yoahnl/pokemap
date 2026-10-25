import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('typed instance locks and family locks remain independent', () {
    final state = MapEditorState(
      lockedElements: {'decor:mist:rear', 'model:smoke'},
      lockedFamilies: {'effect'},
    );
    expect(state.isLocked('decor', 'mist:rear'), isTrue);
    expect(state.isLocked('model', 'smoke'), isTrue);
    expect(state.isLocked('entity', 'smoke'), isFalse);
    expect(state.isLocked('effect', 'firefly'), isTrue);
    expect(
      state.copyWith(lockedFamilies: {'decor'}).isLocked('decor', 'firefly'),
      isTrue,
    );
    expect(MapEditorState.fromJson(state.toJson()), state);
    expect(state.toJson()['lockedElements'], [
      'decor:mist:rear',
      'model:smoke',
    ]);
    expect(
      () => state.lockedElements.add('decor:another'),
      throwsUnsupportedError,
    );
  });

  test('old missing state is unlocked and invalid state is rejected', () {
    expect(MapEditorState.fromJson({}).isLocked('decor', 'mist'), isFalse);
    for (final json in <Map<String, dynamic>>[
      {
        'lockedElements': ['unknown:id'],
      },
      {
        'lockedElements': ['decor:'],
      },
      {
        'lockedElements': ['decor:id', 'decor:id'],
      },
      {
        'lockedFamilies': [1],
      },
      {
        'lockedFamilies': [''],
      },
      {'unknown': true},
      {
        'lockedFamilies': ['particles'],
      },
    ]) {
      expect(() => MapEditorState.fromJson(json), throwsFormatException);
    }
  });

  test('document schema and map paths are strict and preserve typed state', () {
    final document = MapEditorDocument(
      mapId: 'bourg_geon',
      state: MapEditorState(lockedElements: {'model:rear_particles'}),
    );
    expect(MapEditorDocument.fromJson(document.toJson()).state, document.state);
    expect(
      MapEditorDocument.relativePathForMap('bourg_geon'),
      'maps/bourg_geon.editor.json',
    );
    expect(
      () => MapEditorDocument.relativePathForMap('../escape'),
      throwsFormatException,
    );
    expect(
      () => MapEditorDocument.fromJson({
        ...document.toJson(),
        'schemaVersion': 3,
      }),
      throwsFormatException,
    );
  });

  test(
    'visibility has typed instance and family keys independent from locks',
    () {
      final state = MapEditorState(
        lockedElements: {'model:mist'},
        hiddenElements: {'layer:path', 'layer:border', 'model:wind:rear'},
        hiddenFamilies: {'effect'},
      );
      expect(state.isHidden('layer', 'path'), isTrue);
      expect(state.isHidden('layer', 'border'), isTrue);
      expect(state.isHidden('model', 'wind:rear'), isTrue);
      expect(state.isHidden('entity', 'wind:rear'), isFalse);
      expect(state.isHidden('effect', 'firefly'), isTrue);
      expect(state.isHidden('model', 'mist'), isFalse);
      expect(state.isLocked('model', 'wind:rear'), isFalse);
      final copied = state.copyWith(hiddenFamilies: {'model'});
      expect(copied.lockedElements, state.lockedElements);
      expect(copied.hiddenElements, state.hiddenElements);
      expect(copied.isHidden('model', 'mist'), isTrue);
      expect(copied.isHidden('effect', 'firefly'), isFalse);
      expect(
        () => state.hiddenElements.add('model:another'),
        throwsUnsupportedError,
      );
      expect(() => state.hiddenFamilies.clear(), throwsUnsupportedError);
    },
  );

  test(
    'all four collections roundtrip deterministically and affect equality',
    () {
      final state = MapEditorState(
        lockedElements: {'model:z', 'model:a'},
        lockedFamilies: {'trigger', 'effect'},
        hiddenElements: {'decor:z', 'decor:a'},
        hiddenFamilies: {'zone', 'layer'},
      );
      final reordered = MapEditorState(
        lockedElements: {'model:a', 'model:z'},
        lockedFamilies: {'effect', 'trigger'},
        hiddenElements: {'decor:a', 'decor:z'},
        hiddenFamilies: {'layer', 'zone'},
      );
      expect(state, reordered);
      expect(state.hashCode, reordered.hashCode);
      expect(state.toJson(), {
        'lockedElements': ['model:a', 'model:z'],
        'lockedFamilies': ['effect', 'trigger'],
        'hiddenElements': ['decor:a', 'decor:z'],
        'hiddenFamilies': ['layer', 'zone'],
      });
      expect(MapEditorState.fromJson(state.toJson()), state);
      expect(state.copyWith(hiddenElements: {}), isNot(state));
      expect(state.copyWith(hiddenFamilies: {}), isNot(state));
      expect(MapEditorState.fromJson({}).hiddenElements, isEmpty);
      expect(MapEditorState.fromJson({}).hiddenFamilies, isEmpty);
    },
  );

  test(
    'visibility rejects malformed keys duplicates and collection overflow',
    () {
      for (final json in <Map<String, dynamic>>[
        {
          'hiddenElements': ['unknown:id'],
        },
        {
          'hiddenElements': ['decor:'],
        },
        {
          'hiddenElements': ['model:a\u0000b'],
        },
        {
          'hiddenElements': ['model:id', 'model:id'],
        },
        {'hiddenElements': List.generate(4097, (index) => 'model:$index')},
        {
          'hiddenFamilies': [1],
        },
        {
          'hiddenFamilies': ['particles'],
        },
        {
          'hiddenFamilies': ['layer', 'layer'],
        },
        {'hiddenFamilies': List.filled(129, 'layer')},
      ]) {
        expect(() => MapEditorState.fromJson(json), throwsFormatException);
      }
      expect(
        () => MapEditorState(
          hiddenElements: {
            for (var index = 0; index < 4097; index++) 'model:$index',
          },
        ),
        throwsFormatException,
      );
      expect(
        () => MapEditorState(
          hiddenFamilies: {
            for (var index = 0; index < 129; index++) 'family$index',
          },
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'version one reads without visibility and canonical writes use version two',
    () {
      final legacyState = <String, dynamic>{
        'lockedElements': ['model:wind'],
        'lockedFamilies': ['layer'],
      };
      final legacy = <String, dynamic>{
        'schemaVersion': 1,
        'mapId': 'bourg',
        'state': legacyState,
      };
      final document = MapEditorDocument.fromJson(legacy);
      expect(document.state.lockedElements, {'model:wind'});
      expect(document.state.lockedFamilies, {'layer'});
      expect(document.state.hiddenElements, isEmpty);
      expect(document.state.hiddenFamilies, isEmpty);
      expect(legacy['schemaVersion'], 1);
      expect(legacyState.keys, ['lockedElements', 'lockedFamilies']);
      expect(MapEditorDocument.schemaVersion, 2);
      expect(MapEditorDocument.maxBytes, 65536);
      expect(document.toJson()['schemaVersion'], 2);
      expect(
        MapEditorDocument.fromJson(document.toJson()).state,
        document.state,
      );
    },
  );

  test(
    'document versions reject inconsistent visibility instead of dropping it',
    () {
      final document = MapEditorDocument(
        mapId: 'bourg',
        state: MapEditorState(hiddenElements: {'model:wind'}),
      ).toJson();
      for (final field in ['hiddenElements', 'hiddenFamilies']) {
        expect(
          () => MapEditorDocument.fromJson({
            'schemaVersion': 1,
            'mapId': 'bourg',
            'state': {field: <String>[]},
          }),
          throwsFormatException,
        );
      }
      for (final invalid in <Map<String, dynamic>>[
        {...document, 'schemaVersion': 3},
      {...document, 'schemaVersion': 2.0},
        {...document, 'state': {}},
        {
          ...document,
          'state': {...document['state'] as Map, 'hiddenElements': null},
        },
        {
          ...document,
          'state': {...document['state'] as Map, 'futureProperty': true},
        },
      ]) {
        expect(
          () => MapEditorDocument.fromJson(invalid),
          throwsFormatException,
        );
      }
    },
  );
}
