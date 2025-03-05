// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nlip_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiError {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiError()';
}


}

/// @nodoc
class $ApiErrorCopyWith<$Res>  {
$ApiErrorCopyWith(ApiError _, $Res Function(ApiError) __);
}


/// @nodoc


class ApiError_NetworkError extends ApiError {
  const ApiError_NetworkError(this.field0): super._();
  

 final  String field0;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiError_NetworkErrorCopyWith<ApiError_NetworkError> get copyWith => _$ApiError_NetworkErrorCopyWithImpl<ApiError_NetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError_NetworkError&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ApiError.networkError(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ApiError_NetworkErrorCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory $ApiError_NetworkErrorCopyWith(ApiError_NetworkError value, $Res Function(ApiError_NetworkError) _then) = _$ApiError_NetworkErrorCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$ApiError_NetworkErrorCopyWithImpl<$Res>
    implements $ApiError_NetworkErrorCopyWith<$Res> {
  _$ApiError_NetworkErrorCopyWithImpl(this._self, this._then);

  final ApiError_NetworkError _self;
  final $Res Function(ApiError_NetworkError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ApiError_NetworkError(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiError_ServerError extends ApiError {
  const ApiError_ServerError({required this.code, required this.message}): super._();
  

 final  int code;
 final  String message;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiError_ServerErrorCopyWith<ApiError_ServerError> get copyWith => _$ApiError_ServerErrorCopyWithImpl<ApiError_ServerError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError_ServerError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'ApiError.serverError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiError_ServerErrorCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory $ApiError_ServerErrorCopyWith(ApiError_ServerError value, $Res Function(ApiError_ServerError) _then) = _$ApiError_ServerErrorCopyWithImpl;
@useResult
$Res call({
 int code, String message
});




}
/// @nodoc
class _$ApiError_ServerErrorCopyWithImpl<$Res>
    implements $ApiError_ServerErrorCopyWith<$Res> {
  _$ApiError_ServerErrorCopyWithImpl(this._self, this._then);

  final ApiError_ServerError _self;
  final $Res Function(ApiError_ServerError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(ApiError_ServerError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiError_DeserializeError extends ApiError {
  const ApiError_DeserializeError(this.field0): super._();
  

 final  String field0;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiError_DeserializeErrorCopyWith<ApiError_DeserializeError> get copyWith => _$ApiError_DeserializeErrorCopyWithImpl<ApiError_DeserializeError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError_DeserializeError&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ApiError.deserializeError(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ApiError_DeserializeErrorCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory $ApiError_DeserializeErrorCopyWith(ApiError_DeserializeError value, $Res Function(ApiError_DeserializeError) _then) = _$ApiError_DeserializeErrorCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$ApiError_DeserializeErrorCopyWithImpl<$Res>
    implements $ApiError_DeserializeErrorCopyWith<$Res> {
  _$ApiError_DeserializeErrorCopyWithImpl(this._self, this._then);

  final ApiError_DeserializeError _self;
  final $Res Function(ApiError_DeserializeError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ApiError_DeserializeError(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiError_ClientError extends ApiError {
  const ApiError_ClientError(this.field0): super._();
  

 final  String field0;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiError_ClientErrorCopyWith<ApiError_ClientError> get copyWith => _$ApiError_ClientErrorCopyWithImpl<ApiError_ClientError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError_ClientError&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ApiError.clientError(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ApiError_ClientErrorCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory $ApiError_ClientErrorCopyWith(ApiError_ClientError value, $Res Function(ApiError_ClientError) _then) = _$ApiError_ClientErrorCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$ApiError_ClientErrorCopyWithImpl<$Res>
    implements $ApiError_ClientErrorCopyWith<$Res> {
  _$ApiError_ClientErrorCopyWithImpl(this._self, this._then);

  final ApiError_ClientError _self;
  final $Res Function(ApiError_ClientError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ApiError_ClientError(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiError_Other extends ApiError {
  const ApiError_Other(this.field0): super._();
  

 final  String field0;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiError_OtherCopyWith<ApiError_Other> get copyWith => _$ApiError_OtherCopyWithImpl<ApiError_Other>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError_Other&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ApiError.other(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ApiError_OtherCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory $ApiError_OtherCopyWith(ApiError_Other value, $Res Function(ApiError_Other) _then) = _$ApiError_OtherCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$ApiError_OtherCopyWithImpl<$Res>
    implements $ApiError_OtherCopyWith<$Res> {
  _$ApiError_OtherCopyWithImpl(this._self, this._then);

  final ApiError_Other _self;
  final $Res Function(ApiError_Other) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ApiError_Other(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
