import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'bind.dart'; // For reusing ValueBuilder

/// A function that selects a value of type [S] from a
/// source object of type [T].
typedef ValueSelector<T, S> = S Function(T value);

/// A widget that listens to a [ValueNotifier] and rebuilds only when a
/// selected part of its value changes.
///
/// This is a performance optimization widget that helps to prevent unnecessary
/// rebuilds of a widget tree when only a small part of a complex
/// object has changed.
///
/// ---
///
/// ### Example
///
/// Given a `ValueNotifier<User>` where `User` has `name` and `age` properties:
///
/// ```dart
/// BindSelector<User, String>(
///   notifier: userNotifier,
///   selector: (user) => user.name, // Only watch the name
///   builder: (name) => Text(name), // This Text only rebuilds when the name changes
/// );
/// ```
class BindSelector<T, S> extends StatefulWidget {
  const BindSelector({
    required this.notifier,
    required this.selector,
    required this.builder,
    super.key,
  });

  /// The source [ValueNotifier] to listen to.
  final ValueNotifier<T> notifier;

  /// A function that extracts the value to watch from the notifier's value.
  ///
  /// The [builder] will only be called when the value returned by this
  /// function changes.
  final ValueSelector<T, S> selector;

  /// A builder function that is called when the selected value changes.
  ///
  /// It receives the `value` returned by the [selector] and should
  /// return a widget.
  final ValueBuilder<S> builder;

  @override
  State<BindSelector<T, S>> createState() => _BindSelectorState<T, S>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueNotifier<T>>('notifier', notifier))
      ..add(ObjectFlagProperty<ValueSelector<T, S>>.has('selector', selector))
      ..add(ObjectFlagProperty<ValueBuilder<S>>.has('builder', builder));
  }
}

class _BindSelectorState<T, S> extends State<BindSelector<T, S>> {
  late S _selectedValue;
  late final ValueNotifier<S> _proxyNotifier;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.notifier.value);
    _proxyNotifier = ValueNotifier<S>(_selectedValue);
    widget.notifier.addListener(_updateSelectedValue);
  }

  @override
  void didUpdateWidget(covariant BindSelector<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifier != oldWidget.notifier) {
      oldWidget.notifier.removeListener(_updateSelectedValue);
      widget.notifier.addListener(_updateSelectedValue);
      _updateSelectedValue();
    }
  }

  void _updateSelectedValue() {
    final newSelectedValue = widget.selector(widget.notifier.value);
    if (_selectedValue != newSelectedValue) {
      _selectedValue = newSelectedValue;
      _proxyNotifier.value = _selectedValue;
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_updateSelectedValue);
    _proxyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<S>(
    valueListenable: _proxyNotifier,
    builder: (context, value, child) => widget.builder(value),
  );
}
