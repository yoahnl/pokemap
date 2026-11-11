import 'package:avelune_studio/features/regional_map/application/regional_map_choices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a link needs a map', () {
    expect(
      regionalMapLinkConfirmation(name: 'Bourg', mapId: null, asksName: true),
      isNull,
    );
    expect(
      regionalMapLinkConfirmation(name: '', mapId: null, asksName: false),
      isNull,
    );
  });

  test('a link that asks a name refuses a blank name and trims a valid one', () {
    expect(
      regionalMapLinkConfirmation(name: '   ', mapId: 'a', asksName: true),
      isNull,
    );
    expect(
      regionalMapLinkConfirmation(name: '', mapId: 'a', asksName: true),
      isNull,
    );
    expect(
      regionalMapLinkConfirmation(
        name: '  Bourg Palette \n',
        mapId: 'a',
        asksName: true,
      ),
      (name: 'Bourg Palette', mapId: 'a'),
    );
  });

  test('a link that does not ask a name only needs its map and returns an empty name', () {
    expect(
      regionalMapLinkConfirmation(name: '', mapId: 'b', asksName: false),
      (name: '', mapId: 'b'),
    );
  });
}
