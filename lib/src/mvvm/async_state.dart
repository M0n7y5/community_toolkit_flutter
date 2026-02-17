import 'package:flutter/foundation.dart';

import 'base_view_model.dart';

/// Represents the state of an asynchronous operation.
///
/// A sealed type with three variants:
/// - [AsyncLoading] — the operation is in progress.
/// - [AsyncData] — the operation completed successfully with a value.
/// - [AsyncError] — the operation failed with an error message.
///
/// ### Usage with pattern matching
///
/// ```dart
/// Bind<AsyncState<User>>(
///   notifier: vm.userState,
///   builder: (state) => switch (state) {
///     AsyncLoading(:final progress) => CircularProgressIndicator(value: progress),
///     AsyncError(:final message) => Text('Error: $message'),
///     AsyncData(:final data) => Text('Hello, ${data.name}'),
///   },
/// )
/// ```
sealed class AsyncState<T> {
  const AsyncState();

  /// Whether this state represents a loading operation.
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether this state contains data.
  bool get hasData => this is AsyncData<T>;

  /// Whether this state contains an error.
  bool get hasError => this is AsyncError<T>;

  /// Returns the data if this is [AsyncData], or `null` otherwise.
  T? get dataOrNull {
    final self = this;
    if (self is AsyncData<T>) {
      return self.data;
    }
    return null;
  }

  /// Returns the error message if this is [AsyncError], or `null` otherwise.
  String? get errorOrNull {
    final self = this;
    if (self is AsyncError<T>) {
      return self.message;
    }
    return null;
  }

  /// Calls the appropriate callback based on the current state.
  ///
  /// All three callbacks are required, ensuring exhaustive handling.
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function(String message) error,
  }) {
    final self = this;
    switch (self) {
      case AsyncLoading<T>():
        return loading();
      case AsyncData<T>():
        return data(self.data);
      case AsyncError<T>():
        return error(self.message);
    }
  }

  /// Like [when], but each callback receives the full state subtype.
  ///
  /// Use this to access additional state properties like
  /// [AsyncLoading.progress]:
  ///
  /// ```dart
  /// state.map(
  ///   loading: (s) => ProgressIndicator(value: s.progress),
  ///   data: (s) => Text('${s.data}'),
  ///   error: (s) => Text(s.message),
  /// )
  /// ```
  R map<R>({
    required R Function(AsyncLoading<T> state) loading,
    required R Function(AsyncData<T> state) data,
    required R Function(AsyncError<T> state) error,
  }) {
    final self = this;
    switch (self) {
      case AsyncLoading<T>():
        return loading(self);
      case AsyncData<T>():
        return data(self);
      case AsyncError<T>():
        return error(self);
    }
  }

  /// Like [when], but with optional callbacks that fall back to [orElse].
  R maybeWhen<R>({
    R Function()? loading,
    R Function(T data)? data,
    R Function(String message)? error,
    required R Function() orElse,
  }) {
    final self = this;
    switch (self) {
      case AsyncLoading<T>():
        return loading?.call() ?? orElse();
      case AsyncData<T>():
        return data?.call(self.data) ?? orElse();
      case AsyncError<T>():
        return error?.call(self.message) ?? orElse();
    }
  }
}

/// The operation is in progress with an optional [progress] fraction.
class AsyncLoading<T> extends AsyncState<T> {
  /// An optional progress value in the range `[0.0, 1.0]`.
  ///
  /// Non-null only when the producer has called
  /// [AsyncStateNotifier.setProgress].
  final double? progress;

