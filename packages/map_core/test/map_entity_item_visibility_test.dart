import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('item entity visibility is explicit and round-trips', () {
    const hidden = MapEntityItemData(
      gameItemId: 'hidden-tonic',
      visibility: MapEntityItemVisibility.hidden,
    );

    final decoded = MapEntityItemData.fromJson(hidden.toJson());

    expect(decoded.visibility, MapEntityItemVisibility.hidden);
    expect(decoded.toJson()['visibility'], 'hidden');
  });

  test('item entities remain visible unless authored hidden', () {
    final decoded = MapEntityItemData.fromJson(const <String, dynamic>{
      'gameItemId': 'potion',
      'quantity': 1,
      'pickupMode': 'once',
      'respawnPolicy': 'none',
    });

    expect(decoded.visibility, MapEntityItemVisibility.visible);
  });
}
