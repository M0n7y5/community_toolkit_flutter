import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A builder function that receives a value of type [T] and returns a widget.
typedef ValueBuilder<T> = Widget Function(T value);

/// A builder function that receives values of type [A] and [B] and returns a widget.
typedef ValueBuilder2<A, B> = Widget Function(A value1, B value2);

/// A builder function that receives values of type [A], [B], and [C] and returns a widget.
typedef ValueBuilder3<A, B, C> = Widget Function(A value1, B value2, C value3);

/// A builder function that receives values of type [A], [B], [C], and [D] and returns a widget.
typedef ValueBuilder4<A, B, C, D> =
    Widget Function(A value1, B value2, C value3, D value4);

/// A builder function that receives a value of type [T] and an optional
/// static [child] widget, and returns a widget.
typedef ValueChildBuilder<T> = Widget Function(T value, Widget? child);

/// A builder function that receives values of type [A] and [B] and an optional
/// static [child] widget, and returns a widget.
typedef ValueChildBuilder2<A, B> =
    Widget Function(A value1, B value2, Widget? child);

/// A builder function that receives values of type [A], [B], and [C] and an
/// optional static [child] widget, and returns a widget.
typedef ValueChildBuilder3<A, B, C> =
    Widget Function(A value1, B value2, C value3, Widget? child);

/// A builder function that receives values of type [A], [B], [C], and [D] and
/// an optional static [child] widget, and returns a widget.
typedef ValueChildBuilder4<A, B, C, D> =
    Widget Function(A value1, B value2, C value3, D value4, Widget? child);

/// A widget that rebuilds its child when a [ValueListenable] changes.
///
/// This is a lightweight and efficient way to bind a piece of UI to a specific
/// value in a ViewModel. It is a simplified wrapper around
/// [ValueListenableBuilder].
///
/// An optional [child] widget can be provided. This widget is built once and
/// passed through to the [builder] on every rebuild, avoiding unnecessary
/// widget reconstruction for static subtrees.
///
/// ### Example
///
/// ```dart
/// // Simple usage:
/// Bind<int>(
///   notifier: viewModel.counterNotifier,
///   builder: (count) => Text('$count'),
/// )
///
/// // With static child for performance:
/// Bind<int>.child(
///   notifier: viewModel.counterNotifier,
///   child: const Icon(Icons.star),
///   builder: (count, child) => Row(
///     children: [child!, Text('$count')],
///   ),
/// )
/// ```
class Bind<T> extends StatelessWidget {
  /// The [ValueListenable] to listen to.
  final ValueListenable<T> notifier;

  /// A builder function that is called whenever the [notifier]'s value changes.
  final ValueChildBuilder<T> _builder;

  /// An optional static child widget that does not depend on the notifier's
  /// value. It is built once and passed to the [builder] on every rebuild.
  final Widget? child;

  /// Creates a [Bind] widget without a static child.
  Bind({required this.notifier, required ValueBuilder<T> builder, super.key})
    : _builder = ((value, _) => builder(value)),
      child = null;

  /// Creates a [Bind] widget with a static [child] that is passed through
  /// to the [builder] without being rebuilt.
  const Bind.child({
    required this.notifier,
    required ValueChildBuilder<T> builder,
    required this.child,
    super.key,
  }) : _builder = builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<T>(
    valueListenable: notifier,
    child: child,
    builder: (context, value, child) => _builder(value, child),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueListenable<T>>('notifier', notifier))
      ..add(ObjectFlagProperty<ValueChildBuilder<T>>.has('builder', _builder));
  }
}

/// A widget that rebuilds its child when two [ValueListenable]s change.
///
/// See [Bind] for general usage. This variant listens to two notifiers
/// simultaneously and passes both values to the builder.
class Bind2<A, B> extends StatelessWidget {
  /// The first [ValueListenable] to listen to.
  final ValueListenable<A> notifier1;

  /// The second [ValueListenable] to listen to.
  final ValueListenable<B> notifier2;

  /// A builder function that is called whenever either notifier's value changes.
  final ValueChildBuilder2<A, B> _builder;

  /// An optional static child widget.
  final Widget? child;

  /// Creates a [Bind2] widget without a static child.
  Bind2({
    required this.notifier1,
    required this.notifier2,
    required ValueBuilder2<A, B> builder,
    super.key,
  }) : _builder = ((v1, v2, _) => builder(v1, v2)),
       child = null;

