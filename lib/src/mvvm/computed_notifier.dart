import 'package:flutter/foundation.dart';

import 'base_view_model.dart';

/// A [ValueNotifier] whose value is derived from one or more source
/// [Listenable]s and automatically recomputed when any source changes.
///
/// This is the reactive dependency equivalent of Riverpod's `ref.watch`
/// chaining — when any watched source fires, the [compute] function runs
/// and the notifier updates (notifying listeners only if the new value
/// differs from the old one by `==`).
///
/// ### Example
///
/// ```dart
/// class CartViewModel extends BaseViewModel {
///   late final items = notifier<List<Item>>([]);
///   late final taxRate = notifier<double>(0.08);
///
///   late final total = computed<double>(
///     watch: [items, taxRate],
///     compute: () {
///       final subtotal = items.value.fold(0.0, (s, i) => s + i.price);
///       return subtotal * (1 + taxRate.value);
///     },
///   );
/// }
/// ```
///
/// The [compute] function is called synchronously. For async derivations,
/// use [AsyncStateNotifier] with manual listener wiring.
class ComputedNotifier<T> extends ValueNotifier<T> {
  final List<Listenable> _sources;
  final T Function() _compute;

  /// Creates a [ComputedNotifier] that evaluates [compute] whenever any
  /// [Listenable] in [sources] fires.
  ///
  /// The initial value is computed immediately from the current state of
  /// the sources.
  ComputedNotifier({
    required List<Listenable> sources,
    required T Function() compute,
  }) : _sources = List.unmodifiable(sources),
       _compute = compute,
       super(compute()) {
    for (final source in _sources) {
      source.addListener(_recompute);
    }
  }

  void _recompute() {
    final next = _compute();
    if (next != value) {
      value = next;
    }
  }

  /// Forces recomputation and notification regardless of equality.
  ///
  /// Use this when the compute function's result depends on mutable
  /// external state that the sources do not directly represent.
  void recompute() {
    final next = _compute();
    if (next == value) {
      // Bypass ValueNotifier's equality guard — always notify.
      notifyListeners();
    } else {
      value = next;
    }
  }

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(_recompute);
    }
    super.dispose();
  }
}

/// Extension on [BaseViewModel] to create auto-disposed
/// [ComputedNotifier] instances.
extension ComputedViewModelExtension on BaseViewModel {
  /// Creates an auto-disposed [ComputedNotifier] that recomputes when any
  /// [Listenable] in [watch] fires.
  ///
  /// ```dart
  /// late final total = computed<double>(
  ///   watch: [items, taxRate],
  ///   compute: () =>
  ///       items.value.fold(0.0, (s, i) => s + i.price) *
  ///       (1 + taxRate.value),
  /// );
  /// ```
  ComputedNotifier<T> computed<T>({
    required List<Listenable> watch,
    required T Function() compute,
  }) => autoDispose(ComputedNotifier<T>(sources: watch, compute: compute));
}
