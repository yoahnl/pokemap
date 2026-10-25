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
      state
          .copyWith(lockedFamilies: {'decor'})
          .isLocked('decor', 'firefly'),
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
      {'lockedFamilies': ['particles']},
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
        'schemaVersion': 2,
      }),
      throwsFormatException,
    );
  });
}
