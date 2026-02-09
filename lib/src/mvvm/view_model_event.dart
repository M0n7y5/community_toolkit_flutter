import 'package:flutter/foundation.dart';

/// A one-shot event emitter for ViewModel-to-View communication.
///
/// Unlike [ValueNotifier], a [ViewModelEvent] does not hold state. It fires
/// once and is consumed by listeners. This is ideal for transient UI actions
/// that should happen exactly once in response to a ViewModel operation:
///
/// - Showing a SnackBar or toast
/// - Navigating to another screen
/// - Opening a dialog or bottom sheet
/// - Scrolling to a position
///
/// [ViewModelEvent] extends [ChangeNotifier] so it can be registered with
/// [BaseViewModel.autoDispose] for automatic lifecycle management.
///
/// ### Example (ViewModel)
///
/// ```dart
/// class DetailViewModel extends BaseViewModel {
///   late final showError = ViewModelEvent<String>();
///   late final navigate = ViewModelEvent<String>();
///
///   Future<void> _save() async {
///     try {
///       await _service.save();
///       navigate.fire('/success');
///     } catch (e) {
///       showError.fire(e.toString());
///     }
///   }
/// }
/// ```
///
/// ### Example (View — manual listener)
///
/// ```dart
/// @override
/// void onViewModelReady(DetailViewModel vm) {
///   vm.showError.addListener(() {
///     final message = vm.showError.value;
///     if (message != null) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(message)),
///       );
///     }
///   });
/// }
/// ```
///
/// See also [BindEvent] for a declarative widget-based approach.
class ViewModelEvent<T> extends ChangeNotifier {
  T? _value;

  /// The most recently fired event value.
  ///
  /// This is `null` before any event has been fired, and is reset to `null`
  /// after listeners are notified. Listeners should read this value
  /// synchronously in their callback.
  T? get value => _value;

  /// Fires the event with the given [value], notifying all listeners.
  ///
  /// The [value] is available to listeners during the notification callback
  /// via the [value] getter, and is reset to `null` afterward to prevent
  /// stale reads.
  void fire(T value) {
    _value = value;
    notifyListeners();
    _value = null;
  }
}

/// A [ViewModelEvent] that carries no data.
///
/// Use this when the event itself is the signal and no payload is needed.
///
/// ### Example
///
/// ```dart
/// late final closeDialog = SignalEvent();
///
/// void _onComplete() {
///   closeDialog.fire();
/// }
/// ```
class SignalEvent extends ChangeNotifier {
  bool _fired = false;

  /// Whether the event was just fired.
  ///
  /// This is `true` during the notification callback and reset to `false`
  /// afterward.
  bool get fired => _fired;

  /// Fires the event, notifying all listeners.
  void fire() {
    _fired = true;
    notifyListeners();
    _fired = false;
  }
}
