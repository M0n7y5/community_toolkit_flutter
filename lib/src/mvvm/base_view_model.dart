import 'dart:async';

import 'package:flutter/foundation.dart';

import 'relay_command.dart' show RelayCommand;

/// A base class for ViewModels in the MVVM pattern.
///
/// It provides core functionality such as:
/// - A loading state notifier.
/// - An asynchronous initialization method.
/// - Automatic disposal of registered [ChangeNotifier]s to prevent memory leaks.
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

  BaseViewModel() {
    unawaited(_initBaseClass());
  }

  /// Registers a [ChangeNotifier] to be automatically disposed when the ViewModel is disposed.
  ///
  /// This is the cornerstone of the automatic lifecycle management. Any
  /// [ValueNotifier] or [RelayCommand] created should be wrapped in this method.
  ///
  /// Returns the [disposable] so this can be chained during initialization.
  ///
  /// Example:
  /// `late final myNotifier = autoDispose(ValueNotifier(0));`
  T autoDispose<T extends ChangeNotifier>(T disposable) {
    _disposables.add(disposable);
    return disposable;
  }

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
