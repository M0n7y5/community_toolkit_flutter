/// Counter example — demonstrates:
///
/// - [BaseViewModel] with [notifier], [command] factory, [event]
/// - [AsyncStateNotifier] with sealed-class pattern matching
/// - [ViewModelStateMixin] for automatic lifecycle management
/// - [BindEvent] for one-shot error snackbars
/// - [BindCommand] for reactive button enable/disable
/// - [Bind] / [Bind2] for reactive UI
library;

import 'dart:async';

import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class CounterViewModel extends BaseViewModel {
  CounterViewModel() {
    countNotifier = notifier<int>(0);
    errorEvent = event<String>();

    /// Simulates an async operation that loads a random fact about the
    /// current count. Uses [AsyncStateNotifier] so the UI can pattern-match
    /// on loading / data / error.
    factState = asyncNotifier<String>();

    incrementCommand = command.syncUntyped(
      execute: _increment,
      canExecute: () => !resetCommand.isExecuting && countNotifier.value < 10,
      listenables: [countNotifier, resetCommand.executingNotifier],
    );

    decrementCommand = command.syncUntyped(
      execute: () => countNotifier.value--,
      canExecute: () => !resetCommand.isExecuting && countNotifier.value > 0,
      listenables: [countNotifier, resetCommand.executingNotifier],
    );

    addValueCommand = command.sync<int>(
      execute: (value) => countNotifier.value += value,
      canExecute: (value) =>
          !resetCommand.isExecuting &&
          countNotifier.value + value >= 0 &&
          countNotifier.value + value <= 10,
      listenables: [countNotifier, resetCommand.executingNotifier],
    );

    throwErrorCommand = command.syncUntyped(
      execute: () {
        errorEvent.fire('This is a test error!');
      },
    );
  }

  late final ValueNotifier<int> countNotifier;
  late final AsyncStateNotifier<String> factState;
  late final ViewModelEvent<String> errorEvent;

  // The reset command is declared first so other commands can reference
  // its executingNotifier for canExecute guards.
  late final RelayCommand<void> resetCommand = command.untyped(
    executeAsync: _resetCounter,
  );
  late final RelayCommand<void> incrementCommand;
  late final RelayCommand<void> decrementCommand;
  late final RelayCommand<int> addValueCommand;
  late final RelayCommand<void> throwErrorCommand;

  void _increment() {
    countNotifier.value++;
  }

  Future<void> _resetCounter() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    countNotifier.value = 0;
  }

  @override
  Future<void> init() async {
    // Demonstrate AsyncStateNotifier.execute — loads a "fact" on startup.
    await factState.execute(_loadFact);
  }

  Future<String> _loadFact() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return 'The counter starts at ${countNotifier.value}. '
        'You can count up to 10.';
  }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

/// Uses [ViewModelStateMixin] — no manual initState/dispose needed.
class _CounterViewState extends State<CounterView>
    with ViewModelStateMixin<CounterView, CounterViewModel> {
  @override
  CounterViewModel createViewModel() => CounterViewModel();

  @override
  Widget build(BuildContext context) => BindEvent<String>(
    event: vm.errorEvent,
    handler: (ctx, message) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    },
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- AsyncStateNotifier with pattern matching ---
            Bind<AsyncState<String>>(
              notifier: vm.factState,
              builder: (state) => switch (state) {
                AsyncLoading() => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
                AsyncError(:final message) => Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
                AsyncData(:final data) => Text(
                  data,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              },
            ),
            const SizedBox(height: 24),

            // --- Counter display ---
            Bind<int>(
              notifier: vm.countNotifier,
              builder: (count) =>
                  Text('Count: $count', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 16),

            // --- Increment / Decrement ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BindCommand.untyped(
                  command: vm.decrementCommand,
                  child: const Icon(Icons.remove),
                  builder: (onPressed, child, _) =>
                      IconButton(onPressed: onPressed, icon: child),
                ),
                const SizedBox(width: 16),
                BindCommand.untyped(
                  command: vm.incrementCommand,
                  child: const Icon(Icons.add),
                  builder: (onPressed, child, _) =>
                      IconButton(onPressed: onPressed, icon: child),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Add 2 (typed command) ---
            BindCommand<int>(
              command: vm.addValueCommand,
              commandParameter: 2,
              child: const Text('Add 2'),
              builder: (onPressed, child, _) =>
                  ElevatedButton(onPressed: onPressed, child: child),
            ),
            const SizedBox(height: 8),

            // --- Async reset with executing indicator ---
            BindCommand.untyped(
              command: vm.resetCommand,
              child: const Text('Reset (2s delay)'),
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

            // --- Error event demo ---
            BindCommand.untyped(
              command: vm.throwErrorCommand,
              child: const Text('Fire Error Event'),
              builder: (onPressed, child, _) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: onPressed,
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
