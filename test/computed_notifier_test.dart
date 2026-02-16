import 'package:community_toolkit/mvvm.dart';
import 'package:community_toolkit/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _CartViewModel extends BaseViewModel {
  late final items = notifier<List<int>>([10, 20]);
  late final taxRate = notifier<double>(0.1);

  late final total = computed<double>(
    watch: [items, taxRate],
    compute: () {
      final subtotal = items.value.fold(0.0, (s, v) => s + v);
      return subtotal * (1 + taxRate.value);
    },
  );
}

void main() {
  group('ComputedNotifier', () {
    test('computes initial value from sources', () {
      // Arrange
      final a = ValueNotifier(2);
      final b = ValueNotifier(3);

      // Act
      final sum = ComputedNotifier<int>(
        sources: [a, b],
        compute: () => a.value + b.value,
      );

      // Assert
      expect(sum.value, 5);
      sum.dispose();
      a.dispose();
      b.dispose();
    });

    test('recomputes when a source changes', () {
      // Arrange
      final a = ValueNotifier(2);
      final b = ValueNotifier(3);
      final sum = ComputedNotifier<int>(
        sources: [a, b],
        compute: () => a.value + b.value,
      );

      // Act
      a.value = 10;

      // Assert
      expect(sum.value, 13);
      sum.dispose();
      a.dispose();
      b.dispose();
    });

    test('does not notify if computed value is unchanged', () {
      // Arrange
      final source = ValueNotifier(5);
      // Always returns the same thing regardless of source value.
      final constant = ComputedNotifier<int>(
        sources: [source],
        compute: () => 42,
      );
      final history = NotifierHistory<int>(constant);

      // Act
      source.value = 10;
      source.value = 20;

      // Assert — no change events because 42 == 42.
      expect(history.count, 0);
      expect(constant.value, 42);
      history.dispose();
      constant.dispose();
      source.dispose();
    });

    test('recompute() forces notification even when value is equal', () {
      // Arrange
      final source = ValueNotifier(5);
      final computed = ComputedNotifier<int>(
        sources: [source],
        compute: () => source.value * 2,
      );
      final history = NotifierHistory<int>(computed);

      // Act — recompute should set value (ValueNotifier notifies on ==).
      computed.recompute();

      // Assert
      expect(history.count, 1);
      expect(computed.value, 10);
      history.dispose();
      computed.dispose();
      source.dispose();
    });

    test('dispose removes listeners from sources', () {
      // Arrange
      final a = ValueNotifier(1);
      final b = ValueNotifier(2);
      final sum = ComputedNotifier<int>(
        sources: [a, b],
        compute: () => a.value + b.value,
      );

      // Act
      sum.dispose();
      a.value = 100; // Should not throw or recompute.

      // Assert — dispose was clean, no dangling listeners.
      expect(sum.value, 3); // Stale value, not recomputed.
      a.dispose();
      b.dispose();
    });
  });

  group('BaseViewModel.computed()', () {
    test('creates auto-disposed ComputedNotifier', () async {
      // Arrange
      final vm = _CartViewModel();
      await vm.initialize();

      // Assert — initial computation.
      expect(vm.total.value, closeTo(33.0, 0.001)); // (10+20)*1.1

      // Act
      vm.items.value = [10, 20, 30];

      // Assert — recomputed.
      expect(vm.total.value, closeTo(66.0, 0.001)); // (60)*1.1

      // Act — dispose VM.
      vm.dispose();

      // Assert — computed notifier is disposed.
      expect(() => vm.total.addListener(() {}), throwsFlutterError);
    });

    test('recomputes when any watched notifier changes', () async {
      // Arrange
      final vm = _CartViewModel();
      await vm.initialize();

      // Act — change tax rate instead of items.
      vm.taxRate.value = 0.2;

      // Assert
      expect(vm.total.value, closeTo(36.0, 0.001)); // (30)*1.2
      vm.dispose();
    });
  });
}