  /// Creates a [Bind2] widget with a static [child].
  const Bind2.child({
    required this.notifier1,
    required this.notifier2,
    required ValueChildBuilder2<A, B> builder,
    required this.child,
    super.key,
  }) : _builder = builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: notifier1,
    child: child,
    builder: (context, value1, child) => ValueListenableBuilder<B>(
      valueListenable: notifier2,
      child: child,
      builder: (context, value2, child) => _builder(value1, value2, child),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueListenable<A>>('notifier1', notifier1))
      ..add(DiagnosticsProperty<ValueListenable<B>>('notifier2', notifier2))
      ..add(
        ObjectFlagProperty<ValueChildBuilder2<A, B>>.has('builder', _builder),
      );
  }
}

/// A widget that rebuilds its child when three [ValueListenable]s change.
///
/// See [Bind] for general usage. This variant listens to three notifiers
/// simultaneously and passes all three values to the builder.
class Bind3<A, B, C> extends StatelessWidget {
  /// The first [ValueListenable] to listen to.
  final ValueListenable<A> notifier1;

  /// The second [ValueListenable] to listen to.
  final ValueListenable<B> notifier2;

  /// The third [ValueListenable] to listen to.
  final ValueListenable<C> notifier3;

  /// A builder function that is called whenever any of the notifiers' values change.
  final ValueChildBuilder3<A, B, C> _builder;

  /// An optional static child widget.
  final Widget? child;

  /// Creates a [Bind3] widget without a static child.
  Bind3({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required ValueBuilder3<A, B, C> builder,
    super.key,
  }) : _builder = ((v1, v2, v3, _) => builder(v1, v2, v3)),
       child = null;

  /// Creates a [Bind3] widget with a static [child].
  const Bind3.child({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required ValueChildBuilder3<A, B, C> builder,
    required this.child,
    super.key,
  }) : _builder = builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: notifier1,
    child: child,
    builder: (context, value1, child) => ValueListenableBuilder<B>(
      valueListenable: notifier2,
      child: child,
      builder: (context, value2, child) => ValueListenableBuilder<C>(
        valueListenable: notifier3,
        child: child,
        builder: (context, value3, child) =>
            _builder(value1, value2, value3, child),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueListenable<A>>('notifier1', notifier1))
      ..add(DiagnosticsProperty<ValueListenable<B>>('notifier2', notifier2))
      ..add(DiagnosticsProperty<ValueListenable<C>>('notifier3', notifier3))
      ..add(
        ObjectFlagProperty<ValueChildBuilder3<A, B, C>>.has(
          'builder',
          _builder,
        ),
      );
  }
}

/// A widget that rebuilds its child when four [ValueListenable]s change.
///
/// See [Bind] for general usage. This variant listens to four notifiers
/// simultaneously and passes all four values to the builder.
class Bind4<A, B, C, D> extends StatelessWidget {
  /// The first [ValueListenable] to listen to.
  final ValueListenable<A> notifier1;

  /// The second [ValueListenable] to listen to.
  final ValueListenable<B> notifier2;

  /// The third [ValueListenable] to listen to.
  final ValueListenable<C> notifier3;

  /// The fourth [ValueListenable] to listen to.
  final ValueListenable<D> notifier4;

  /// A builder function that is called whenever any of the notifiers' values change.
  final ValueChildBuilder4<A, B, C, D> _builder;

  /// An optional static child widget.
  final Widget? child;

  /// Creates a [Bind4] widget without a static child.
  Bind4({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.notifier4,
    required ValueBuilder4<A, B, C, D> builder,
    super.key,
  }) : _builder = ((v1, v2, v3, v4, _) => builder(v1, v2, v3, v4)),
       child = null;

  /// Creates a [Bind4] widget with a static [child].
  const Bind4.child({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.notifier4,
    required ValueChildBuilder4<A, B, C, D> builder,
    required this.child,
    super.key,
  }) : _builder = builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: notifier1,
    child: child,
    builder: (context, value1, child) => ValueListenableBuilder<B>(
      valueListenable: notifier2,
      child: child,
      builder: (context, value2, child) => ValueListenableBuilder<C>(
        valueListenable: notifier3,
        child: child,
        builder: (context, value3, child) => ValueListenableBuilder<D>(
          valueListenable: notifier4,
          child: child,
          builder: (context, value4, child) =>
              _builder(value1, value2, value3, value4, child),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueListenable<A>>('notifier1', notifier1))
      ..add(DiagnosticsProperty<ValueListenable<B>>('notifier2', notifier2))
      ..add(DiagnosticsProperty<ValueListenable<C>>('notifier3', notifier3))
      ..add(DiagnosticsProperty<ValueListenable<D>>('notifier4', notifier4))
      ..add(
        ObjectFlagProperty<ValueChildBuilder4<A, B, C, D>>.has(
          'builder',
          _builder,
        ),
      );
  }
}
