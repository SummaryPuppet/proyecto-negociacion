// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Offer {

 String get id; String get taskId; String get projectId; String get groupId; String get authorId; int get points; int get hours; String get argument; String? get parentOfferId; String get status; Map<String, String> get votes; int? get resolvedAt; String? get resolvedBy; String? get resolution; int get createdAt; int get updatedAt;
/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfferCopyWith<Offer> get copyWith => _$OfferCopyWithImpl<Offer>(this as Offer, _$identity);

  /// Serializes this Offer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Offer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Offer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.taskId, _this.taskId) || other.taskId == _this.taskId)&&(identical(other.projectId, _this.projectId) || other.projectId == _this.projectId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.hours, _this.hours) || other.hours == _this.hours)&&(identical(other.argument, _this.argument) || other.argument == _this.argument)&&(identical(other.parentOfferId, _this.parentOfferId) || other.parentOfferId == _this.parentOfferId)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.votes, _this.votes)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt)&&(identical(other.resolvedBy, _this.resolvedBy) || other.resolvedBy == _this.resolvedBy)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Offer;
  return Object.hash(runtimeType,_this.id,_this.taskId,_this.projectId,_this.groupId,_this.authorId,_this.points,_this.hours,_this.argument,_this.parentOfferId,_this.status,const DeepCollectionEquality().hash(_this.votes),_this.resolvedAt,_this.resolvedBy,_this.resolution,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Offer;
  return 'Offer(id: ${_this.id}, taskId: ${_this.taskId}, projectId: ${_this.projectId}, groupId: ${_this.groupId}, authorId: ${_this.authorId}, points: ${_this.points}, hours: ${_this.hours}, argument: ${_this.argument}, parentOfferId: ${_this.parentOfferId}, status: ${_this.status}, votes: ${_this.votes}, resolvedAt: ${_this.resolvedAt}, resolvedBy: ${_this.resolvedBy}, resolution: ${_this.resolution}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $OfferCopyWith<$Res>  {
  factory $OfferCopyWith(Offer value, $Res Function(Offer) _then) = _$OfferCopyWithImpl;
@useResult
$Res call({
 String id, String taskId, String projectId, String groupId, String authorId, int points, int hours, String argument, String? parentOfferId, String status, Map<String, String> votes, int? resolvedAt, String? resolvedBy, String? resolution, int createdAt, int updatedAt
});




}
/// @nodoc
class _$OfferCopyWithImpl<$Res>
    implements $OfferCopyWith<$Res> {
  _$OfferCopyWithImpl(this._self, this._then);

  final Offer _self;
  final $Res Function(Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskId = null,Object? projectId = null,Object? groupId = null,Object? authorId = null,Object? points = null,Object? hours = null,Object? argument = null,Object? parentOfferId = freezed,Object? status = null,Object? votes = null,Object? resolvedAt = freezed,Object? resolvedBy = freezed,Object? resolution = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Offer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as int,argument: null == argument ? _self.argument : argument // ignore: cast_nullable_to_non_nullable
as String,parentOfferId: freezed == parentOfferId ? _self.parentOfferId : parentOfferId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as int?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Offer].
extension OfferPatterns on Offer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Offer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Offer value)  $default,){
final _that = this;
switch (_that) {
case _Offer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Offer value)?  $default,){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskId,  String projectId,  String groupId,  String authorId,  int points,  int hours,  String argument,  String? parentOfferId,  String status,  Map<String, String> votes,  int? resolvedAt,  String? resolvedBy,  String? resolution,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.id,_that.taskId,_that.projectId,_that.groupId,_that.authorId,_that.points,_that.hours,_that.argument,_that.parentOfferId,_that.status,_that.votes,_that.resolvedAt,_that.resolvedBy,_that.resolution,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskId,  String projectId,  String groupId,  String authorId,  int points,  int hours,  String argument,  String? parentOfferId,  String status,  Map<String, String> votes,  int? resolvedAt,  String? resolvedBy,  String? resolution,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Offer():
return $default(_that.id,_that.taskId,_that.projectId,_that.groupId,_that.authorId,_that.points,_that.hours,_that.argument,_that.parentOfferId,_that.status,_that.votes,_that.resolvedAt,_that.resolvedBy,_that.resolution,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskId,  String projectId,  String groupId,  String authorId,  int points,  int hours,  String argument,  String? parentOfferId,  String status,  Map<String, String> votes,  int? resolvedAt,  String? resolvedBy,  String? resolution,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.id,_that.taskId,_that.projectId,_that.groupId,_that.authorId,_that.points,_that.hours,_that.argument,_that.parentOfferId,_that.status,_that.votes,_that.resolvedAt,_that.resolvedBy,_that.resolution,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Offer implements Offer {
  const _Offer({required this.id, required this.taskId, required this.projectId, required this.groupId, required this.authorId, required this.points, required this.hours, required this.argument, this.parentOfferId, this.status = 'pending',  Map<String, String> votes = const {}, this.resolvedAt, this.resolvedBy, this.resolution, this.createdAt = 0, this.updatedAt = 0}): _votes = votes;
  factory _Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

@override final  String id;
@override final  String taskId;
@override final  String projectId;
@override final  String groupId;
@override final  String authorId;
@override final  int points;
@override final  int hours;
@override final  String argument;
@override final  String? parentOfferId;
@override@JsonKey() final  String status;
 final  Map<String, String> _votes;
@override@JsonKey() Map<String, String> get votes {
  if (_votes is EqualUnmodifiableMapView) return _votes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_votes);
}

@override final  int? resolvedAt;
@override final  String? resolvedBy;
@override final  String? resolution;
@override@JsonKey() final  int createdAt;
@override@JsonKey() final  int updatedAt;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfferCopyWith<_Offer> get copyWith => __$OfferCopyWithImpl<_Offer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfferToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Offer&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.points, points) || other.points == points)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.argument, argument) || other.argument == argument)&&(identical(other.parentOfferId, parentOfferId) || other.parentOfferId == parentOfferId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.votes, _votes)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,taskId,projectId,groupId,authorId,points,hours,argument,parentOfferId,status,const DeepCollectionEquality().hash(_votes),resolvedAt,resolvedBy,resolution,createdAt,updatedAt);
}

