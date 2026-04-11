import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapEntityEditorVisual', () {
    test('defaults to background entity rendering', () {
      const visual = MapEntityEditorVisual(elementId: 'pokeball');

      expect(visual.renderInForeground, isFalse);
    });

    test('serializes and exposes the foreground render flag', () {
      const entity = MapEntity(
        id: 'pokeball',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 3),
        editorVisual: MapEntityEditorVisual(
          elementId: 'pokeball',
          renderInForeground: true,
        ),
      );

      final json = entity.toJson();
      final roundTrip = MapEntity.fromJson(json);

      expect(
        (json['editorVisual'] as Map<String, dynamic>)['renderInForeground'],
        isTrue,
      );
      expect(roundTrip.editorVisual?.renderInForeground, isTrue);
      expect(roundTrip.shouldRenderProjectElementInForeground, isTrue);
    });
  });
}
