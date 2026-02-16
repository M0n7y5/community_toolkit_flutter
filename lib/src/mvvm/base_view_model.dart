import 'package:flutter/foundation.dart';

import 'relay_command.dart';
import 'view_model_event.dart';
import 'view_model_observer.dart';

/// A base class for ViewModels in the MVVM pattern.
///
/// It provides core functionality such as:
/// - A loading state notifier.
/// - An explicit, guarded [initialize] lifecycle method.
/// - Automatic disposal of registered [ChangeNotifier]s to prevent memory leaks.
/// - Convenience factory methods ([notifier], [command], etc.) that create
///   common primitives and auto-register them for disposal.
///
/// ### Lifecycle
///
/// Unlike earlier versions, `init()` is **not** called automatically from the
/// constructor. Instead, [ViewModelStateMixin] calls [initialize] after
/// `createViewModel()` and `onViewModelReady()` complete. This eliminates the
/// timing race between the superclass constructor scheduling a microtask and
/// the subclass constructor body initializing `late final` fields.
///
/// When creating a ViewModel outside of a widget (e.g. in tests), call
/// [initialize] manually or use `ViewModelHarness`.
///
/// ### Example
///
/// ```dart
/// class CounterViewModel extends BaseViewModel {
///   late final count = notifier(0);
///   late final incrementCommand = command.syncUntyped(
///     execute: () => count.value++,
///   );
///
///   @override
///   Future<void> init() async {
///     // Fetch initial data, etc.
///   }
/// }
/// ```
class BaseViewModel {
  /// Global observers that receive lifecycle events from all ViewModels.
  ///
  /// Add observers at app startup to log, monitor, or debug ViewModel
  /// activity. See [ViewModelObserver] for available hooks.
  ///
  /// ```dart
  /// BaseViewModel.observers.add(DebugObserver());
  /// ```
  static final List<ViewModelObserver> observers = [];

  final List<ChangeNotifier> _disposables = [];
  bool _initialized = false;

  /// A notifier that holds the current loading state of the ViewModel.
  ///
  /// Starts as `true` and transitions to `false` after [init] completes.
  /// This notifier is automatically disposed.
  late final ValueNotifier<bool> loadingNotifier = autoDispose(
    ValueNotifier(true),
  );

  /// A factory helper for creating auto-disposed [RelayCommand] instances.
  ///
  /// Access the various factory methods through this object:
  /// - `command<T>(executeAsync: ...)` — typed async command
  /// - `command.untyped(executeAsync: ...)` — parameterless async command
  /// - `command.sync<T>(execute: ...)` — typed sync command
  /// - `command.syncUntyped(execute: ...)` — parameterless sync command
  ///
  /// All commands created through this helper are automatically registered
  /// for disposal when the ViewModel is disposed.
  late final CommandFactory command = CommandFactory._(this);

