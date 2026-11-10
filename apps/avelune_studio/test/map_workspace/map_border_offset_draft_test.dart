import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'world offset draft preserves source and accepts French finite coordinates',
    () {
      final source = Model3dVector3(x: 1, y: 2, z: 3);
      final draft = MapBorderOffsetDraft(source);
      expect(draft.value, source);
      draft.inputs['x'] = '-2,5';
      draft.inputs['y'] = ' 0,125 ';
      expect(draft.value, Model3dVector3(x: -2.5, y: .125, z: 3));
      expect(source, Model3dVector3(x: 1, y: 2, z: 3));
      for (final invalid in ['NaN', 'Infinity', 'wrong']) {
        draft.inputs['z'] = invalid;
        expect(draft.value, isNull);
        expect(draft.inputs['x'], '-2,5');
      }
      expect(MapBorderOffsetDraft(null).value, Model3dVector3.zero);
    },
  );
}
