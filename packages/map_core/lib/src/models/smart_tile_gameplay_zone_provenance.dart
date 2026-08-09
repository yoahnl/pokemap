final class SmartTileGameplayZoneProvenance {
  const SmartTileGameplayZoneProvenance({
    required this.smartTileLayerId,
    required this.smartTilePresetId,
    required this.materialId,
    required this.behaviorKey,
  });

  factory SmartTileGameplayZoneProvenance.fromJson(Map<String, dynamic> json) {
    return SmartTileGameplayZoneProvenance(
      smartTileLayerId: _requiredString(json, 'smartTileLayerId'),
      smartTilePresetId: _requiredString(json, 'smartTilePresetId'),
      materialId: _requiredString(json, 'materialId'),
      behaviorKey: _requiredString(json, 'behaviorKey'),
    );
  }

  final String smartTileLayerId;
  final String smartTilePresetId;
  final String materialId;
  final String behaviorKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'smartTileLayerId': smartTileLayerId,
    'smartTilePresetId': smartTilePresetId,
    'materialId': materialId,
    'behaviorKey': behaviorKey,
  };

  bool hasSameBinding(SmartTileGameplayZoneProvenance other) {
    return smartTileLayerId == other.smartTileLayerId &&
        behaviorKey == other.behaviorKey;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneProvenance &&
            smartTileLayerId == other.smartTileLayerId &&
            smartTilePresetId == other.smartTilePresetId &&
            materialId == other.materialId &&
            behaviorKey == other.behaviorKey;
  }

  @override
  int get hashCode =>
      Object.hash(smartTileLayerId, smartTilePresetId, materialId, behaviorKey);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('\$.$key: expected a nonblank string');
  }
  return value.trim();
}
