// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_presentation_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProjectPresentationDiagnostic {
  String get code => throw _privateConstructorUsedError;
  ProjectPresentationCategory get category =>
      throw _privateConstructorUsedError;
  ProjectPresentationDiagnosticSeverity get severity =>
      throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPresentationDiagnostic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPresentationDiagnosticCopyWith<ProjectPresentationDiagnostic>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPresentationDiagnosticCopyWith<$Res> {
  factory $ProjectPresentationDiagnosticCopyWith(
          ProjectPresentationDiagnostic value,
          $Res Function(ProjectPresentationDiagnostic) then) =
      _$ProjectPresentationDiagnosticCopyWithImpl<$Res,
          ProjectPresentationDiagnostic>;
  @useResult
  $Res call(
      {String code,
      ProjectPresentationCategory category,
      ProjectPresentationDiagnosticSeverity severity,
      String path,
      String message});
}

/// @nodoc
class _$ProjectPresentationDiagnosticCopyWithImpl<$Res,
        $Val extends ProjectPresentationDiagnostic>
    implements $ProjectPresentationDiagnosticCopyWith<$Res> {
  _$ProjectPresentationDiagnosticCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPresentationDiagnostic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? category = null,
    Object? severity = null,
    Object? path = null,
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ProjectPresentationCategory,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ProjectPresentationDiagnosticSeverity,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectPresentationDiagnosticImplCopyWith<$Res>
    implements $ProjectPresentationDiagnosticCopyWith<$Res> {
  factory _$$ProjectPresentationDiagnosticImplCopyWith(
          _$ProjectPresentationDiagnosticImpl value,
          $Res Function(_$ProjectPresentationDiagnosticImpl) then) =
      __$$ProjectPresentationDiagnosticImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      ProjectPresentationCategory category,
      ProjectPresentationDiagnosticSeverity severity,
      String path,
      String message});
}

