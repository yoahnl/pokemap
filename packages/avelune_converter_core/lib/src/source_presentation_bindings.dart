part of '../avelune_converter_core.dart';

int _presentationInt(Object? value, int minimum, int maximum) {
  _require(
      value is int && value >= minimum && value <= maximum,
      'presentation.value',
      r'$',
      'Presentation values must be bounded integers.');
  return value as int;
}

String _presentationCharset(Object? value) {
  final name = _interpretationString(value);
  _require(
      name.length <= 128 &&
          !name.contains('/') &&
          !name.contains('\\') &&
          name != '.' &&
          name != '..' &&
          !name.contains(':') &&
          !name.toLowerCase().endsWith('.png'),
      'presentation.charset',
      r'$',
      'Character bindings require a plain charset name.');
  validateSourceRelativePath('Graphics/Characters/$name.png');
  return name;
}

List<Map<String, Object?>> _presentationRows(Object? value, int maximum) {
  final rows = value ?? const [];
  _require(rows is List && rows.length <= maximum, 'presentation.quota', r'$',
      'Presentation collections exceed their bounded inventory.');
  return (rows as List).map(_interpretationObject).toList();
}

final class SourcePresentationAssetPin {
  SourcePresentationAssetPin._(this.relativePath, this.sha256);
  factory SourcePresentationAssetPin.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {'relativePath', 'sha256'});
    final path = _interpretationString(json['relativePath']);
    validateSourceRelativePath(path, maxCodeUnits: 512);
    return SourcePresentationAssetPin._(
        path, Sha256Hash(_interpretationString(json['sha256'])));
  }
  final String relativePath;
  final Sha256Hash sha256;
  Map<String, Object?> toJson() =>
      {'relativePath': relativePath, 'sha256': sha256.value};
}

final class SourceCharacterSubstitution {
  SourceCharacterSubstitution._(this.requestedCharset, this.actualCharset,
      this.targetSha256, this.reason);
  factory SourceCharacterSubstitution.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json,
        const {'requestedCharset', 'actualCharset', 'targetSha256', 'reason'});
    final requested = _presentationCharset(json['requestedCharset']);
    final actual = _presentationCharset(json['actualCharset']);
    _require(
        sourcePathCollisionKey(requested) != sourcePathCollisionKey(actual),
        'presentation.substitution',
        r'$',
        'A substitution must name a distinct actual charset.');
    return SourceCharacterSubstitution._(
        requested,
        actual,
        Sha256Hash(_interpretationString(json['targetSha256'])),
        _interpretationString(json['reason']));
  }
  final String requestedCharset, actualCharset, reason;
  final Sha256Hash targetSha256;
  Map<String, Object?> toJson() => {
        'requestedCharset': requestedCharset,
        'actualCharset': actualCharset,
        'targetSha256': targetSha256.value,
        'reason': reason
      };
}

final class SourceRoutedDoorPattern {
  SourceRoutedDoorPattern._(
      this.charset, this.sha256, this.departurePattern, this.arrivalPattern);
  factory SourceRoutedDoorPattern.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json,
        const {'charset', 'sha256', 'departurePattern', 'arrivalPattern'});
    return SourceRoutedDoorPattern._(
        _presentationCharset(json['charset']),
        Sha256Hash(_interpretationString(json['sha256'])),
        _presentationInt(json['departurePattern'], 0, 3),
        _presentationInt(json['arrivalPattern'], 0, 3));
  }
  final String charset;
  final Sha256Hash sha256;
  final int departurePattern, arrivalPattern;
  Map<String, Object?> toJson() => {
        'charset': charset,
        'sha256': sha256.value,
        'departurePattern': departurePattern,
        'arrivalPattern': arrivalPattern
      };
}

