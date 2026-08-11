// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_item_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectItemCatalog {

 int get schemaVersion; List<ProjectItemDefinition> get entries;
/// Create a copy of ProjectItemCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectItemCatalogCopyWith<ProjectItemCatalog> get copyWith => _$ProjectItemCatalogCopyWithImpl<ProjectItemCatalog>(this as ProjectItemCatalog, _$identity);

  /// Serializes this ProjectItemCatalog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectItemCatalog&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'ProjectItemCatalog(schemaVersion: $schemaVersion, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $ProjectItemCatalogCopyWith<$Res>  {
  factory $ProjectItemCatalogCopyWith(ProjectItemCatalog value, $Res Function(ProjectItemCatalog) _then) = _$ProjectItemCatalogCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, List<ProjectItemDefinition> entries
});




}
/// @nodoc
class _$ProjectItemCatalogCopyWithImpl<$Res>
    implements $ProjectItemCatalogCopyWith<$Res> {
  _$ProjectItemCatalogCopyWithImpl(this._self, this._then);

  final ProjectItemCatalog _self;
  final $Res Function(ProjectItemCatalog) _then;

/// Create a copy of ProjectItemCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? entries = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<ProjectItemDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectItemCatalog].
extension ProjectItemCatalogPatterns on ProjectItemCatalog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectItemCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectItemCatalog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectItemCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ProjectItemCatalog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectItemCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectItemCatalog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  List<ProjectItemDefinition> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectItemCatalog() when $default != null:
return $default(_that.schemaVersion,_that.entries);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  List<ProjectItemDefinition> entries)  $default,) {final _that = this;
switch (_that) {
case _ProjectItemCatalog():
return $default(_that.schemaVersion,_that.entries);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  List<ProjectItemDefinition> entries)?  $default,) {final _that = this;
switch (_that) {
case _ProjectItemCatalog() when $default != null:
return $default(_that.schemaVersion,_that.entries);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectItemCatalog extends ProjectItemCatalog {
  const _ProjectItemCatalog({required this.schemaVersion, required final  List<ProjectItemDefinition> entries}): _entries = entries,super._();
  factory _ProjectItemCatalog.fromJson(Map<String, dynamic> json) => _$ProjectItemCatalogFromJson(json);

@override final  int schemaVersion;
 final  List<ProjectItemDefinition> _entries;
@override List<ProjectItemDefinition> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of ProjectItemCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectItemCatalogCopyWith<_ProjectItemCatalog> get copyWith => __$ProjectItemCatalogCopyWithImpl<_ProjectItemCatalog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectItemCatalogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectItemCatalog&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'ProjectItemCatalog(schemaVersion: $schemaVersion, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$ProjectItemCatalogCopyWith<$Res> implements $ProjectItemCatalogCopyWith<$Res> {
  factory _$ProjectItemCatalogCopyWith(_ProjectItemCatalog value, $Res Function(_ProjectItemCatalog) _then) = __$ProjectItemCatalogCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, List<ProjectItemDefinition> entries
});




}
/// @nodoc
class __$ProjectItemCatalogCopyWithImpl<$Res>
    implements _$ProjectItemCatalogCopyWith<$Res> {
  __$ProjectItemCatalogCopyWithImpl(this._self, this._then);

  final _ProjectItemCatalog _self;
  final $Res Function(_ProjectItemCatalog) _then;

/// Create a copy of ProjectItemCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? entries = null,}) {
  return _then(_ProjectItemCatalog(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ProjectItemDefinition>,
  ));
}


}

// dart format on
