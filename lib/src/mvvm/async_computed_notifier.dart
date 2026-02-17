import 'dart:async';

import 'package:flutter/foundation.dart';

import 'async_state.dart';
import 'base_view_model.dart';

/// A [ValueNotifier] whose value is an [AsyncState<T>] derived from one or
/// more source [Listenable]s via an asynchronous computation.
///
/// This is the async counterpart to [ComputedNotifier]. When any watched
/// source fires, the [compute] function is re-invoked and the notifier
/// transitions through [AsyncLoading] → [AsyncData] / [AsyncError]
/// automatically.
///
/// If a source fires while a previous computation is still in-flight, the
/// previous result is discarded (last-write-wins). An optional [debounce]
/// duration coalesces rapid source changes to avoid unnecessary work.
///
/// ### Example
///
/// ```dart
/// class SearchViewModel extends BaseViewModel {
///   late final query = notifier<String>('');
///   late final filters = notifier<Filters>(Filters.defaults);
///
///   late final results = asyncComputed<List<Item>>(
///     watch: [query, filters],
///     compute: () => _api.search(query.value, filters.value),
///   );
/// }
/// ```
///
/// ### Example (View)
///
/// ```dart
/// BindAsync<List<Item>>(
///   notifier: vm.results,
///   loading: (_) => const CircularProgressIndicator(),
///   data: (items) => ItemList(items),
///   error: (message) => Text('Error: $message'),
/// )
/// ```
class AsyncComputedNotifier<T> extends ValueNotifier<AsyncState<T>> {
  final List<Listenable> _sources;
  final Future<T> Function() _compute;
  final Duration? _debounce;

  bool _disposed = false;

  /// Monotonically increasing version counter used to discard stale results.
  int _version = 0;

  Timer? _debounceTimer;

  /// Creates an [AsyncComputedNotifier] that evaluates [compute] whenever
  /// any [Listenable] in [sources] fires.
  ///
  /// The initial computation is triggered immediately. If [debounce] is
  /// provided, rapid source changes within that window are coalesced into
  /// a single computation.
  ///
  /// If [initialState] is provided, it is used as the state before the
  /// first computation completes. Defaults to [AsyncLoading].
  AsyncComputedNotifier({
    required List<Listenable> sources,
    required Future<T> Function() compute,
    Duration? debounce,
    AsyncState<T>? initialState,
  }) : _sources = List.unmodifiable(sources),
       _compute = compute,
       _debounce = debounce,
       super(initialState ?? const AsyncLoading()) {
    for (final source in _sources) {
      source.addListener(_onSourceChanged);
    }
    // Trigger the first computation.
    unawaited(_execute());
  }

  /// Creates an [AsyncComputedNotifier] that does **not** compute
  /// immediately, starting with [data] as the initial value.
  ///
  /// The computation will run on the next source change.
  ///
  /// ```dart
  /// final notifier = AsyncComputedNotifier.withData(
  ///   sources: [source],
  ///   compute: () async => expensiveCalculation(source.value),
  ///   data: cachedValue,
  /// );
  /// ```
  AsyncComputedNotifier.withData({
    required List<Listenable> sources,
    required Future<T> Function() compute,
    required T data,
    Duration? debounce,
  }) : _sources = List.unmodifiable(sources),
       _compute = compute,
       _debounce = debounce,
       super(AsyncData<T>(data)) {
    for (final source in _sources) {
      source.addListener(_onSourceChanged);
    }
  }

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

  /// Forces re-execution of the async computation.
  ///
  /// Unlike automatic recomputation triggered by source changes, this
  /// method ignores the [debounce] duration and executes immediately.
  Future<void> recompute() => _execute();

  /// Re-runs the computation **without** transitioning through the
  /// loading state.
  ///
  /// This is useful for pull-to-refresh patterns where you want to keep
  /// the current data visible while new data loads.
  Future<void> refresh() async {
    final version = ++_version;
    try {
      final result = await _compute();
      if (_disposed || _version != version) {
        return;
      }
      value = AsyncData<T>(result);
    } on Exception catch (e) {
      if (_disposed || _version != version) {
        return;
      }
      value = AsyncError<T>(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onSourceChanged() {
    final debounce = _debounce;
    if (debounce != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounce, () => unawaited(_execute()));
    } else {
      unawaited(_execute());
    }
  }

  Future<void> _execute() async {
    final version = ++_version;
    value = const AsyncLoading();
    try {
      final result = await _compute();
      // Discard if disposed or a newer computation has started.
      if (_disposed || _version != version) {
        return;
      }
      value = AsyncData<T>(result);
    } on Exception catch (e) {
      if (_disposed || _version != version) {
        return;
      }
      value = AsyncError<T>(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    for (final source in _sources) {
      source.removeListener(_onSourceChanged);
    }
    super.dispose();
  }
}

/// Extension on [BaseViewModel] to create auto-disposed
/// [AsyncComputedNotifier] instances.
extension AsyncComputedViewModelExtension on BaseViewModel {
  /// Creates an auto-disposed [AsyncComputedNotifier] that recomputes
  /// when any [Listenable] in [watch] fires.
  ///
  /// ```dart
  /// late final results = asyncComputed<List<Item>>(
  ///   watch: [query, filters],
  ///   compute: () => api.search(query.value, filters.value),
  /// );
  /// ```
  AsyncComputedNotifier<T> asyncComputed<T>({
    required List<Listenable> watch,
    required Future<T> Function() compute,
    Duration? debounce,
  }) => autoDispose(
    AsyncComputedNotifier<T>(
      sources: watch,
      compute: compute,
      debounce: debounce,
    ),
  );

  /// Creates an auto-disposed [AsyncComputedNotifier] starting with [data]
  /// as the initial value, without triggering the computation immediately.
  ///
  /// ```dart
  /// late final results = asyncComputedWithData<List<Item>>(
  ///   watch: [query],
  ///   compute: () => api.search(query.value),
  ///   data: cachedItems,
  /// );
  /// ```
  AsyncComputedNotifier<T> asyncComputedWithData<T>({
    required List<Listenable> watch,
    required Future<T> Function() compute,
    required T data,
    Duration? debounce,
  }) => autoDispose(
    AsyncComputedNotifier<T>.withData(
      sources: watch,
      compute: compute,
      data: data,
      debounce: debounce,
    ),
  );
}
