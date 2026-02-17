import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForceValueNotifier', () {
    test('notifies when value changes to a different value', () {
      final notifier = ForceValueNotifier<int>(0);
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.value = 1;

      expect(notifier.value, 1);
      expect(notifyCount, 1);
      notifier.dispose();
    });

    test('notifies when value is set to same value', () {
      final notifier = ForceValueNotifier<int>(42);
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.value = 42;

      expect(notifier.value, 42);
      expect(notifyCount, 1);
      notifier.dispose();
    });

    test('notifies exactly once per set for equal values', () {
      final notifier = ForceValueNotifier<String>('hello');
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.value = 'hello';
      notifier.value = 'hello';
      notifier.value = 'hello';

      expect(notifyCount, 3);
      notifier.dispose();
    });

    test('works with complex objects using coarse equality', () {
      final notifier = ForceValueNotifier<_Entity>(_Entity(1, 'old'));
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      // Same ID (equals by ID), but different name.
      notifier.value = _Entity(1, 'updated');

      expect(notifyCount, 1);
      expect(notifier.value.name, 'updated');
      notifier.dispose();
    });
  });

  group('ForceNotifierViewModelExtension', () {
    test('creates auto-disposed ForceValueNotifier', () {
      final vm = _TestVm();

      expect(vm.entityNotifier, isA<ForceValueNotifier<String?>>());
      expect(vm.entityNotifier.value, isNull);

      vm.dispose();
    });
  });

  group('ValueNotifierExtensions', () {
    test('update applies transformation and notifies', () {
      final notifier = ValueNotifier<List<int>>([1, 2]);
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.update((items) => [...items, 3]);

      expect(notifier.value, [1, 2, 3]);
      expect(notifyCount, 1);
      notifier.dispose();
    });

    test('update with no change still sets value', () {
      final notifier = ValueNotifier<int>(5);
      var notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      // ValueNotifier suppresses notification for equal values.
      notifier.update((v) => v);

      expect(notifier.value, 5);
      // Standard ValueNotifier: no notification for equal value.
      expect(notifyCount, 0);
      notifier.dispose();
    });

    test('update works with mutable state', () {
      final notifier = ValueNotifier<Map<String, int>>({'a': 1});

      notifier.update((map) => {...map, 'b': 2});

      expect(notifier.value, {'a': 1, 'b': 2});
      notifier.dispose();
    });
  });
}

class _Entity {
  final int id;
  final String name;
  _Entity(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _Entity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _TestVm extends BaseViewModel {
  late final entityNotifier = forceNotifier<String?>(null);
}
