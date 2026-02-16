import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bind.dart';

/// A widget that listens to a [ValueListenable] and automatically pauses
/// updates when the widget is not visible (based on [TickerMode]).
///
/// When the widget becomes invisible (e.g. inside a non-active tab),
/// changes to the [notifier] are deferred. When the widget becomes visible
/// again, it catches up to the latest value in a single rebuild.
///
/// This is a performance optimisation for apps with tab-based navigation
/// or screens that remain in the widget tree but are not currently displayed.
///
/// ### Example
///
/// ```dart
/// BindPauseable<int>(
///   notifier: vm.counter,
///   builder: (count) => Text('$count'),
/// )
/// ```
class BindPauseable<T> extends StatefulWidget {
  /// The [ValueListenable] to listen to.
  final ValueListenable<T> notifier;

  /// A builder function called with the latest value when the widget is
  /// visible, or the last known value while paused.
  final ValueBuilder<T> builder;

  /// Creates a [BindPauseable] widget.
  const BindPauseable({
    required this.notifier,
    required this.builder,
    super.key,
  });

  @override
  State<BindPauseable<T>> createState() => _BindPauseableState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<ValueListenable<T>>('notifier', notifier),
    );
  }
}

class _BindPauseableState<T> extends State<BindPauseable<T>> {
  late T _value;
  bool _stale = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _value = widget.notifier.value;
    widget.notifier.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasActive = _active;
    _active = TickerMode.valuesOf(context).enabled;
    if (!wasActive && _active && _stale) {
      // Becoming visible again — catch up to latest value.
      // The framework already schedules a rebuild after
      // didChangeDependencies, so updating _value is sufficient.
      _value = widget.notifier.value;
      _stale = false;
    }
  }

  @override
  void didUpdateWidget(covariant BindPauseable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifier != oldWidget.notifier) {
      oldWidget.notifier.removeListener(_onChanged);
      widget.notifier.addListener(_onChanged);
      _value = widget.notifier.value;
      _stale = false;
    }
  }

  void _onChanged() {
    if (_active) {
      setState(() {
        _value = widget.notifier.value;
      });
    } else {
      _stale = true;
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_value);
}
