import 'dart:async';

import 'package:community_toolkit/mvvm.dart';
import 'package:community_toolkit/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SearchViewModel extends BaseViewModel {
  late final query = notifier<String>('');
  late final filters = notifier<int>(0);

  late final results = asyncComputed<List<String>>(
    watch: [query, filters],
    compute: () async {
      if (query.value == 'error') {
        throw Exception('Search failed');
      }
      return ['result-${query.value}-${filters.value}'];
    },
  );
}

void main() {
  // -----------------------------------------------------------------------
  // Core functionality
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier', () {
    test('starts in loading state and computes initial value', () async {
      // Arrange
      final source = ValueNotifier(5);
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async => source.value * 2,
      );

      // Assert — starts as loading.
      expect(notifier.isLoading, isTrue);

      // Act — let the microtask complete.
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.hasData, isTrue);
      expect(notifier.data, 10);

      notifier.dispose();
      source.dispose();
    });

    test('recomputes when a source changes', () async {
      // Arrange
      final source = ValueNotifier(3);
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async => source.value * 10,
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.data, 30);

      // Act
      source.value = 7;
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.data, 70);

      notifier.dispose();
      source.dispose();
    });

    test('recomputes when any of multiple sources change', () async {
      // Arrange
      final a = ValueNotifier(2);
      final b = ValueNotifier(3);
      final notifier = AsyncComputedNotifier<int>(
        sources: [a, b],
        compute: () async => a.value + b.value,
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.data, 5);

      // Act — change second source.
      b.value = 10;
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.data, 12);

      notifier.dispose();
      a.dispose();
      b.dispose();
    });

    test('transitions to AsyncError on exception', () async {
      // Arrange
      final source = ValueNotifier(0);
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async {
          if (source.value == 0) {
            throw Exception('Cannot divide by zero');
          }
          return 100 ~/ source.value;
        },
      );

      // Act
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.hasError, isTrue);
      expect(notifier.error, 'Cannot divide by zero');

      // Act — fix the source.
      source.value = 5;
      await Future<void>.delayed(Duration.zero);

      // Assert — recovers.
      expect(notifier.hasData, isTrue);
      expect(notifier.data, 20);

      notifier.dispose();
      source.dispose();
    });

    test('discards stale results (last-write-wins)', () async {
      // Arrange
      final source = ValueNotifier(1);
      final completers = <int, Completer<int>>{};
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () {
          final v = source.value;
          final c = Completer<int>();
          completers[v] = c;
          return c.future;
        },
      );

      // The initial compute created completer for value 1.
      expect(completers, hasLength(1));

      // Act — trigger a second computation before the first finishes.
      source.value = 2;
      // Give the microtask queue a chance to run _execute.
      await Future<void>.delayed(Duration.zero);
      expect(completers, hasLength(2));

      // Complete the FIRST computation (stale).
      completers[1]!.complete(100);
      await Future<void>.delayed(Duration.zero);

      // Assert — stale result is discarded.
      expect(notifier.isLoading, isTrue);

      // Complete the second computation.
      completers[2]!.complete(200);
      await Future<void>.delayed(Duration.zero);

      // Assert — latest result is used.
      expect(notifier.data, 200);

      notifier.dispose();
      source.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Debounce
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier debounce', () {
    test('coalesces rapid source changes', () async {
      // Arrange
      final source = ValueNotifier(0);
      var computeCount = 0;
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async {
          computeCount++;
          return source.value;
        },
        debounce: const Duration(milliseconds: 50),
      );

      // Wait for initial computation.
      await Future<void>.delayed(Duration.zero);
      final initialCount = computeCount; // 1 (initial)

      // Act — rapid-fire changes.
      source.value = 1;
      source.value = 2;
      source.value = 3;

      // Not enough time for debounce to fire.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(computeCount, initialCount); // No extra computes yet.

      // Wait for debounce + computation.
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Assert — only one additional computation (for value 3).
      expect(computeCount, initialCount + 1);
      expect(notifier.data, 3);

      notifier.dispose();
      source.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // recompute() and refresh()
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier recompute/refresh', () {
    test('recompute() forces re-execution and goes through loading', () async {
      // Arrange
      final source = ValueNotifier(5);
      var callCount = 0;
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async {
          callCount++;
          return source.value;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.data, 5);
      final countAfterInit = callCount;

      // Act
      unawaited(notifier.recompute());

      // Assert — enters loading.
      expect(notifier.isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.data, 5);
      expect(callCount, countAfterInit + 1);

      notifier.dispose();
      source.dispose();
    });

    test('refresh() keeps current value during recomputation', () async {
      // Arrange
      var multiplier = 2;
      final source = ValueNotifier(5);
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async => source.value * multiplier,
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.data, 10);

      // Act — change external state and refresh (without changing source).
      multiplier = 3;
      final refreshFuture = notifier.refresh();

      // Assert — state remains AsyncData during refresh (no loading).
      expect(notifier.hasData, isTrue);
      expect(notifier.data, 10); // Still old value.

      await refreshFuture;

      // Assert — updated after refresh completes.
      expect(notifier.data, 15); // 5 * 3

      notifier.dispose();
      source.dispose();
    });

    test('refresh() handles errors without losing data', () async {
      // Arrange
      final source = ValueNotifier(0);
      var shouldFail = false;
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async {
          if (shouldFail) {
            throw Exception('refresh error');
          }
          return source.value;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.data, 0);

      // Act
      shouldFail = true;
      await notifier.refresh();

      // Assert — error state, but the transition was clean.
      expect(notifier.hasError, isTrue);
      expect(notifier.error, 'refresh error');

      notifier.dispose();
      source.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // withData constructor
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier.withData', () {
    test('starts with data and does not compute initially', () async {
      // Arrange
      var computeCount = 0;
      final source = ValueNotifier(5);
      final notifier = AsyncComputedNotifier<int>.withData(
        sources: [source],
        compute: () async {
          computeCount++;
          return source.value * 2;
        },
        data: 42,
      );

      // Assert — starts with the given data, no computation.
      expect(notifier.hasData, isTrue);
      expect(notifier.data, 42);
      await Future<void>.delayed(Duration.zero);
      expect(computeCount, 0);

      // Act — trigger computation via source change.
      source.value = 10;
      await Future<void>.delayed(Duration.zero);

      // Assert — now recomputed.
      expect(computeCount, 1);
      expect(notifier.data, 20);

      notifier.dispose();
      source.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Convenience getters
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier getters', () {
    test('isLoading, hasData, hasError, data, error', () async {
      // Arrange
      final source = ValueNotifier(0);
      final completer = Completer<int>();
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () => completer.future,
      );

      // Assert — loading state.
      expect(notifier.isLoading, isTrue);
      expect(notifier.hasData, isFalse);
      expect(notifier.hasError, isFalse);
      expect(notifier.data, isNull);
      expect(notifier.error, isNull);

      // Act — complete with data.
      completer.complete(42);
      await Future<void>.delayed(Duration.zero);

      // Assert — data state.
      expect(notifier.isLoading, isFalse);
      expect(notifier.hasData, isTrue);
      expect(notifier.hasError, isFalse);
      expect(notifier.data, 42);
      expect(notifier.error, isNull);

      notifier.dispose();
      source.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Disposal
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier disposal', () {
    test('dispose removes listeners from sources', () async {
      // Arrange
      final source = ValueNotifier(5);
      var computeCount = 0;
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async {
          computeCount++;
          return source.value;
        },
      );
      await Future<void>.delayed(Duration.zero);
      final countAfterInit = computeCount;

      // Act
      notifier.dispose();
      source.value = 100; // Should not trigger compute.
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(computeCount, countAfterInit);

      source.dispose();
    });

    test('dispose discards in-flight computation results', () async {
      // Arrange
      final source = ValueNotifier(5);
      final completer = Completer<int>();
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () => completer.future,
      );
      expect(notifier.isLoading, isTrue);

      // Act — dispose before completion.
      notifier.dispose();
      completer.complete(42);
      await Future<void>.delayed(Duration.zero);

      // Assert — value is not updated (still loading from before dispose).
      expect(notifier.value, isA<AsyncLoading<int>>());

      source.dispose();
    });

    test('dispose cancels debounce timer', () async {
      // Arrange
      final source = ValueNotifier(0);
      var computeCount = 0;
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async {
          computeCount++;
          return source.value;
        },
        debounce: const Duration(milliseconds: 50),
      );
      await Future<void>.delayed(Duration.zero);
      final countAfterInit = computeCount;

      // Act — change source then dispose before debounce fires.
      source.value = 10;
      notifier.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Assert — no additional computation after dispose.
      expect(computeCount, countAfterInit);

      source.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // BaseViewModel extension
  // -----------------------------------------------------------------------

  group('BaseViewModel.asyncComputed()', () {
    test('creates auto-disposed AsyncComputedNotifier', () async {
      // Arrange
      final vm = _SearchViewModel();
      await vm.initialize();

      // Force late field initialization and let initial compute complete.
      // The late field runs its constructor (which triggers _execute) on
      // first access; a second microtask yield lets it finish.
      expect(vm.results.isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);

      // Assert — initial computation completes.
      expect(vm.results.hasData, isTrue);
      expect(vm.results.data, ['result--0']);

      // Act
      vm.query.value = 'flutter';
      await Future<void>.delayed(Duration.zero);

      // Assert — recomputed.
      expect(vm.results.data, ['result-flutter-0']);

      // Act — dispose VM.
      vm.dispose();

      // Assert — notifier is disposed.
      expect(() => vm.results.addListener(() {}), throwsFlutterError);
    });

    test('error propagation through ViewModel', () async {
      // Arrange
      final vm = _SearchViewModel();
      await vm.initialize();

      // Force late field initialization and let initial compute complete.
      expect(vm.results.isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(vm.results.hasData, isTrue);

      // Act — trigger error.
      vm.query.value = 'error';
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(vm.results.hasError, isTrue);
      expect(vm.results.error, 'Search failed');

      vm.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // NotifierHistory integration
  // -----------------------------------------------------------------------

  group('AsyncComputedNotifier history tracking', () {
    test('emits state transitions in order', () async {
      // Arrange
      final source = ValueNotifier(5);
      final notifier = AsyncComputedNotifier<int>(
        sources: [source],
        compute: () async => source.value * 2,
      );
      final history = NotifierHistory<AsyncState<int>>(notifier);

      // Act — wait for initial computation.
      await Future<void>.delayed(Duration.zero);

      // Assert — initial loading→data transition recorded.
      expect(history.values, [isA<AsyncData<int>>()]);
      expect((history.values.first as AsyncData<int>).data, 10);

      // Act — trigger recompute via source.
      source.value = 3;
      await Future<void>.delayed(Duration.zero);

      // Assert — loading→data recorded.
      expect(history.count, 3); // data(10), loading, data(6)

      history.dispose();
      notifier.dispose();
      source.dispose();
    });
  });
}