  /// Runs the async initialization lifecycle.
  ///
  /// Called automatically by [ViewModelStateMixin] after `createViewModel()`
  /// and `onViewModelReady()`. When constructing a ViewModel outside of a
  /// widget (e.g. in unit tests), call this explicitly:
  ///
  /// ```dart
  /// final vm = MyViewModel();
  /// await vm.initialize();
  /// // ... test ...
  /// vm.dispose();
  /// ```
  ///
  /// This method is guarded — calling it more than once is a safe no-op.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _notifyObservers((o) => o.onViewModelCreated(this));
    setLoading(true);
    _notifyObservers((o) => o.onInitStarted(this));
    final sw = Stopwatch()..start();
    try {
      await init();
      sw.stop();
      setLoading(false);
      _notifyObservers((o) => o.onInitCompleted(this, sw.elapsed));
    } on Object catch (error, stack) {
      sw.stop();
      setLoading(false);
      _notifyObservers((o) => o.onInitFailed(this, error, stack));
      rethrow;
    }
  }

  /// Whether [initialize] has been called (and potentially completed).
  bool get isInitialized => _initialized;

  /// Registers a [ChangeNotifier] to be automatically disposed when the
  /// ViewModel is disposed.
  ///
  /// This is the cornerstone of the automatic lifecycle management. Any
  /// [ValueNotifier] or [RelayCommand] created should be wrapped in this
  /// method.
  ///
  /// Returns the [disposable] so this can be chained during initialization.
  ///
  /// Example:
  /// ```dart
  /// late final myNotifier = autoDispose(ValueNotifier(0));
  /// ```
  ///
  /// Prefer the convenience helpers [notifier] and [command] for common cases.
  T autoDispose<T extends ChangeNotifier>(T disposable) {
    _disposables.add(disposable);
    return disposable;
  }

  /// Creates an auto-disposed [ValueNotifier] with the given [initialValue].
  ///
  /// This is a shorthand for `autoDispose(ValueNotifier<T>(initialValue))`.
  ///
  /// Example:
  /// ```dart
  /// // Before:
  /// late final count = autoDispose(ValueNotifier<int>(0));
  ///
  /// // After:
  /// late final count = notifier<int>(0);
  /// ```
  ValueNotifier<T> notifier<T>(T initialValue) =>
      autoDispose(ValueNotifier<T>(initialValue));

  /// Creates an auto-disposed [ViewModelEvent] for one-shot ViewModel-to-View
  /// communication.
  ///
  /// Use this for transient UI actions like showing a SnackBar, navigating,
  /// or opening a dialog.
  ///
  /// Example:
  /// ```dart
  /// late final showError = event<String>();
  /// late final navigateToDetail = event<int>();
  /// ```
  ViewModelEvent<T> event<T>() => autoDispose(ViewModelEvent<T>());

  /// Creates an auto-disposed [SignalEvent] for one-shot events that carry
  /// no data.
  ///
  /// Example:
  /// ```dart
  /// late final closeDialog = signalEvent();
  /// ```
  SignalEvent signalEvent() => autoDispose(SignalEvent());

  /// Sets the value of the [loadingNotifier].
  void setLoading(bool loading) {
    loadingNotifier.value = loading;
  }

  /// An asynchronous method that is called once during [initialize].
  ///
  /// Override this to perform initial data loading or other setup tasks.
  /// The [loadingNotifier] will be true while this method is executing.
  @protected
  Future<void> init() async {}

  /// Disposes the ViewModel and all registered [ChangeNotifier]s.
  ///
  /// This method should be called by the owner of the ViewModel (e.g., a State
  /// object in a StatefulWidget) to prevent memory leaks. Subclasses
  /// can override this but must call `super.dispose()`.
  @mustCallSuper
  void dispose() {
    for (final disposable in _disposables) {
      disposable.dispose();
    }
    _notifyObservers((o) => o.onViewModelDisposed(this));
  }

  void _notifyObservers(void Function(ViewModelObserver) action) {
    for (final observer in observers) {
      action(observer);
    }
  }
}

/// A factory for creating auto-disposed [RelayCommand] instances.
///
/// Accessed via [BaseViewModel.command]. All commands created through this
/// factory are automatically registered for disposal with the parent
/// ViewModel.
///
/// ### Example
///
/// ```dart
/// class MyViewModel extends BaseViewModel {
///   // Typed async command
///   late final saveCommand = command<String>(
///     executeAsync: (name) async => await _save(name),
///   );
///
///   // Untyped async command
///   late final refreshCommand = command.untyped(
///     executeAsync: () async => await _refresh(),
///   );
///
///   // Typed sync command
///   late final selectCommand = command.sync<int>(
///     execute: (index) => _selectedIndex.value = index,
///   );
///
///   // Untyped sync command
///   late final incrementCommand = command.syncUntyped(
///     execute: () => _count.value++,
///   );
/// }
/// ```
class CommandFactory {
  final BaseViewModel _vm;

  const CommandFactory._(this._vm);

  /// Creates an auto-disposed typed async [RelayCommand].
  RelayCommand<T> call<T>({
    required AsyncCommandAction<T> executeAsync,
    CanExecuteFunc<T>? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => _vm.autoDispose(
    RelayCommand<T>(
      executeAsync: executeAsync,
      canExecute: canExecute,
      listenables: listenables,
      errorNotifier: errorNotifier,
    ),
  );

  /// Creates an auto-disposed untyped async [RelayCommand].
  RelayCommand<void> untyped({
    required AsyncCommandActionUntyped executeAsync,
    CanExecuteFuncUntyped? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => _vm.autoDispose(
    RelayCommand<void>.untyped(
      executeAsync: executeAsync,
      canExecute: canExecute,
      listenables: listenables,
      errorNotifier: errorNotifier,
    ),
  );

  /// Creates an auto-disposed typed sync [RelayCommand].
  RelayCommand<T> sync<T>({
    required void Function(T) execute,
    CanExecuteFunc<T>? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => _vm.autoDispose(
    RelayCommand<T>.sync(
      execute: execute,
      canExecute: canExecute,
      listenables: listenables,
      errorNotifier: errorNotifier,
    ),
  );

  /// Creates an auto-disposed untyped sync [RelayCommand].
  RelayCommand<void> syncUntyped({
    required void Function() execute,
    CanExecuteFuncUntyped? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => _vm.autoDispose(
    RelayCommand<void>.syncUntyped(
      execute: execute,
      canExecute: canExecute,
      listenables: listenables,
      errorNotifier: errorNotifier,
    ),
  );
}