@override
String toString() {
    return 'Offer(id: $id, taskId: $taskId, projectId: $projectId, groupId: $groupId, authorId: $authorId, points: $points, hours: $hours, argument: $argument, parentOfferId: $parentOfferId, status: $status, votes: $votes, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy, resolution: $resolution, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OfferCopyWith<$Res> implements $OfferCopyWith<$Res> {
  factory _$OfferCopyWith(_Offer value, $Res Function(_Offer) _then) = __$OfferCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskId, String projectId, String groupId, String authorId, int points, int hours, String argument, String? parentOfferId, String status, Map<String, String> votes, int? resolvedAt, String? resolvedBy, String? resolution, int createdAt, int updatedAt
});




}
/// @nodoc
class __$OfferCopyWithImpl<$Res>
    implements _$OfferCopyWith<$Res> {
  __$OfferCopyWithImpl(this._self, this._then);

  final _Offer _self;
  final $Res Function(_Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskId = null,Object? projectId = null,Object? groupId = null,Object? authorId = null,Object? points = null,Object? hours = null,Object? argument = null,Object? parentOfferId = freezed,Object? status = null,Object? votes = null,Object? resolvedAt = freezed,Object? resolvedBy = freezed,Object? resolution = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Offer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as int,argument: null == argument ? _self.argument : argument // ignore: cast_nullable_to_non_nullable
as String,parentOfferId: freezed == parentOfferId ? _self.parentOfferId : parentOfferId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,votes: null == votes ? _self._votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as int?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
