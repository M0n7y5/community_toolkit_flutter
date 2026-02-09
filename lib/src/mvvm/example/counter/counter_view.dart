import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../base_view_model.dart';
import '../../bind.dart';
import '../../bind_command.dart';
import '../../relay_command.dart';

class CounterViewModel extends BaseViewModel {
  CounterViewModel() {
    // Initialize the reset command first so its state can be used by others.
    resetCounterCommand = autoDispose(
      RelayCommand.untyped(
        executeAsync: _resetCounter,
        listenables: [countNotifier],
      ),
    );

    // Now, other commands can listen to the reset command's execution state.
    incrementCommand = autoDispose(
      RelayCommand.syncUntyped(
        execute: _increment,
        canExecute: _canIncrement,
        listenables: [countNotifier, resetCounterCommand.executingNotifier],
        errorNotifier: errorNotifier,
      ),
    );

    decrementCommand = autoDispose(
      RelayCommand.syncUntyped(
        execute: () => countNotifier.value--,
        canExecute: () =>
            !resetCounterCommand.executingNotifier.value &&
            countNotifier.value > 0,
        listenables: [countNotifier, resetCounterCommand.executingNotifier],
      ),
    );

    addValueCommand = autoDispose(
      RelayCommand<int>.sync(
        execute: (value) => countNotifier.value += value,
        canExecute: (value) =>
            !resetCounterCommand.executingNotifier.value &&
            countNotifier.value + value >= 0 &&
            countNotifier.value + value <= 10,
        listenables: [countNotifier, resetCounterCommand.executingNotifier],
      ),
    );

    errorCommand = autoDispose(
      RelayCommand.syncUntyped(
        execute: () => throw Exception('This is a test error!'),
        canExecute: () => !resetCounterCommand.executingNotifier.value,
        listenables: [resetCounterCommand.executingNotifier],
        errorNotifier: errorNotifier,
      ),
    );
  }
  late final ValueNotifier<int> countNotifier = autoDispose(ValueNotifier(0));
  late final ValueNotifier<String?> errorNotifier = autoDispose(
    ValueNotifier(null),
  );

  late final RelayCommand<void> incrementCommand;
  late final RelayCommand<void> decrementCommand;
  late final RelayCommand<int> addValueCommand;
  late final RelayCommand<void> resetCounterCommand;
  late final RelayCommand<void> errorCommand;

  // Method referenced by incrementCommand
  void _increment() {
    // The canExecute check is handled by the RelayCommand,
    // so we can directly execute the logic here.
    countNotifier.value++;
    errorNotifier.value = null;
  }

  // Method referenced by incrementCommand
  bool _canIncrement() {
    if (resetCounterCommand.executingNotifier.value) {
      return false;
    }
    if (countNotifier.value >= 10) {
      return false;
    }
    return true;
  }

  // Async method for reset command
  Future<void> _resetCounter() async {
    errorNotifier.value = null; // Clear previous errors on reset
    await Future<void>.delayed(const Duration(seconds: 2));
    countNotifier.value = 0;
  }

  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final CounterViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = CounterViewModel();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Bind(
      notifier: vm.loadingNotifier,
      builder: (isLoading) {
        if (isLoading) {
          return const CircularProgressIndicator();
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Bind<String?>(
              notifier: vm.errorNotifier,
              builder: (error) => error != null
                  ? Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Bind<int>(
              notifier: vm.countNotifier,
              builder: (count) =>
                  Text('Count: $count', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 16),
            BindCommand<void>.untyped(
              command: vm.incrementCommand,
              child: const Text('Increment'),
              builder: (onPressed, child, isExecuting) =>
                  ElevatedButton(onPressed: onPressed, child: child),
            ),
            const SizedBox(height: 8),
            BindCommand<void>.untyped(
              command: vm.decrementCommand,
              child: const Text('Decrement'),
              builder: (onPressed, child, isExecuting) =>
                  ElevatedButton(onPressed: onPressed, child: child),
            ),
            const SizedBox(height: 8),
            BindCommand<int>(
              command: vm.addValueCommand,
              commandParameter: 2,
              child: const Text('Add 2'),
              builder: (onPressed, child, isExecuting) =>
                  ElevatedButton(onPressed: onPressed, child: child),
            ),
            const SizedBox(height: 8),
            // Example of an async command with the flexible builder
            BindCommand<void>.untyped(
              command: vm.resetCounterCommand,
              child: const Text('Reset'),
              builder: (onPressed, child, isExecuting) {
                if (isExecuting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return ElevatedButton(onPressed: onPressed, child: child);
              },
            ),
            const SizedBox(height: 8),
            BindCommand<void>.untyped(
              command: vm.errorCommand,
              child: const Text('Throw Error'),
              builder: (onPressed, child, isExecuting) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: onPressed,
                child: child,
              ),
            ),
          ],
        );
      },
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CounterViewModel>('vm', vm));
  }
}
