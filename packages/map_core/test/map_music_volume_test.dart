import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('map metadata retains an explicit finite music gain', () {
    for (final volume in [0, 0.37, 0.8, 1]) {
      final metadata = MapMetadata.fromJson({'musicVolume': volume});
      expect(metadata.toJson()['musicVolume'], volume.toDouble());
      expect(MapMetadata.fromJson(metadata.toJson()), metadata);
    }
  });

  test('omitted and cleared music gains retain the native default marker', () {
    expect(MapMetadata.fromJson({}).toJson()['musicVolume'], isNull);
    expect(
      MapMetadata.fromJson({'musicVolume': null}).toJson()['musicVolume'],
      isNull,
    );
  });

  test('metadata rejects invalid music gains before loading a map', () {
    for (final value in [
      -0.01,
      1.01,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      '0.8',
      true,
      [],
    ]) {
      expect(
        () => MapMetadata.fromJson({'musicVolume': value}),
        throwsFormatException,
        reason: '$value',
      );
    }
  });

  test('music gain survives map normalization and full map round-trip', () {
    final metadata = MapMetadata.fromJson({
      'displayName': ' Route ',
      'musicPath': ' assets/music/route.ogg ',
      'musicVolume': 0.375,
      'tags': [' outdoor '],
    });
    final map = updateMapMetadataOnMap(
      const MapData(
        id: 'route',
        name: 'Route',
        size: GridSize(width: 2, height: 2),
      ),
      metadata,
    );
    expect(map.mapMetadata.displayName, 'Route');
    expect(map.mapMetadata.tags, ['outdoor']);
    expect(map.mapMetadata.toJson()['musicVolume'], 0.375);
    expect(MapData.fromJson(map.toJson()), map);
  });

  test('typed invalid metadata is refused by canonical map validation', () {
    for (final value in [-0.1, 1.1, double.nan, double.infinity]) {
      final map = MapData(
        id: 'route',
        name: 'Route',
        size: const GridSize(width: 2, height: 2),
        mapMetadata: MapMetadata(musicVolume: value),
      );
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => updateMapMetadataOnMap(
          map.copyWith(mapMetadata: const MapMetadata()),
          map.mapMetadata,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('copy and value equality include explicit gain and clearing', () {
    const base = MapMetadata(
      musicPath: 'assets/music/route.ogg',
      musicVolume: 0.37,
    );
    expect(base.musicVolume, 0.37);
    expect(
      base,
      const MapMetadata(musicPath: 'assets/music/route.ogg', musicVolume: 0.37),
    );
    expect(
      base.hashCode,
      const MapMetadata(
        musicPath: 'assets/music/route.ogg',
        musicVolume: 0.37,
      ).hashCode,
    );
    expect(base.copyWith(musicVolume: 0), isNot(base));
    expect(base.copyWith(musicVolume: null).musicVolume, isNull);
    expect(base.copyWith(musicVolume: null).musicPath, base.musicPath);
  });
}
