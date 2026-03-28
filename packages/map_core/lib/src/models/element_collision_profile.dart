import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';

part 'element_collision_profile.freezed.dart';
part 'element_collision_profile.g.dart';

@freezed
class ElementCollisionProfile with _$ElementCollisionProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ElementCollisionProfile({
    @Default(ElementCollisionProfileSource.generated)
    ElementCollisionProfileSource source,
    @Default([]) List<GridPos> cells,
  }) = _ElementCollisionProfile;

  factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionProfileFromJson(json);
}
