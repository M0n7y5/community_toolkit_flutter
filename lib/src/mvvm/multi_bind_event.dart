import 'package:flutter/widgets.dart';

import 'view_model_event.dart';

/// A handler entry that pairs a [ViewModelEvent] with its callback.
///
/// Used by [MultiBindEvent] to register multiple event listeners in a
/// single widget without deep nesting.
///
/// ```dart
/// EventHandler(vm.errorEvent, (ctx, msg) {
///   ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
/// })
/// ```
class EventHandler<T> {
  /// The event to listen to.
  final ViewModelEvent<T> event;

  /// The callback to execute when [event] fires.
  final void Function(BuildContext context, T value) handler;

  /// Creates an event handler pairing.
  const EventHandler(this.event, this.handler);
}

/// A handler entry for [SignalEvent]s (events with no payload).
///
/// Used by [MultiBindEvent] alongside [EventHandler] entries.
///
/// ```dart
/// SignalHandler(vm.closeDialog, (ctx) => Navigator.of(ctx).pop())
/// ```
class SignalHandler {
  /// The signal event to listen to.
  final SignalEvent event;

  /// The callback to execute when [event] fires.
  final void Function(BuildContext context) handler;

  /// Creates a signal handler pairing.
  const SignalHandler(this.event, this.handler);
}

/// A widget that listens to multiple [ViewModelEvent]s and [SignalEvent]s
/// without requiring deeply nested [BindEvent] wrappers.
///
/// The [child] is rendered as-is and never rebuilt by this widget.
///
/// ### Before
///
/// ```dart
/// BindEvent<String>(
///   event: vm.errorEvent,
///   handler: (ctx, msg) => showSnackBar(ctx, msg),
///   child: BindEvent<String>(
///     event: vm.successEvent,
///     handler: (ctx, msg) => showSnackBar(ctx, msg),
///     child: BindEvent<Playable>(
///       event: vm.navigateEvent,
///       handler: (ctx, p) => navigate(ctx, p),
///       child: Scaffold(...),
///     ),
///   ),
/// )
/// ```
///
/// ### After
///
/// ```dart
/// MultiBindEvent(
///   handlers: [
///     EventHandler(vm.errorEvent, (ctx, msg) => showSnackBar(ctx, msg)),
///     EventHandler(vm.successEvent, (ctx, msg) => showSnackBar(ctx, msg)),
///     EventHandler(vm.navigateEvent, (ctx, p) => navigate(ctx, p)),
///   ],
///   child: Scaffold(...),
/// )
/// ```
class MultiBindEvent extends StatefulWidget {
  /// The list of typed event handlers.
  final List<EventHandler<dynamic>> handlers;

  /// The list of signal event handlers (no payload).
  final List<SignalHandler> signalHandlers;

  /// The child widget to render. Never rebuilt by this widget.
  final Widget child;

  /// Creates a [MultiBindEvent] with typed [handlers] and optional
  /// [signalHandlers].
  const MultiBindEvent({
    required this.handlers,
    required this.child,
    this.signalHandlers = const [],
    super.key,
  });

  @override
  State<MultiBindEvent> createState() => _MultiBindEventState();
}

class _MultiBindEventState extends State<MultiBindEvent> {
  final _listenerCleanups = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _attachAll();
  }

  @override
  void didUpdateWidget(covariant MultiBindEvent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Simple identity check — if the lists changed, re-wire everything.
    if (!identical(widget.handlers, oldWidget.handlers) ||
        !identical(widget.signalHandlers, oldWidget.signalHandlers)) {
      _detachAll();
      _attachAll();
    }
  }

  void _attachAll() {
    for (final entry in widget.handlers) {
      _attachTyped(entry);
    }
    for (final entry in widget.signalHandlers) {
      _attachSignal(entry);
    }
  }

  void _attachTyped(EventHandler<dynamic> entry) {
    // The handler list erases EventHandler<String> to EventHandler<dynamic>,
    // but Dart function types are contravariant in parameters: accessing
    // .handler as (BuildContext, dynamic) → void when the runtime type is
    // (BuildContext, String) → void would throw a TypeError. Casting entry
    // to dynamic bypasses the static type check entirely.
    final dynamic e = entry;
    void listener() {
      final dynamic value = e.event.value;
      if (value != null) {
        e.handler(context, value);
      }
    }

    entry.event.addListener(listener);
    _listenerCleanups.add(() => entry.event.removeListener(listener));
  }

  void _attachSignal(SignalHandler entry) {
    void listener() {
      if (entry.event.fired) {
        entry.handler(context);
      }
    }

    entry.event.addListener(listener);
    _listenerCleanups.add(() => entry.event.removeListener(listener));
  }

  void _detachAll() {
    for (final cleanup in _listenerCleanups) {
      cleanup();
    }
    _listenerCleanups.clear();
  }

  @override
  void dispose() {
    _detachAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
