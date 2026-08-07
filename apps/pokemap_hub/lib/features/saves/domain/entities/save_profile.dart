import 'package:map_core/map_core.dart';

final class SaveProfile {
  const SaveProfile({
    required this.profileId,
    required this.displayName,
  });

  final String profileId;
  final String displayName;

  void validate() {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    if (displayName.trim().isEmpty ||
        displayName.length > 80 ||
        displayName.runes.any((rune) => rune < 0x20)) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Profile display name must contain 1-80 printable characters.',
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'profileId': profileId,
        'displayName': displayName,
      };

  static SaveProfile fromJson(Map<String, Object?> json) {
    if (json.length != 2 ||
        json['profileId'] is! String ||
        json['displayName'] is! String) {
      throw const FormatException('Invalid save profile metadata.');
    }
    final profile = SaveProfile(
      profileId: json['profileId']! as String,
      displayName: json['displayName']! as String,
    );
    profile.validate();
    return profile;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveProfile &&
          profileId == other.profileId &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(profileId, displayName);
}
