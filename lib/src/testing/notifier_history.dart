import 'package:flutter/foundation.dart';

/// Records all value transitions on a [ValueListenable] for test assertions.
///
/// Captures every value change in order, making it easy to assert on
/// intermediate states, transition sequences, or the final state.
///
/// ### Example
///
/// ```dart
/// final history = NotifierHistory(vm.stepNotifier);
/// await vm.performMultiStepOperation();
///
/// expect(history.values, [Step.validating, Step.downloading, Step.complete]);
/// expect(history.latest, Step.complete);
/// expect(history.count, 3);
///
/// history.dispose();
/// ```
class NotifierHistory<T> {
  /// All recorded values in chronological order.
  final List<T> values = [];

  final ValueListenable<T> _notifier;

  /// Creates a [NotifierHistory] that immediately starts recording changes
  /// on [notifier].
  NotifierHistory(this._notifier) {
    _notifier.addListener(_record);
  }

  void _record() {
    values.add(_notifier.value);
  }

  /// The most recently recorded value.
  ///
  /// Throws [StateError] if no values have been recorded.
  T get latest {
    if (values.isEmpty) {
      throw StateError('No values have been recorded yet.');
    }
    return values.last;
  }

  /// The first recorded value.
  ///
  /// Throws [StateError] if no values have been recorded.
  T get first {
    if (values.isEmpty) {
      throw StateError('No values have been recorded yet.');
    }
    return values.first;
  }

  /// The number of value changes recorded.
  int get count => values.length;

  /// Whether any values have been recorded.
  bool get hasValues => values.isNotEmpty;

  /// Clears the recorded history.
  void clear() => values.clear();

  /// Stops recording and removes the listener.
  void dispose() {
    _notifier.removeListener(_record);
  }
}
