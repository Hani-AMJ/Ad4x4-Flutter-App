// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_trip_search_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AdminTripSearchCriteria {
  /// Trip type filter (upcoming, pending, completed, all)
  TripType? get tripType => throw _privateConstructorUsedError;

  /// Selected level IDs (multi-select)
  List<int> get levelIds => throw _privateConstructorUsedError;

  /// Trip lead user ID filter (single user only - API limitation)
  int? get leadUserId => throw _privateConstructorUsedError;

  /// Meeting point area filter (single area only - API limitation)
  String? get meetingPointArea => throw _privateConstructorUsedError;

  /// Current wizard step (0=landing, 1-4=wizard steps, 5=results)
  int get currentStep => throw _privateConstructorUsedError;

  /// Search results (populated after search execution)
  List<dynamic>? get searchResults => throw _privateConstructorUsedError;

  /// Loading state for search
  bool get isSearching => throw _privateConstructorUsedError;

  /// Error message if search failed
  String? get searchError => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AdminTripSearchCriteriaCopyWith<AdminTripSearchCriteria> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminTripSearchCriteriaCopyWith<$Res> {
  factory $AdminTripSearchCriteriaCopyWith(AdminTripSearchCriteria value,
          $Res Function(AdminTripSearchCriteria) then) =
      _$AdminTripSearchCriteriaCopyWithImpl<$Res, AdminTripSearchCriteria>;
  @useResult
  $Res call(
      {TripType? tripType,
      List<int> levelIds,
      int? leadUserId,
      String? meetingPointArea,
      int currentStep,
      List<dynamic>? searchResults,
      bool isSearching,
      String? searchError});
}

