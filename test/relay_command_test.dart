import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RelayCommand - typed async', () {
    test('executes with parameter', () async {
      String? received;
      final cmd = RelayCommand<String>(
        executeAsync: (arg) async => received = arg,
      );
      await cmd.execute('test');
      expect(received, 'test');
      cmd.dispose();
    });

    test('canExecute defaults to true', () {
      final cmd = RelayCommand<int>(executeAsync: (arg) async {});
      expect(cmd.canExecute(1), isTrue);
      cmd.dispose();
    });

    test('canExecute respects predicate', () {
      final cmd = RelayCommand<int>(
        executeAsync: (arg) async {},
        canExecute: (arg) => arg > 0,
      );
      expect(cmd.canExecute(1), isTrue);
      expect(cmd.canExecute(-1), isFalse);
      cmd.dispose();
    });

    test('canExecute returns false while executing', () async {
      final completer = Future<void>.delayed(const Duration(milliseconds: 50));
      final cmd = RelayCommand<void>.untyped(executeAsync: () => completer);
      final future = cmd.invoke();
      expect(cmd.canExecute(), isFalse);
      expect(cmd.isExecuting, isTrue);
      await future;
      expect(cmd.canExecute(), isTrue);
      expect(cmd.isExecuting, isFalse);
      cmd.dispose();
    });

    test('does not execute when canExecute is false', () async {
      var called = false;
      final cmd = RelayCommand<int>(
        executeAsync: (arg) async => called = true,
        canExecute: (arg) => false,
      );
      await cmd.execute(1);
      expect(called, isFalse);
      cmd.dispose();
    });
  });

  group('RelayCommand - untyped', () {
    test('executes without parameter', () async {
      var called = false;
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async => called = true,
      );
      await cmd.invoke();
      expect(called, isTrue);
      cmd.dispose();
    });
  });

  group('RelayCommand - sync variants', () {
    test('sync executes with parameter', () async {
      int? received;
      final cmd = RelayCommand<int>.sync(execute: (val) => received = val);
      await cmd.execute(42);
      expect(received, 42);
      cmd.dispose();
    });

    test('syncUntyped executes without parameter', () async {
      var called = false;
      final cmd = RelayCommand<void>.syncUntyped(execute: () => called = true);
      await cmd.invoke();
      expect(called, isTrue);
      cmd.dispose();
    });
  });

  group('RelayCommand - invoke()', () {
    test('invoke is equivalent to execute()', () async {
      var count = 0;
      final cmd = RelayCommand<void>.untyped(executeAsync: () async => count++);
      await cmd.invoke();
      await cmd.invoke();
      expect(count, 2);
      cmd.dispose();
    });
  });

  group('RelayCommand - error handling', () {
    test('catches Exception and writes to errorNotifier', () async {
      final errorNotifier = ValueNotifier<String?>(null);
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async => throw Exception('boom'),
        errorNotifier: errorNotifier,
      );
      await cmd.invoke();
      expect(errorNotifier.value, 'boom');
      expect(cmd.isExecuting, isFalse);
      cmd.dispose();
      errorNotifier.dispose();
    });

    test('catches non-Exception errors', () async {
      final errorNotifier = ValueNotifier<String?>(null);
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async => throw 'string error',
        errorNotifier: errorNotifier,
      );
      await cmd.invoke();
      expect(errorNotifier.value, 'string error');
      cmd.dispose();
      errorNotifier.dispose();
    });

    test('clears errorNotifier before each execution', () async {
      final errorNotifier = ValueNotifier<String?>('old error');
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async {},
        errorNotifier: errorNotifier,
      );
      await cmd.invoke();
      expect(errorNotifier.value, isNull);
      cmd.dispose();
      errorNotifier.dispose();
    });
  });

  group('RelayCommand - executingNotifier', () {
    test('transitions correctly during execution', () async {
      final states = <bool>[];
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
      );
      cmd.executingNotifier.addListener(() {
        states.add(cmd.executingNotifier.value);
      });
      await cmd.invoke();
      expect(states, [true, false]);
      cmd.dispose();
    });
  });

  group('RelayCommand - listenables', () {
    test('re-notifies when external listenable changes', () {
      final external = ValueNotifier<int>(0);
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async {},
        canExecute: () => external.value > 0,
        listenables: [external],
      );
      var notifyCount = 0;
      cmd.addListener(() => notifyCount++);

      expect(cmd.canExecute(), isFalse);
      external.value = 1;
      expect(cmd.canExecute(), isTrue);
      expect(notifyCount, greaterThan(0));

      cmd.dispose();
      external.dispose();
    });
  });

  group('RelayCommand - requery', () {
    test('fires notifyListeners', () {
      final cmd = RelayCommand<void>.untyped(executeAsync: () async {});
      var notified = false;
      cmd.addListener(() => notified = true);
      cmd.requery();
      expect(notified, isTrue);
      cmd.dispose();
    });
  });

  group('RelayCommand - dispose', () {
    test('removes listeners from external listenables', () {
      final external = ValueNotifier<int>(0);
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async {},
        listenables: [external],
      );
      cmd.dispose();

      // Modifying external should not throw or interact with disposed cmd.
      external.value = 1;
      external.dispose();
    });
  });
}
