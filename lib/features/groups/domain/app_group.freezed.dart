// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppGroup {

 String get id; String get name; String get period; String get teacherId; String get leaderId; List<String> get memberIds; String get joinCode; ApprovalConfig get approvalConfig; int get createdAt;
/// Create a copy of AppGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppGroupCopyWith<AppGroup> get copyWith => _$AppGroupCopyWithImpl<AppGroup>(this as AppGroup, _$identity);

  /// Serializes this AppGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.teacherId, _this.teacherId) || other.teacherId == _this.teacherId)&&(identical(other.leaderId, _this.leaderId) || other.leaderId == _this.leaderId)&&const DeepCollectionEquality().equals(other.memberIds, _this.memberIds)&&(identical(other.joinCode, _this.joinCode) || other.joinCode == _this.joinCode)&&(identical(other.approvalConfig, _this.approvalConfig) || other.approvalConfig == _this.approvalConfig)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppGroup;
  return Object.hash(runtimeType,_this.id,_this.name,_this.period,_this.teacherId,_this.leaderId,const DeepCollectionEquality().hash(_this.memberIds),_this.joinCode,_this.approvalConfig,_this.createdAt);
}

@override
String toString() {
  final _this = this as AppGroup;
  return 'AppGroup(id: ${_this.id}, name: ${_this.name}, period: ${_this.period}, teacherId: ${_this.teacherId}, leaderId: ${_this.leaderId}, memberIds: ${_this.memberIds}, joinCode: ${_this.joinCode}, approvalConfig: ${_this.approvalConfig}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AppGroupCopyWith<$Res>  {
  factory $AppGroupCopyWith(AppGroup value, $Res Function(AppGroup) _then) = _$AppGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, String period, String teacherId, String leaderId, List<String> memberIds, String joinCode, ApprovalConfig approvalConfig, int createdAt
});


$ApprovalConfigCopyWith<$Res> get approvalConfig;

}
/// @nodoc
class _$AppGroupCopyWithImpl<$Res>
    implements $AppGroupCopyWith<$Res> {
  _$AppGroupCopyWithImpl(this._self, this._then);

  final AppGroup _self;
  final $Res Function(AppGroup) _then;

/// Create a copy of AppGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? period = null,Object? teacherId = null,Object? leaderId = null,Object? memberIds = null,Object? joinCode = null,Object? approvalConfig = null,Object? createdAt = null,}) {
  return _then(AppGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,leaderId: null == leaderId ? _self.leaderId : leaderId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,approvalConfig: null == approvalConfig ? _self.approvalConfig : approvalConfig // ignore: cast_nullable_to_non_nullable
as ApprovalConfig,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AppGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApprovalConfigCopyWith<$Res> get approvalConfig {
  
  return $ApprovalConfigCopyWith<$Res>(_self.approvalConfig, (value) {
    return _then(_self.copyWith(approvalConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppGroup].
extension AppGroupPatterns on AppGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppGroup value)  $default,){
final _that = this;
switch (_that) {
case _AppGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppGroup value)?  $default,){
final _that = this;
switch (_that) {
case _AppGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String period,  String teacherId,  String leaderId,  List<String> memberIds,  String joinCode,  ApprovalConfig approvalConfig,  int createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppGroup() when $default != null:
return $default(_that.id,_that.name,_that.period,_that.teacherId,_that.leaderId,_that.memberIds,_that.joinCode,_that.approvalConfig,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String period,  String teacherId,  String leaderId,  List<String> memberIds,  String joinCode,  ApprovalConfig approvalConfig,  int createdAt)  $default,) {final _that = this;
switch (_that) {
case _AppGroup():
return $default(_that.id,_that.name,_that.period,_that.teacherId,_that.leaderId,_that.memberIds,_that.joinCode,_that.approvalConfig,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String period,  String teacherId,  String leaderId,  List<String> memberIds,  String joinCode,  ApprovalConfig approvalConfig,  int createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AppGroup() when $default != null:
return $default(_that.id,_that.name,_that.period,_that.teacherId,_that.leaderId,_that.memberIds,_that.joinCode,_that.approvalConfig,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppGroup implements AppGroup {
  const _AppGroup({required this.id, required this.name, required this.period, required this.teacherId, this.leaderId = '',  List<String> memberIds = const [], required this.joinCode, this.approvalConfig = const ApprovalConfig(), this.createdAt = 0}): _memberIds = memberIds;
  factory _AppGroup.fromJson(Map<String, dynamic> json) => _$AppGroupFromJson(json);

@override final  String id;
@override final  String name;
@override final  String period;
@override final  String teacherId;
@override@JsonKey() final  String leaderId;
 final  List<String> _memberIds;
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

@override final  String joinCode;
@override@JsonKey() final  ApprovalConfig approvalConfig;
@override@JsonKey() final  int createdAt;

/// Create a copy of AppGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppGroupCopyWith<_AppGroup> get copyWith => __$AppGroupCopyWithImpl<_AppGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppGroupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.period, period) || other.period == period)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.leaderId, leaderId) || other.leaderId == leaderId)&&const DeepCollectionEquality().equals(other.memberIds, _memberIds)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.approvalConfig, approvalConfig) || other.approvalConfig == approvalConfig)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,period,teacherId,leaderId,const DeepCollectionEquality().hash(_memberIds),joinCode,approvalConfig,createdAt);
}

@override
String toString() {
    return 'AppGroup(id: $id, name: $name, period: $period, teacherId: $teacherId, leaderId: $leaderId, memberIds: $memberIds, joinCode: $joinCode, approvalConfig: $approvalConfig, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AppGroupCopyWith<$Res> implements $AppGroupCopyWith<$Res> {
  factory _$AppGroupCopyWith(_AppGroup value, $Res Function(_AppGroup) _then) = __$AppGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String period, String teacherId, String leaderId, List<String> memberIds, String joinCode, ApprovalConfig approvalConfig, int createdAt
});


@override $ApprovalConfigCopyWith<$Res> get approvalConfig;

}
/// @nodoc
class __$AppGroupCopyWithImpl<$Res>
    implements _$AppGroupCopyWith<$Res> {
  __$AppGroupCopyWithImpl(this._self, this._then);

  final _AppGroup _self;
  final $Res Function(_AppGroup) _then;

/// Create a copy of AppGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? period = null,Object? teacherId = null,Object? leaderId = null,Object? memberIds = null,Object? joinCode = null,Object? approvalConfig = null,Object? createdAt = null,}) {
  return _then(_AppGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,leaderId: null == leaderId ? _self.leaderId : leaderId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,approvalConfig: null == approvalConfig ? _self.approvalConfig : approvalConfig // ignore: cast_nullable_to_non_nullable
as ApprovalConfig,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AppGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApprovalConfigCopyWith<$Res> get approvalConfig {
  
  return $ApprovalConfigCopyWith<$Res>(_self.approvalConfig, (value) {
    return _then(_self.copyWith(approvalConfig: value));
  });
}
}

// dart format on
