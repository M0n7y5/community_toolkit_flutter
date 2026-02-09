import 'dart:async';

import 'package:flutter/foundation.dart';

import 'relay_command.dart';
import 'view_model_event.dart';

/// A base class for ViewModels in the MVVM pattern.
///
/// It provides core functionality such as:
/// - A loading state notifier.
/// - An asynchronous initialization method.
/// - Automatic disposal of registered [ChangeNotifier]s to prevent memory leaks.
/// - Convenience factory methods ([notifier], [command], etc.) that create
///   common primitives and auto-register them for disposal.
///
/// ### Example
///
/// ```dart
/// class CounterViewModel extends BaseViewModel {
///   late final count = notifier(0);
///   late final incrementCommand = command.syncUntyped(
///     execute: () => count.value++,
///   );
/// }
/// ```
class BaseViewModel {
  final List<ChangeNotifier> _disposables = [];

  /// A notifier that holds the current loading state of the ViewModel.
  ///
  /// Typically used to show a loading indicator in the View while the
  /// ViewModel is performing an asynchronous operation (e.g., in [init]).
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

  BaseViewModel() {
    unawaited(_initBaseClass());
  }

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

  /// Internal method to manage the initialization lifecycle.
  Future<void> _initBaseClass() async {
    setLoading(true);
    await init();
    setLoading(false);
  }

  /// An asynchronous method that is called once when the ViewModel is created.
  ///
  /// Override this to perform initial data loading or other setup tasks.
  /// The [loadingNotifier] will be true while this method is executing.
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