  const AsyncLoading({this.progress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncLoading<T> && other.progress == progress;

  @override
  int get hashCode => Object.hash(runtimeType, progress);

  @override
  String toString() {
    if (progress != null) {
      return 'AsyncLoading<$T>(progress: $progress)';
    }
    return 'AsyncLoading<$T>()';
  }
}

/// The operation completed with [data].
class AsyncData<T> extends AsyncState<T> {
  /// The result data.
  final T data;

  const AsyncData(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncData<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'AsyncData<$T>($data)';
}

/// The operation failed with [message].
class AsyncError<T> extends AsyncState<T> {
  /// A human-readable error description.
  final String message;

  const AsyncError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncError<T> && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AsyncError<$T>($message)';
}

// ---------------------------------------------------------------------------
// Retry policy
// ---------------------------------------------------------------------------

/// Configuration for automatic retry with exponential back-off.
///
/// Used by [AsyncStateNotifier.execute] to transparently retry a failed
/// async action before surfacing an error.
///
/// ```dart
/// await entityState.execute(
///   () => api.getEntity(id),
///   retry: const RetryPolicy(maxRetries: 3),
/// );
/// ```
class RetryPolicy {
  /// Maximum number of retry attempts after the initial failure.
  final int maxRetries;

  /// Delay before the first retry. Doubles on each subsequent attempt.
  final Duration baseDelay;

  /// Upper bound on the retry delay.
  final Duration maxDelay;

  const RetryPolicy({
    this.maxRetries = 5,
    this.baseDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 6),
  });
}

// ---------------------------------------------------------------------------
// AsyncStateNotifier
// ---------------------------------------------------------------------------

/// A [ValueNotifier] that holds an [AsyncState] and provides convenience
/// methods for executing asynchronous operations.
///
/// This replaces the common pattern of declaring three separate notifiers
/// (data, loading, error) with a single notifier that encodes all three
/// states.
///
/// ### Example (ViewModel)
///
/// ```dart
/// class DetailViewModel extends BaseViewModel {
///   late final entityState = asyncNotifier<PluginEntity>();
///
///   @override
///   Future<void> init() async {
///     await entityState.execute(() => _api.getEntity(id));
///   }
/// }
/// ```
///
/// ### Example (View)
///
/// ```dart
/// BindAsync<PluginEntity>(
///   notifier: vm.entityState,
///   loading: (_) => const CircularProgressIndicator(),
///   data: (entity) => EntityView(entity),
///   error: (message) => ErrorWidget(message),
/// )
/// ```
class AsyncStateNotifier<T> extends ValueNotifier<AsyncState<T>> {
  bool _disposed = false;
  Future<T> Function()? _lastAction;

  /// Creates an [AsyncStateNotifier] starting in the [AsyncLoading] state.
  AsyncStateNotifier() : super(const AsyncLoading());

  /// Creates an [AsyncStateNotifier] starting with [data].
  AsyncStateNotifier.withData(T data) : super(AsyncData<T>(data));

  /// Whether the current state is loading.
  bool get isLoading => value.isLoading;

  /// Whether the current state contains data.
  bool get hasData => value.hasData;

  /// Whether the current state contains an error.
  bool get hasError => value.hasError;

  /// The current data, or `null` if not in the [AsyncData] state.
  T? get data => value.dataOrNull;

  /// The current error message, or `null` if not in the [AsyncError] state.
  String? get error => value.errorOrNull;

  /// Sets the state to [AsyncLoading].
  void setLoading() {
    value = const AsyncLoading();
  }

  /// Sets the state to [AsyncData] with [data].
  void setData(T data) {
    value = AsyncData<T>(data);
  }

  /// Sets the state to [AsyncError] with [message].
  void setError(String message) {
    value = AsyncError<T>(message);
  }

  /// Updates the [AsyncLoading.progress] value.
  ///
  /// Ignored when the current state is not [AsyncLoading].
  ///
  /// ```dart
  /// await entityState.execute(() async {
  ///   entityState.setProgress(0.5);
  ///   final half = await downloadFirstHalf();
  ///   entityState.setProgress(1.0);
  ///   final rest = await downloadSecondHalf();
  ///   return merge(half, rest);
  /// });
  /// ```
  void setProgress(double progress) {
    if (value.isLoading) {
      value = AsyncLoading<T>(progress: progress);
    }
  }

  /// Executes [action] and transitions the state accordingly.
  ///
  /// 1. Sets state to [AsyncLoading].
  /// 2. Awaits [action].
  /// 3. On success, sets state to [AsyncData] with the result.
  /// 4. On failure, sets state to [AsyncError] with the exception message.
  ///
  /// If [retry] is provided, failed attempts are retried with exponential
  /// back-off according to the [RetryPolicy].
  ///
  /// The action is stored for later use by [invalidate] and [refresh].
  Future<void> execute(
    Future<T> Function() action, {
    RetryPolicy? retry,
  }) async {
    _lastAction = action;
    value = const AsyncLoading();
    if (retry != null) {
      await _executeWithRetry(action, retry);
    } else {
      await _executeDirect(action);
    }
  }

  /// Re-runs the last action passed to [execute].
  ///
  /// Transitions through [AsyncLoading] → [AsyncData] / [AsyncError] just
  /// like [execute]. Does nothing if [execute] has never been called.
  Future<void> invalidate({RetryPolicy? retry}) async {
    final action = _lastAction;
    if (action != null) {
      await execute(action, retry: retry);
    }
  }

  /// Re-runs [action] (or the last action) **without** entering the
  /// loading state.
  ///
  /// This is useful for pull-to-refresh where you want to keep the
  /// current data visible while new data loads.
  Future<void> refresh([Future<T> Function()? action]) async {
    final fn = action ?? _lastAction;
    if (fn == null) {
      return;
    }
    _lastAction = fn;
    try {
      value = AsyncData<T>(await fn());
    } on Exception catch (e) {
      value = AsyncError<T>(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---- private helpers ----------------------------------------------------

  Future<void> _executeDirect(Future<T> Function() action) async {
    try {
      value = AsyncData<T>(await action());
    } on Exception catch (e) {
      if (_disposed) {
        return;
      }
      value = AsyncError<T>(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _executeWithRetry(
    Future<T> Function() action,
    RetryPolicy policy,
  ) async {
    for (var attempt = 0; attempt <= policy.maxRetries; attempt++) {
      try {
        final result = await action();
        if (_disposed) {
          return;
        }
        value = AsyncData<T>(result);
        return;
      } on Exception catch (e) {
        if (_disposed) {
          return;
        }
        if (attempt >= policy.maxRetries) {
          value = AsyncError<T>(e.toString().replaceFirst('Exception: ', ''));
          return;
        }
        // Exponential back-off capped at maxDelay.
        var delay = policy.baseDelay * (1 << attempt);
        if (delay > policy.maxDelay) {
          delay = policy.maxDelay;
        }
        await Future<void>.delayed(delay);
        if (_disposed) {
          return;
        }
      }
    }
  }
}

/// Extension on [BaseViewModel] to create auto-disposed
/// [AsyncStateNotifier] instances.
extension AsyncStateViewModelExtension on BaseViewModel {
  /// Creates an auto-disposed [AsyncStateNotifier] starting in the
  /// loading state.
  ///
  /// ```dart
  /// late final userState = asyncNotifier<User>();
  /// ```
  AsyncStateNotifier<T> asyncNotifier<T>() =>
      autoDispose(AsyncStateNotifier<T>());

  /// Creates an auto-disposed [AsyncStateNotifier] starting with [data].
  ///
  /// ```dart
  /// late final countState = asyncNotifierWithData<int>(0);
  /// ```
  AsyncStateNotifier<T> asyncNotifierWithData<T>(T data) =>
      autoDispose(AsyncStateNotifier<T>.withData(data));
}