/// @nodoc
class __$$ProjectPresentationDiagnosticImplCopyWithImpl<$Res>
    extends _$ProjectPresentationDiagnosticCopyWithImpl<$Res,
        _$ProjectPresentationDiagnosticImpl>
    implements _$$ProjectPresentationDiagnosticImplCopyWith<$Res> {
  __$$ProjectPresentationDiagnosticImplCopyWithImpl(
      _$ProjectPresentationDiagnosticImpl _value,
      $Res Function(_$ProjectPresentationDiagnosticImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPresentationDiagnostic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? category = null,
    Object? severity = null,
    Object? path = null,
    Object? message = null,
  }) {
    return _then(_$ProjectPresentationDiagnosticImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ProjectPresentationCategory,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ProjectPresentationDiagnosticSeverity,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ProjectPresentationDiagnosticImpl
    implements _ProjectPresentationDiagnostic {
  const _$ProjectPresentationDiagnosticImpl(
      {required this.code,
      required this.category,
      required this.severity,
      required this.path,
      required this.message});

  @override
  final String code;
  @override
  final ProjectPresentationCategory category;
  @override
  final ProjectPresentationDiagnosticSeverity severity;
  @override
  final String path;
  @override
  final String message;

  @override
  String toString() {
    return 'ProjectPresentationDiagnostic(code: $code, category: $category, severity: $severity, path: $path, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPresentationDiagnosticImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, code, category, severity, path, message);

  /// Create a copy of ProjectPresentationDiagnostic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPresentationDiagnosticImplCopyWith<
          _$ProjectPresentationDiagnosticImpl>
      get copyWith => __$$ProjectPresentationDiagnosticImplCopyWithImpl<
          _$ProjectPresentationDiagnosticImpl>(this, _$identity);
}

abstract class _ProjectPresentationDiagnostic
    implements ProjectPresentationDiagnostic {
  const factory _ProjectPresentationDiagnostic(
      {required final String code,
      required final ProjectPresentationCategory category,
      required final ProjectPresentationDiagnosticSeverity severity,
      required final String path,
      required final String message}) = _$ProjectPresentationDiagnosticImpl;

  @override
  String get code;
  @override
  ProjectPresentationCategory get category;
  @override
  ProjectPresentationDiagnosticSeverity get severity;
  @override
  String get path;
  @override
  String get message;

  /// Create a copy of ProjectPresentationDiagnostic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPresentationDiagnosticImplCopyWith<
          _$ProjectPresentationDiagnosticImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectBrandingProfile _$ProjectBrandingProfileFromJson(
    Map<String, dynamic> json) {
  return _ProjectBrandingProfile.fromJson(json);
}

/// @nodoc
mixin _$ProjectBrandingProfile {
  @JsonKey(includeIfNull: false)
  String? get iconPath => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get coverPath => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get heroPath => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get accentColor => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get titleMusicPath => throw _privateConstructorUsedError;
  String get layoutVariant => throw _privateConstructorUsedError;

  /// Serializes this ProjectBrandingProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectBrandingProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectBrandingProfileCopyWith<ProjectBrandingProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectBrandingProfileCopyWith<$Res> {
  factory $ProjectBrandingProfileCopyWith(ProjectBrandingProfile value,
          $Res Function(ProjectBrandingProfile) then) =
      _$ProjectBrandingProfileCopyWithImpl<$Res, ProjectBrandingProfile>;
  @useResult
  $Res call(
      {@JsonKey(includeIfNull: false) String? iconPath,
      @JsonKey(includeIfNull: false) String? coverPath,
      @JsonKey(includeIfNull: false) String? heroPath,
      @JsonKey(includeIfNull: false) String? accentColor,
      @JsonKey(includeIfNull: false) String? titleMusicPath,
      String layoutVariant});
}

/// @nodoc
class _$ProjectBrandingProfileCopyWithImpl<$Res,
        $Val extends ProjectBrandingProfile>
    implements $ProjectBrandingProfileCopyWith<$Res> {
  _$ProjectBrandingProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectBrandingProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? iconPath = freezed,
    Object? coverPath = freezed,
    Object? heroPath = freezed,
    Object? accentColor = freezed,
    Object? titleMusicPath = freezed,
    Object? layoutVariant = null,
  }) {
    return _then(_value.copyWith(
      iconPath: freezed == iconPath
          ? _value.iconPath
          : iconPath // ignore: cast_nullable_to_non_nullable
              as String?,
      coverPath: freezed == coverPath
          ? _value.coverPath
          : coverPath // ignore: cast_nullable_to_non_nullable
              as String?,
      heroPath: freezed == heroPath
          ? _value.heroPath
          : heroPath // ignore: cast_nullable_to_non_nullable
              as String?,
      accentColor: freezed == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as String?,
      titleMusicPath: freezed == titleMusicPath
          ? _value.titleMusicPath
          : titleMusicPath // ignore: cast_nullable_to_non_nullable
              as String?,
      layoutVariant: null == layoutVariant
          ? _value.layoutVariant
          : layoutVariant // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectBrandingProfileImplCopyWith<$Res>
    implements $ProjectBrandingProfileCopyWith<$Res> {
  factory _$$ProjectBrandingProfileImplCopyWith(
          _$ProjectBrandingProfileImpl value,
          $Res Function(_$ProjectBrandingProfileImpl) then) =
      __$$ProjectBrandingProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeIfNull: false) String? iconPath,
      @JsonKey(includeIfNull: false) String? coverPath,
      @JsonKey(includeIfNull: false) String? heroPath,
      @JsonKey(includeIfNull: false) String? accentColor,
      @JsonKey(includeIfNull: false) String? titleMusicPath,
      String layoutVariant});
}

/// @nodoc
class __$$ProjectBrandingProfileImplCopyWithImpl<$Res>
    extends _$ProjectBrandingProfileCopyWithImpl<$Res,
        _$ProjectBrandingProfileImpl>
    implements _$$ProjectBrandingProfileImplCopyWith<$Res> {
  __$$ProjectBrandingProfileImplCopyWithImpl(
      _$ProjectBrandingProfileImpl _value,
      $Res Function(_$ProjectBrandingProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectBrandingProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? iconPath = freezed,
    Object? coverPath = freezed,
    Object? heroPath = freezed,
    Object? accentColor = freezed,
    Object? titleMusicPath = freezed,
    Object? layoutVariant = null,
  }) {
    return _then(_$ProjectBrandingProfileImpl(
      iconPath: freezed == iconPath
          ? _value.iconPath
          : iconPath // ignore: cast_nullable_to_non_nullable
              as String?,
      coverPath: freezed == coverPath
          ? _value.coverPath
          : coverPath // ignore: cast_nullable_to_non_nullable
              as String?,
      heroPath: freezed == heroPath
          ? _value.heroPath
          : heroPath // ignore: cast_nullable_to_non_nullable
              as String?,
      accentColor: freezed == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as String?,
      titleMusicPath: freezed == titleMusicPath
          ? _value.titleMusicPath
          : titleMusicPath // ignore: cast_nullable_to_non_nullable
              as String?,
      layoutVariant: null == layoutVariant
          ? _value.layoutVariant
          : layoutVariant // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectBrandingProfileImpl implements _ProjectBrandingProfile {
  const _$ProjectBrandingProfileImpl(
      {@JsonKey(includeIfNull: false) this.iconPath,
      @JsonKey(includeIfNull: false) this.coverPath,
      @JsonKey(includeIfNull: false) this.heroPath,
      @JsonKey(includeIfNull: false) this.accentColor,
      @JsonKey(includeIfNull: false) this.titleMusicPath,
      this.layoutVariant = 'standard'});

  factory _$ProjectBrandingProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectBrandingProfileImplFromJson(json);

  @override
  @JsonKey(includeIfNull: false)
  final String? iconPath;
  @override
  @JsonKey(includeIfNull: false)
  final String? coverPath;
  @override
  @JsonKey(includeIfNull: false)
  final String? heroPath;
  @override
  @JsonKey(includeIfNull: false)
  final String? accentColor;
  @override
  @JsonKey(includeIfNull: false)
  final String? titleMusicPath;
  @override
  @JsonKey()
  final String layoutVariant;

  @override
  String toString() {
    return 'ProjectBrandingProfile(iconPath: $iconPath, coverPath: $coverPath, heroPath: $heroPath, accentColor: $accentColor, titleMusicPath: $titleMusicPath, layoutVariant: $layoutVariant)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectBrandingProfileImpl &&
            (identical(other.iconPath, iconPath) ||
                other.iconPath == iconPath) &&
            (identical(other.coverPath, coverPath) ||
                other.coverPath == coverPath) &&
            (identical(other.heroPath, heroPath) ||
                other.heroPath == heroPath) &&
            (identical(other.accentColor, accentColor) ||
                other.accentColor == accentColor) &&
            (identical(other.titleMusicPath, titleMusicPath) ||
                other.titleMusicPath == titleMusicPath) &&
            (identical(other.layoutVariant, layoutVariant) ||
                other.layoutVariant == layoutVariant));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, iconPath, coverPath, heroPath,
      accentColor, titleMusicPath, layoutVariant);

  /// Create a copy of ProjectBrandingProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectBrandingProfileImplCopyWith<_$ProjectBrandingProfileImpl>
      get copyWith => __$$ProjectBrandingProfileImplCopyWithImpl<
          _$ProjectBrandingProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectBrandingProfileImplToJson(
      this,
    );
  }
}

abstract class _ProjectBrandingProfile implements ProjectBrandingProfile {
  const factory _ProjectBrandingProfile(
      {@JsonKey(includeIfNull: false) final String? iconPath,
      @JsonKey(includeIfNull: false) final String? coverPath,
      @JsonKey(includeIfNull: false) final String? heroPath,
      @JsonKey(includeIfNull: false) final String? accentColor,
      @JsonKey(includeIfNull: false) final String? titleMusicPath,
      final String layoutVariant}) = _$ProjectBrandingProfileImpl;

  factory _ProjectBrandingProfile.fromJson(Map<String, dynamic> json) =
      _$ProjectBrandingProfileImpl.fromJson;

  @override
  @JsonKey(includeIfNull: false)
  String? get iconPath;
  @override
  @JsonKey(includeIfNull: false)
  String? get coverPath;
  @override
  @JsonKey(includeIfNull: false)
  String? get heroPath;
  @override
  @JsonKey(includeIfNull: false)
  String? get accentColor;
  @override
  @JsonKey(includeIfNull: false)
  String? get titleMusicPath;
  @override
  String get layoutVariant;

  /// Create a copy of ProjectBrandingProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectBrandingProfileImplCopyWith<_$ProjectBrandingProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectIntroVideoProfile _$ProjectIntroVideoProfileFromJson(
    Map<String, dynamic> json) {
  return _ProjectIntroVideoProfile.fromJson(json);
}

/// @nodoc
mixin _$ProjectIntroVideoProfile {
  String get videoPath => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get posterPath => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  String? get captionsPath => throw _privateConstructorUsedError;
  int get durationMilliseconds => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  int get bitrateKbps => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  String get videoCodec => throw _privateConstructorUsedError;
  String get audioCodec => throw _privateConstructorUsedError;
  String get reducedMotionBehavior => throw _privateConstructorUsedError;
  bool get allowReplay => throw _privateConstructorUsedError;

  /// Serializes this ProjectIntroVideoProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectIntroVideoProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectIntroVideoProfileCopyWith<ProjectIntroVideoProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectIntroVideoProfileCopyWith<$Res> {
  factory $ProjectIntroVideoProfileCopyWith(ProjectIntroVideoProfile value,
          $Res Function(ProjectIntroVideoProfile) then) =
      _$ProjectIntroVideoProfileCopyWithImpl<$Res, ProjectIntroVideoProfile>;
  @useResult
  $Res call(
      {String videoPath,
      @JsonKey(includeIfNull: false) String? posterPath,
      @JsonKey(includeIfNull: false) String? captionsPath,
      int durationMilliseconds,
      int width,
      int height,
      int bitrateKbps,
      int sizeBytes,
      String videoCodec,
      String audioCodec,
      String reducedMotionBehavior,
      bool allowReplay});
}

/// @nodoc
class _$ProjectIntroVideoProfileCopyWithImpl<$Res,
        $Val extends ProjectIntroVideoProfile>
    implements $ProjectIntroVideoProfileCopyWith<$Res> {
  _$ProjectIntroVideoProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectIntroVideoProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoPath = null,
    Object? posterPath = freezed,
    Object? captionsPath = freezed,
    Object? durationMilliseconds = null,
    Object? width = null,
    Object? height = null,
    Object? bitrateKbps = null,
    Object? sizeBytes = null,
    Object? videoCodec = null,
    Object? audioCodec = null,
    Object? reducedMotionBehavior = null,
    Object? allowReplay = null,
  }) {
    return _then(_value.copyWith(
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      posterPath: freezed == posterPath
          ? _value.posterPath
          : posterPath // ignore: cast_nullable_to_non_nullable
              as String?,
      captionsPath: freezed == captionsPath
          ? _value.captionsPath
          : captionsPath // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMilliseconds: null == durationMilliseconds
          ? _value.durationMilliseconds
          : durationMilliseconds // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      bitrateKbps: null == bitrateKbps
          ? _value.bitrateKbps
          : bitrateKbps // ignore: cast_nullable_to_non_nullable
              as int,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      videoCodec: null == videoCodec
          ? _value.videoCodec
          : videoCodec // ignore: cast_nullable_to_non_nullable
              as String,
      audioCodec: null == audioCodec
          ? _value.audioCodec
          : audioCodec // ignore: cast_nullable_to_non_nullable
              as String,
      reducedMotionBehavior: null == reducedMotionBehavior
          ? _value.reducedMotionBehavior
          : reducedMotionBehavior // ignore: cast_nullable_to_non_nullable
              as String,
      allowReplay: null == allowReplay
          ? _value.allowReplay
          : allowReplay // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectIntroVideoProfileImplCopyWith<$Res>
    implements $ProjectIntroVideoProfileCopyWith<$Res> {
  factory _$$ProjectIntroVideoProfileImplCopyWith(
          _$ProjectIntroVideoProfileImpl value,
          $Res Function(_$ProjectIntroVideoProfileImpl) then) =
      __$$ProjectIntroVideoProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String videoPath,
      @JsonKey(includeIfNull: false) String? posterPath,
      @JsonKey(includeIfNull: false) String? captionsPath,
      int durationMilliseconds,
      int width,
      int height,
      int bitrateKbps,
      int sizeBytes,
      String videoCodec,
      String audioCodec,
      String reducedMotionBehavior,
      bool allowReplay});
}

/// @nodoc
class __$$ProjectIntroVideoProfileImplCopyWithImpl<$Res>
    extends _$ProjectIntroVideoProfileCopyWithImpl<$Res,
        _$ProjectIntroVideoProfileImpl>
    implements _$$ProjectIntroVideoProfileImplCopyWith<$Res> {
  __$$ProjectIntroVideoProfileImplCopyWithImpl(
      _$ProjectIntroVideoProfileImpl _value,
      $Res Function(_$ProjectIntroVideoProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectIntroVideoProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoPath = null,
    Object? posterPath = freezed,
    Object? captionsPath = freezed,
    Object? durationMilliseconds = null,
    Object? width = null,
    Object? height = null,
    Object? bitrateKbps = null,
    Object? sizeBytes = null,
    Object? videoCodec = null,
    Object? audioCodec = null,
    Object? reducedMotionBehavior = null,
    Object? allowReplay = null,
  }) {
    return _then(_$ProjectIntroVideoProfileImpl(
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      posterPath: freezed == posterPath
          ? _value.posterPath
          : posterPath // ignore: cast_nullable_to_non_nullable
              as String?,
      captionsPath: freezed == captionsPath
          ? _value.captionsPath
          : captionsPath // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMilliseconds: null == durationMilliseconds
          ? _value.durationMilliseconds
          : durationMilliseconds // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      bitrateKbps: null == bitrateKbps
          ? _value.bitrateKbps
          : bitrateKbps // ignore: cast_nullable_to_non_nullable
              as int,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      videoCodec: null == videoCodec
          ? _value.videoCodec
          : videoCodec // ignore: cast_nullable_to_non_nullable
              as String,
      audioCodec: null == audioCodec
          ? _value.audioCodec
          : audioCodec // ignore: cast_nullable_to_non_nullable
              as String,
      reducedMotionBehavior: null == reducedMotionBehavior
          ? _value.reducedMotionBehavior
          : reducedMotionBehavior // ignore: cast_nullable_to_non_nullable
              as String,
      allowReplay: null == allowReplay
          ? _value.allowReplay
          : allowReplay // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectIntroVideoProfileImpl implements _ProjectIntroVideoProfile {
  const _$ProjectIntroVideoProfileImpl(
      {required this.videoPath,
      @JsonKey(includeIfNull: false) this.posterPath,
      @JsonKey(includeIfNull: false) this.captionsPath,
      required this.durationMilliseconds,
      required this.width,
      required this.height,
      required this.bitrateKbps,
      required this.sizeBytes,
      required this.videoCodec,
      this.audioCodec = 'none',
      this.reducedMotionBehavior = 'poster',
      this.allowReplay = true});

  factory _$ProjectIntroVideoProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectIntroVideoProfileImplFromJson(json);

  @override
  final String videoPath;
  @override
  @JsonKey(includeIfNull: false)
  final String? posterPath;
  @override
  @JsonKey(includeIfNull: false)
  final String? captionsPath;
  @override
  final int durationMilliseconds;
  @override
  final int width;
  @override
  final int height;
  @override
  final int bitrateKbps;
  @override
  final int sizeBytes;
  @override
  final String videoCodec;
  @override
  @JsonKey()
  final String audioCodec;
  @override
  @JsonKey()
  final String reducedMotionBehavior;
  @override
  @JsonKey()
  final bool allowReplay;

  @override
  String toString() {
    return 'ProjectIntroVideoProfile(videoPath: $videoPath, posterPath: $posterPath, captionsPath: $captionsPath, durationMilliseconds: $durationMilliseconds, width: $width, height: $height, bitrateKbps: $bitrateKbps, sizeBytes: $sizeBytes, videoCodec: $videoCodec, audioCodec: $audioCodec, reducedMotionBehavior: $reducedMotionBehavior, allowReplay: $allowReplay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectIntroVideoProfileImpl &&
            (identical(other.videoPath, videoPath) ||
                other.videoPath == videoPath) &&
            (identical(other.posterPath, posterPath) ||
                other.posterPath == posterPath) &&
            (identical(other.captionsPath, captionsPath) ||
                other.captionsPath == captionsPath) &&
            (identical(other.durationMilliseconds, durationMilliseconds) ||
                other.durationMilliseconds == durationMilliseconds) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.bitrateKbps, bitrateKbps) ||
                other.bitrateKbps == bitrateKbps) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.videoCodec, videoCodec) ||
                other.videoCodec == videoCodec) &&
            (identical(other.audioCodec, audioCodec) ||
                other.audioCodec == audioCodec) &&
            (identical(other.reducedMotionBehavior, reducedMotionBehavior) ||
                other.reducedMotionBehavior == reducedMotionBehavior) &&
            (identical(other.allowReplay, allowReplay) ||
                other.allowReplay == allowReplay));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      videoPath,
      posterPath,
      captionsPath,
      durationMilliseconds,
      width,
      height,
      bitrateKbps,
      sizeBytes,
      videoCodec,
      audioCodec,
      reducedMotionBehavior,
      allowReplay);

  /// Create a copy of ProjectIntroVideoProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectIntroVideoProfileImplCopyWith<_$ProjectIntroVideoProfileImpl>
      get copyWith => __$$ProjectIntroVideoProfileImplCopyWithImpl<
          _$ProjectIntroVideoProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectIntroVideoProfileImplToJson(
      this,
    );
  }
}

abstract class _ProjectIntroVideoProfile implements ProjectIntroVideoProfile {
  const factory _ProjectIntroVideoProfile(
      {required final String videoPath,
      @JsonKey(includeIfNull: false) final String? posterPath,
      @JsonKey(includeIfNull: false) final String? captionsPath,
      required final int durationMilliseconds,
      required final int width,
      required final int height,
      required final int bitrateKbps,
      required final int sizeBytes,
      required final String videoCodec,
      final String audioCodec,
      final String reducedMotionBehavior,
      final bool allowReplay}) = _$ProjectIntroVideoProfileImpl;

  factory _ProjectIntroVideoProfile.fromJson(Map<String, dynamic> json) =
      _$ProjectIntroVideoProfileImpl.fromJson;

  @override
  String get videoPath;
  @override
  @JsonKey(includeIfNull: false)
  String? get posterPath;
  @override
  @JsonKey(includeIfNull: false)
  String? get captionsPath;
  @override
  int get durationMilliseconds;
  @override
  int get width;
  @override
  int get height;
  @override
  int get bitrateKbps;
  @override
  int get sizeBytes;
  @override
  String get videoCodec;
  @override
  String get audioCodec;
  @override
  String get reducedMotionBehavior;
  @override
  bool get allowReplay;

  /// Create a copy of ProjectIntroVideoProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectIntroVideoProfileImplCopyWith<_$ProjectIntroVideoProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectPresentationProfile _$ProjectPresentationProfileFromJson(
    Map<String, dynamic> json) {
  return _ProjectPresentationProfile.fromJson(json);
}

/// @nodoc
mixin _$ProjectPresentationProfile {
  int get schemaVersion => throw _privateConstructorUsedError;
  ProjectBrandingProfile get branding => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  ProjectIntroVideoProfile? get intro => throw _privateConstructorUsedError;

  /// Serializes this ProjectPresentationProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPresentationProfileCopyWith<ProjectPresentationProfile>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPresentationProfileCopyWith<$Res> {
  factory $ProjectPresentationProfileCopyWith(ProjectPresentationProfile value,
          $Res Function(ProjectPresentationProfile) then) =
      _$ProjectPresentationProfileCopyWithImpl<$Res,
          ProjectPresentationProfile>;
  @useResult
  $Res call(
      {int schemaVersion,
      ProjectBrandingProfile branding,
      @JsonKey(includeIfNull: false) ProjectIntroVideoProfile? intro});

  $ProjectBrandingProfileCopyWith<$Res> get branding;
  $ProjectIntroVideoProfileCopyWith<$Res>? get intro;
}

/// @nodoc
class _$ProjectPresentationProfileCopyWithImpl<$Res,
        $Val extends ProjectPresentationProfile>
    implements $ProjectPresentationProfileCopyWith<$Res> {
  _$ProjectPresentationProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? branding = null,
    Object? intro = freezed,
  }) {
    return _then(_value.copyWith(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      branding: null == branding
          ? _value.branding
          : branding // ignore: cast_nullable_to_non_nullable
              as ProjectBrandingProfile,
      intro: freezed == intro
          ? _value.intro
          : intro // ignore: cast_nullable_to_non_nullable
              as ProjectIntroVideoProfile?,
    ) as $Val);
  }

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectBrandingProfileCopyWith<$Res> get branding {
    return $ProjectBrandingProfileCopyWith<$Res>(_value.branding, (value) {
      return _then(_value.copyWith(branding: value) as $Val);
    });
  }

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectIntroVideoProfileCopyWith<$Res>? get intro {
    if (_value.intro == null) {
      return null;
    }

    return $ProjectIntroVideoProfileCopyWith<$Res>(_value.intro!, (value) {
      return _then(_value.copyWith(intro: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectPresentationProfileImplCopyWith<$Res>
    implements $ProjectPresentationProfileCopyWith<$Res> {
  factory _$$ProjectPresentationProfileImplCopyWith(
          _$ProjectPresentationProfileImpl value,
          $Res Function(_$ProjectPresentationProfileImpl) then) =
      __$$ProjectPresentationProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int schemaVersion,
      ProjectBrandingProfile branding,
      @JsonKey(includeIfNull: false) ProjectIntroVideoProfile? intro});

  @override
  $ProjectBrandingProfileCopyWith<$Res> get branding;
  @override
  $ProjectIntroVideoProfileCopyWith<$Res>? get intro;
}

/// @nodoc
class __$$ProjectPresentationProfileImplCopyWithImpl<$Res>
    extends _$ProjectPresentationProfileCopyWithImpl<$Res,
        _$ProjectPresentationProfileImpl>
    implements _$$ProjectPresentationProfileImplCopyWith<$Res> {
  __$$ProjectPresentationProfileImplCopyWithImpl(
      _$ProjectPresentationProfileImpl _value,
      $Res Function(_$ProjectPresentationProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? branding = null,
    Object? intro = freezed,
  }) {
    return _then(_$ProjectPresentationProfileImpl(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      branding: null == branding
          ? _value.branding
          : branding // ignore: cast_nullable_to_non_nullable
              as ProjectBrandingProfile,
      intro: freezed == intro
          ? _value.intro
          : intro // ignore: cast_nullable_to_non_nullable
              as ProjectIntroVideoProfile?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectPresentationProfileImpl extends _ProjectPresentationProfile {
  const _$ProjectPresentationProfileImpl(
      {this.schemaVersion = ProjectPresentationProfile.supportedSchemaVersion,
      this.branding = const ProjectBrandingProfile(),
      @JsonKey(includeIfNull: false) this.intro})
      : super._();

  factory _$ProjectPresentationProfileImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectPresentationProfileImplFromJson(json);

  @override
  @JsonKey()
  final int schemaVersion;
  @override
  @JsonKey()
  final ProjectBrandingProfile branding;
  @override
  @JsonKey(includeIfNull: false)
  final ProjectIntroVideoProfile? intro;

  @override
  String toString() {
    return 'ProjectPresentationProfile(schemaVersion: $schemaVersion, branding: $branding, intro: $intro)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPresentationProfileImpl &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.branding, branding) ||
                other.branding == branding) &&
            (identical(other.intro, intro) || other.intro == intro));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, schemaVersion, branding, intro);

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPresentationProfileImplCopyWith<_$ProjectPresentationProfileImpl>
      get copyWith => __$$ProjectPresentationProfileImplCopyWithImpl<
          _$ProjectPresentationProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectPresentationProfileImplToJson(
      this,
    );
  }
}

abstract class _ProjectPresentationProfile extends ProjectPresentationProfile {
  const factory _ProjectPresentationProfile(
          {final int schemaVersion,
          final ProjectBrandingProfile branding,
          @JsonKey(includeIfNull: false)
          final ProjectIntroVideoProfile? intro}) =
      _$ProjectPresentationProfileImpl;
  const _ProjectPresentationProfile._() : super._();

  factory _ProjectPresentationProfile.fromJson(Map<String, dynamic> json) =
      _$ProjectPresentationProfileImpl.fromJson;

  @override
  int get schemaVersion;
  @override
  ProjectBrandingProfile get branding;
  @override
  @JsonKey(includeIfNull: false)
  ProjectIntroVideoProfile? get intro;

  /// Create a copy of ProjectPresentationProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPresentationProfileImplCopyWith<_$ProjectPresentationProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}
