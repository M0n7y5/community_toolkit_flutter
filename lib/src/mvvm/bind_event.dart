import 'package:flutter/widgets.dart';

import 'view_model_event.dart';

/// A widget that listens to a [ViewModelEvent] and calls a handler when
/// the event fires.
///
/// Unlike [Bind], this widget does not rebuild its child. Instead, it
/// executes an imperative [handler] callback — perfect for side effects
/// like showing SnackBars, navigating, or opening dialogs.
///
/// The [child] widget is rendered as-is and never rebuilt by this widget.
///
/// ### Example
///
/// ```dart
/// BindEvent<String>(
///   event: viewModel.showError,
///   handler: (context, message) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(message)),
///     );
///   },
///   child: MyContentWidget(),
/// )
/// ```
class BindEvent<T> extends StatefulWidget {
  /// The [ViewModelEvent] to listen to.
  final ViewModelEvent<T> event;

  /// The callback to execute when the [event] fires.
  ///
  /// Receives the current [BuildContext] and the event's [value].
  /// The value is guaranteed to be non-null when this is called.
  final void Function(BuildContext context, T value) handler;

  /// The child widget to render. This widget is never rebuilt by [BindEvent].
  final Widget child;

  const BindEvent({
    required this.event,
    required this.handler,
    required this.child,
    super.key,
  });

  @override
  State<BindEvent<T>> createState() => _BindEventState<T>();
}

class _BindEventState<T> extends State<BindEvent<T>> {
  @override
  void initState() {
    super.initState();
    widget.event.addListener(_onEvent);
  }

  @override
  void didUpdateWidget(covariant BindEvent<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != oldWidget.event) {
      oldWidget.event.removeListener(_onEvent);
      widget.event.addListener(_onEvent);
    }
  }

  void _onEvent() {
    final value = widget.event.value;
    if (value != null) {
      widget.handler(context, value);
    }
  }

  @override
  void dispose() {
    widget.event.removeListener(_onEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A widget that listens to a [SignalEvent] and calls a handler when
/// the event fires.
///
/// This is the counterpart to [BindEvent] for events that carry no data.
///
/// ### Example
///
/// ```dart
/// BindSignalEvent(
///   event: viewModel.closeDialog,
///   handler: (context) => Navigator.of(context).pop(),
///   child: MyDialogContent(),
/// )
/// ```
class BindSignalEvent extends StatefulWidget {
  /// The [SignalEvent] to listen to.
  final SignalEvent event;

  /// The callback to execute when the [event] fires.
  final void Function(BuildContext context) handler;

  /// The child widget to render. This widget is never rebuilt.
  final Widget child;

  const BindSignalEvent({
    required this.event,
    required this.handler,
    required this.child,
    super.key,
  });

  @override
  State<BindSignalEvent> createState() => _BindSignalEventState();
}

class _BindSignalEventState extends State<BindSignalEvent> {
  @override
  void initState() {
    super.initState();
    widget.event.addListener(_onEvent);
  }

  @override
  void didUpdateWidget(covariant BindSignalEvent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != oldWidget.event) {
      oldWidget.event.removeListener(_onEvent);
      widget.event.addListener(_onEvent);
    }
  }

  void _onEvent() {
    if (widget.event.fired) {
      widget.handler(context);
    }
  }

  @override
  void dispose() {
    widget.event.removeListener(_onEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