final class SourcePickupFeedbackRegion {
  SourcePickupFeedbackRegion._(this.regionId, this.windowskinPinnedAsset,
      this.iconsByPocket, this.audioByItemKind);
  factory SourcePickupFeedbackRegion.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {
      'regionId',
      'windowskinPinnedAsset',
      'iconsByPocket',
      'audioByItemKind'
    });
    final rawIcons = _interpretationObject(json['iconsByPocket']);
    final rawAudio = _interpretationObject(json['audioByItemKind']);
    _require(
        rawIcons.isNotEmpty &&
            rawIcons.length <= 64 &&
            rawAudio.isNotEmpty &&
            rawAudio.keys.every(const {'item', 'keyItem', 'machine'}.contains),
        'presentation.pickup',
        r'$',
        'Pickup presentation requires supported pockets and item kinds.');
    final icons = <int, SourcePresentationAssetPin>{};
    for (final entry in rawIcons.entries) {
      final index = int.tryParse(entry.key);
      _require(
          index != null && index >= 1 && index <= 64 && '$index' == entry.key,
          'presentation.pickup',
          r'$',
          'Pocket indices must be canonical positive integers.');
      icons[index!] = SourcePresentationAssetPin.fromJson(entry.value);
    }
    return SourcePickupFeedbackRegion._(
        _presentationInt(json['regionId'], 0, 2147483647),
        SourcePresentationAssetPin.fromJson(json['windowskinPinnedAsset']),
        Map.unmodifiable(icons),
        Map.unmodifiable(rawAudio.map((key, value) =>
            MapEntry(key, SourcePresentationAssetPin.fromJson(value)))));
  }
  final int regionId;
  final SourcePresentationAssetPin windowskinPinnedAsset;
  final Map<int, SourcePresentationAssetPin> iconsByPocket;
  final Map<String, SourcePresentationAssetPin> audioByItemKind;
  Map<String, Object?> toJson() => {
        'regionId': regionId,
        'windowskinPinnedAsset': windowskinPinnedAsset.toJson(),
        'iconsByPocket': {
          for (final e in iconsByPocket.entries) '${e.key}': e.value.toJson()
        },
        'audioByItemKind': {
          for (final e in audioByItemKind.entries) e.key: e.value.toJson()
        }
      };
}

final class SourceHealingPresentationSheet {
  SourceHealingPresentationSheet._(this.asset, this.pixelWidth,
      this.pixelHeight, this.tileWidth, this.tileHeight);
  factory SourceHealingPresentationSheet.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {
      'asset',
      'pixelWidth',
      'pixelHeight',
      'tileWidth',
      'tileHeight'
    });
    final width = _presentationInt(json['pixelWidth'], 1, 16384);
    final height = _presentationInt(json['pixelHeight'], 1, 16384);
    final tileWidth = _presentationInt(json['tileWidth'], 1, 4096);
    final tileHeight = _presentationInt(json['tileHeight'], 1, 4096);
    _require(
        width % tileWidth == 0 && height % tileHeight == 0,
        'presentation.healing_grid',
        r'$',
        'Healing sheets require a complete integral tile grid.');
    return SourceHealingPresentationSheet._(
        SourcePresentationAssetPin.fromJson(json['asset']),
        width,
        height,
        tileWidth,
        tileHeight);
  }
  final SourcePresentationAssetPin asset;
  final int pixelWidth, pixelHeight, tileWidth, tileHeight;
  Map<String, Object?> toJson() => {
        'asset': asset.toJson(),
        'pixelWidth': pixelWidth,
        'pixelHeight': pixelHeight,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight
      };
}

final class SourceHealingPresentationFrame {
  SourceHealingPresentationFrame._(
      this.x, this.y, this.width, this.height, this.durationMs);
  factory SourceHealingPresentationFrame.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(
        json, const {'x', 'y', 'width', 'height', 'durationMs'});
    return SourceHealingPresentationFrame._(
        _presentationInt(json['x'], 0, 16383),
        _presentationInt(json['y'], 0, 16383),
        _presentationInt(json['width'], 1, 16384),
        _presentationInt(json['height'], 1, 16384),
        _presentationInt(json['durationMs'], 1, 60000));
  }
  final int x, y, width, height, durationMs;
  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'durationMs': durationMs
      };
}

final class SourceHealingPresentationVariant {
  SourceHealingPresentationVariant._(this.count, this.sheetIndex, this.frames);
  factory SourceHealingPresentationVariant.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {'count', 'sheetIndex', 'frames'});
    final frames = _presentationRows(json['frames'], 64)
        .map(SourceHealingPresentationFrame.fromJson)
        .toList();
    _require(frames.isNotEmpty, 'presentation.healing_frames', r'$',
        'Each healing variant requires animation frames.');
    return SourceHealingPresentationVariant._(
        _presentationInt(json['count'], 1, 6),
        _presentationInt(json['sheetIndex'], 0, 7),
        List.unmodifiable(frames));
  }
  final int count, sheetIndex;
  final List<SourceHealingPresentationFrame> frames;
  Map<String, Object?> toJson() => {
        'count': count,
        'sheetIndex': sheetIndex,
        'frames': frames.map((f) => f.toJson()).toList()
      };
}

