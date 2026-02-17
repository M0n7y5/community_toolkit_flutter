import 'package:flutter/material.dart';
import 'relay_command.dart';

/// A builder function that receives the state from a [BindCommand] and returns a widget.
///
/// - `onPressed`: The callback to trigger the command's execution. It will be `null`
///   if the command's `canExecute` returns false.
/// - `child`: The constant child widget passed to the [BindCommand].
/// - `isExecuting`: A boolean flag that is true while the command is executing.
typedef BindCommandBuilder =
    Widget Function(VoidCallback? onPressed, Widget child, bool isExecuting);

/// A widget that connects a [RelayCommand] to a UI element.
///
/// It listens to the command and uses a builder function to construct the UI,
/// providing the `onPressed` callback, the original `child`, and the
/// command's current `isExecuting` state.
class BindCommand<T> extends StatelessWidget {
  /// Creates a binding for a [RelayCommand] that takes a parameter.
  ///
  /// - [command]: The [RelayCommand<T>] to bind to.
  /// - [commandParameter]: The parameter of type [T] to pass to the command's
  ///   `execute` and `canExecute` methods.
  /// - [child]: A widget that is passed to the [builder] and can be used in your UI.
  ///   This is a performance optimization; the child is constructed once and reused.
  /// - [builder]: A function that builds the UI. It receives `onPressed` (which
  ///   will be null if the command cannot execute), the `child` widget, and
  ///   an `isExecuting` flag.
  factory BindCommand({
    required RelayCommand<T> command,
    required Widget child,
    required BindCommandBuilder builder,
    Key? key,
    T? commandParameter,
  }) => BindCommand<T>._(
    key: key,
    command: command,
    commandParameter: commandParameter,
    builder: builder,
    child: child,
  );

  const BindCommand._({
    required RelayCommand<T> command,
    required Widget child,
    required BindCommandBuilder builder,
    super.key,
    T? commandParameter,
  }) : _command = command,
       _child = child,
       _builder = builder,
       _commandParameter = commandParameter;

  /// Creates a binding for a [RelayCommand] that does not take a parameter.
  ///
  /// See the default constructor for parameter details.
  static BindCommand<void> untyped({
    required RelayCommand<void> command,
    required Widget child,
    required BindCommandBuilder builder,
    Key? key,
  }) => BindCommand<void>._(
    key: key,
    command: command,
    builder: builder,
    child: child,
  );
  final RelayCommand<T> _command;
  final T? _commandParameter;
  final Widget _child;
  final BindCommandBuilder _builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _command,
    builder: (context, _) {
      VoidCallback? onPressed;
      if (_command.canExecute(_commandParameter)) {
        onPressed = () => _command.execute(_commandParameter);
      }

      return _builder(onPressed, _child, _command.executingNotifier.value);
    },
  );
}
