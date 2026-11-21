import 'package:map_core/map_core.dart';

final class SaveSlotMetadata {
  const SaveSlotMetadata({
    required this.slotId,
    required this.displayName,
    required this.createdAt,
  });

  final String slotId;
  final String displayName;
  final DateTime createdAt;

  void validate() {
    GameIdentity.validateLocalId(slotId, path: r'$.slotId');
    if (displayName.trim().isEmpty ||
        displayName.length > 80 ||
        displayName.runes.any((rune) => rune < 0x20)) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Slot display name must contain 1-80 printable characters.',
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'slotId': slotId,
        'displayName': displayName,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static SaveSlotMetadata fromJson(Map<String, Object?> json) {
    if (json.length != 3 ||
        json['slotId'] is! String ||
        json['displayName'] is! String ||
        json['createdAt'] is! String) {
      throw const FormatException('Invalid save slot metadata.');
    }
    final metadata = SaveSlotMetadata(
      slotId: json['slotId']! as String,
      displayName: json['displayName']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
    );
    metadata.validate();
    return metadata;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveSlotMetadata &&
          slotId == other.slotId &&
          displayName == other.displayName &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(slotId, displayName, createdAt);
}
