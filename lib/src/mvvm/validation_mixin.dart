import 'package:flutter/foundation.dart';

import 'base_view_model.dart';

/// A mixin that adds field-level validation support to a [BaseViewModel].
///
/// Inspired by .NET CommunityToolkit's `ObservableValidator`. Provides a
/// reactive [isValidNotifier] that can be wired into [RelayCommand.canExecute]
/// and [RelayCommand.listenables] for automatic button enable/disable.
///
/// ### Example
///
/// ```dart
/// class LoginViewModel extends BaseViewModel with ValidationMixin {
///   late final email = notifier('');
///   late final password = notifier('');
///
///   late final loginCommand = command.untyped(
///     executeAsync: _login,
///     canExecute: () => isValid,
///     listenables: [isValidNotifier],
///   );
///
///   void validateEmail(String value) {
///     if (value.isEmpty) {
///       setFieldError('email', 'Email is required');
///     } else if (!value.contains('@')) {
///       setFieldError('email', 'Invalid email');
///     } else {
///       clearFieldError('email');
///     }
///   }
///
///   void validatePassword(String value) {
///     if (value.length < 6) {
///       setFieldError('password', 'Must be at least 6 characters');
///     } else {
///       clearFieldError('password');
///     }
///   }
/// }
/// ```
///
/// In the view, use [getFieldError] to show inline error messages:
///
/// ```dart
/// Bind<bool>(
///   notifier: vm.isValidNotifier,
///   builder: (_) => TextField(
///     onChanged: (v) {
///       vm.email.value = v;
///       vm.validateEmail(v);
///     },
///     decoration: InputDecoration(
///       errorText: vm.getFieldError('email'),
///     ),
///   ),
/// )
/// ```
mixin ValidationMixin on BaseViewModel {
  final Map<String, String> _fieldErrors = {};

  /// A notifier that is `true` when all fields are valid (no errors).
  ///
  /// Wire this into [RelayCommand.listenables] to auto-update
  /// `canExecute` when validation state changes.
  late final ValueNotifier<bool> isValidNotifier = notifier(true);

  /// Whether all fields are currently valid.
  bool get isValid => _fieldErrors.isEmpty;

  /// Returns the current error for [field], or `null` if valid.
  String? getFieldError(String field) => _fieldErrors[field];

  /// Returns all current field errors as an unmodifiable map.
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  /// Sets an [error] for [field] and updates [isValidNotifier].
  void setFieldError(String field, String error) {
    _fieldErrors[field] = error;
    isValidNotifier.value = false;
  }

  /// Clears the error for [field] and updates [isValidNotifier].
  void clearFieldError(String field) {
    _fieldErrors.remove(field);
    isValidNotifier.value = _fieldErrors.isEmpty;
  }

  /// Clears all field errors and sets [isValidNotifier] to `true`.
  void clearAllErrors() {
    _fieldErrors.clear();
    isValidNotifier.value = true;
  }

  /// Validates a [field] with [value] using a list of [validators].
  ///
  /// Each validator returns an error string or `null` if valid. The first
  /// non-null error wins.
  ///
  /// ```dart
  /// validateField('email', email.value, [
  ///   (v) => v.isEmpty ? 'Required' : null,
  ///   (v) => !v.contains('@') ? 'Invalid format' : null,
  /// ]);
  /// ```
  void validateField<T>(
    String field,
    T value,
    List<String? Function(T value)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        setFieldError(field, error);
        return;
      }
    }
    clearFieldError(field);
  }
}