/// @nodoc
class _$AdminTripSearchCriteriaCopyWithImpl<$Res,
        $Val extends AdminTripSearchCriteria>
    implements $AdminTripSearchCriteriaCopyWith<$Res> {
  _$AdminTripSearchCriteriaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripType = freezed,
    Object? levelIds = null,
    Object? leadUserId = freezed,
    Object? meetingPointArea = freezed,
    Object? currentStep = null,
    Object? searchResults = freezed,
    Object? isSearching = null,
    Object? searchError = freezed,
  }) {
    return _then(_value.copyWith(
      tripType: freezed == tripType
          ? _value.tripType
          : tripType // ignore: cast_nullable_to_non_nullable
              as TripType?,
      levelIds: null == levelIds
          ? _value.levelIds
          : levelIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      leadUserId: freezed == leadUserId
          ? _value.leadUserId
          : leadUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      meetingPointArea: freezed == meetingPointArea
          ? _value.meetingPointArea
          : meetingPointArea // ignore: cast_nullable_to_non_nullable
              as String?,
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      searchResults: freezed == searchResults
          ? _value.searchResults
          : searchResults // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      isSearching: null == isSearching
          ? _value.isSearching
          : isSearching // ignore: cast_nullable_to_non_nullable
              as bool,
      searchError: freezed == searchError
          ? _value.searchError
          : searchError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminTripSearchCriteriaImplCopyWith<$Res>
    implements $AdminTripSearchCriteriaCopyWith<$Res> {
  factory _$$AdminTripSearchCriteriaImplCopyWith(
          _$AdminTripSearchCriteriaImpl value,
          $Res Function(_$AdminTripSearchCriteriaImpl) then) =
      __$$AdminTripSearchCriteriaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TripType? tripType,
      List<int> levelIds,
      int? leadUserId,
      String? meetingPointArea,
      int currentStep,
      List<dynamic>? searchResults,
      bool isSearching,
      String? searchError});
}

/// @nodoc
class __$$AdminTripSearchCriteriaImplCopyWithImpl<$Res>
    extends _$AdminTripSearchCriteriaCopyWithImpl<$Res,
        _$AdminTripSearchCriteriaImpl>
    implements _$$AdminTripSearchCriteriaImplCopyWith<$Res> {
  __$$AdminTripSearchCriteriaImplCopyWithImpl(
      _$AdminTripSearchCriteriaImpl _value,
      $Res Function(_$AdminTripSearchCriteriaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripType = freezed,
    Object? levelIds = null,
    Object? leadUserId = freezed,
    Object? meetingPointArea = freezed,
    Object? currentStep = null,
    Object? searchResults = freezed,
    Object? isSearching = null,
    Object? searchError = freezed,
  }) {
    return _then(_$AdminTripSearchCriteriaImpl(
      tripType: freezed == tripType
          ? _value.tripType
          : tripType // ignore: cast_nullable_to_non_nullable
              as TripType?,
      levelIds: null == levelIds
          ? _value._levelIds
          : levelIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      leadUserId: freezed == leadUserId
          ? _value.leadUserId
          : leadUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      meetingPointArea: freezed == meetingPointArea
          ? _value.meetingPointArea
          : meetingPointArea // ignore: cast_nullable_to_non_nullable
              as String?,
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      searchResults: freezed == searchResults
          ? _value._searchResults
          : searchResults // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      isSearching: null == isSearching
          ? _value.isSearching
          : isSearching // ignore: cast_nullable_to_non_nullable
              as bool,
      searchError: freezed == searchError
          ? _value.searchError
          : searchError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AdminTripSearchCriteriaImpl extends _AdminTripSearchCriteria {
  const _$AdminTripSearchCriteriaImpl(
      {this.tripType,
      final List<int> levelIds = const [],
      this.leadUserId,
      this.meetingPointArea,
      this.currentStep = 0,
      final List<dynamic>? searchResults = null,
      this.isSearching = false,
      this.searchError = null})
      : _levelIds = levelIds,
        _searchResults = searchResults,
        super._();

  /// Trip type filter (upcoming, pending, completed, all)
  @override
  final TripType? tripType;

  /// Selected level IDs (multi-select)
  final List<int> _levelIds;

  /// Selected level IDs (multi-select)
  @override
  @JsonKey()
  List<int> get levelIds {
    if (_levelIds is EqualUnmodifiableListView) return _levelIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_levelIds);
  }

  /// Trip lead user ID filter (single user only - API limitation)
  @override
  final int? leadUserId;

  /// Meeting point area filter (single area only - API limitation)
  @override
  final String? meetingPointArea;

  /// Current wizard step (0=landing, 1-4=wizard steps, 5=results)
  @override
  @JsonKey()
  final int currentStep;

  /// Search results (populated after search execution)
  final List<dynamic>? _searchResults;

  /// Search results (populated after search execution)
  @override
  @JsonKey()
  List<dynamic>? get searchResults {
    final value = _searchResults;
    if (value == null) return null;
    if (_searchResults is EqualUnmodifiableListView) return _searchResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Loading state for search
  @override
  @JsonKey()
  final bool isSearching;

  /// Error message if search failed
  @override
  @JsonKey()
  final String? searchError;

  @override
  String toString() {
    return 'AdminTripSearchCriteria(tripType: $tripType, levelIds: $levelIds, leadUserId: $leadUserId, meetingPointArea: $meetingPointArea, currentStep: $currentStep, searchResults: $searchResults, isSearching: $isSearching, searchError: $searchError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminTripSearchCriteriaImpl &&
            (identical(other.tripType, tripType) ||
                other.tripType == tripType) &&
            const DeepCollectionEquality().equals(other._levelIds, _levelIds) &&
            (identical(other.leadUserId, leadUserId) ||
                other.leadUserId == leadUserId) &&
            (identical(other.meetingPointArea, meetingPointArea) ||
                other.meetingPointArea == meetingPointArea) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            const DeepCollectionEquality()
                .equals(other._searchResults, _searchResults) &&
            (identical(other.isSearching, isSearching) ||
                other.isSearching == isSearching) &&
            (identical(other.searchError, searchError) ||
                other.searchError == searchError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripType,
      const DeepCollectionEquality().hash(_levelIds),
      leadUserId,
      meetingPointArea,
      currentStep,
      const DeepCollectionEquality().hash(_searchResults),
      isSearching,
      searchError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminTripSearchCriteriaImplCopyWith<_$AdminTripSearchCriteriaImpl>
      get copyWith => __$$AdminTripSearchCriteriaImplCopyWithImpl<
          _$AdminTripSearchCriteriaImpl>(this, _$identity);
}

abstract class _AdminTripSearchCriteria extends AdminTripSearchCriteria {
  const factory _AdminTripSearchCriteria(
      {final TripType? tripType,
      final List<int> levelIds,
      final int? leadUserId,
      final String? meetingPointArea,
      final int currentStep,
      final List<dynamic>? searchResults,
      final bool isSearching,
      final String? searchError}) = _$AdminTripSearchCriteriaImpl;
  const _AdminTripSearchCriteria._() : super._();

  @override

  /// Trip type filter (upcoming, pending, completed, all)
  TripType? get tripType;
  @override

  /// Selected level IDs (multi-select)
  List<int> get levelIds;
  @override

  /// Trip lead user ID filter (single user only - API limitation)
  int? get leadUserId;
  @override

  /// Meeting point area filter (single area only - API limitation)
  String? get meetingPointArea;
  @override

  /// Current wizard step (0=landing, 1-4=wizard steps, 5=results)
  int get currentStep;
  @override

  /// Search results (populated after search execution)
  List<dynamic>? get searchResults;
  @override

  /// Loading state for search
  bool get isSearching;
  @override

  /// Error message if search failed
  String? get searchError;
  @override
  @JsonKey(ignore: true)
  _$$AdminTripSearchCriteriaImplCopyWith<_$AdminTripSearchCriteriaImpl>
      get copyWith => throw _privateConstructorUsedError;
}
