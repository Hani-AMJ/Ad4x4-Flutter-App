// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_wizard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminWizardHash() => r'4f60a8cc73999a71e84ded86d5eafbac067114d1';

/// Admin Wizard State Notifier
///
/// Manages wizard navigation and search criteria for admin trips search
///
/// Copied from [AdminWizard].
@ProviderFor(AdminWizard)
final adminWizardProvider =
    AutoDisposeNotifierProvider<AdminWizard, AdminTripSearchCriteria>.internal(
  AdminWizard.new,
  name: r'adminWizardProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adminWizardHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminWizard = AutoDisposeNotifier<AdminTripSearchCriteria>;
String _$adminWizardResultsHash() =>
    r'ecee59f15c0c1928aabbc1546cd359e9ead6ac35';

/// Admin Wizard Results Provider
///
/// Manages search results for admin trips wizard
///
/// Copied from [AdminWizardResults].
@ProviderFor(AdminWizardResults)
final adminWizardResultsProvider = AutoDisposeNotifierProvider<
    AdminWizardResults, AsyncValue<List<TripListItem>>>.internal(
  AdminWizardResults.new,
  name: r'adminWizardResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminWizardResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminWizardResults
    = AutoDisposeNotifier<AsyncValue<List<TripListItem>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
