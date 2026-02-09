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

/// A widget that rebuilds its child when a [ValueListenable] changes.
///
/// This is a lightweight and efficient way to bind a piece of UI to a specific
/// value in a ViewModel. It is a simplified wrapper around [ValueListenableBuilder].
class Bind<T> extends StatelessWidget {
  /// The [ValueListenable] to listen to.
  final ValueListenable<T> notifier;

  /// A builder function that is called whenever the [notifier]'s value changes.
  final ValueBuilder<T> builder;

  const Bind({required this.notifier, required this.builder, super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<T>(
    valueListenable: notifier,
    builder: (context, value, child) => builder(value),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueListenable<T>>('notifier', notifier))
      ..add(ObjectFlagProperty<ValueBuilder<T>>.has('builder', builder));
  }
}

/// A widget that rebuilds its child when two [ValueListenable]s change.
///
/// This is a lightweight and efficient way to bind a piece of UI to two specific
/// values in a ViewModel. It uses nested [ValueListenableBuilder] widgets.
class Bind2<A, B> extends StatelessWidget {
  /// The first [ValueListenable] to listen to.
  final ValueListenable<A> notifier1;

  /// The second [ValueListenable] to listen to.
  final ValueListenable<B> notifier2;

  /// A builder function that is called whenever either [notifier1] or [notifier2]'s value changes.
  final ValueBuilder2<A, B> builder;

  const Bind2({
    required this.notifier1,
    required this.notifier2,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: notifier1,
    builder: (context, value1, child) => ValueListenableBuilder<B>(
      valueListenable: notifier2,
      builder: (context, value2, child) => builder(value1, value2),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ValueListenable<A>>('notifier1', notifier1))
      ..add(DiagnosticsProperty<ValueListenable<B>>('notifier2', notifier2))
      ..add(ObjectFlagProperty<ValueBuilder2<A, B>>.has('builder', builder));
  }
}

/// A widget that rebuilds its child when three [ValueListenable]s change.
///
/// This is a lightweight and efficient way to bind a piece of UI to three specific
/// values in a ViewModel. It uses nested [ValueListenableBuilder] widgets.
class Bind3<A, B, C> extends StatelessWidget {
  /// The first [ValueListenable] to listen to.
  final ValueListenable<A> notifier1;

  /// The second [ValueListenable] to listen to.
  final ValueListenable<B> notifier2;

  /// The third [ValueListenable] to listen to.
  final ValueListenable<C> notifier3;

  /// A builder function that is called whenever any of the notifiers' values change.
  final ValueBuilder3<A, B, C> builder;

  const Bind3({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: notifier1,
    builder: (context, value1, child) => ValueListenableBuilder<B>(
      valueListenable: notifier2,
      builder: (context, value2, child) => ValueListenableBuilder<C>(
        valueListenable: notifier3,
        builder: (context, value3, child) => builder(value1, value2, value3),
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
      ..add(ObjectFlagProperty<ValueBuilder3<A, B, C>>.has('builder', builder));
  }
}

/// A widget that rebuilds its child when four [ValueListenable]s change.
///
/// This is a lightweight and efficient way to bind a piece of UI to four specific
/// values in a ViewModel. It uses nested [ValueListenableBuilder] widgets.
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
  final ValueBuilder4<A, B, C, D> builder;

  const Bind4({
    required this.notifier1,
    required this.notifier2,
    required this.notifier3,
    required this.notifier4,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: notifier1,
    builder: (context, value1, child) => ValueListenableBuilder<B>(
      valueListenable: notifier2,
      builder: (context, value2, child) => ValueListenableBuilder<C>(
        valueListenable: notifier3,
        builder: (context, value3, child) => ValueListenableBuilder<D>(
          valueListenable: notifier4,
          builder: (context, value4, child) =>
              builder(value1, value2, value3, value4),
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
        ObjectFlagProperty<ValueBuilder4<A, B, C, D>>.has('builder', builder),
      );
  }
}
