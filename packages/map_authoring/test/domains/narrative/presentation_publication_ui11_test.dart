import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('targeted Presentation publication is canonical and atomic', () async {
    final dispatcher = MapMutationDispatcher.canonical();
    expect(dispatcher.descriptors.map((e) => e.id),
        contains('presentationCinematic.publish'));
    final action = dispatcher.descriptors
        .singleWhere((a) => a.id == 'presentationCinematic.publish');
    expect(
        action.guarantees,
        containsAll([
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ]));
  });
}
