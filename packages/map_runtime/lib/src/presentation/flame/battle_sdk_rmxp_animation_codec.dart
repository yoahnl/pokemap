import 'dart:convert';
import 'dart:typed_data';

import 'battle_sdk_rmxp_animation_spec.dart';

/// Codec binaire du catalogue d'animations RMXP.
///
/// Le catalogue (874 animations, ~37k constructeurs const) vivait en Dart
/// généré : ~2,5 Mo de snapshot AOT chargés même sans combat, et le premier
/// poste de temps de compilation du repo. Il vit maintenant dans
/// `assets/battle_animations/rmxp_animation_catalog.bin`, encodé ici et
/// décodé paresseusement au premier combat.
///
/// Format v1, little-endian :
/// - magic `RMXA`, version u8
/// - table de chaînes : u16 count, puis (u16 longueur + UTF-8) par entrée
/// - u16 animationCount, puis par animation :
///   i32 id, u16 nameIdx, u16 animationNameIdx, u16 assetIdIdx,
///   i16 animationHue, u8 position, u16 frameMax, u8 option,
///   u8 forceNoReverse,
///   u16 frameCount × (u16 cellMax, u16 cellCount × cellule),
///   u16 timingCount × timing
/// - cellule : i16 index, pattern, x, y, zoom, angle ; u8 mirror ;
///   i16 opacity ; u8 blendType
/// - timing : i16 frame, condition ; u8 flashScope ; i16 flashDuration,
///   flashRed, flashGreen, flashBlue, flashAlpha ;
///   u16 seNameIdx (0xFFFF = null) ; i16 seVolume, sePitch
const int rmxpAnimationCatalogCodecVersion = 1;
const List<int> _magic = <int>[0x52, 0x4D, 0x58, 0x41]; // 'RMXA'
const int _nullStringIndex = 0xFFFF;

Uint8List encodeRmxpAnimationCatalog(Map<int, RmxpAnimationSpec> catalog) {
  final strings = <String, int>{};
  int intern(String value) =>
      strings.putIfAbsent(value, () => strings.length);

  // Première passe : interner toutes les chaînes dans l'ordre de rencontre.
  final specs = catalog.values.toList(growable: false);
  for (final spec in specs) {
    intern(spec.name);
    intern(spec.animationName);
    intern(spec.assetId);
    for (final timing in spec.timings) {
      final seName = timing.seName;
      if (seName != null) {
        intern(seName);
      }
    }
  }
  if (strings.length >= _nullStringIndex) {
    throw StateError('RMXP catalog string table overflow.');
  }

  final writer = _ByteWriter();
  writer.bytes(_magic);
  writer.u8(rmxpAnimationCatalogCodecVersion);
  writer.u16(strings.length);
  for (final value in strings.keys) {
    final encoded = utf8.encode(value);
    writer.u16(encoded.length);
    writer.bytes(encoded);
  }
  writer.u16(specs.length);
  for (final spec in specs) {
    writer.i32(spec.id);
    writer.u16(intern(spec.name));
    writer.u16(intern(spec.animationName));
    writer.u16(intern(spec.assetId));
    writer.i16(spec.animationHue);
    writer.u8(spec.position);
    writer.u16(spec.frameMax);
    writer.u8(spec.option.index);
    writer.u8(spec.forceNoReverse ? 1 : 0);
    writer.u16(spec.frames.length);
    for (final frame in spec.frames) {
      writer.u16(frame.cellMax);
      writer.u16(frame.cells.length);
      for (final cell in frame.cells) {
        writer.i16(cell.index);
        writer.i16(cell.pattern);
        writer.i16(cell.x);
        writer.i16(cell.y);
        writer.i16(cell.zoom);
        writer.i16(cell.angle);
        writer.u8(cell.mirror ? 1 : 0);
        writer.i16(cell.opacity);
        writer.u8(cell.blendType);
      }
    }
    writer.u16(spec.timings.length);
    for (final timing in spec.timings) {
      writer.i16(timing.frame);
      writer.i16(timing.condition);
      writer.u8(timing.flashScope);
      writer.i16(timing.flashDuration);
      writer.i16(timing.flashRed);
      writer.i16(timing.flashGreen);
      writer.i16(timing.flashBlue);
      writer.i16(timing.flashAlpha);
      final seName = timing.seName;
      writer.u16(seName == null ? _nullStringIndex : intern(seName));
      writer.i16(timing.seVolume);
      writer.i16(timing.sePitch);
    }
  }
  return writer.take();
}