final class SourceHealingDisplayPresentation {
  SourceHealingDisplayPresentation._(this.sheets, this.variants);
  factory SourceHealingDisplayPresentation.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {'sheets', 'variants'});
    final sheets = _presentationRows(json['sheets'], 8)
        .map(SourceHealingPresentationSheet.fromJson)
        .toList();
    final variants = _presentationRows(json['variants'], 6)
        .map(SourceHealingPresentationVariant.fromJson)
        .toList();
    _require(
        sheets.isNotEmpty &&
            variants.length == 6 &&
            variants.map((v) => v.count).toSet().length == 6 &&
            sheets
                    .map((s) => sourcePathCollisionKey(s.asset.relativePath))
                    .toSet()
                    .length ==
                sheets.length,
        'presentation.healing_inventory',
        r'$',
        'Healing presentation requires distinct sheets and all six counts.');
    for (final variant in variants) {
      _require(variant.sheetIndex < sheets.length, 'presentation.healing_sheet',
          r'$', 'Healing variant references an absent sheet.');
      final sheet = sheets[variant.sheetIndex];
      for (final frame in variant.frames) {
        _require(
            frame.x + frame.width <= sheet.pixelWidth ~/ sheet.tileWidth &&
                frame.y + frame.height <= sheet.pixelHeight ~/ sheet.tileHeight,
            'presentation.healing_rect',
            r'$',
            'Healing frames must fit their declared sheet grid.');
      }
    }
    variants.sort((a, b) => a.count.compareTo(b.count));
    return SourceHealingDisplayPresentation._(
        List.unmodifiable(sheets), List.unmodifiable(variants));
  }
  final List<SourceHealingPresentationSheet> sheets;
  final List<SourceHealingPresentationVariant> variants;
  Map<String, Object?> toJson() => {
        'sheets': sheets.map((s) => s.toJson()).toList(),
        'variants': variants.map((v) => v.toJson()).toList()
      };
}

final class SourcePresentationBindings {
  SourcePresentationBindings._(
      this.characterSubstitutions,
      this.routedDoorPatterns,
      this.pickupFeedbackByRegion,
      this.healingDisplay);
  factory SourcePresentationBindings.fromJson(Object? value) {
    final json = _interpretationObject(value);
    _interpretationKeys(json, const {
      'characterSubstitutions',
      'routedDoorPatterns',
      'pickupFeedbackByRegion',
      'healingDisplay'
    });
    final characters = _presentationRows(json['characterSubstitutions'], 128)
        .map(SourceCharacterSubstitution.fromJson)
        .toList();
    final doors = _presentationRows(json['routedDoorPatterns'], 128)
        .map(SourceRoutedDoorPattern.fromJson)
        .toList();
    final pickups = _presentationRows(json['pickupFeedbackByRegion'], 128)
        .map(SourcePickupFeedbackRegion.fromJson)
        .toList();
    _require(
        characters
                    .map((c) => sourcePathCollisionKey(c.requestedCharset))
                    .toSet()
                    .length ==
                characters.length &&
            doors
                    .map((d) => sourcePathCollisionKey(d.charset))
                    .toSet()
                    .length ==
                doors.length &&
            pickups.map((p) => p.regionId).toSet().length == pickups.length,
        'presentation.duplicate',
        r'$',
        'Presentation mappings must have unambiguous identities.');
    return SourcePresentationBindings._(
        List.unmodifiable(characters),
        List.unmodifiable(doors),
        List.unmodifiable(pickups),
        json['healingDisplay'] == null
            ? null
            : SourceHealingDisplayPresentation.fromJson(
                json['healingDisplay']));
  }
  final List<SourceCharacterSubstitution> characterSubstitutions;
  final List<SourceRoutedDoorPattern> routedDoorPatterns;
  final List<SourcePickupFeedbackRegion> pickupFeedbackByRegion;
  final SourceHealingDisplayPresentation? healingDisplay;
  Map<String, Object?> toJson() => {
        if (characterSubstitutions.isNotEmpty)
          'characterSubstitutions':
              characterSubstitutions.map((c) => c.toJson()).toList(),
        if (routedDoorPatterns.isNotEmpty)
          'routedDoorPatterns':
              routedDoorPatterns.map((d) => d.toJson()).toList(),
        if (pickupFeedbackByRegion.isNotEmpty)
          'pickupFeedbackByRegion':
              pickupFeedbackByRegion.map((p) => p.toJson()).toList(),
        if (healingDisplay != null) 'healingDisplay': healingDisplay!.toJson()
      };
}
