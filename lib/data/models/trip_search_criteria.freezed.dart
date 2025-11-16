// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_search_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TripSearchCriteria {
  /// Quick filter type (upcoming, pending, completed, all)
  TripSearchType get searchType => throw _privateConstructorUsedError;

  /// Date range filter (optional)
  DateTime? get dateFrom => throw _privateConstructorUsedError;
  DateTime? get dateTo => throw _privateConstructorUsedError;

  /// Selected level IDs (multi-select - filtered client-side if multiple)
  List<int> get levelIds => throw _privateConstructorUsedError;

  /// Trip lead username (autocomplete search - filtered client-side)
  String? get leadUsername => throw _privateConstructorUsedError;

  /// Meeting point area filter (single area - API supported)
  String? get meetingPointArea => throw _privateConstructorUsedError;

  /// Sort option
  TripSortOption get sortBy => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TripSearchCriteriaCopyWith<TripSearchCriteria> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripSearchCriteriaCopyWith<$Res> {
  factory $TripSearchCriteriaCopyWith(
          TripSearchCriteria value, $Res Function(TripSearchCriteria) then) =
      _$TripSearchCriteriaCopyWithImpl<$Res, TripSearchCriteria>;
  @useResult
  $Res call(
      {TripSearchType searchType,
      DateTime? dateFrom,
      DateTime? dateTo,
      List<int> levelIds,
      String? leadUsername,
      String? meetingPointArea,
      TripSortOption sortBy});
}