Map<int, RmxpAnimationSpec> decodeRmxpAnimationCatalog(Uint8List bytes) {
  final reader = _ByteReader(bytes);
  for (final expected in _magic) {
    if (reader.u8() != expected) {
      throw const FormatException('Invalid RMXP animation catalog magic.');
    }
  }
  final version = reader.u8();
  if (version != rmxpAnimationCatalogCodecVersion) {
    throw FormatException(
      'Unsupported RMXP animation catalog version: $version',
    );
  }
  final stringCount = reader.u16();
  final strings = List<String>.generate(stringCount, (_) {
    final length = reader.u16();
    return utf8.decode(reader.raw(length));
  });
  String stringAt(int index) => strings[index];

  final animationCount = reader.u16();
  final catalog = <int, RmxpAnimationSpec>{};
  for (var a = 0; a < animationCount; a += 1) {
    final id = reader.i32();
    final name = stringAt(reader.u16());
    final animationName = stringAt(reader.u16());
    final assetId = stringAt(reader.u16());
    final animationHue = reader.i16();
    final position = reader.u8();
    final frameMax = reader.u16();
    final option = RmxpAnimationOption.values[reader.u8()];
    final forceNoReverse = reader.u8() != 0;
    final frameCount = reader.u16();
    final frames = List<RmxpAnimationFrameSpec>.generate(frameCount, (_) {
      final cellMax = reader.u16();
      final cellCount = reader.u16();
      final cells = List<RmxpAnimationCellSpec>.generate(cellCount, (_) {
        final index = reader.i16();
        final pattern = reader.i16();
        final x = reader.i16();
        final y = reader.i16();
        final zoom = reader.i16();
        final angle = reader.i16();
        final mirror = reader.u8() != 0;
        final opacity = reader.i16();
        final blendType = reader.u8();
        return RmxpAnimationCellSpec(
          index: index,
          pattern: pattern,
          x: x,
          y: y,
          zoom: zoom,
          angle: angle,
          mirror: mirror,
          opacity: opacity,
          blendType: blendType,
        );
      }, growable: false);
      return RmxpAnimationFrameSpec(cellMax: cellMax, cells: cells);
    }, growable: false);
    final timingCount = reader.u16();
    final timings = List<RmxpAnimationTimingSpec>.generate(timingCount, (_) {
      final frame = reader.i16();
      final condition = reader.i16();
      final flashScope = reader.u8();
      final flashDuration = reader.i16();
      final flashRed = reader.i16();
      final flashGreen = reader.i16();
      final flashBlue = reader.i16();
      final flashAlpha = reader.i16();
      final seNameIndex = reader.u16();
      final seVolume = reader.i16();
      final sePitch = reader.i16();
      return RmxpAnimationTimingSpec(
        frame: frame,
        condition: condition,
        flashScope: flashScope,
        flashDuration: flashDuration,
        flashRed: flashRed,
        flashGreen: flashGreen,
        flashBlue: flashBlue,
        flashAlpha: flashAlpha,
        seName: seNameIndex == _nullStringIndex ? null : stringAt(seNameIndex),
        seVolume: seVolume,
        sePitch: sePitch,
      );
    }, growable: false);
    catalog[id] = RmxpAnimationSpec(
      id: id,
      name: name,
      animationName: animationName,
      assetId: assetId,
      animationHue: animationHue,
      position: position,
      frameMax: frameMax,
      option: option,
      forceNoReverse: forceNoReverse,
      frames: frames,
      timings: timings,
    );
  }
  if (!reader.isAtEnd) {
    throw const FormatException(
      'Trailing bytes after RMXP animation catalog payload.',
    );
  }
  return Map<int, RmxpAnimationSpec>.unmodifiable(catalog);
}

final class _ByteWriter {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  void u8(int value) {
    if (value < 0 || value > 0xFF) {
      throw RangeError.range(value, 0, 0xFF, 'u8');
    }
    _builder.addByte(value);
  }

  void u16(int value) {
    if (value < 0 || value > 0xFFFF) {
      throw RangeError.range(value, 0, 0xFFFF, 'u16');
    }
    _builder
      ..addByte(value & 0xFF)
      ..addByte((value >> 8) & 0xFF);
  }

  void i16(int value) {
    if (value < -0x8000 || value > 0x7FFF) {
      throw RangeError.range(value, -0x8000, 0x7FFF, 'i16');
    }
    u16(value & 0xFFFF);
  }

  void i32(int value) {
    if (value < -0x80000000 || value > 0x7FFFFFFF) {
      throw RangeError.range(value, -0x80000000, 0x7FFFFFFF, 'i32');
    }
    final unsigned = value & 0xFFFFFFFF;
    _builder
      ..addByte(unsigned & 0xFF)
      ..addByte((unsigned >> 8) & 0xFF)
      ..addByte((unsigned >> 16) & 0xFF)
      ..addByte((unsigned >> 24) & 0xFF);
  }

  void bytes(List<int> value) {
    _builder.add(value);
  }

  Uint8List take() => _builder.takeBytes();
}

final class _ByteReader {
  _ByteReader(this._bytes) : _view = ByteData.sublistView(_bytes);

  final Uint8List _bytes;
  final ByteData _view;
  int _offset = 0;

  bool get isAtEnd => _offset == _bytes.length;

  int u8() {
    final value = _view.getUint8(_offset);
    _offset += 1;
    return value;
  }

  int u16() {
    final value = _view.getUint16(_offset, Endian.little);
    _offset += 2;
    return value;
  }

  int i16() {
    final value = _view.getInt16(_offset, Endian.little);
    _offset += 2;
    return value;
  }

  int i32() {
    final value = _view.getInt32(_offset, Endian.little);
    _offset += 4;
    return value;
  }

  Uint8List raw(int length) {
    final value = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return value;
  }
}
