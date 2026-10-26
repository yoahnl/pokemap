import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('real weather is explicit, versioned and old modes retain their versions', () {
    final patch = SpatialVisualPatch.fromJson({'weatherMode': 'real'});
    final json = SpatialVisualDocument(profile: patch).toJson();
    expect(json['schemaVersion'], 6);
    expect(SpatialVisualDocument.fromJson(json).profile, patch);
    expect(() => SpatialVisualDocument.fromJson({...json, 'schemaVersion': 5}), throwsFormatException);
    expect(SpatialVisualDocument(profile: SpatialVisualPatch.fromJson({'weatherMode': 'automatic'})).toJson()['schemaVersion'], 5);
  });
  test('player weather choices round trip without an IP address', () {
    final location = RealWeatherLocation(latitude: 48.86, longitude: 2.35, label: 'Paris', countryCode: 'FR');
    final prefs = RealWeatherPreferences(enabled: true, location: location);
    expect(RealWeatherPreferences.fromJson(prefs.toJson()), prefs);
    expect(location.toJson(), isNot(contains('ip')));
    expect(() => RealWeatherLocation(latitude: double.nan, longitude: 2, label: 'City'), throwsFormatException);
    expect(() => RealWeatherPreferences.fromJson({'enabled': 'yes'}), throwsFormatException);
    expect(() => RealWeatherLocation.fromJson({...location.toJson(), 'ip': 'address'}), throwsFormatException);
  });
}
