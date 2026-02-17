import 'package:flutter/foundation.dart';

import 'base_view_model.dart';

/// A [ValueListenable] that always notifies listeners on [value] set,
/// even when the new value is equal to the old value.
///
/// Unlike [ValueNotifier], which short-circuits when the new value is
/// `==` to the old value, this class always stores the new value and
/// fires notifications.
///
/// Use this when domain objects have coarse equality (e.g., comparing
/// only an ID) but other fields may have changed and listeners need
/// to be notified.
///
/// ```dart
/// // In a ViewModel:
/// late final entityNotifier = forceNotifier<PluginEntity?>(null);
///
/// // This always notifies, even if entity.id == old.id:
/// entityNotifier.value = enrichedEntity;
/// ```
class ForceValueNotifier<T> extends ChangeNotifier
    implements ValueListenable<T> {
  T _value;

  /// Creates a [ForceValueNotifier] with the given initial [value].
  ForceValueNotifier(this._value);

  @override
  T get value => _value;

  /// Sets the value and always notifies listeners, even when
  /// [newValue] is equal to the current value.
  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }
}

/// Extensions on [ValueNotifier] for common operations.
extension ValueNotifierExtensions<T> on ValueNotifier<T> {
  /// Updates the current value by applying [updater] and notifying listeners.
  ///
  /// This is a convenience for read-modify-write operations:
  ///
  /// ```dart
  /// // Before:
  /// itemsNotifier.value = [...itemsNotifier.value, newItem];
  ///
  /// // After:
  /// itemsNotifier.update((items) => [...items, newItem]);
  /// ```
  void update(T Function(T current) updater) {
    value = updater(value);
  }
}

/// Extension on [BaseViewModel] to create auto-disposed
/// [ForceValueNotifier] instances.
extension ForceNotifierViewModelExtension on BaseViewModel {
  /// Creates an auto-disposed [ForceValueNotifier] that always notifies
  /// listeners on set, bypassing the equality check.
  ///
  /// ```dart
  /// late final entityNotifier = forceNotifier<PluginEntity?>(null);
  /// ```
  ForceValueNotifier<T> forceNotifier<T>(T initialValue) =>
      autoDispose(ForceValueNotifier<T>(initialValue));
}