/// @nodoc
class _$TripSearchCriteriaCopyWithImpl<$Res, $Val extends TripSearchCriteria>
    implements $TripSearchCriteriaCopyWith<$Res> {
  _$TripSearchCriteriaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchType = null,
    Object? dateFrom = freezed,
    Object? dateTo = freezed,
    Object? levelIds = null,
    Object? leadUsername = freezed,
    Object? meetingPointArea = freezed,
    Object? sortBy = null,
  }) {
    return _then(_value.copyWith(
      searchType: null == searchType
          ? _value.searchType
          : searchType // ignore: cast_nullable_to_non_nullable
              as TripSearchType,
      dateFrom: freezed == dateFrom
          ? _value.dateFrom
          : dateFrom // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateTo: freezed == dateTo
          ? _value.dateTo
          : dateTo // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      levelIds: null == levelIds
          ? _value.levelIds
          : levelIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      leadUsername: freezed == leadUsername
          ? _value.leadUsername
          : leadUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      meetingPointArea: freezed == meetingPointArea
          ? _value.meetingPointArea
          : meetingPointArea // ignore: cast_nullable_to_non_nullable
              as String?,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as TripSortOption,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripSearchCriteriaImplCopyWith<$Res>
    implements $TripSearchCriteriaCopyWith<$Res> {
  factory _$$TripSearchCriteriaImplCopyWith(_$TripSearchCriteriaImpl value,
          $Res Function(_$TripSearchCriteriaImpl) then) =
      __$$TripSearchCriteriaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TripSearchType searchType,
      DateTime? dateFrom,
      DateTime? dateTo,
      List<int> levelIds,
      String? leadUsername,
      String? meetingPointArea,
      TripSortOption sortBy});
}

/// @nodoc
class __$$TripSearchCriteriaImplCopyWithImpl<$Res>
    extends _$TripSearchCriteriaCopyWithImpl<$Res, _$TripSearchCriteriaImpl>
    implements _$$TripSearchCriteriaImplCopyWith<$Res> {
  __$$TripSearchCriteriaImplCopyWithImpl(_$TripSearchCriteriaImpl _value,
      $Res Function(_$TripSearchCriteriaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchType = null,
    Object? dateFrom = freezed,
    Object? dateTo = freezed,
    Object? levelIds = null,
    Object? leadUsername = freezed,
    Object? meetingPointArea = freezed,
    Object? sortBy = null,
  }) {
    return _then(_$TripSearchCriteriaImpl(
      searchType: null == searchType
          ? _value.searchType
          : searchType // ignore: cast_nullable_to_non_nullable
              as TripSearchType,
      dateFrom: freezed == dateFrom
          ? _value.dateFrom
          : dateFrom // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateTo: freezed == dateTo
          ? _value.dateTo
          : dateTo // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      levelIds: null == levelIds
          ? _value._levelIds
          : levelIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      leadUsername: freezed == leadUsername
          ? _value.leadUsername
          : leadUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      meetingPointArea: freezed == meetingPointArea
          ? _value.meetingPointArea
          : meetingPointArea // ignore: cast_nullable_to_non_nullable
              as String?,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as TripSortOption,
    ));
  }
}

/// @nodoc

class _$TripSearchCriteriaImpl extends _TripSearchCriteria {
  const _$TripSearchCriteriaImpl(
      {this.searchType = TripSearchType.upcoming,
      this.dateFrom,
      this.dateTo,
      final List<int> levelIds = const [],
      this.leadUsername,
      this.meetingPointArea,
      this.sortBy = TripSortOption.dateNewest})
      : _levelIds = levelIds,
        super._();

  /// Quick filter type (upcoming, pending, completed, all)
  @override
  @JsonKey()
  final TripSearchType searchType;

  /// Date range filter (optional)
  @override
  final DateTime? dateFrom;
  @override
  final DateTime? dateTo;

  /// Selected level IDs (multi-select - filtered client-side if multiple)
  final List<int> _levelIds;

  /// Selected level IDs (multi-select - filtered client-side if multiple)
  @override
  @JsonKey()
  List<int> get levelIds {
    if (_levelIds is EqualUnmodifiableListView) return _levelIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_levelIds);
  }

  /// Trip lead username (autocomplete search - filtered client-side)
  @override
  final String? leadUsername;

  /// Meeting point area filter (single area - API supported)
  @override
  final String? meetingPointArea;

  /// Sort option
  @override
  @JsonKey()
  final TripSortOption sortBy;

  @override
  String toString() {
    return 'TripSearchCriteria(searchType: $searchType, dateFrom: $dateFrom, dateTo: $dateTo, levelIds: $levelIds, leadUsername: $leadUsername, meetingPointArea: $meetingPointArea, sortBy: $sortBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripSearchCriteriaImpl &&
            (identical(other.searchType, searchType) ||
                other.searchType == searchType) &&
            (identical(other.dateFrom, dateFrom) ||
                other.dateFrom == dateFrom) &&
            (identical(other.dateTo, dateTo) || other.dateTo == dateTo) &&
            const DeepCollectionEquality().equals(other._levelIds, _levelIds) &&
            (identical(other.leadUsername, leadUsername) ||
                other.leadUsername == leadUsername) &&
            (identical(other.meetingPointArea, meetingPointArea) ||
                other.meetingPointArea == meetingPointArea) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      searchType,
      dateFrom,
      dateTo,
      const DeepCollectionEquality().hash(_levelIds),
      leadUsername,
      meetingPointArea,
      sortBy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripSearchCriteriaImplCopyWith<_$TripSearchCriteriaImpl> get copyWith =>
      __$$TripSearchCriteriaImplCopyWithImpl<_$TripSearchCriteriaImpl>(
          this, _$identity);
}

abstract class _TripSearchCriteria extends TripSearchCriteria {
  const factory _TripSearchCriteria(
      {final TripSearchType searchType,
      final DateTime? dateFrom,
      final DateTime? dateTo,
      final List<int> levelIds,
      final String? leadUsername,
      final String? meetingPointArea,
      final TripSortOption sortBy}) = _$TripSearchCriteriaImpl;
  const _TripSearchCriteria._() : super._();

  @override

  /// Quick filter type (upcoming, pending, completed, all)
  TripSearchType get searchType;
  @override

  /// Date range filter (optional)
  DateTime? get dateFrom;
  @override
  DateTime? get dateTo;
  @override

  /// Selected level IDs (multi-select - filtered client-side if multiple)
  List<int> get levelIds;
  @override

  /// Trip lead username (autocomplete search - filtered client-side)
  String? get leadUsername;
  @override

  /// Meeting point area filter (single area - API supported)
  String? get meetingPointArea;
  @override

  /// Sort option
  TripSortOption get sortBy;
  @override
  @JsonKey(ignore: true)
  _$$TripSearchCriteriaImplCopyWith<_$TripSearchCriteriaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
