import '../mvvm/base_view_model.dart';

/// A test harness that manages [BaseViewModel] lifecycle in unit tests.
///
/// Eliminates the manual `await Future.delayed(Duration.zero)` + `vm.dispose()`
/// boilerplate that appears in every ViewModel test.
///
/// ### Example
///
/// ```dart
/// late final harness = ViewModelHarness<MyViewModel>();
///
/// tearDown(() => harness.dispose());
///
/// test('loads data on init', () async {
///   final vm = await harness.create(() => MyViewModel());
///   expect(vm.dataNotifier.value, isNotNull);
/// });
/// ```
///
/// ### With setup callback
///
/// ```dart
/// test('loads data', () async {
///   final vm = await harness.create(
///     () => MyViewModel(id: 'test'),
///     setUp: (vm) {
///       // Register listeners, inject test doubles, etc.
///     },
///   );
///   expect(vm.loadingNotifier.value, isFalse);
/// });
/// ```
class ViewModelHarness<VM extends BaseViewModel> {
  VM? _vm;

  /// The current ViewModel, or `null` if none has been created.
  VM? get vmOrNull => _vm;

  /// The current ViewModel.
  ///
  /// Throws [StateError] if [create] has not been called.
  VM get vm {
    if (_vm == null) {
      throw StateError('No ViewModel has been created. Call create() first.');
    }
    return _vm!;
  }

  /// Creates a ViewModel using [factory], runs [initialize], and returns it.
  ///
  /// If a previous ViewModel exists, it is disposed first.
  ///
  /// The optional [setUp] callback is invoked after construction but before
  /// [BaseViewModel.initialize] — mirroring the timing of
  /// [ViewModelStateMixin.onViewModelReady].
  Future<VM> create(
    VM Function() factory, {
    void Function(VM vm)? setUp,
  }) async {
    dispose();
    _vm = factory();
    setUp?.call(_vm as VM);
    await _vm!.initialize();
    return _vm as VM;
  }

  /// Creates a ViewModel without calling [initialize].
  ///
  /// Use this when you need to test behavior before or during initialization,
  /// or when the ViewModel's [init] depends on external state that must be
  /// configured first.
  ///
  /// ```dart
  /// final vm = harness.createManual(() => MyViewModel());
  /// // Configure dependencies...
  /// await vm.initialize();
  /// ```
  VM createManual(VM Function() factory) {
    dispose();
    _vm = factory();
    return _vm as VM;
  }

  /// Disposes the current ViewModel if one exists.
  ///
  /// Safe to call multiple times. Call this in `tearDown`:
  ///
  /// ```dart
  /// tearDown(() => harness.dispose());
  /// ```
  void dispose() {
    _vm?.dispose();
    _vm = null;
  }
}
