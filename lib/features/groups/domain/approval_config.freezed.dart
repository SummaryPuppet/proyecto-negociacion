// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApprovalConfig {

 int get quorumPercent; int get leaderVoteWeight; bool get teacherCanOverride;
/// Create a copy of ApprovalConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalConfigCopyWith<ApprovalConfig> get copyWith => _$ApprovalConfigCopyWithImpl<ApprovalConfig>(this as ApprovalConfig, _$identity);

  /// Serializes this ApprovalConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ApprovalConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalConfig&&(identical(other.quorumPercent, _this.quorumPercent) || other.quorumPercent == _this.quorumPercent)&&(identical(other.leaderVoteWeight, _this.leaderVoteWeight) || other.leaderVoteWeight == _this.leaderVoteWeight)&&(identical(other.teacherCanOverride, _this.teacherCanOverride) || other.teacherCanOverride == _this.teacherCanOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ApprovalConfig;
  return Object.hash(runtimeType,_this.quorumPercent,_this.leaderVoteWeight,_this.teacherCanOverride);
}

@override
String toString() {
  final _this = this as ApprovalConfig;
  return 'ApprovalConfig(quorumPercent: ${_this.quorumPercent}, leaderVoteWeight: ${_this.leaderVoteWeight}, teacherCanOverride: ${_this.teacherCanOverride})';
}


}

/// @nodoc
abstract mixin class $ApprovalConfigCopyWith<$Res>  {
  factory $ApprovalConfigCopyWith(ApprovalConfig value, $Res Function(ApprovalConfig) _then) = _$ApprovalConfigCopyWithImpl;
@useResult
$Res call({
 int quorumPercent, int leaderVoteWeight, bool teacherCanOverride
});




}
/// @nodoc
class _$ApprovalConfigCopyWithImpl<$Res>
    implements $ApprovalConfigCopyWith<$Res> {
  _$ApprovalConfigCopyWithImpl(this._self, this._then);

  final ApprovalConfig _self;
  final $Res Function(ApprovalConfig) _then;

/// Create a copy of ApprovalConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quorumPercent = null,Object? leaderVoteWeight = null,Object? teacherCanOverride = null,}) {
  return _then(ApprovalConfig(
quorumPercent: null == quorumPercent ? _self.quorumPercent : quorumPercent // ignore: cast_nullable_to_non_nullable
as int,leaderVoteWeight: null == leaderVoteWeight ? _self.leaderVoteWeight : leaderVoteWeight // ignore: cast_nullable_to_non_nullable
as int,teacherCanOverride: null == teacherCanOverride ? _self.teacherCanOverride : teacherCanOverride // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ApprovalConfig].
extension ApprovalConfigPatterns on ApprovalConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalConfig value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int quorumPercent,  int leaderVoteWeight,  bool teacherCanOverride)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalConfig() when $default != null:
return $default(_that.quorumPercent,_that.leaderVoteWeight,_that.teacherCanOverride);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int quorumPercent,  int leaderVoteWeight,  bool teacherCanOverride)  $default,) {final _that = this;
switch (_that) {
case _ApprovalConfig():
return $default(_that.quorumPercent,_that.leaderVoteWeight,_that.teacherCanOverride);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int quorumPercent,  int leaderVoteWeight,  bool teacherCanOverride)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalConfig() when $default != null:
return $default(_that.quorumPercent,_that.leaderVoteWeight,_that.teacherCanOverride);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalConfig implements ApprovalConfig {
  const _ApprovalConfig({this.quorumPercent = 50, this.leaderVoteWeight = 2, this.teacherCanOverride = true});
  factory _ApprovalConfig.fromJson(Map<String, dynamic> json) => _$ApprovalConfigFromJson(json);

@override@JsonKey() final  int quorumPercent;
@override@JsonKey() final  int leaderVoteWeight;
@override@JsonKey() final  bool teacherCanOverride;

/// Create a copy of ApprovalConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalConfigCopyWith<_ApprovalConfig> get copyWith => __$ApprovalConfigCopyWithImpl<_ApprovalConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalConfig&&(identical(other.quorumPercent, quorumPercent) || other.quorumPercent == quorumPercent)&&(identical(other.leaderVoteWeight, leaderVoteWeight) || other.leaderVoteWeight == leaderVoteWeight)&&(identical(other.teacherCanOverride, teacherCanOverride) || other.teacherCanOverride == teacherCanOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,quorumPercent,leaderVoteWeight,teacherCanOverride);
}

@override
String toString() {
    return 'ApprovalConfig(quorumPercent: $quorumPercent, leaderVoteWeight: $leaderVoteWeight, teacherCanOverride: $teacherCanOverride)';
}


}

/// @nodoc
abstract mixin class _$ApprovalConfigCopyWith<$Res> implements $ApprovalConfigCopyWith<$Res> {
  factory _$ApprovalConfigCopyWith(_ApprovalConfig value, $Res Function(_ApprovalConfig) _then) = __$ApprovalConfigCopyWithImpl;
@override @useResult
$Res call({
 int quorumPercent, int leaderVoteWeight, bool teacherCanOverride
});




}
/// @nodoc
class __$ApprovalConfigCopyWithImpl<$Res>
    implements _$ApprovalConfigCopyWith<$Res> {
  __$ApprovalConfigCopyWithImpl(this._self, this._then);

  final _ApprovalConfig _self;
  final $Res Function(_ApprovalConfig) _then;

/// Create a copy of ApprovalConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quorumPercent = null,Object? leaderVoteWeight = null,Object? teacherCanOverride = null,}) {
  return _then(_ApprovalConfig(
quorumPercent: null == quorumPercent ? _self.quorumPercent : quorumPercent // ignore: cast_nullable_to_non_nullable
as int,leaderVoteWeight: null == leaderVoteWeight ? _self.leaderVoteWeight : leaderVoteWeight // ignore: cast_nullable_to_non_nullable
as int,teacherCanOverride: null == teacherCanOverride ? _self.teacherCanOverride : teacherCanOverride // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
