import 'package:community_toolkit/mvvm.dart';
import 'package:community_toolkit/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // -----------------------------------------------------------------------
  // AsyncState sealed class
  // -----------------------------------------------------------------------

  group('AsyncState', () {
    test('type predicates are correct', () {
      const AsyncState<int> loading = AsyncLoading();
      const AsyncState<int> data = AsyncData(42);
      const AsyncState<int> error = AsyncError('fail');

      expect(loading.isLoading, isTrue);
      expect(loading.hasData, isFalse);
      expect(loading.hasError, isFalse);

      expect(data.isLoading, isFalse);
      expect(data.hasData, isTrue);
      expect(data.hasError, isFalse);

      expect(error.isLoading, isFalse);
      expect(error.hasData, isFalse);
      expect(error.hasError, isTrue);
    });

    test('dataOrNull and errorOrNull', () {
      const AsyncState<int> loading = AsyncLoading();
      const AsyncState<int> data = AsyncData(42);
      const AsyncState<int> error = AsyncError('fail');

      expect(loading.dataOrNull, isNull);
      expect(loading.errorOrNull, isNull);
      expect(data.dataOrNull, 42);
      expect(data.errorOrNull, isNull);
      expect(error.dataOrNull, isNull);
      expect(error.errorOrNull, 'fail');
    });

    test('when() calls correct callback', () {
      const AsyncState<int> data = AsyncData(7);
      final result = data.when(
        loading: () => 'loading',
        data: (v) => 'data:$v',
        error: (m) => 'error:$m',
      );
      expect(result, 'data:7');
    });

    test('map() passes full subtype', () {
      const AsyncState<int> loading = AsyncLoading(progress: 0.5);
      final result = loading.map(
        loading: (s) => 'progress:${s.progress}',
        data: (s) => 'data',
        error: (s) => 'error',
      );
      expect(result, 'progress:0.5');
    });

    test('maybeWhen() falls back to orElse', () {
      const AsyncState<int> loading = AsyncLoading();
      final result = loading.maybeWhen(
        onData: (v) => 'data:$v',
        orElse: () => 'fallback',
      );
      expect(result, 'fallback');
    });
  });

  // -----------------------------------------------------------------------
  // AsyncLoading with progress
  // -----------------------------------------------------------------------

  group('AsyncLoading', () {
    test('default progress is null', () {
      const loading = AsyncLoading<int>();
      expect(loading.progress, isNull);
    });

    test('progress value is stored', () {
      const loading = AsyncLoading<int>(progress: 0.75);
      expect(loading.progress, 0.75);
    });

    test('equality includes progress', () {
      const a = AsyncLoading<int>();
      const b = AsyncLoading<int>(progress: 0.5);
      const c = AsyncLoading<int>(progress: 0.5);
      const d = AsyncLoading<int>();

      expect(a, equals(d));
      expect(b, equals(c));
      expect(a, isNot(equals(b)));
    });

    test('toString includes progress when present', () {
      expect(const AsyncLoading<int>().toString(), 'AsyncLoading<int>()');
      expect(
        const AsyncLoading<int>(progress: 0.5).toString(),
        'AsyncLoading<int>(progress: 0.5)',
      );
    });
  });

  // -----------------------------------------------------------------------
  // RetryPolicy
  // -----------------------------------------------------------------------

  group('RetryPolicy', () {
    test('has sensible defaults', () {
      const policy = RetryPolicy();
      expect(policy.maxRetries, 5);
      expect(policy.baseDelay, const Duration(milliseconds: 200));
      expect(policy.maxDelay, const Duration(seconds: 6));
    });
  });

  // -----------------------------------------------------------------------
  // AsyncStateNotifier basics
  // -----------------------------------------------------------------------

  group('AsyncStateNotifier', () {
    test('starts in loading state', () {
      final n = AsyncStateNotifier<int>();
      expect(n, isAsyncLoading);
      n.dispose();
    });

    test('withData starts in data state', () {
      final n = AsyncStateNotifier<int>.withData(42);
      expect(n, hasAsyncData<int>(42));
      n.dispose();
    });

    test('execute transitions loading → data', () async {
      // Arrange
      final n = AsyncStateNotifier<int>();
      final history = NotifierHistory<AsyncState<int>>(n);

      // Act
      await n.execute(() async => 99);

      // Assert
      expect(n, hasAsyncData<int>(99));
      // History: initial loading is the constructor default,
      // execute sets loading again (same value), then data.
      expect(history.values.last, isA<AsyncData<int>>());
      history.dispose();
      n.dispose();
    });

    test('execute transitions loading → error on failure', () async {
      // Arrange
      final n = AsyncStateNotifier<int>();

      // Act
      await n.execute(() async => throw Exception('boom'));

      // Assert
      expect(n, isAsyncError);
      expect(n, hasAsyncError(contains('boom')));
      n.dispose();
    });

    test('setProgress updates loading state', () {
      // Arrange
      final n = AsyncStateNotifier<int>();

      // Act
      n.setProgress(0.5);

      // Assert
      final state = n.value;
      expect(state, isA<AsyncLoading<int>>());
      expect((state as AsyncLoading<int>).progress, 0.5);
      n.dispose();
    });

    test('setProgress is ignored when not loading', () {
      // Arrange
      final n = AsyncStateNotifier<int>.withData(42);

      // Act
      n.setProgress(0.5);

      // Assert — still data, not loading.
      expect(n, hasAsyncData<int>(42));
      n.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Retry
  // -----------------------------------------------------------------------

  group('AsyncStateNotifier.execute with retry', () {
    test('succeeds on first try', () async {
      // Arrange
      final n = AsyncStateNotifier<int>();

      // Act
      await n.execute(() async => 42, retry: const RetryPolicy(maxRetries: 3));

      // Assert
      expect(n, hasAsyncData<int>(42));
      n.dispose();
    });

    test('succeeds after retries', () async {
      // Arrange
      var attempt = 0;
      final n = AsyncStateNotifier<int>();

      // Act — fail twice, succeed on third.
      await n.execute(
        () async {
          attempt++;
          if (attempt < 3) {
            throw Exception('transient');
          }
          return 99;
        },
        retry: const RetryPolicy(
          maxRetries: 5,
          baseDelay: Duration(milliseconds: 1),
          maxDelay: Duration(milliseconds: 10),
        ),
      );

      // Assert
      expect(n, hasAsyncData<int>(99));
      expect(attempt, 3);
      n.dispose();
    });

    test('fails after exhausting retries', () async {
      // Arrange
      var attempt = 0;
      final n = AsyncStateNotifier<int>();

      // Act
      await n.execute(
        () async {
          attempt++;
          throw Exception('permanent');
        },
        retry: const RetryPolicy(
          maxRetries: 2,
          baseDelay: Duration(milliseconds: 1),
          maxDelay: Duration(milliseconds: 5),
        ),
      );

      // Assert — 1 initial + 2 retries = 3 attempts.
      expect(attempt, 3);
      expect(n, isAsyncError);
      expect(n, hasAsyncError(contains('permanent')));
      n.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Invalidate / Refresh
  // -----------------------------------------------------------------------

  group('AsyncStateNotifier.invalidate', () {
    test('re-executes last action', () async {
      // Arrange
      var callCount = 0;
      final n = AsyncStateNotifier<int>();
      await n.execute(() async {
        callCount++;
        return callCount;
      });
      expect(n, hasAsyncData<int>(1));

      // Act
      await n.invalidate();

      // Assert
      expect(callCount, 2);
      expect(n, hasAsyncData<int>(2));
      n.dispose();
    });

    test('is a no-op if execute was never called', () async {
      // Arrange
      final n = AsyncStateNotifier<int>.withData(42);

      // Act
      await n.invalidate();

      // Assert — unchanged.
      expect(n, hasAsyncData<int>(42));
      n.dispose();
    });
  });

  group('AsyncStateNotifier.refresh', () {
    test('does not enter loading state', () async {
      // Arrange
      final n = AsyncStateNotifier<int>.withData(1);
      final history = NotifierHistory<AsyncState<int>>(n);

      // Act
      await n.refresh(() async => 2);

      // Assert — no AsyncLoading in history.
      expect(history.values, isNot(contains(isA<AsyncLoading<int>>())));
      expect(n, hasAsyncData<int>(2));
      history.dispose();
      n.dispose();
    });

    test('uses last action when called without argument', () async {
      // Arrange
      var counter = 0;
      final n = AsyncStateNotifier<int>();
      await n.execute(() async => ++counter);
      expect(n, hasAsyncData<int>(1));

      // Act
      await n.refresh();

      // Assert
      expect(counter, 2);
      expect(n, hasAsyncData<int>(2));
      n.dispose();
    });

    test('is a no-op without action or prior execute', () async {
      // Arrange
      final n = AsyncStateNotifier<int>.withData(42);

      // Act
      await n.refresh();

      // Assert
      expect(n, hasAsyncData<int>(42));
      n.dispose();
    });
  });

  // -----------------------------------------------------------------------
  // Matchers
  // -----------------------------------------------------------------------

  group('AsyncState matchers', () {
    test('isAsyncLoading / isAsyncData / isAsyncError', () {
      final loading = AsyncStateNotifier<int>();
      final data = AsyncStateNotifier<int>.withData(1);
      final error = AsyncStateNotifier<int>()..setError('oops');

      expect(loading, isAsyncLoading);
      expect(data, isAsyncData);
      expect(error, isAsyncError);

      expect(loading, isNot(isAsyncData));
      expect(data, isNot(isAsyncError));
      expect(error, isNot(isAsyncLoading));

      loading.dispose();
      data.dispose();
      error.dispose();
    });

    test('hasAsyncData matches inner value', () {
      final n = AsyncStateNotifier<String>.withData('hello');
      expect(n, hasAsyncData<String>('hello'));
      expect(n, hasAsyncData<String>(startsWith('he')));
      expect(n, isNot(hasAsyncData<String>('world')));
      n.dispose();
    });

    test('hasAsyncError matches message', () {
      final n = AsyncStateNotifier<int>()..setError('timeout');
      expect(n, hasAsyncError('timeout'));
      expect(n, hasAsyncError(contains('time')));
      n.dispose();
    });
  });
}
