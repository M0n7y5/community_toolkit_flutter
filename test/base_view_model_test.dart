import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to let the unawaited _initBaseClass future complete before
/// proceeding. Two microtask ticks are needed: one for the Future to start,
/// one for the await inside _initBaseClass to finish.
Future<void> pumpInit() => Future<void>.delayed(Duration.zero);

class _TestViewModel extends BaseViewModel {
  bool initCalled = false;
  late final count = notifier(0);
  late final name = notifier<String>('');
  late final error = event<String>();
  late final done = signalEvent();
  late final incrementCommand = command.syncUntyped(
    execute: () => count.value++,
  );

  @override
  Future<void> init() async {
    initCalled = true;
  }
}

class _SlowInitViewModel extends BaseViewModel {
  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

class _LegacyViewModel extends BaseViewModel {
  late final count = autoDispose(ValueNotifier<int>(0));
  late final incrementCommand = autoDispose(
    RelayCommand<void>.syncUntyped(execute: () => count.value++),
  );
}

void main() {
  group('BaseViewModel', () {
    test('calls init() on construction', () async {
      final vm = _TestViewModel();
      await pumpInit();
      expect(vm.initCalled, isTrue);
      vm.dispose();
    });

    test('loadingNotifier transitions during init', () async {
      final vm = _SlowInitViewModel();
      // Immediately after construction, loading should be true.
      expect(vm.loadingNotifier.value, isTrue);

      // Wait for init to complete.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(vm.loadingNotifier.value, isFalse);
      vm.dispose();
    });

    test('setLoading updates loadingNotifier', () async {
      final vm = _TestViewModel();
      await pumpInit();
      vm.setLoading(true);
      expect(vm.loadingNotifier.value, isTrue);
      vm.setLoading(false);
      expect(vm.loadingNotifier.value, isFalse);
      vm.dispose();
    });

    test('dispose cleans up all registered disposables', () async {
      final vm = _TestViewModel();
      // Access lazy fields to force initialization.
      vm.count;
      vm.name;
      vm.incrementCommand;
      vm.error;
      vm.done;

      // Wait for init to complete so the unawaited future doesn't fire
      // after dispose.
      await pumpInit();

      vm.dispose();

      // Accessing disposed notifiers should throw.
      expect(() => vm.count.addListener(() {}), throwsFlutterError);
      expect(() => vm.name.addListener(() {}), throwsFlutterError);
    });
  });

  group('BaseViewModel.notifier()', () {
    test('creates a ValueNotifier with initial value', () async {
      final vm = _TestViewModel();
      expect(vm.count.value, 0);
      expect(vm.name.value, '');
      await pumpInit();
      vm.dispose();
    });

    test('created notifier is auto-disposed', () async {
      final vm = _TestViewModel();
      vm.count; // Force lazy init.
      await pumpInit();
      vm.dispose();
      expect(() => vm.count.addListener(() {}), throwsFlutterError);
    });
  });

  group('BaseViewModel.event()', () {
    test('creates a ViewModelEvent that is auto-disposed', () async {
      final vm = _TestViewModel();
      vm.error; // Force lazy init.
      await pumpInit();
      vm.dispose();
      expect(() => vm.error.addListener(() {}), throwsFlutterError);
    });
  });

  group('BaseViewModel.signalEvent()', () {
    test('creates a SignalEvent that is auto-disposed', () async {
      final vm = _TestViewModel();
      vm.done; // Force lazy init.
      await pumpInit();
      vm.dispose();
      expect(() => vm.done.addListener(() {}), throwsFlutterError);
    });
  });

  group('CommandFactory', () {
    test('command.syncUntyped creates an auto-disposed command', () async {
      final vm = _TestViewModel();
      vm.incrementCommand; // Force lazy init.
      await pumpInit();
      await vm.incrementCommand.invoke();
      expect(vm.count.value, 1);
      vm.dispose();
      expect(() => vm.incrementCommand.addListener(() {}), throwsFlutterError);
    });

    test('command.untyped creates an async auto-disposed command', () async {
      var called = false;
      final vm = _TestViewModel();
      await pumpInit();
      final cmd = vm.command.untyped(executeAsync: () async => called = true);
      await cmd.invoke();
      expect(called, isTrue);
      vm.dispose();
    });

    test('command<T> creates a typed auto-disposed command', () async {
      String? received;
      final vm = _TestViewModel();
      await pumpInit();
      final cmd = vm.command<String>(
        executeAsync: (arg) async => received = arg,
      );
      await cmd.execute('hello');
      expect(received, 'hello');
      vm.dispose();
    });

    test(
      'command.sync<T> creates a typed sync auto-disposed command',
      () async {
        int? received;
        final vm = _TestViewModel();
        await pumpInit();
        final cmd = vm.command.sync<int>(execute: (val) => received = val);
        await cmd.execute(42);
        expect(received, 42);
        vm.dispose();
      },
    );
  });

  group('Backward compatibility', () {
    test('autoDispose(ValueNotifier(...)) still works', () async {
      final vm = _LegacyViewModel();
      await pumpInit();
      expect(vm.count.value, 0);
      await vm.incrementCommand.invoke();
      expect(vm.count.value, 1);
      vm.dispose();
    });
  });
}
