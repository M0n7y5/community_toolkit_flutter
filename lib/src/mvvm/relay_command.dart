import 'package:flutter/foundation.dart';

// Typedefs for command actions and conditions.
typedef AsyncCommandAction<T> = Future<void> Function(T arg);
typedef AsyncCommandActionUntyped = Future<void> Function();
typedef CanExecuteFunc<T> = bool Function(T arg);
typedef CanExecuteFuncUntyped = bool Function();

/// An implementation of the command pattern that relays an `execute` and
/// `canExecute` method to other objects.
class RelayCommand<T> extends ChangeNotifier {
  final AsyncCommandAction<T>? _executeAsync;

  final CanExecuteFunc<T>? _canExecute;

  final List<Listenable> _listenables;

  ValueNotifier<String?>? errorNotifier;

  late final ValueNotifier<bool> executingNotifier = ValueNotifier(false);

  /// Creates a command that takes a parameter of type [T].
  factory RelayCommand({
    required AsyncCommandAction<T> executeAsync,
    CanExecuteFunc<T>? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => RelayCommand<T>._(
    executeAsync: executeAsync,
    canExecute: canExecute,
    listenables: listenables,
    errorNotifier: errorNotifier,
  );

  RelayCommand._({
    this.errorNotifier,
    AsyncCommandAction<T>? executeAsync,
    CanExecuteFunc<T>? canExecute,
    List<Listenable> listenables = const [],
  }) : _executeAsync = executeAsync,
       _canExecute = canExecute,
       _listenables = listenables {
    for (final listenable in _listenables) {
      listenable.addListener(notifyListeners);
    }
  }

  /// Creates a command that does not take a parameter.
  factory RelayCommand.untyped({
    required AsyncCommandActionUntyped executeAsync,
    CanExecuteFuncUntyped? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) {
    // Convert untyped functions to typed ones for internal storage
    AsyncCommandAction<T>? typedExecuteAsync;
    CanExecuteFunc<T>? typedCanExecute;

    typedExecuteAsync = (arg) => executeAsync();

    if (canExecute != null) {
      typedCanExecute = (arg) => canExecute();
    }

    return RelayCommand<T>._(
      executeAsync: typedExecuteAsync,
      canExecute: typedCanExecute,
      listenables: listenables,
      errorNotifier: errorNotifier,
    );
  }

  /// A convenience factory for creating a command with a synchronous action
  /// that takes a parameter of type [T].
  factory RelayCommand.sync({
    required void Function(T) execute,
    CanExecuteFunc<T>? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => RelayCommand<T>(
    executeAsync: (arg) async => execute(arg),
    canExecute: canExecute,
    listenables: listenables,
    errorNotifier: errorNotifier,
  );

  /// A convenience factory for creating a command with a synchronous action
  /// that does not take a parameter.
  factory RelayCommand.syncUntyped({
    required void Function() execute,
    CanExecuteFuncUntyped? canExecute,
    List<Listenable> listenables = const [],
    ValueNotifier<String?>? errorNotifier,
  }) => RelayCommand.untyped(
    executeAsync: () async => execute(),
    canExecute: canExecute,
    listenables: listenables,
    errorNotifier: errorNotifier,
  );

  bool get isExecuting => executingNotifier.value;

  /// Whether the command can currently execute.
  ///
  /// Returns `false` while the command is already executing.
  ///
  /// For **typed** commands (`RelayCommand<int>`, etc.) the [arg] must be
  /// provided when a `canExecute` guard was supplied at construction — the
  /// guard needs the typed value to evaluate. Calling this without an
  /// argument on a typed command that has a guard will throw a [TypeError].
  ///
  /// For **untyped** commands (`RelayCommand<void>`) the argument is ignored.
  bool canExecute([T? arg]) {
    if (executingNotifier.value) {
      return false;
    }
    if (_canExecute == null) {
      return true;
    }
    return _canExecute(arg as T);
  }

  /// Executes the command without any parameter.
  ///
  /// This is a convenience method for void/untyped commands where calling
  /// `execute(null)` or `execute()` feels awkward. It is equivalent to
  /// calling `execute()`.
  ///
  /// Example:
  /// ```dart
  /// // Instead of:
  /// command.execute(null);
  ///
  /// // Use:
  /// command.invoke();
  /// ```
  Future<void> invoke() => execute();

  Future<void> execute([T? arg]) async {
    if (!canExecute(arg)) {
      return;
    }

    executingNotifier.value = true;
    errorNotifier?.value = null;
    notifyListeners();

    try {
      if (_executeAsync != null) {
        await _executeAsync(arg as T);
      }
    } on Exception catch (e) {
      errorNotifier?.value = e.toString().replaceFirst('Exception: ', '');
    } on Object catch (e) {
      errorNotifier?.value = e.toString();
    } finally {
      executingNotifier.value = false;
      notifyListeners();
    }
  }

  void requery() {
    notifyListeners();
  }

  @override
  @mustCallSuper
  void dispose() {
    for (final listenable in _listenables) {
      listenable.removeListener(notifyListeners);
    }
    executingNotifier.dispose();
    super.dispose();
  }
}
