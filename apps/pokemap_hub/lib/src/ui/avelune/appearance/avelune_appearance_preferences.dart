import 'package:flutter/foundation.dart';

import 'avelune_appearance_catalog.dart';

@immutable
final class AveluneAppearancePreferences {
  const AveluneAppearancePreferences({
    this.backgroundId = AveluneAppearanceCatalog.defaultBackgroundId,
    this.furnitureId = AveluneAppearanceCatalog.defaultFurnitureId,
  });

  factory AveluneAppearancePreferences.fromJson(Map<String, Object?> json) {
    const allowedKeys = <String>{
      'schemaVersion',
      'backgroundId',
      'furnitureId',
    };
    final keys = json.keys.toSet();
    if (keys.length != allowedKeys.length ||
        keys.difference(allowedKeys).isNotEmpty ||
        json['schemaVersion'] != 1 ||
        json['backgroundId'] is! String ||
        json['furnitureId'] is! String) {
      throw const FormatException(
        'Avelune appearance preferences must use the exact V1 schema.',
      );
    }
    final backgroundId = json['backgroundId']! as String;
    final furnitureId = json['furnitureId']! as String;
    if (!AveluneAppearanceCatalog.backgroundIds.contains(backgroundId) ||
        !AveluneAppearanceCatalog.furnitureIds.contains(furnitureId)) {
      throw const FormatException('Unknown Avelune appearance identifier.');
    }
    return AveluneAppearancePreferences(
      backgroundId: backgroundId,
      furnitureId: furnitureId,
    );
  }

  final String backgroundId;
  final String furnitureId;

  AveluneAppearancePreferences copyWith({
    String? backgroundId,
    String? furnitureId,
  }) =>
      AveluneAppearancePreferences(
        backgroundId: backgroundId ?? this.backgroundId,
        furnitureId: furnitureId ?? this.furnitureId,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'backgroundId': backgroundId,
        'furnitureId': furnitureId,
      };

  @override
  bool operator ==(Object other) =>
      other is AveluneAppearancePreferences &&
      backgroundId == other.backgroundId &&
      furnitureId == other.furnitureId;

  @override
  int get hashCode => Object.hash(backgroundId, furnitureId);
}
