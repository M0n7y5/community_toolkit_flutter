import '../mvvm/view_model_event.dart';

/// Records all firings of a [ViewModelEvent] for test assertions.
///
/// Captures every event payload in order, making it easy to verify that
/// one-shot events fired with the expected values.
///
/// ### Example
///
/// ```dart
/// final recorder = EventRecorder(vm.errorEvent);
/// await vm.performAction();
///
/// expect(recorder.fired, isTrue);
/// expect(recorder.latest, 'Something went wrong');
/// expect(recorder.count, 1);
///
/// recorder.dispose();
/// ```
class EventRecorder<T> {
  /// All recorded event payloads in chronological order.
  ///
  /// Only non-null payloads are recorded. For [ViewModelEvent<void>] events
  /// that fire with `null`, use [fired] and [count] instead.
  final List<T> values = [];

  final ViewModelEvent<T> _event;

  int _fireCount = 0;

  /// Creates an [EventRecorder] that immediately starts recording firings
  /// of [event].
  EventRecorder(this._event) {
    _event.addListener(_record);
  }

  void _record() {
    _fireCount++;
    final value = _event.value;
    if (value != null) {
      values.add(value);
    }
  }

  /// Whether the event has fired at least once.
  ///
  /// Unlike checking `values.isNotEmpty`, this correctly reports `true` for
  /// [ViewModelEvent<void>] events that fire with a `null` payload.
  bool get fired => _fireCount > 0;

  /// The number of times the event has fired.
  ///
  /// For [ViewModelEvent<void>] events, this tracks the fire count even
  /// though `null` payloads are not added to [values].
  int get count => _fireCount;

  /// The most recently fired value.
  ///
  /// Throws [StateError] if the event has not fired.
  T get latest {
    if (values.isEmpty) {
      throw StateError('Event has not fired yet.');
    }
    return values.last;
  }

  /// The first fired value.
  ///
  /// Throws [StateError] if the event has not fired.
  T get first {
    if (values.isEmpty) {
      throw StateError('Event has not fired yet.');
    }
    return values.first;
  }

  /// Clears the recorded history and resets the fire count.
  void clear() {
    values.clear();
    _fireCount = 0;
  }

  /// Stops recording and removes the listener.
  void dispose() {
    _event.removeListener(_record);
  }
}

/// Records all firings of a [SignalEvent] for test assertions.
///
/// Since [SignalEvent]s carry no payload, this only tracks the fire count.
///
/// ### Example
///
/// ```dart
/// final recorder = SignalRecorder(vm.closeDialogEvent);
/// await vm.performAction();
///
/// expect(recorder.fired, isTrue);
/// expect(recorder.count, 1);
///
/// recorder.dispose();
/// ```
class SignalRecorder {
  /// The number of times the signal has fired.
  int count = 0;

  final SignalEvent _event;

  /// Creates a [SignalRecorder] that immediately starts recording firings
  /// of [event].
  SignalRecorder(this._event) {
    _event.addListener(_record);
  }

  void _record() {
    if (_event.fired) {
      count++;
    }
  }

  /// Whether the signal has fired at least once.
  bool get fired => count > 0;

  /// Resets the fire count to zero.
  void clear() => count = 0;

  /// Stops recording and removes the listener.
  void dispose() {
    _event.removeListener(_record);
  }
}
