import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'async_state.dart';

/// A widget that binds to an [AsyncStateNotifier] and renders different
/// widgets for each state (loading, data, error).
///
/// This eliminates the boilerplate of writing `Bind<AsyncState<T>>` with
/// a manual `switch` expression for the three async states.
///
/// ### Example
///
/// ```dart
/// BindAsync<User>(
///   notifier: vm.userState,
///   loading: (progress) => CircularProgressIndicator(value: progress),
///   data: (user) => Text(user.name),
///   error: (message) => Text('Error: $message'),
/// )
/// ```
class BindAsync<T> extends StatelessWidget {
  /// The [AsyncStateNotifier] to listen to.
  final AsyncStateNotifier<T> notifier;

  /// Builder called when the state is [AsyncData].
  final Widget Function(T data) data;

  /// Builder called when the state is [AsyncError].
  final Widget Function(String message) error;

  /// Builder called when the state is [AsyncLoading].
  ///
  /// The [progress] parameter is non-null only when
  /// [AsyncStateNotifier.setProgress] has been called.
  final Widget Function(double? progress) loading;

  /// Creates a [BindAsync] widget with required builders for all three
  /// async states.
  const BindAsync({
    required this.notifier,
    required this.loading,
    required this.data,
    required this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AsyncState<T>>(
    valueListenable: notifier,
    builder: (context, state, _) => switch (state) {
      AsyncLoading<T>(:final progress) => loading(progress),
      AsyncData<T>(:final data) => this.data(data),
      AsyncError<T>(:final message) => error(message),
    },
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<AsyncStateNotifier<T>>('notifier', notifier),
    );
  }
}
