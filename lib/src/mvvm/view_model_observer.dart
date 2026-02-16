import 'base_view_model.dart';

/// An observer that receives lifecycle events from [BaseViewModel] instances.
///
/// Register observers globally via [BaseViewModel.observers] to log, monitor,
/// or debug ViewModel activity across the application.
///
/// All methods have empty default implementations so subclasses only need
/// to override the hooks they care about.
///
/// ### Example
///
/// ```dart
/// class DebugObserver extends ViewModelObserver {
///   @override
///   void onInitCompleted(BaseViewModel vm, Duration elapsed) {
///     debugPrint('${vm.runtimeType} initialized in ${elapsed.inMilliseconds}ms');
///   }
///
///   @override
///   void onInitFailed(BaseViewModel vm, Object error, StackTrace stackTrace) {
///     debugPrint('${vm.runtimeType} init failed: $error');
///   }
/// }
///
/// // In main():
/// BaseViewModel.observers.add(DebugObserver());
/// ```
abstract class ViewModelObserver {
  /// Called when [BaseViewModel.initialize] is first invoked.
  void onViewModelCreated(BaseViewModel vm) {}

  /// Called after [BaseViewModel.dispose] completes.
  void onViewModelDisposed(BaseViewModel vm) {}

  /// Called immediately before [BaseViewModel.init] runs.
  void onInitStarted(BaseViewModel vm) {}

  /// Called after [BaseViewModel.init] completes successfully.
  ///
  /// [elapsed] is the wall-clock time spent in [init].
  void onInitCompleted(BaseViewModel vm, Duration elapsed) {}

  /// Called when [BaseViewModel.init] throws.
  ///
  /// The error is re-thrown after all observers are notified.
  void onInitFailed(BaseViewModel vm, Object error, StackTrace stackTrace) {}
}
